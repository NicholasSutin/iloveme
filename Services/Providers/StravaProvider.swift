import Foundation

/// Strava. Blocked on the Worker proxy: token exchange requires a `client_secret`
/// we refuse to embed in the app.
struct StravaProvider: ServiceProvider {
    let kind = ServiceKind.strava

    let config = OAuthConfig(
        clientID: "175321",          // paste from the portal — see docs/registration.md
        authorize: "https://www.strava.com/oauth/mobile/authorize",
        token: "https://www.strava.com/oauth/token",
        scopes: ["activity:read_all"])

    // Browser consent on Strava, then the code is exchanged through the relay,
    // because Strava requires a client_secret at exchange AND at every refresh.
    let connect = ConnectAffordance.webRedirect
    let usesRelay = true

    var placeholderRows: [Row] { Summary().rows }

    func rows(token: String) async throws -> [Row] {
        try await summary(token: token).rows
    }

    // MARK: Data

    struct Summary: Sendable {
        var totalDistanceMeters: Double?
        var activitiesToday: Int?
        var activitiesThisWeek: Int?
        var activitiesThisMonth: Int?

        var rows: [Row] {
            [Row("Total distance", value: totalDistanceMeters.dashed { String(format: "%.1f km", $0 / 1000) }),
             Row("Today", value: activitiesToday.dashed()),
             Row("This week", value: activitiesThisWeek.dashed()),
             Row("This month", value: activitiesThisMonth.dashed())]
        }
    }

    // MARK: Fetch

    private struct Athlete: Decodable { let id: Int }
    private struct Totals: Decodable { let distance: Double? }
    private struct Stats: Decodable {
        let all_ride_totals: Totals?
        let all_run_totals: Totals?
        let all_swim_totals: Totals?
    }
    private struct Activity: Decodable { let start_date: String? }

    private static let base = "https://www.strava.com/api/v3"

    func summary(token: String) async throws -> Summary {
        let decoder = JSONDecoder()
        let calendar = Calendar.current

        // One monthly fetch; today and this-week are counted from the same list.
        // It depends on nothing else, so it flies alongside the athlete/stats pair
        // rather than queueing behind them — 2 round trips instead of 3.
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let after = Int(monthStart.timeIntervalSince1970)
        async let activityData = HTTP.get(
            URL(string: "\(Self.base)/athlete/activities?after=\(after)&per_page=200")!, bearer: token)

        let athlete = try decoder.decode(
            Athlete.self, from: try await HTTP.get(URL(string: "\(Self.base)/athlete")!, bearer: token))
        let stats = try decoder.decode(
            Stats.self,
            from: try await HTTP.get(URL(string: "\(Self.base)/athletes/\(athlete.id)/stats")!, bearer: token))

        // Annotated one per line: the type-checker times out on the folded sum.
        let ride: Double = stats.all_ride_totals?.distance ?? 0
        let run: Double = stats.all_run_totals?.distance ?? 0
        let swim: Double = stats.all_swim_totals?.distance ?? 0
        let total: Double = ride + run + swim

        let activities = try decoder.decode([Activity].self, from: try await activityData)
        let formatter = ISO8601DateFormatter()
        let dates = activities.compactMap { $0.start_date.flatMap(formatter.date(from:)) }
        let dayStart = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? dayStart

        return Summary(
            totalDistanceMeters: total,
            activitiesToday: dates.filter { $0 >= dayStart }.count,
            activitiesThisWeek: dates.filter { $0 >= weekStart }.count,
            activitiesThisMonth: dates.count)
    }
}
