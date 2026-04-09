import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
@Observable
final class UserProfileStore {
    static let shared = UserProfileStore()

    private let db: Firestore
    private var bootstrapTask: Task<Void, Never>?
    private var lastBootstrappedUID: String?

    var currentProfile: FirestoreUserProfile?
    var isBootstrapping = false
    var errorMessage: String?

    init(db: Firestore? = nil) {
        FirebaseConfiguration.ensureConfigured()
        self.db = db ?? Firestore.firestore()
    }

    func handleAuthStateChange(user: FirebaseAuth.User?) {
        bootstrapTask?.cancel()
        errorMessage = nil

        guard let user else {
            currentProfile = nil
            lastBootstrappedUID = nil
            return
        }

        if lastBootstrappedUID == user.uid, currentProfile?.uid == user.uid {
            return
        }

        bootstrapTask = Task { [weak self] in
            await self?.bootstrapSignedInUser(user)
        }
    }

    func createInitialProfile(for user: FirebaseAuth.User) async {
        await bootstrap(user: user, createIfMissing: true)
    }

    func bootstrapSignedInUser(_ user: FirebaseAuth.User) async {
        await bootstrap(user: user, createIfMissing: false)
    }

    func refreshCurrentProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            let snapshot = try await userDocument(uid: uid).getDocument()
            currentProfile = FirestoreUserProfile(document: snapshot)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func bootstrap(user: FirebaseAuth.User, createIfMissing: Bool) async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        let profile = FirestoreUserProfile(user: user)

        do {
            let document = userDocument(uid: user.uid)
            let snapshot = try await document.getDocument()

            if !snapshot.exists {
                try await document.setData(sanitized(profile.createData))
            } else {
                let payload = createIfMissing ? sanitized(profile.createData) : sanitized(profile.mergeData)
                try await document.setData(payload, merge: true)
            }

            let refreshedSnapshot = try await document.getDocument()
            guard !Task.isCancelled else { return }

            currentProfile = FirestoreUserProfile(document: refreshedSnapshot) ?? profile
            lastBootstrappedUID = user.uid
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func userDocument(uid: String) -> DocumentReference {
        db.collection(FirestorePath.users).document(uid)
    }

    private func sanitized(_ input: [String: Any]) -> [String: Any] {
        input.compactMapValues { value in
            if value is NSNull {
                return nil
            }

            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                return mirror.children.first?.value
            }

            return value
        }
    }
}
