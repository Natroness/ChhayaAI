import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
@Observable
final class FriendService {
    static let shared = FriendService()

    private let db: Firestore
    private var incomingListener: ListenerRegistration?
    private var outgoingListener: ListenerRegistration?
    private var acceptedListener: ListenerRegistration?
    private var currentUID: String?

    var incomingRequests: [FriendRequestRecord] = []
    var outgoingRequests: [FriendRequestRecord] = []
    var acceptedFriends: [FriendRecord] = []
    var searchResult: FirestoreUserProfile?
    var isSearching = false
    var isSendingRequest = false
    var isUpdatingRequest = false
    var errorMessage: String?
    var successMessage: String?

    init(db: Firestore? = nil) {
        FirebaseConfiguration.ensureConfigured()
        self.db = db ?? Firestore.firestore()
    }

    func handleAuthStateChange(user: FirebaseAuth.User?) {
        stopListeners()
        searchResult = nil
        errorMessage = nil
        successMessage = nil
        incomingRequests = []
        outgoingRequests = []
        acceptedFriends = []
        currentUID = user?.uid

        guard let user else { return }
        startListeners(for: user)
    }

    func searchUser(byEmail rawEmail: String) async {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else {
            errorMessage = "Enter an email address to find a close friend."
            searchResult = nil
            return
        }

        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Sign in again to search for users."
            searchResult = nil
            return
        }

        if currentUser.email?.lowercased() == email {
            errorMessage = "Use a different email address. You cannot add yourself."
            searchResult = nil
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let snapshot = try await db.collection(FirestorePath.users)
                .whereField(FirestoreUserField.email, isEqualTo: email)
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first,
                  let profile = FirestoreUserProfile(document: document) else {
                searchResult = nil
                errorMessage = "No ChhayaAI user was found for that email."
                return
            }

            if acceptedFriends.contains(where: { $0.friendUid == profile.uid }) {
                searchResult = profile
                errorMessage = "\(profile.displayName) is already in your close friends list."
                return
            }

            searchResult = profile
            errorMessage = nil
            successMessage = nil
        } catch {
            searchResult = nil
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(to target: FirestoreUserProfile) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Sign in again to send a friend request."
            return
        }

        if currentUser.uid == target.uid {
            errorMessage = "You cannot send a request to yourself."
            return
        }

        if acceptedFriends.contains(where: { $0.friendUid == target.uid }) {
            errorMessage = "\(target.displayName) is already in your close friends list."
            return
        }

        if outgoingRequests.contains(where: { $0.toUid == target.uid && $0.status == .pending }) {
            errorMessage = "A pending request already exists for \(target.displayName)."
            return
        }

        if incomingRequests.contains(where: { $0.fromUid == target.uid && $0.status == .pending }) {
            errorMessage = "\(target.displayName) already sent you a request. Accept it below."
            return
        }

        isSendingRequest = true
        defer { isSendingRequest = false }

        let payload: [String: Any] = [
            FirestoreFriendRequestField.fromUid: currentUser.uid,
            FirestoreFriendRequestField.fromDisplayName: currentUser.displayName ?? currentUser.email?.components(separatedBy: "@").first ?? "User",
            FirestoreFriendRequestField.fromEmail: currentUser.email as Any,
            FirestoreFriendRequestField.toUid: target.uid,
            FirestoreFriendRequestField.toDisplayName: target.displayName,
            FirestoreFriendRequestField.toEmail: target.email as Any,
            FirestoreFriendRequestField.status: FriendRequestStatus.pending.rawValue,
            FirestoreFriendRequestField.createdAt: FieldValue.serverTimestamp(),
            FirestoreFriendRequestField.respondedAt: NSNull(),
        ]

