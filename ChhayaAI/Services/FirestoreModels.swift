import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

enum FirestorePath {
    static let users = "users"
    static let friendRequests = "friend_requests"
    static let friends = "friends"
}

enum FirestoreUserField {
    static let uid = "uid"
    static let displayName = "displayName"
    static let email = "email"
    static let photoURL = "photoURL"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
    static let locationSharingEnabled = "locationSharingEnabled"
    static let sosEnabled = "sosEnabled"
}

enum FirestoreFriendRequestField {
    static let fromUid = "fromUid"
    static let fromDisplayName = "fromDisplayName"
    static let fromEmail = "fromEmail"
    static let toUid = "toUid"
    static let toDisplayName = "toDisplayName"
    static let toEmail = "toEmail"
    static let status = "status"
    static let createdAt = "createdAt"
    static let respondedAt = "respondedAt"
}

enum FirestoreFriendField {
    static let friendUid = "friendUid"
    static let displayName = "displayName"
    static let email = "email"
    static let status = "status"
    static let canSeeLocation = "canSeeLocation"
    static let canReceiveSOS = "canReceiveSOS"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
}

struct FirestoreUserProfile: Identifiable, Equatable {
    let id: String
    let uid: String
    let displayName: String
    let email: String?
    let photoURL: String?
    let createdAt: Date?
    let updatedAt: Date?
    let locationSharingEnabled: Bool
    let sosEnabled: Bool

    init(
        uid: String,
        displayName: String,
        email: String?,
        photoURL: String?,
        createdAt: Date?,
        updatedAt: Date?,
        locationSharingEnabled: Bool = true,
        sosEnabled: Bool = true
    ) {
        self.id = uid
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.locationSharingEnabled = locationSharingEnabled
        self.sosEnabled = sosEnabled
    }

    init(user: FirebaseAuth.User) {
        self.init(
            uid: user.uid,
            displayName: user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User",
            email: user.email,
            photoURL: user.photoURL?.absoluteString,
            createdAt: nil,
            updatedAt: nil
        )
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        let uid = (data[FirestoreUserField.uid] as? String) ?? document.documentID
        let displayName = (data[FirestoreUserField.displayName] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let displayName, !displayName.isEmpty else { return nil }

        self.init(
            uid: uid,
            displayName: displayName,
            email: data[FirestoreUserField.email] as? String,
            photoURL: data[FirestoreUserField.photoURL] as? String,
            createdAt: (data[FirestoreUserField.createdAt] as? Timestamp)?.dateValue(),
            updatedAt: (data[FirestoreUserField.updatedAt] as? Timestamp)?.dateValue(),
            locationSharingEnabled: data[FirestoreUserField.locationSharingEnabled] as? Bool ?? true,
            sosEnabled: data[FirestoreUserField.sosEnabled] as? Bool ?? true
        )
    }

    var createData: [String: Any] {
        [
            FirestoreUserField.uid: uid,
            FirestoreUserField.displayName: displayName,
            FirestoreUserField.email: email as Any,
            FirestoreUserField.photoURL: photoURL as Any,
            FirestoreUserField.createdAt: FieldValue.serverTimestamp(),
            FirestoreUserField.updatedAt: FieldValue.serverTimestamp(),
            FirestoreUserField.locationSharingEnabled: locationSharingEnabled,
            FirestoreUserField.sosEnabled: sosEnabled,
        ]
    }

    var mergeData: [String: Any] {
        [
            FirestoreUserField.uid: uid,
            FirestoreUserField.displayName: displayName,
            FirestoreUserField.email: email as Any,
            FirestoreUserField.photoURL: photoURL as Any,
            FirestoreUserField.updatedAt: FieldValue.serverTimestamp(),
            FirestoreUserField.locationSharingEnabled: locationSharingEnabled,
            FirestoreUserField.sosEnabled: sosEnabled,
        ]
    }
}

enum FriendRequestStatus: String, CaseIterable {
    case pending
    case accepted
    case declined
    case cancelled

    var label: String {
        rawValue.capitalized
    }
}

struct FriendRequestRecord: Identifiable, Equatable {
    let id: String
    let fromUid: String
    let fromDisplayName: String
    let fromEmail: String?
    let toUid: String
    let toDisplayName: String?
    let toEmail: String?
    let status: FriendRequestStatus
    let createdAt: Date?
    let respondedAt: Date?

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard
            let fromUid = data[FirestoreFriendRequestField.fromUid] as? String,
            let fromDisplayName = data[FirestoreFriendRequestField.fromDisplayName] as? String,
            let toUid = data[FirestoreFriendRequestField.toUid] as? String,
            let rawStatus = data[FirestoreFriendRequestField.status] as? String,
            let status = FriendRequestStatus(rawValue: rawStatus.lowercased())
        else {
            return nil
        }

