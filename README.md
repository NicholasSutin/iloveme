# ILoveMe

iOS app + widget extension, one screen of text cards.

- **Health** — steps, distance, flights climbed, walking speed, step length and a
  workout count from HealthKit. **iPhone-only by rule**: every metric comes from the
  phone's motion coprocessor or barometer, so nothing needs an Apple Watch. Steps are
  mirrored to an App Group snapshot for the Lock Screen / Home Screen widget.
- **Three service integrations** — GitHub, Notion, Pinterest — shown as four cards,
  because Notion is connected once per account (personal and work are separate Notion
  accounts, and a Notion token is scoped to one workspace). Every data client is
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
Reality check: neither Notion nor Pinterest offers PKCE or a device flow, so neither
can do user OAuth without a server. Notion takes a pasted integration token;
Pinterest takes a pasted app secret and mints its own tokens from it via the
client-credentials grant. GitHub is credential-free via the device flow. **No
integration needs a server-side secret** — Pinterest's lives in the Keychain on the
device, which is why the relay Worker stayed deleted.

Full detail and next actions in **docs/registration.md**.

| Service | Registered | Client ID | Works? | Next action |
|---|---|---|---|---|
| **GitHub** | yes, device flow on | in place | **yes — done** | none |
| **Notion** | n/a — internal token | n/a | ready | paste one token per account |
| **Pinterest** | yes, approved | `1606244` | wired | paste the app secret once |

- **GitHub**: fully live. Device flow implemented, cancellable, single-flight.
- **Notion**: paste-in path implemented and ready, with a card each for **Personal**
  and **Work**. Use an internal-integration token, NOT OAuth — OAuth needs a Notion
  review, restores the secret-holding Worker, and adds rotating-refresh-token upkeep,
  while still requiring one token per workspace. Reasoning in docs/registration.md.
- **Pinterest**: approved 2026-08-30, **blocked** — minting needs 2FA on the account
  and enabling it currently errors on Pinterest's side. The card meanwhile accepts a
  24-hour portal token, told apart from a secret by Pinterest's `pin` token prefix,
  which exercises the whole data path. Once 2FA works: paste the **app secret** once
  and the app mints and renews its own tokens via the client-credentials grant. The grant acts on
  behalf of the app owner, who is the only user here, so the authorization-code
  flow's consent leg would be ceremony with nobody to perform it for. The secret
  lives in the Keychain only — never the repo, an xcconfig, or the binary. Needs 2FA
  on the account. Sources in docs/pinterest-docs/.
- **Strava was removed 2026-08-29.** Its auth worked end to end, but Strava's
  Developer Program requires a paid subscription on the account owning the API
  application, so it returned 403 `Application/Status/Inactive` for all data. The
  HealthKit card was expanded to cover some of the same ground — workouts this week
  and walking/running distance. See docs/registration.md for the full record.
- Each provider's client lives in its own `Services/Providers/*Provider.swift`;
  token plumbing in `Services/Auth/`.
- A card is one **account**, not one service: `ServiceAccount` (a `ServiceKind` plus
  an optional label) keys both the dashboard and the Keychain. A new provider gets a
  single unlabelled account for free; only Notion overrides `accounts`.

### The Worker (`worker/`) — website only

Hono on Cloudflare Workers, serving the homepage and the privacy policy that
Pinterest's review requires. Staging deploys as `iloveme-app`; production as
`iloveme` on `iloveme.nicholassutin.com`.

It was built to hold Strava's `client_secret`. With Strava gone it **holds no secrets
and receives no user data**. Pinterest's app secret is a device-side credential in
the Keychain, not a server-side one, so nothing needs to move back here. `git log`
has the relay if a provider ever genuinely requires one.

Xcode cannot see `worker/`: only App/, Services/, Shared/ and Widget/ are
synchronized roots. Confirmed by building both targets with an invalid `.swift` file
planted in `worker/src/` — both succeeded and it never reached a compile step.

### Not built (deliberate)
- **Refresh-token grant.** Still unbuilt, and now unnecessary. `OAuthToken.isExpired`
  *is* used — `ServiceCard.currentToken()` checks it before every load and a
  `.clientCredentials` provider mints a replacement on the spot, so Pinterest renews
  itself without a server. GitHub's and Notion's tokens do not expire. A provider
  that could neither renew nor refresh would surface expiry as a 401 chip naming the
  field to fix; none currently exists.
- Notion OAuth (access token chosen instead — see docs/registration.md). Revisit only
  when someone other than Nick needs to sign in; two Notion accounts is not that
  reason, since OAuth also issues one token per workspace.
- HealthKit background delivery — see the entitlement note above.