        do {
            try await db.collection(FirestorePath.friendRequests).addDocument(data: payload)
            successMessage = "Friend request sent to \(target.displayName)."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ request: FriendRequestRecord) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Sign in again to accept this request."
            return
        }

        isUpdatingRequest = true
        defer { isUpdatingRequest = false }

        let requestRef = db.collection(FirestorePath.friendRequests).document(request.id)
        let myFriendRef = db.collection(FirestorePath.users)
            .document(currentUser.uid)
            .collection(FirestorePath.friends)
            .document(request.fromUid)
        let theirFriendRef = db.collection(FirestorePath.users)
            .document(request.fromUid)
            .collection(FirestorePath.friends)
            .document(currentUser.uid)

        let myDisplayName = currentUser.displayName ?? currentUser.email?.components(separatedBy: "@").first ?? "User"

        let batch = db.batch()
        batch.updateData([
            FirestoreFriendRequestField.status: FriendRequestStatus.accepted.rawValue,
            FirestoreFriendRequestField.respondedAt: FieldValue.serverTimestamp(),
        ], forDocument: requestRef)
        batch.setData(friendPayload(friendUid: request.fromUid, displayName: request.fromDisplayName, email: request.fromEmail), forDocument: myFriendRef, merge: true)
        batch.setData(friendPayload(friendUid: currentUser.uid, displayName: myDisplayName, email: currentUser.email), forDocument: theirFriendRef, merge: true)

        do {
            try await batch.commit()
            successMessage = "You and \(request.fromDisplayName) are now close friends."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ request: FriendRequestRecord) async {
        await update(request: request, status: .declined, success: "Friend request declined.")
    }

    func cancel(_ request: FriendRequestRecord) async {
        await update(request: request, status: .cancelled, success: "Friend request cancelled.")
    }

    private func startListeners(for user: FirebaseAuth.User) {
        incomingListener = db.collection(FirestorePath.friendRequests)
            .whereField(FirestoreFriendRequestField.toUid, isEqualTo: user.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let records = snapshot?.documents.compactMap(FriendRequestRecord.init(document:)) ?? []
                    self.incomingRequests = records.sorted(by: self.requestSort)
                }
            }

        outgoingListener = db.collection(FirestorePath.friendRequests)
            .whereField(FirestoreFriendRequestField.fromUid, isEqualTo: user.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let records = snapshot?.documents.compactMap(FriendRequestRecord.init(document:)) ?? []
                    self.outgoingRequests = records.sorted(by: self.requestSort)
                }
            }

        acceptedListener = db.collection(FirestorePath.users)
            .document(user.uid)
            .collection(FirestorePath.friends)
            .whereField(FirestoreFriendField.status, isEqualTo: FriendRequestStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    let records = snapshot?.documents.compactMap(FriendRecord.init(document:)) ?? []
                    self.acceptedFriends = records.sorted(by: self.friendSort)
                }
            }
    }

    private func stopListeners() {
        incomingListener?.remove()
        outgoingListener?.remove()
        acceptedListener?.remove()
        incomingListener = nil
        outgoingListener = nil
        acceptedListener = nil
    }

    private func update(request: FriendRequestRecord, status: FriendRequestStatus, success: String) async {
        isUpdatingRequest = true
        defer { isUpdatingRequest = false }

        do {
            try await db.collection(FirestorePath.friendRequests)
                .document(request.id)
                .updateData([
                    FirestoreFriendRequestField.status: status.rawValue,
                    FirestoreFriendRequestField.respondedAt: FieldValue.serverTimestamp(),
                ])
            successMessage = success
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func friendPayload(friendUid: String, displayName: String, email: String?) -> [String: Any] {
        [
            FirestoreFriendField.friendUid: friendUid,
            FirestoreFriendField.displayName: displayName,
            FirestoreFriendField.email: email as Any,
            FirestoreFriendField.status: FriendRequestStatus.accepted.rawValue,
            FirestoreFriendField.canSeeLocation: true,
            FirestoreFriendField.canReceiveSOS: true,
            FirestoreFriendField.createdAt: FieldValue.serverTimestamp(),
            FirestoreFriendField.updatedAt: FieldValue.serverTimestamp(),
        ]
    }

    private func requestSort(_ lhs: FriendRequestRecord, _ rhs: FriendRequestRecord) -> Bool {
        let lhsDate = lhs.createdAt ?? .distantPast
        let rhsDate = rhs.createdAt ?? .distantPast
        if lhsDate != rhsDate {
            return lhsDate > rhsDate
        }
        return lhs.id > rhs.id
    }

    private func friendSort(_ lhs: FriendRecord, _ rhs: FriendRecord) -> Bool {
        let lhsName = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
        if lhsName != .orderedSame {
            return lhsName == .orderedAscending
        }
        return lhs.friendUid < rhs.friendUid
    }
}
