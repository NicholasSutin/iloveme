import SwiftUI

/// One integration's card. Provider-agnostic — it reads rows and a status, and
/// delegates the connect affordance. Adding an integration does not touch this file.
struct ServiceCardView: View {
    let card: ServiceCard

    var body: some View {
        CardView(symbol: card.kind.symbol,
                 title: card.kind.title,
                 status: card.status,
                 rows: card.rows) {
            ConnectControls(card: card)
        }
    }
}
