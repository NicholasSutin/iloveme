import SwiftUI

/// The one screen. Layout only: each card owns its own loading and state.
struct RootView: View {
    @State private var steps = StepsModel()
    @State private var dashboard = Dashboard()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.cardGap) {
                StepsCardView(model: steps)
                ForEach(dashboard.services) { ServiceCardView(card: $0) }
            }
            .padding(Theme.gutter)
        }
        .background(Color(.systemGroupedBackground))
        .task { await reload() }
        .refreshable { await reload() }
    }

    /// HealthKit and the network services share nothing, so they run together —
    /// otherwise the service cards wait behind the (modal, first-launch) HealthKit
    /// permission prompt.
    private func reload() async {
        async let health: Void = steps.load()
        async let services: Void = dashboard.refreshAll()
        _ = await (health, services)
    }
}

#Preview {
    RootView()
}
