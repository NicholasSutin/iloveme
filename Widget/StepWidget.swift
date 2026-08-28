import WidgetKit
import SwiftUI

struct StepEntry: TimelineEntry {
    let date: Date
    /// nil when no snapshot exists yet — the app has never had a usable HealthKit
    /// read. Rendered as an em dash rather than a confident 0.
    let steps: Int?

    var display: String { steps.dashed { $0.formatted() } }

    static func current() -> StepEntry {
        StepEntry(date: Date(), steps: StepSnapshot.load()?.steps)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(date: Date(), steps: 4321)   // gallery preview only
    }

    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        completion(.current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        // The system budget is ~15-30 min regardless of what we ask for.
        completion(Timeline(entries: [.current()],
                            policy: .after(Date().addingTimeInterval(15 * 60))))
    }
}

struct StepWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StepEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.display) steps")
        case .accessoryCircular:
            Text(entry.display).font(.headline)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.display).font(.headline)
                Text("steps today").font(.caption)
            }
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.display).font(.title).bold()
                Text("steps today").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct StepWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepWidget", provider: Provider()) { entry in
            StepWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Steps")
        .description("Steps today.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct ILoveMeWidgetBundle: WidgetBundle {
    var body: some Widget { StepWidget() }
}
