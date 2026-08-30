# ILoveMe

iOS app + widget extension, one screen of text cards.

- **Health** — steps, distance, flights climbed, walking speed, step length and a
  workout count from HealthKit. **iPhone-only by rule**: every metric comes from the
  phone's motion coprocessor or barometer, so nothing needs an Apple Watch. Steps are
  mirrored to an App Group snapshot for the Lock Screen / Home Screen widget.
- **Three service integrations** — GitHub, Notion, Pinterest. Every data client is
  written; only auth is outstanding. See "Live wiring status" below.

Adding a fifth integration is one file plus one enum case — see "Adding an
integration".

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
    Health/              HealthCardView
Services/                app-target logic, no SwiftUI except where noted
  Core/                  Row, ServiceStatus, ServiceKind, ServiceError
  Networking/            HTTP (one send path), JSON (tolerant digging)
  Auth/                  OAuthConfig/Token, TokenStore, TokenExchange,
                         GitHubDeviceFlow
  Providers/             ServiceProvider protocol, registry, one file per service
  Dashboard/             ServiceCard, Dashboard
  Health/                HealthModel, HealthMetric (HealthKit)
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

### Removed: unused HealthKit declarations

`App.entitlements` used to request `healthkit.background-delivery` and `Info.plist`
declared `NSHealthClinicalHealthRecordsShareUsageDescription`, neither of which the
app used — there is no `HKObserverQuery`, no `enableBackgroundDelivery`, no
`BGAppRefreshTask`, and clinical records are never read. Both were dropped rather
than left as questions at review time. Health data refreshes when the app is
foregrounded.

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

Swap `-scheme ILoveMe` for `-scheme ILoveMeWidget` to build the extension.

For a pure compile check (no Health access), adding `CODE_SIGNING_ALLOWED=NO` is
fine and faster — but the resulting build cannot talk to HealthKit, per the note
above.

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
- `HealthModel` — HealthKit, driven by a declarative `HealthMetric` list so adding a
  metric is one entry. Deliberately *not* a `ServiceCard` (no token, no client
  ID, no connect flow), but exposes the same `status`/`rows`/`load()` surface so the
  same card view renders it
- `HTTP.send` — the single request path; every failure keeps its status and body
- `TokenStore` — Keychain. Real, working

Status per card: Not configured / Not connected / Connecting / Connected / error.

### No URL scheme, deliberately

`App/Info.plist` has no `CFBundleURLTypes`, and that is correct: nothing in the app
handles an incoming URL. GitHub's device flow has no redirect leg, and Notion and
Pinterest paste tokens. The `iloveme://` scheme existed only for Strava's browser
redirect and was removed with it — `git log` has both if a redirect provider returns.
Pinterest's portal requires a redirect URI to register at all, so `iloveme://oauth`
is on file there; it is simply never exercised.

### Live wiring status (2026-08-30)
Endpoints verified against official docs — see docs/api-notes.md (injection-screened: PASS).
Reality check: Notion and Pinterest both require a client_secret for full OAuth, so
both take a pasted token instead. Notion's does not expire; Pinterest's does. GitHub
is secret-free via the device flow. No integration needs a server-side secret.

Full detail and next actions in **docs/registration.md**.

| Service | Registered | Client ID | Works? | Next action |
|---|---|---|---|---|
| **GitHub** | yes, device flow on | in place | **yes — done** | none |
| **Notion** | no | n/a | no | create the internal integration, paste token |
| **Pinterest** | yes, approved | `1606244` | wired | paste a token (expires in 24h) |

- **GitHub**: fully live. Device flow implemented, cancellable, single-flight.
- **Notion**: paste-in path implemented and ready. Use an internal-integration token,
  NOT OAuth — reasoning recorded in docs/registration.md.
- **Pinterest**: approved 2026-08-30. Connects by pasting a token generated in the
  developer portal — the **production-limited** one, not the sandbox one, which only
  works against `api-sandbox.pinterest.com`. The app secret is never needed. Caveat:
  portal tokens are *test* tokens and expire after **24 hours**, so this verifies the
  integration rather than standing it up. A lasting connection needs OAuth refresh,
  which needs the client secret, which needs the relay Worker back. See
  docs/registration.md for that trade, and docs/pinterest-docs/ for the sources.
- **Strava was removed 2026-08-29.** Its auth worked end to end, but Strava's
  Developer Program requires a paid subscription on the account owning the API
  application, so it returned 403 `Application/Status/Inactive` for all data. The
  HealthKit card was expanded to cover some of the same ground — workouts this week
  and walking/running distance. See docs/registration.md for the full record.
- Each provider's client lives in its own `Services/Providers/*Provider.swift`;
  token plumbing in `Services/Auth/`.

### The Worker (`worker/`) — website only

Hono on Cloudflare Workers, serving the homepage and the privacy policy that
Pinterest's review requires. Staging deploys as `iloveme-app`; production as
`iloveme` on `iloveme.nicholassutin.com`.

It was built to hold Strava's `client_secret`. With Strava gone it **holds no secrets
and receives no user data** — every remaining integration is secret-free. `git log`
has the relay if one is ever needed again.

Xcode cannot see `worker/`: only App/, Services/, Shared/ and Widget/ are
synchronized roots. Confirmed by building both targets with an invalid `.swift` file
planted in `worker/src/` — both succeeded and it never reached a compile step.

### Not built (deliberate)
- **Token refresh.** `OAuthToken.isExpired` exists but nothing calls it. GitHub's
  and Notion's tokens do not expire, so nothing breaks there. **Pinterest's expires
  in 24 hours** — and refreshing it needs the client secret, hence a server, hence
  the relay that went with Strava. Rather than pretend otherwise, a 401 surfaces as
  "Token expired — paste a new one" with the paste field already beneath it. That
  keeps Pinterest a verify-it-works integration until the server is worth building.
- Notion OAuth (access token chosen instead — see docs/registration.md)
- HealthKit background delivery — see the entitlement note above.
