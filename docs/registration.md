# App registrations — status and exact values

Client IDs are public and safe to commit; paste them into that service's
`Services/Providers/<Name>Provider.swift` (`OAuthConfig(clientID: …)`).
**Secrets are not.** They never enter the app or this repo — they go into the
future Worker via `wrangler secret put`.

## Where we paused — 2026-08-28

| Service | Registered | Client ID in code | Works? |
|---|---|---|---|
| **GitHub** | yes, device flow enabled | yes | **yes — done** |
| **Strava** | yes | yes (`175321`) | **no — unresolved, see the experiment below** |
| **Notion** | no | n/a | not started (needs no client ID) |
| **Pinterest** | no | no | not started — blocked on a privacy policy + domain |

---

## GitHub — DONE

Fully working. Device flow, no secret, no proxy. Nothing left to do.

https://github.com/settings/applications/new
- Application name: ILoveMe
- Homepage URL: https://github.com/NicholasSutin
- Callback URL: `iloveme://oauth`
- **[x] Enable Device Flow** — confirmed ticked 2026-08-28. Without it,
  `POST /login/device/code` fails outright.
- [ ] Expire user access tokens — left unchecked (no refresh plumbing; personal app)

Client ID is in `GitHubProvider.swift`. The secret is never needed.

---

## Strava — CALLBACK RESOLVED, auth not yet built

https://www.strava.com/settings/api
- Application name: ILoveMe
- Category: Data Importer
- Website: https://github.com/NicholasSutin
- Client ID `175321` → in `StravaProvider.swift`
- Authorization Callback Domain: **`iloveme`** ✅

### ✅ RESOLVED 2026-08-29 — use `iloveme://iloveme`, NOT `iloveme://oauth`

The experiment ran. Callback domain `iloveme` was accepted by the form — but form
acceptance proves nothing (`localhost` was accepted too and was unusable). What
settles it is hitting the authorize endpoint directly; no app or simulator needed:

```bash
curl -o /dev/null -w '%{http_code}\n' \
 "https://www.strava.com/oauth/mobile/authorize?client_id=175321&response_type=code&scope=activity%3Aread_all&redirect_uri=<URL-ENCODED>"
```

400 with `{"field":"redirect_uri","code":"invalid"}` = rejected.
302 to `https://www.strava.com/login` = accepted.

Measured 2026-08-29 with callback domain `iloveme`:

| redirect_uri | host | verdict |
|---|---|---|
| `https://example.com/x` | example.com | 400 rejected *(control)* |
| **`iloveme://oauth`** | oauth | **400 REJECTED** |
| **`iloveme://iloveme`** | iloveme | **302 ACCEPTED** |
| `http://iloveme/oauth` | iloveme | 302 accepted |
| `https://iloveme/oauth` | iloveme | 302 accepted |
| `iloveme://` | *(none)* | 400 rejected |
| `iloveme:/oauth` · `iloveme:oauth` | *(none)* | 400 rejected |
| `https://iloveme.nicholassutin.com/strava/callback` | that host | 400 rejected |

**Strava matches the redirect_uri's HOST against the callback domain and ignores the
scheme.** Domain `iloveme` therefore demands host `iloveme`, so the working value is
`iloveme://iloveme` — not the conventional `iloveme://oauth`. A custom scheme is
fine; only the host is checked.

Consequences:

- The app's redirect URI is **`iloveme://iloveme`**. `ASWebAuthenticationSession`
  matches on scheme alone, so it intercepts this without trouble.
- **The Worker's `/strava/callback` bounce is not needed.** It is now dead code, and
  would itself be rejected — `iloveme.nicholassutin.com` is not the callback domain.
  Using it would mean changing the callback domain, which would then break the
  direct custom-scheme redirect. Pick one; the direct one is cheaper.

### Strava also needs token refresh

Access tokens live **~6 hours**. `OAuthToken.isExpired` exists but nothing calls
it, so Strava cannot work without new refresh plumbing in `ServiceCard.load()` —
independent of the callback-domain question. Remaining for Strava, now that the callback question is closed:

1. `CFBundleURLTypes` for scheme `iloveme` in `App/Info.plist` — still absent.
2. A `webRedirect` case on `ConnectAffordance` + `connectWebRedirect()` on `ServiceCard`.
3. Refresh plumbing (the ~6h expiry above).
4. Worker secrets — `/strava/exchange` currently returns 500 `server_misconfigured`
   in production because `APP_SHARED_TOKEN` and `STRAVA_CLIENT_SECRET` are unset.
   That is the fail-closed path working as designed, not a bug.

---

## Pinterest

**Privacy policy URL: `https://iloveme.nicholassutin.com/privacy`** — served by the
Worker (`worker/src/privacy.ts`). It must be DEPLOYED before Pinterest will accept
the registration; `npm run deploy:production` in `worker/`, which needs no secrets.
Set a real `CONTACT_EMAIL` in `worker/wrangler.jsonc` first — it is shown publicly.
 — NOT STARTED

https://developers.pinterest.com/apps/
- Create app: ILoveMe, personal/prototyping purpose
- Redirect URI: `iloveme://oauth`
- Request Trial access (reads real boards/pins; 1,000 req/day cap)

### Blocked on: a privacy policy at a real domain

Pinterest reviews every app before granting any access, and wants a reachable
privacy-policy URL plus a working site.

**Use `nicholassutin.com`.** It is a live site with real content, which is what a
reviewer is checking for; `s5.design` is currently empty, and a parked-looking
domain invites a rejection round-trip on a process that is already slow and manual.
A personal site is also the truthful representation here — this app reads Nick's
own boards, for Nick. It matches the homepage already registered with GitHub and
Strava.

Keep `s5.design` for infrastructure if you want the separation — it is the better
home for the Worker (`api.s5.design`) than a portfolio domain, and that keeps
personal brand and app plumbing apart.

The privacy policy itself is short for this app: read-only access, everything stays
on device, tokens in the iOS Keychain, no analytics, no third-party sharing, and
disconnecting in-app deletes the token. (When the Worker exists it relays token
exchange only and stores nothing.)

### Shortcut once approved
Trial apps can mint a test token in the portal **without OAuth**. So Pinterest
likely never needs the Worker — give `PinterestProvider` a `.pastedToken`
affordance like Notion's and paste the test token in.

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
