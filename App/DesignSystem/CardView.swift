import SwiftUI

/// The app's one container: a titled, status-chipped card holding label/value rows
/// and an optional footer for controls.
///
/// Everything on screen is one of these, which is what keeps the feature views
/// short — they supply data and a footer, never layout.
struct CardView<Footer: View>: View {
    let symbol: String
    let title: String
    let status: ServiceStatus
    let rows: [Row]
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.rowGap) {
            CardHeader(symbol: symbol, title: title, status: status)
            RowsView(rows: rows)
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

extension CardView where Footer == EmptyView {
    init(symbol: String, title: String, status: ServiceStatus, rows: [Row]) {
        self.init(symbol: symbol, title: title, status: status, rows: rows) { EmptyView() }
    }
}

struct CardHeader: View {
    let symbol: String
    let title: String
    let status: ServiceStatus

    var body: some View {
        HStack(spacing: Theme.rowGap) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: Theme.symbolColumn)
            Text(title).font(.headline).layoutPriority(1)
            Spacer(minLength: Theme.rowGap)
            StatusChip(status: status)
        }
        .padding(.bottom, 2)
    }
}

struct StatusChip: View {
    let status: ServiceStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.tint)
                .frame(width: Theme.statusDot, height: Theme.statusDot)
            Text(status.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
    }
}