        self.id = document.documentID
        self.fromUid = fromUid
        self.fromDisplayName = fromDisplayName
        self.fromEmail = data[FirestoreFriendRequestField.fromEmail] as? String
        self.toUid = toUid
        self.toDisplayName = data[FirestoreFriendRequestField.toDisplayName] as? String
        self.toEmail = data[FirestoreFriendRequestField.toEmail] as? String
        self.status = status
        self.createdAt = (data[FirestoreFriendRequestField.createdAt] as? Timestamp)?.dateValue()
        self.respondedAt = (data[FirestoreFriendRequestField.respondedAt] as? Timestamp)?.dateValue()
    }
}

// MARK: - Emergency Operators

enum FirestoreOperatorPath {
    static let emergencyOperators = "emergency_operators"
}

enum FirestoreOperatorField {
    static let operatorId = "operatorId"
    static let type = "type"
    static let label = "label"
    static let description = "description"
    static let phone = "phone"
    static let lat = "lat"
    static let lon = "lon"
    static let status = "status"
    static let synthetic = "synthetic"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
}

enum EmergencyOperatorType: String, CaseIterable {
    case ambulance
    case firetruck
    case police

    var displayName: String {
        switch self {
        case .ambulance:  return "Ambulance"
        case .firetruck:  return "Fire Truck"
        case .police:     return "Police"
        }
    }

    var systemImage: String {
        switch self {
        case .ambulance:  return "cross.case.fill"
        case .firetruck:  return "flame.fill"
        case .police:     return "shield.lefthalf.filled"
        }
    }

    var markerColor: UIColor {
        switch self {
        case .ambulance:  return .systemRed
        case .firetruck:  return .systemOrange
        case .police:     return .systemIndigo
        }
    }
}

struct EmergencyOperatorRecord: Identifiable, Equatable {
    let id: String
    let operatorId: String
    let type: EmergencyOperatorType
    let label: String
    let operatorDescription: String
    let phone: String
    let lat: Double
    let lon: Double
    let status: String
    let synthetic: Bool
    let createdAt: Date?
    let updatedAt: Date?

    var distanceMeters: Double?

    var formattedDistance: String {
        guard let d = distanceMeters else { return "Unknown" }
        if d < 1000 {
            return "\(Int(d))m away"
        }
        return String(format: "%.1f km away", d / 1000)
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard
            let operatorId = data[FirestoreOperatorField.operatorId] as? String,
            let rawType = data[FirestoreOperatorField.type] as? String,
            let type = EmergencyOperatorType(rawValue: rawType),
            let label = data[FirestoreOperatorField.label] as? String,
            let lat = data[FirestoreOperatorField.lat] as? Double,
            let lon = data[FirestoreOperatorField.lon] as? Double
        else { return nil }

        self.id = operatorId
        self.operatorId = operatorId
        self.type = type
        self.label = label
        self.operatorDescription = (data[FirestoreOperatorField.description] as? String) ?? ""
        self.phone = (data[FirestoreOperatorField.phone] as? String) ?? ""
        self.lat = lat
        self.lon = lon
        self.status = (data[FirestoreOperatorField.status] as? String) ?? "available"
        self.synthetic = (data[FirestoreOperatorField.synthetic] as? Bool) ?? false
        self.createdAt = (data[FirestoreOperatorField.createdAt] as? Timestamp)?.dateValue()
        self.updatedAt = (data[FirestoreOperatorField.updatedAt] as? Timestamp)?.dateValue()
        self.distanceMeters = nil
    }
}

// MARK: - Friend Records

struct FriendRecord: Identifiable, Equatable {
    let id: String
    let friendUid: String
    let displayName: String
    let email: String?
    let status: String
    let canSeeLocation: Bool
    let canReceiveSOS: Bool
    let createdAt: Date?
    let updatedAt: Date?

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard
            let friendUid = data[FirestoreFriendField.friendUid] as? String,
            let displayName = data[FirestoreFriendField.displayName] as? String
        else {
            return nil
        }

        self.id = friendUid
        self.friendUid = friendUid
        self.displayName = displayName
        self.email = data[FirestoreFriendField.email] as? String
        self.status = (data[FirestoreFriendField.status] as? String) ?? FriendRequestStatus.accepted.rawValue
        self.canSeeLocation = data[FirestoreFriendField.canSeeLocation] as? Bool ?? true
        self.canReceiveSOS = data[FirestoreFriendField.canReceiveSOS] as? Bool ?? true
        self.createdAt = (data[FirestoreFriendField.createdAt] as? Timestamp)?.dateValue()
        self.updatedAt = (data[FirestoreFriendField.updatedAt] as? Timestamp)?.dateValue()
    }
}
