import CoreLocation
import FirebaseFirestore
import Foundation

@MainActor
@Observable
final class EmergencyOperatorService {
    static let shared = EmergencyOperatorService()

    private let db: Firestore
    private var listener: ListenerRegistration?

    var operators: [EmergencyOperatorRecord] = []
    var isLoading = false
    var errorMessage: String?

    init(db: Firestore? = nil) {
        FirebaseConfiguration.ensureConfigured()
        self.db = db ?? Firestore.firestore()
    }

    func startListening() {
        guard listener == nil else { return }
        isLoading = true

        listener = db.collection(FirestoreOperatorPath.emergencyOperators)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false

                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    self.operators = snapshot?.documents.compactMap(EmergencyOperatorRecord.init(document:)) ?? []
                    self.errorMessage = nil
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        operators = []
    }

    func updateDistances(from userLocation: CLLocationCoordinate2D) {
        let userCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

        for i in operators.indices {
            let opCL = CLLocation(latitude: operators[i].lat, longitude: operators[i].lon)
            operators[i].distanceMeters = userCL.distance(from: opCL)
        }

        operators.sort { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }

    func operatorsByType(_ type: EmergencyOperatorType) -> [EmergencyOperatorRecord] {
        operators.filter { $0.type == type }
    }

    var nearestByType: [EmergencyOperatorType: EmergencyOperatorRecord] {
        var result: [EmergencyOperatorType: EmergencyOperatorRecord] = [:]
        for op in operators {
            if result[op.type] == nil {
                result[op.type] = op
            } else if let existing = result[op.type],
                      let existingDist = existing.distanceMeters,
                      let opDist = op.distanceMeters,
                      opDist < existingDist {
                result[op.type] = op
            }
        }
        return result
    }
}
