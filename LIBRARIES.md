# Library notes

## Verdict
For this app, Apple's built-ins cover ~everything. Third-party adds risk, not capability.
Only reach outside for persistence (if SwiftData chafes) and DX sugar.

## Apple (use these)
- HealthKit — https://developer.apple.com/documentation/healthkit
- HKObserverQuery + background delivery (the "live" path) —
  https://developer.apple.com/documentation/healthkit/hkobserverquery
  https://developer.apple.com/documentation/healthkit/hkhealthstore/enablebackgrounddelivery(for:frequency:handler:)
- WidgetKit — https://developer.apple.com/documentation/widgetkit
- Swift Charts (if you graph steps/sleep) — https://developer.apple.com/documentation/charts
- SwiftData (local store) — https://developer.apple.com/documentation/swiftdata

## Third-party worth considering
- Defaults — typed UserDefaults, supports App Groups. Directly replaces the hand-rolled
  StepSnapshot codec. https://github.com/sindresorhus/Defaults
- GRDB.swift — SQLite. Use if SwiftData is too limiting for time-series queries.
  Very actively maintained. https://github.com/groue/GRDB.swift
- SFSafeSymbols — compile-checked SF Symbols. https://github.com/SFSafeSymbols/SFSafeSymbols
- swift-dependencies — DI for testing HealthKit behind a protocol.
  https://github.com/pointfreeco/swift-dependencies

## Reference, not dependency
- WidgetExamples — every widget type, working. https://github.com/pawello2222/WidgetExamples
- awesome-swiftui — https://github.com/onmyway133/awesome-swiftui

## Skip
- HealthKitReporter (https://github.com/kvs-coder/HealthKitReporter) — 91 stars, unclear
  maintenance, wraps an API you're already calling directly in ~20 lines. Not worth the dep.
- "iOS Widget Development Kit"-style grab-bag repos — thin wrappers over WidgetKit, low value.

## Not verified
Maintenance status checked only for HealthKitReporter. Confirm last-commit dates on the
others before adding.

## Remote APIs (Notion, Pinterest, Strava, Finnhub, Perplexity, Claude, GitHub)
Not dependencies. HTTP over URLSession — no SPM, no Swift 6 impact, no install.
Verified: none ship an official Swift SDK. Community wrappers are thin URLSession
shims — write your own client, stay at zero deps.

Real constraints:
- Secrets. Keys in an iOS binary are extractable.
  - OAuth (GitHub): device flow, secret-free, Keychain. Notion and Pinterest use
    pasted long-lived tokens rather than OAuth, so no secret is needed at all.
  - API key (Finnhub/Perplexity/Claude): needs a backend proxy. No client-side workaround.
- Never network from TimelineProvider. Fetch in app/bg task → App Group → widget reads.
- BGAppRefreshTask for periodic pulls.
  https://developer.apple.com/documentation/backgroundtasks/bgapprefreshtask

## Cloudflare Worker — now website only

Built as a secrets proxy for Strava, which was **removed 2026-08-29** (its Developer
Program requires a paid subscription — see docs/registration.md). With it went the
only route needing a secret.

`worker/` now serves just the homepage and privacy policy: no secrets, no user data,
nothing authenticated. The Pinterest review requires a reachable privacy-policy URL,
which is why it still exists.

If a provider ever needs a server-side secret again, the traps still apply and the
implementation is in `git log`:
- Proxy, not vending. app→Worker→(key added)→upstream. Never return the key to the app.
- The Worker URL becomes the open door. App Attest (DCAppAttestService) is the only
  control that actually holds on iOS; a bearer token in the app is a speed bump only.
  Add rate limits + provider spend caps regardless.
  https://developer.apple.com/documentation/devicecheck/dcappattestservice
- Do NOT share one Worker between projects. Separate Workers/routes/secrets.
- Free tier (~100k req/day) is far above a 15-min polling app.
Pull current Cloudflare docs before building — platform details move.
