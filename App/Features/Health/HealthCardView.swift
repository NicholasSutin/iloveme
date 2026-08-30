import SwiftUI

/// Today's health metrics. No connect affordance — HealthKit permission is granted
/// through the system prompt, not through this card.
struct HealthCardView: View {
    let model: HealthModel

    var body: some View {
        CardView(symbol: "heart.text.square",
                 title: "Health",
                 status: model.status,
                 rows: model.rows)
    }
}
