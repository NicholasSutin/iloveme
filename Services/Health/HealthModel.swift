import Foundation
import HealthKit
import WidgetKit

/// The Health card: today's activity from HealthKit, plus sleep and workouts.
///
/// Deliberately *not* a `ServiceCard`: there is no OAuth token, no client ID and no
/// connect flow, so sharing that type would mean threading `kind == .health` special
/// cases through every one of them. It exposes the same surface — `status`, `rows`,
/// `load()` — so the same card view renders it.
@MainActor
@Observable
final class HealthModel {
    private(set) var status: ServiceStatus = .disconnected
    private(set) var rows: [Row] = HealthModel.placeholderRows

    /// Mirrored into the App Group for the widget, which cannot read HealthKit
    /// while the device is locked. nil rather than 0 when there is no reading.
    private(set) var steps: Int?

    /// Apple documents one long-lived store per app; each instance opens its own
    /// connection to healthd.
    private static let store = HKHealthStore()

    /// Authorization is a one-time prompt. Living on the model rather than in
    /// `@State` means it survives view re-creation.
    private var didRequestAuth = false

    static var placeholderRows: [Row] {
        HealthMetric.today.map { Row($0.label, value: "—") }
            + [Row("Sleep", value: "—"), Row("Workouts this week", value: "—")]
    }

    init() {
        steps = StepSnapshot.load()?.steps
        if let steps { rows = Self.placeholderRows.replacingFirst(with: steps.formatted()) }
    }

    func load() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = .failed("HealthKit unavailable")
            return
        }
        status = .connecting

        if !didRequestAuth {
            do {
                try await Self.store.requestAuthorization(toShare: [], read: HealthMetric.readTypes)
                didRequestAuth = true
            } catch {
                status = .failure(error)
                return
            }
        }

        // Sequential on purpose. These are on-device IPC round trips measured in
        // milliseconds, not network calls, so a task group would add Sendable
        // friction for no meaningful wall-clock gain.
        var values: [Double?] = []
        for metric in HealthMetric.today {
            values.append(await todayTotal(metric))
        }
        let sleep = await lastNightAsleep()
        let workouts = await workoutsThisWeek()

        var newRows = zip(HealthMetric.today, values).map { metric, value in
            Row(metric.label, value: value.dashed(metric.format))
        }
        newRows.append(Row("Sleep", value: sleep.dashed(Self.formatDuration)))
        newRows.append(Row("Workouts this week", value: workouts.dashed { $0.formatted() }))
        rows = newRows

        // A denied read and an empty store are indistinguishable — both come back
        // with no samples. So "nothing at all" is reported as not-connected rather
        // than as a screen full of confident zeroes.
        guard values.contains(where: { $0 != nil }) || sleep != nil || workouts != nil else {
            steps = nil
            status = .disconnected
            return
        }

        if let stepValue = values.first ?? nil {
            let count = Int(stepValue)
            steps = count
            StepSnapshot(steps: count, updated: Date()).save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        status = .updatedNow()
    }

    // MARK: Queries

    /// nil when HealthKit holds no samples for the window — which renders as "—".
    /// Collapsing that to 0 is what makes a dashboard lie about a still day.
    private func todayTotal(_ metric: HealthMetric) async -> Double? {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: metric.quantityType,
                                          quantitySamplePredicate: predicate,
                                          options: metric.options) { _, statistics, _ in
                let quantity = metric.options == .cumulativeSum
                    ? statistics?.sumQuantity()
                    : statistics?.averageQuantity()
                continuation.resume(returning: quantity?.doubleValue(for: metric.unit))
            }
            Self.store.execute(query)
        }
    }

    /// Hours asleep last night, counting from 6pm yesterday so an early night is
    /// still attributed to the right night.
    private func lastNightAsleep() async -> Double? {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .hour, value: -6, to: todayStart) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis),
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                // "In bed" and "awake" are not sleep; everything else is a sleep
                // stage, and summing them covers both the pre- and post-iOS 16
                // shapes without branching on OS version.
                let asleep = samples.filter {
                    $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue
                        && $0.value != HKCategoryValueSleepAnalysis.awake.rawValue
                }
                guard !asleep.isEmpty else { continuation.resume(returning: nil); return }
                let seconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: seconds / 3600)
            }
            Self.store.execute(query)
        }
    }

    /// The closest HealthKit analogue to a Strava activity count.
    private func workoutsThisWeek() async -> Int? {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: weekStart, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(),
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: samples.map { $0.count })
            }
            Self.store.execute(query)
        }
    }

    private static func formatDuration(_ hours: Double) -> String {
        let whole = Int(hours)
        let minutes = Int((hours - Double(whole)) * 60)
        return whole > 0 ? "\(whole)h \(minutes)m" : "\(minutes)m"
    }
}

private extension [Row] {
    /// Seeds the first row from the widget snapshot so the card is not blank on
    /// launch while HealthKit is still answering.
    func replacingFirst(with value: String) -> [Row] {
        guard var first = self.first else { return self }
        first.value = value
        return [first] + dropFirst()
    }
}
