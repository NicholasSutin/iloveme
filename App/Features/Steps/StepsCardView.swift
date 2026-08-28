import SwiftUI

/// Today's steps. No connect affordance — HealthKit permission is granted through
/// the system prompt, not through this card.
struct StepsCardView: View {
    let model: StepsModel

    var body: some View {
        CardView(symbol: "figure.walk",
                 title: "Steps",
                 status: model.status,
                 rows: model.rows)
    }
}
