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

### Which token to generate: the production-limited one

The portal offers two buttons. **Use "Generate Access Tokens" — not the sandbox
variant.**

| | Production (limited) | Sandbox |
|---|---|---|
| Scopes | `pins:read`, `boards:read`, `user_accounts:read` | all open scopes |
| Data | the real account's boards and pins | synthetic sandbox entities |
| Base URL | `api.pinterest.com` | `api-sandbox.pinterest.com` |

Sandbox's wider scope list is not an advantage here. `PinterestProvider` calls
exactly two endpoints — `GET /v5/boards` and `GET /v5/boards/{id}/pins` — and the
production token's `boards:read` + `pins:read` already cover both. The extra
sandbox scopes buy endpoints the app never calls, against boards that do not exist,
at a base URL the provider does not point to. Pinterest is explicit that the two
are not interchangeable:

> "You cannot use the Sandbox token in your production environment, nor can you use
> a production token for Sandbox."
> — `docs/pinterest-docs/sandbox.md`

### The catch: it expires after 24 hours

Pinterest classes portal-generated tokens as **test** tokens:

> "Once your app is approved for Trial access you can generate a token to test the
> API without setting up the Oauth flow. Test tokens expire after 24 hours."
> — `docs/pinterest-docs/connect-app.md`

Do not confuse this with the 30 days (`expires_in: 2592000`) quoted throughout
`set-up-authentication-and-authorization.md` — that figure describes tokens issued
by the OAuth flow, not by the portal button.

**So the paste path verifies the integration; it is not a standing connection.**
Left alone, the Pinterest card is red more often than green.

The app handles the expiry honestly rather than pretending otherwise: a 401 shows
**"Token expired — paste a new one"** with the paste field already visible beneath
it, because `.failed` counts as idle in `ServiceStatus`. Pasting overwrites the
stored token, so no disconnect step.

### The durable alternative, and what it costs

A connection that survives needs the authorization-code flow: a 30-day access token
plus a *continuous* refresh token (60-day, refreshable indefinitely, per
`set-up-authentication-and-authorization.md`). Refreshing requires HTTP Basic with
the client secret, so it requires a server.

That server is the relay Worker deleted with Strava. Bringing Pinterest to a
standing connection means restoring roughly what commit `4871d9d` held — an
authenticated Worker route, a shared token split between Cloudflare and the app
binary, and refresh plumbing — for one integration. It also needs a URL scheme back
in `Info.plist` for the redirect leg.

**Not yet.** Generate a 24-hour token first and confirm the boards render. Whether
the data is worth a server is a judgement best made after seeing the card populated
once, and that costs nothing to find out.

### To connect

1. Portal → **Manage** → **Configure** tab → **Generate Access Tokens** (the
   production button, not sandbox).
2. Copy the token immediately — the portal will not show it again.
3. Run the app → Pinterest card → paste into **Access token** → Save.

Boards appear with their pin counts, expandable to pin titles. Expect a 401 the
next day; that is the documented behaviour, not a regression.

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
