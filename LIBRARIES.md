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
  - OAuth (Strava/Notion/Pinterest/GitHub): ASWebAuthenticationSession + PKCE, Keychain.
    https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession
  - API key (Finnhub/Perplexity/Claude): needs a backend proxy. No client-side workaround.
- Never network from TimelineProvider. Fetch in app/bg task → App Group → widget reads.
- BGAppRefreshTask for periodic pulls.
  https://developer.apple.com/documentation/backgroundtasks/bgapprefreshtask

## Cloudflare Worker as secrets proxy (deferred — decisions made 2026-08-28)

**Scaffolded 2026-08-28 in `worker/` — see worker/README.md. Never deployed.**
- Hono (zero-dep, ~14 kB, Workers-native). Astro/Svelte are site frameworks and this
  has no UI — three JSON routes and one redirect.
- Lives in `worker/` in this repo. Xcode cannot see it (only App/, Services/,
  Shared/, Widget/ are synchronized roots), its routes mirror the providers 1:1, and
  no secret is in source — `wrangler secret put` keeps them in Cloudflare.
- Hosted at `iloveme.nicholassutin.com` (production) and `iloveme-app` (staging).
  Chosen over s5.design because the callback URL is visible to the user mid-OAuth,
  which makes it user-facing rather than pure infrastructure.
- **Only Strava actually needs it.** Notion uses an internal-integration token and
  Pinterest can mint a Trial test token, both without OAuth; GitHub is device flow.
  See docs/registration.md.

Right shape for the key-based services. Two traps:
- Proxy, not vending. app→Worker→(key added)→upstream. Never return the key to the app.
  Vending is fine for hackathons/trusted devs, never for a shipped app.
- The Worker becomes the open door. Anyone who extracts its URL can spend your quota.
  - App Attest (DCAppAttestService) is the only control that actually holds on iOS.
    https://developer.apple.com/documentation/devicecheck/dcappattestservice
  - Bearer token in app = speed bump only. Add rate limits + provider spend caps regardless.
- Do NOT share one Worker between hackathons and the app. Separate Workers/routes/secrets.
- Free tier (~100k req/day) is far above a 15-min polling app. SSE passthrough works.
Pull current Cloudflare docs before building — platform details move.
