# App registrations — status and exact values

Client IDs are public and safe to commit; paste them into that service's
`Services/Providers/<Name>Provider.swift` (`OAuthConfig(clientID: …)`).
**Secrets are not.** Since Strava's removal no integration needs one: every
remaining service connects by device flow or by a token the user pastes, so the
Worker holds no secrets and serves only the public site.

## Where things stand — 2026-08-30

| Service | Registered | Client ID in code | Works? |
|---|---|---|---|
| **GitHub** | yes, device flow enabled | yes | **yes — done** |
| **Pinterest** | yes, approved | yes (`1606244`) | wired — paste a token to confirm |
| **Notion** | no | n/a | not started (needs no client ID) |
| **Strava** | was, then removed | n/a | **removed 2026-08-29 — see below** |

---

## GitHub — DONE

Fully working. Device flow, no secret, no proxy. Nothing left to do.

https://github.com/settings/applications/new
- Application name: ILoveMe
- Homepage URL: `https://iloveme.nicholassutin.com`
- Callback URL: `iloveme://oauth`
- **[x] Enable Device Flow** — confirmed ticked 2026-08-28. Without it,
  `POST /login/device/code` fails outright.
- [ ] Expire user access tokens — left unchecked (no refresh plumbing; personal app)

Client ID is in `GitHubProvider.swift`. The secret is never needed.

---

## Strava — REMOVED 2026-08-29

Registered, fully working, and dropped anyway. Recorded so the decision is not
relitigated from scratch.

**Everything technical worked.** Callback domain `oauth`, redirect `iloveme://oauth`,
browser consent, code captured, exchanged through the relay Worker with the client
secret, token decoded and stored in the Keychain. Verified in the simulator against
the live Strava login page.

**Then every data call returned 403:**

```json
{"message":"Forbidden","errors":[{"resource":"Application","field":"Status","code":"Inactive"}]}
```

Strava's Community Manager, on the official forum:

> "Your API application is currently inactive because the owner of your app does not
> have an active Strava subscription. A Strava subscription is a requirement for all
> applications in our Developer Program's Standard Tier."

In force since roughly July 2026.
Source: https://communityhub.strava.com/developers-api-7/code-inactive-on-all-new-requests-13620

**Why removed rather than parked:** Strava was the only integration needing a
server-side secret. Keeping it meant keeping the relay Worker's authenticated
routes, a shared token duplicated between Cloudflare and the app binary, and refresh
plumbing for its ~6h tokens — all for an integration gated behind a subscription.
The HealthKit card was expanded instead: workouts this week and walking/running
distance cover some of the same ground from data the phone already has. Metrics
needing an Apple Watch were deliberately excluded — see the note in
`Services/Health/HealthMetric.swift`.

**To bring it back:** subscribe on the account owning the API application, reactivate
it in the API Settings Dashboard, then recover from `git log` — commit `4871d9d` has
the provider, relay client, `webRedirect` affordance and Worker routes intact.

## Pinterest — APPROVED 2026-08-30

https://developers.pinterest.com/apps/
- App ID: **`1606244`** — this is the client ID, public, already in
  `PinterestProvider.swift`.
- Redirect URI: `iloveme://oauth` (registered, but unused — see below)
- Privacy policy: `https://iloveme.nicholassutin.com/privacy`, served by the Worker
  (`worker/src/privacy.ts`). Deploying that is what unblocked the review.

### The app secret is not needed — do not paste it anywhere

The portal shows an app secret alongside the App ID. It only signs the OAuth token
exchange, and this app does no OAuth: it takes a token generated in the portal.
Leave the secret in the portal. Putting it in the app would embed a credential in a
binary; putting it in the Worker would resurrect the authenticated relay that
Strava's removal deleted.

### How it connects: paste the app secret once

The app uses the **client-credentials grant** and mints its own tokens. You paste
the app secret one time; `ServiceCard` renews the token automatically whenever it
expires. There is nothing to do again.

Pinterest's own description of the grant:

> "the access token generated from this grant type is on behalf of the current app
> owner … Automate API calls for your developer account by setting up CRON jobs."
> — `docs/pinterest-docs/set-up-authentication-and-authorization.md`

The app owner is the only user this dashboard will ever have. The
authorization-code flow exists to get consent from a *third party*, and there is no
third party here — so its browser leg, redirect URI, URL scheme and token-exchange
server are all ceremony with nobody to perform it for.

**Verified against the official OpenAPI spec** (v5.28.0,
`github.com/pinterest/api-description`) — both endpoints accept the grant:

```
GET /boards                  security: client_credentials [boards:read]
GET /boards/{board_id}/pins  security: client_credentials [boards:read, pins:read]
```

### Where the secret lives

**The iOS Keychain, and nowhere else.** Not in the repo, not in an xcconfig, not
compiled into the binary, not in Cloudflare. `TokenStore` stores it under
`pinterest.secret`, beside the token it mints, and `disconnect()` deletes both.

This matters beyond tidiness: the repo is public, and Pinterest runs GitHub secret
scanning that revokes leaked secrets within 24 hours
(`set-up-authentication-and-authorization.md`). A secret that never reaches a file
cannot be committed by accident.

The alternative — the relay Worker holding the secret — needs a shared token in the
app binary to authenticate the app to the Worker, and *that* is extractable. It
trades a secret on your own device for a server plus a credential with the same
weakness. Not worth it here.

### Why not the other two token options

| | Portal "Generate Access Tokens" | **Client credentials** | Authorization code |
|---|---|---|---|
| Lifetime | 24 hours | 30 days, auto-renewed | 30 days + refresh |
| User action | paste daily | **paste once** | paste once |
| Needs a server | no | no | yes |

Pinterest classes portal tokens as *test* tokens:

> "Test tokens expire after 24 hours." — `docs/pinterest-docs/connect-app.md`

Do not confuse that with the 30 days (`expires_in: 2592000`) quoted throughout
`set-up-authentication-and-authorization.md`, which describes tokens issued by the
OAuth endpoint — what this app now uses.

Sandbox tokens are a dead end regardless: only valid against
`api-sandbox.pinterest.com`, and Pinterest states the two environments' tokens are
not interchangeable in either direction.

### Setup

1. **Enable two-factor auth** on the Pinterest account. Pinterest mandates it for
   this grant type; without it, minting fails.
2. Portal → **My apps** → **Manage** → copy the **app secret key**.
3. App → Pinterest card → paste into **App secret** → Save.

The app immediately exchanges it for a token, which doubles as validation: a wrong
secret shows **"Secret rejected — check it"** and is not stored. A correct one
shows your boards.

Scopes requested at mint time are in `PinterestProvider.config` —
`boards:read`, `boards:read_secret`, `pins:read`, `pins:read_secret`. The `_secret`
pair includes secret boards; drop those two entries to exclude them.

### Verified 2026-08-30

Against the live endpoint with a deliberately wrong secret, the app got
`401 {"code":2,"message":"Authentication failed."}` — a 401 rather than a 400,
meaning Pinterest parsed the request and rejected only the credential. The request
shape (Basic auth, `grant_type`, scope encoding) is therefore confirmed correct end
to end; the real secret is the only untested variable.

---

## Notion — NOT STARTED (deliberate choice recorded)

notion.so/profile/integrations → **internal integration**, Read content capability
→ share chosen pages with it → paste the token into the app's Notion card.
No client ID, no redirect URI, no Worker. The code path is already built.

**Why the access token and not OAuth**, despite OAuth offering per-user sign-in:
Notion's token exchange requires `client_secret` over HTTP Basic and the public
REST API has no PKCE. Choosing OAuth would put Notion behind the same deferred
Worker as Strava, for a per-user benefit worth nothing while the user population is
one person. OAuth also does not save the page-sharing step — both paths make you
pick which pages the integration can see.

Revisit if the app gains users other than Nick. The migration is one line in
`NotionProvider.swift` (`.pastedToken` → `.webRedirect`) plus one Worker route.
