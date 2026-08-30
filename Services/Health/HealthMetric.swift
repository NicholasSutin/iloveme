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
    /// Steps, distance and flights come from the iPhone alone. Energy, exercise
    /// minutes and resting heart rate generally need a Watch or a third-party app
    /// writing into Health — they degrade to "—" rather than showing a false zero.
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

        HealthMetric(label: "Active energy",
                     identifier: .activeEnergyBurned,
                     unit: .kilocalorie(),
                     options: .cumulativeSum,
                     format: { "\(Int($0).formatted()) kcal" }),

        HealthMetric(label: "Exercise",
                     identifier: .appleExerciseTime,
                     unit: .minute(),
                     options: .cumulativeSum,
                     format: { "\(Int($0)) min" }),

        HealthMetric(label: "Resting heart rate",
                     identifier: .restingHeartRate,
                     unit: HKUnit.count().unitDivided(by: .minute()),
                     options: .discreteAverage,
                     format: { "\(Int($0.rounded())) bpm" }),
    ]

    /// Everything the app asks permission to read.
    static var readTypes: Set<HKObjectType> {
        var types = Set(today.map { $0.quantityType as HKObjectType })
        types.insert(HKCategoryType(.sleepAnalysis))
        types.insert(HKObjectType.workoutType())
        return types
    }
}
