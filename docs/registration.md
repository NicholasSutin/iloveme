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

### Which token: client credentials, not the portal button

Three ways to get a token. The portal button is the obvious one and the worst one.

| | Portal "Generate Access Tokens" | **Client credentials** | Authorization code |
|---|---|---|---|
| Lifetime | **24 hours** | **30 days** | 30 days + refresh |
| Effort | click | one `curl` | browser consent + server |
| Needs the secret? | no | yes, on your laptop only | yes, on a server |
| Re-paste cadence | daily | ~monthly | never |

Pinterest classes portal tokens as *test* tokens:

> "Once your app is approved for Trial access you can generate a token to test the
> API without setting up the Oauth flow. Test tokens expire after 24 hours."
> — `docs/pinterest-docs/connect-app.md`

Do not confuse that with the 30 days (`expires_in: 2592000`) quoted throughout
`set-up-authentication-and-authorization.md` — that describes tokens issued by the
OAuth endpoint, which is what the other two columns use.

### Why client credentials fits this app exactly

Pinterest's own description:

> "the access token generated from this grant type is on behalf of the current app
> owner … Automate API calls for your developer account by setting up CRON jobs."
> — `docs/pinterest-docs/set-up-authentication-and-authorization.md`

The app owner *is* the only user. There is no third party to authorize, so the
authorization-code flow's whole purpose — consent on behalf of someone else — is
overhead here. No browser leg, no redirect, no code, no server.

**Verified against Pinterest's official OpenAPI spec (v5.28.0,
`github.com/pinterest/api-description`, `v5/openapi.json`)** — both endpoints this
provider calls accept the grant:

```
GET /boards                  → security: [pinterest_oauth2: [boards:read],
                                          client_credentials: [boards:read]]
GET /boards/{board_id}/pins  → security: [pinterest_oauth2: [boards:read, pins:read],
                                          client_credentials: [boards:read, pins:read]]
```

Requirement: **two-factor auth must be enabled** on the Pinterest account, which
Pinterest mandates for this grant type.

### The command

Run it on your machine; the secret never leaves it. `read -rs` keeps it off screen
and out of shell history.

```bash
read -rs "?Pinterest app secret: " S && curl -sX POST https://api.pinterest.com/v5/oauth/token -u "1606244:$S" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=boards:read,boards:read_secret,pins:read,pins:read_secret'; unset S
```

`boards:read` alone covers public boards; the `_secret` scopes add secret boards and
pins, and are available to this grant (confirmed in the spec's `securitySchemes`).
Drop them if you would rather the dashboard not surface secret boards.

The response's `access_token` carries a `pinc` prefix. Paste it into the app →
Pinterest card → **Access token** → Save. Re-run monthly.

### If it ever needs to be permanent

The authorization-code flow gives a 30-day access token plus a *continuous* refresh
token (60-day, refreshable indefinitely). Refreshing needs HTTP Basic with the
client secret, so it needs a server — the relay Worker deleted with Strava, plus a
URL scheme back in `Info.plist` for the redirect leg.

**Twelve pastes a year is cheaper than a server.** Revisit only if that stops being
true.

The app handles expiry honestly meanwhile: a 401 shows **"Token expired — paste a
new one"** with the paste field already visible beneath it, because `.failed` counts
as idle in `ServiceStatus`. Pasting overwrites, so there is no disconnect step.

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
