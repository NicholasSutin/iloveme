import SwiftUI

/// Renders a list of `Row`, expanding any that carry children into a disclosure
/// group. One level deep, which is all the data shapes need.
struct RowsView: View {
    let rows: [Row]

    var body: some View {
        // Rows are positional, so identity is the index: a refresh producing the
        // same shape diffs as unchanged and leaves open disclosure groups open.
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
            if row.children.isEmpty {
                RowView(row: row)
            } else {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: Theme.rowGap) {
                        ForEach(Array(row.children.enumerated()), id: \.offset) { _, child in
                            RowView(row: child)
                        }
                    }
                    .padding(.top, Theme.rowGap)
                } label: {
                    RowView(row: row)
                }
                .tint(.secondary)
            }
        }
    }
}

struct RowView: View {
    let row: Row

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(row.label).font(.subheadline)
            Spacer(minLength: 12)
            if let value = row.value {
                Text(value)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
