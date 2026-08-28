import Foundation
import HealthKit
import WidgetKit

/// Today's step count, read from HealthKit and mirrored into the app group for the
/// widget.
///
/// Deliberately *not* a `ServiceCard`: there is no OAuth token, no client ID and no
/// connect flow, so sharing that type would mean threading `kind == .steps` special
/// cases through every one of them. It exposes the same surface — `status`, `rows`,
/// `load()` — so the same card view renders it.
@MainActor
@Observable
final class StepsModel {
    private(set) var status: ServiceStatus = .disconnected
    private(set) var steps: Int?

    var rows: [Row] { [Row("Today", value: steps.dashed { $0.formatted() })] }

    /// Apple documents one long-lived store per app; each instance opens its own
    /// connection to healthd.
    private static let store = HKHealthStore()
    private static let stepType = HKQuantityType(.stepCount)

    /// Authorization is a one-time prompt, and "has ever recorded a step" only ever
    /// goes false → true. Neither needs re-asking on every refresh. Living on the
    /// model rather than in `@State` means they survive view re-creation.
    private var didRequestAuth = false
    private var confirmedHasSamples = false

    init() {
        steps = StepSnapshot.load()?.steps
    }

    func load() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            status = .failed("HealthKit unavailable")
            return
        }
        status = .connecting
        if !didRequestAuth {
            do {
                try await Self.store.requestAuthorization(toShare: [], read: [Self.stepType])
                didRequestAuth = true
            } catch {
                status = .failure(error)
                return
            }
        }

        let total = await todaysStepTotal()

        // HealthKit never reports a denied *read*: requestAuthorization succeeds
        // either way and the query simply returns 0. A zero is therefore ambiguous —
        // no permission, an empty store, or a genuinely still day. Probing for any
        // step sample ever separates the last case from the first two, so a bogus 0
        // never overwrites a good snapshot. The probe is skipped once it has
        // answered yes, since that answer cannot revert.
        if total == 0, !confirmedHasSamples {
            guard await hasAnyStepSample() else {
                steps = nil
                status = .disconnected
                return
            }
            confirmedHasSamples = true
        }

        let count = Int(total)
        steps = count
        StepSnapshot(steps: count, updated: Date()).save()
        WidgetCenter.shared.reloadAllTimelines()
        status = .updatedNow()
    }

    private func todaysStepTotal() async -> Double {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: Self.stepType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
            Self.store.execute(query)
        }
    }

    /// True if HealthKit holds at least one step sample, ever. A denied read and an
    /// empty store both come back empty — exactly the pair we cannot tell apart, and
    /// so the pair we refuse to render as "0".
    private func hasAnyStepSample() async -> Bool {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: Self.stepType,
                                      predicate: nil,
                                      limit: 1,
                                      sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: !(samples ?? []).isEmpty)
            }
            Self.store.execute(query)
        }
    }
}
