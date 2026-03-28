import FirebaseAuth
import SwiftUI
import MapKit

struct AmbulanceAnnotation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let status: BadgeVariant
    let type: String

    static func == (lhs: AmbulanceAnnotation, rhs: AmbulanceAnnotation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AlertZone: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let radiusMeters: Double
    let severity: ZoneSeverity

    enum ZoneSeverity {
        case danger
        case caution
        case safe
    }
}

struct MapTabView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AgentAPIClient.self) private var agentAPI
    @Environment(AgentSessionStore.self) private var sessionStore
    @Environment(LocationManager.self) private var locationManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )
    @State private var selectedUnitID: String?
    @State private var searchText = ""
    @State private var mapLoading = false
    @State private var mapError: String?
    /// Last assistant text from the map refresh action (any `response_type`).
    @State private var lastMapAssistantText: String?

    private let sampleUnits: [AmbulanceAnnotation] = [
        AmbulanceAnnotation(id: "AMB-2847", coordinate: .init(latitude: 28.617, longitude: 77.212), status: .enRoute, type: "Advanced Life Support"),
        AmbulanceAnnotation(id: "AMB-1192", coordinate: .init(latitude: 28.610, longitude: 77.205), status: .active, type: "Basic Life Support"),
        AmbulanceAnnotation(id: "AMB-3301", coordinate: .init(latitude: 28.620, longitude: 77.200), status: .active, type: "Advanced Life Support"),
    ]

    private let sampleZones: [AlertZone] = [
        AlertZone(id: "z1", coordinate: .init(latitude: 28.615, longitude: 77.209), radiusMeters: 300, severity: .danger),
        AlertZone(id: "z2", coordinate: .init(latitude: 28.620, longitude: 77.215), radiusMeters: 500, severity: .safe),
    ]

    private var selectedUnit: AmbulanceAnnotation? {
        sampleUnits.first { $0.id == selectedUnitID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(sampleZones) { zone in
                    MapCircle(center: zone.coordinate, radius: zone.radiusMeters)
                        .foregroundStyle(zoneColor(zone.severity))
                        .stroke(zoneStroke(zone.severity), lineWidth: 1.5)
                }

                ForEach(sampleUnits) { unit in
                    Annotation(unit.id, coordinate: unit.coordinate) {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedUnitID = selectedUnitID == unit.id ? nil : unit.id
                            }
                        } label: {
                            ambulanceMarker(unit)
                        }
                        .buttonStyle(.plain)
                    }
                }

                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: Spacing.space3) {
                searchBar
                backendBanner
                if let selected = selectedUnit {
                    unitDetailSheet(selected)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.screenPaddingH)
            .padding(.top, Spacing.space12)
            .animation(.spring(duration: 0.3), value: selectedUnitID)

            VStack {
                Spacer()
                mapLegend
                    .padding(.horizontal, Spacing.screenPaddingH)
                    .padding(.bottom, Spacing.space4)
            }
        }
        .onAppear {
            locationManager.requestWhenInUse()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await askMapAgent() }
                } label: {
                    if mapLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(mapLoading)
                .accessibilityLabel("Refresh from assistant")
            }
        }
    }

    /// Calls backend with `MAP` intent; shows `chat_message` / map payload hints without fabricating units.
    private var backendBanner: some View {
        Group {
            if let err = mapError {
                Text(err)
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.statusError)
                    .padding(Spacing.space3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SemanticColor.statusError.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            } else if let msg = lastMapAssistantText?.trimmingCharacters(in: .whitespacesAndNewlines), !msg.isEmpty {
                Text(msg)
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.textPrimary)
                    .padding(Spacing.space3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }
        }
    }

    private func askMapAgent() async {
        await MainActor.run {
            mapError = nil
        }
        let token: String? = await withCheckedContinuation { cont in
            Auth.auth().currentUser?.getIDTokenForcingRefresh(false) { token, _ in
                cont.resume(returning: token)
            } ?? cont.resume(returning: nil)
        }
        let pair = locationManager.latLonPair
        guard let pair else {
            await MainActor.run {
                mapError = "Turn on location to use the map assistant."
            }
            return
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "nearby helpers"
            : searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        await MainActor.run { mapLoading = true }
        defer { Task { @MainActor in mapLoading = false } }

        do {
            let res = try await agentAPI.sendChat(
                userId: authService.backendUserId,
                sessionId: SessionIdentity.sessionId,
                query: q,
                lat: pair.lat,
                lon: pair.lon,
                triggerType: "CHAT",
                idToken: token
            )
            let assistantText = [res.chatMessage, res.mapPayload?.message]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            await MainActor.run {
                sessionStore.lastResponse = res
                lastMapAssistantText = assistantText
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: pair.lat, longitude: pair.lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                        )
                    )
                }
            }
        } catch {
            await MainActor.run {
                mapError = error.localizedDescription
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        AppTextField(
            placeholder: "Search location or unit...",
            text: $searchText,
            icon: "magnifyingglass",
            isPill: false
        )
        .appShadow(.elevated)
    }

    // MARK: - Ambulance Marker

    private func ambulanceMarker(_ unit: AmbulanceAnnotation) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(SemanticColor.actionPrimary)
                    .frame(width: 36, height: 36)
                Image(systemName: "cross.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BrandColor.white)
            }
            .appShadow(.elevated)

            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(SemanticColor.actionPrimary)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
    }

    // MARK: - Unit Detail Sheet

    private func unitDetailSheet(_ unit: AmbulanceAnnotation) -> some View {
        InfoCard {
            HStack(spacing: Spacing.space3) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(SemanticColor.actionPrimary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cross.vial.fill")
                        .foregroundStyle(SemanticColor.actionPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.space1) {
                    HStack {
                        Text(unit.id)
                            .textStyle(.labelBold)
                            .foregroundStyle(SemanticColor.textPrimary)
                        StatusBadge(variant: unit.status)
                    }
                    Text(unit.type)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                }

                Spacer()

                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(BrandColor.white)
                        .frame(width: 36, height: 36)
                        .background(SemanticColor.actionPrimary)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Map Legend

    private var mapLegend: some View {
        HStack(spacing: Spacing.space4) {
            legendItem(color: SemanticColor.statusError.opacity(0.3), label: "Danger Zone")
            legendItem(color: SemanticColor.statusSuccess.opacity(0.3), label: "Safe Zone")
            legendItem(color: SemanticColor.actionPrimary, label: "Ambulance", isCircle: true)
        }
        .padding(.horizontal, Spacing.space4)
        .padding(.vertical, Spacing.space2)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func legendItem(color: Color, label: String, isCircle: Bool = false) -> some View {
        HStack(spacing: Spacing.space1_5) {
            if isCircle {
                Circle().fill(color).frame(width: 10, height: 10)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 14, height: 10)
            }
            Text(label)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textPrimary)
        }
    }

    // MARK: - Zone Colors

    private func zoneColor(_ severity: AlertZone.ZoneSeverity) -> Color {
        switch severity {
        case .danger:  return SemanticColor.statusError.opacity(0.15)
        case .caution: return SemanticColor.statusWarning.opacity(0.15)
        case .safe:    return SemanticColor.statusSuccess.opacity(0.15)
        }
    }

    private func zoneStroke(_ severity: AlertZone.ZoneSeverity) -> Color {
        switch severity {
        case .danger:  return SemanticColor.statusError.opacity(0.4)
        case .caution: return SemanticColor.statusWarning.opacity(0.4)
        case .safe:    return SemanticColor.statusSuccess.opacity(0.4)
        }
    }
}

#Preview {
    MapTabView()
        .environment(AuthService())
        .environment(AgentAPIClient())
        .environment(AgentSessionStore())
        .environment(LocationManager())
}
