import HealthKit

/// One HealthKit quantity, described declaratively so the model can loop over a
/// list rather than hand-writing a query per metric. Adding a metric is one entry.
///
/// Main-actor isolated rather than `Sendable`: `HKUnit` is not `Sendable`, and every
/// use is main-actor bound anyway, so isolation states the truth instead of fighting it.
@MainActor
struct HealthMetric {
    let label: String
    let identifier: HKQuantityTypeIdentifier
    let unit: HKUnit
    let options: HKStatisticsOptions
    /// Renders the raw value. Returning nil means "present but not worth showing".
    let format: (Double) -> String

    var quantityType: HKQuantityType { HKQuantityType(identifier) }

    /// Today's totals, in the order they appear on the card.
    ///
    /// **iPhone-only by rule.** Every metric here comes from sensors the phone
    /// actually has — the motion coprocessor and the barometer. Anything needing
    /// Apple Watch hardware was removed: resting heart rate (no heart sensor),
    /// active energy and Apple exercise minutes (both derived from continuous heart
    /// rate), and sleep stages. A metric that can only ever render "—" is worse than
    /// no row at all.
    static let today: [HealthMetric] = [
        HealthMetric(label: "Steps",
                     identifier: .stepCount,
                     unit: .count(),
                     options: .cumulativeSum,
                     format: { Int($0).formatted() }),

        HealthMetric(label: "Distance",
                     identifier: .distanceWalkingRunning,
                     unit: .meter(),
                     options: .cumulativeSum,
                     format: { String(format: "%.2f km", $0 / 1000) }),

        HealthMetric(label: "Flights climbed",
                     identifier: .flightsClimbed,
                     unit: .count(),
                     options: .cumulativeSum,
                     format: { Int($0).formatted() }),

        // Mobility metrics: Apple derives these from the iPhone's own motion
        // sensors while it is carried, so they need no wearable.
        HealthMetric(label: "Walking speed",
                     identifier: .walkingSpeed,
                     unit: HKUnit.meter().unitDivided(by: .second()),
                     options: .discreteAverage,
                     format: { String(format: "%.1f km/h", $0 * 3.6) }),

        HealthMetric(label: "Step length",
                     identifier: .walkingStepLength,
                     unit: .meter(),
                     options: .discreteAverage,
                     format: { String(format: "%.0f cm", $0 * 100) }),
    ]

    /// Everything the app asks permission to read.
    static var readTypes: Set<HKObjectType> {
        var types = Set(today.map { $0.quantityType as HKObjectType })
        // Workouts stay: they are not Watch-exclusive — iPhone running, cycling and
        // fitness apps write them to HealthKit directly.
        types.insert(HKObjectType.workoutType())
        return types
    }
}
