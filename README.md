# ILoveMe — bare scaffold

iOS app + widget extension. Steps from HealthKit → App Group snapshot → widget.
No features beyond that path.

## Layout

Four synchronized folder roots. Xcode 16+ folder references, so **new files on disk
appear in the build automatically** — no project-file edits, no regeneration.

```
App/                     iOS app target
  ILoveMeApp.swift       entry point
  RootView.swift         the one screen; layout only
  DesignSystem/          Theme, CardView, RowsView — reusable chrome
  Features/              one folder per feature area
    Dashboard/           ServiceCardView, ConnectControls
    Steps/               StepsCardView
Services/                app-target logic, no SwiftUI except where noted
  Core/                  Row, ServiceStatus, ServiceKind, ServiceError
  Networking/            HTTP (one send path), JSON (tolerant digging)
  Auth/                  OAuthConfig/Token, TokenStore, TokenExchange,
                         AuthSession, GitHubDeviceFlow
  Providers/             ServiceProvider protocol, registry, one file per service
  Dashboard/             ServiceCard, Dashboard
  Health/                StepsModel (HealthKit)
Shared/                  member of BOTH targets — StepSnapshot, Formatting
Widget/                  WidgetKit extension; reads only the snapshot
screentime/              standalone macOS CLI, in no Xcode target — see
                         screentime/README.md (dead end, kept for the record)
```

Dependency direction is one way: `Core` knows nothing; `Networking`/`Auth` know
`Core`; `Providers` know all three; `Dashboard`/`Health` know `Providers`; the
`App` layer knows the models. Nothing in `Services/` imports SwiftUI except
`ServiceStatus`, which owns a `Color`.

`ILoveMe.xcodeproj` is the single source of truth (XcodeGen retired 2026-08-28).

Bundle IDs: `com.nick.iloveme`, `.widget`. App Group: `group.com.nick.iloveme`.

## Status
Builds, installs, launches, renders. The HealthKit path works end to end on the
Simulator (verified 2026-08-28): permission sheet shown, statistics query read,
App Group snapshot written, widget timelines reloaded.

### The entitlement is real — don't build with `CODE_SIGNING_ALLOWED=NO`
`App/App.entitlements` has `com.apple.developer.healthkit` and the team
(ZBS8P77LNL) is set in the project, so a normally signed Simulator build works.
But `CODE_SIGNING_ALLOWED=NO` strips the entitlement, and the app then reports
"Missing com.apple.developer.healthkit entitlement" at `requestAuthorization`.
That flag is fine for a compile check and wrong for anything that touches Health.

Simulator entitlements live in the binary's `__TEXT,__entitlements` section, not
in the code signature — `codesign -d --entitlements` prints `{}` even on a good
build. To confirm they were applied, read the generated file instead:

```
plutil -p build/Build/Intermediates.noindex/ILoveMe.build/Debug-iphonesimulator/ILoveMe.build/DerivedSources/Entitlements-Simulated.plist
```

### Steps read 0 on a fresh Simulator
Not a bug and not a sign-in problem. A Simulator is born with an empty HealthKit
store — no pedometer, and Health data never arrives over iCloud, signed in or
not. Add data by hand: Health app → search → Activity → Steps → **+**. Relaunch
the app and the number appears.

HealthKit deliberately never reports a denied *read*: `requestAuthorization`
succeeds either way and the query returns 0. So the app probes for any step
sample ever before trusting a zero; with none it shows "—" under a "Not
connected" chip rather than a confident 0 under a green dot, and leaves the last
good snapshot alone. Denial and an empty store still look identical to any app —
that pair is what the dash covers.

## On a real device
1. `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. Open `ILoveMe.xcodeproj` → both targets → Signing & Capabilities →
   select your team. Confirm HealthKit + App Groups capabilities are listed.
3. Build/run from Xcode.

Project uses Xcode 16+ synchronized folder groups: App/, Shared/, Services/, Widget/
are folder references, so NEW FILES ADDED ON DISK APPEAR IN THE BUILD AUTOMATICALLY —
no project-file edits, no regeneration, no Xcode reopening. Shared/ is a member of both
targets; Info.plist and .entitlements files are membership-excluded via exception sets.
Team (ZBS8P77LNL) and all settings live directly in the project.

## Build from CLI
Signing stays ON — see the entitlement note above.

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ILoveMe.xcodeproj -scheme ILoveMe -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build build
```

## Architecture

One screen. Text only, no charts. Light/dark via semantic colours. No subpages —
Pinterest boards expand inline (`DisclosureGroup`), so no navigation stack yet.

Everything renders as a `Row` (label / optional value / optional children). That is
what lets one `CardView` render every integration without knowing which it is.

### Adding an integration

Two edits, and the compiler demands the second:

1. Write `Services/Providers/<Name>Provider.swift` conforming to `ServiceProvider`
   — its `OAuthConfig`, its `ConnectAffordance`, its data shape, its fetch, and its
   `rows`. One self-contained file.
2. Add the case to `ServiceKind` (title + SF Symbol) and to the `Providers`
   registry switch.

Nothing else changes. `ServiceCard`, `Dashboard`, `ServiceCardView` and
`ConnectControls` are all written against the protocol, never against a `kind`.

`ConnectAffordance` is why the view needs no edit: a provider declares
`.deviceFlow`, `.pastedToken(prompt:)` or `.unavailable(reason:)`, and
`ConnectControls` renders the matching control.

### Key types

- `ServiceProvider` — one integration's whole contract (config, connect, fetch, rows)
- `Providers` — exhaustive `kind → provider` registry; a new case is a compile error
- `ServiceCard` — per-card state machine: load, connect, disconnect. Provider-agnostic
- `Dashboard` — the card set; refreshes them in a cancellable task group
- `StepsModel` — HealthKit. Deliberately *not* a `ServiceCard` (no token, no client
  ID, no connect flow), but exposes the same `status`/`rows`/`load()` surface so the
  same card view renders it
- `HTTP.send` — the single request path; every failure keeps its status and body
- `TokenStore` — Keychain. Real, working

Status per card: Not configured / Not connected / Connecting / Connected / error.
OAuth redirect scheme `iloveme://oauth` registered in `App/Info.plist`.

### Live wiring status (2026-08-28)
Endpoints verified against official docs — see docs/api-notes.md (injection-screened: PASS).
Reality check: Strava/Notion/Pinterest REQUIRE client_secret at token exchange (no PKCE
public clients). Only GitHub is secret-free, via the device flow.

- GitHub: device flow fully implemented (`Services/Auth/GitHubDeviceFlow.swift`). Needs only a
  client ID from app registration (docs/registration.md) to go live.
- Notion: token paste-in path implemented (personal internal-integration token; no OAuth,
  favorites not exposed by API → recent-edited top 5). Integration not yet created (per instruction).
- Strava/Pinterest: data clients implemented; token exchange gated on the Cloudflare Worker
  proxy (LIBRARIES.md notes). Client registrations pending — exact values in docs/registration.md.
- Each provider's client lives in its own `Services/Providers/*Provider.swift`;
  token plumbing in `Services/Auth/`.

### Not built (deliberate)
- Worker proxy (user deferred)
- Notion platform integration (user deferred)
- GitHub token refresh (unchecked "expire tokens" recommended instead)
