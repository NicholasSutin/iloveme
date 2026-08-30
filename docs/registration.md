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
- Homepage URL: `https://iloveme.nicholassutin.com`
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
- Website: `https://iloveme.nicholassutin.com`
- Client ID `175321` → in `StravaProvider.swift`
- Authorization Callback Domain: **`oauth`** ✅

### ✅ RESOLVED — callback domain `oauth`, redirect `iloveme://oauth`

**Strava matches the redirect_uri's HOST against the Authorization Callback Domain
and ignores the scheme.** So the domain is chosen to fit the conventional URI, not
the other way round: domain `oauth` makes `iloveme://oauth` valid.

Form acceptance proves nothing — `localhost` and `iloveme` were both accepted and
neither did what was wanted. What settles it is the authorize endpoint, which needs
no app or simulator:

```bash
curl -o /dev/null -w '%{http_code}\n' \
 "https://www.strava.com/oauth/mobile/authorize?client_id=175321&response_type=code&scope=activity%3Aread_all&redirect_uri=<URL-ENCODED>"
```

400 with `{"field":"redirect_uri","code":"invalid"}` = rejected.
302 to `https://www.strava.com/login` = accepted.

Measured against a known-bad control, before and after changing the domain — the
verdicts invert exactly, which is what proves the rule rather than assuming it:

| redirect_uri | host | domain `iloveme` | domain `oauth` (current) |
|---|---|---|---|
| `https://example.com/x` | example.com | 400 | 400 *(control)* |
| **`iloveme://oauth`** | oauth | 400 | **302 ACCEPTED** |
| `iloveme://iloveme` | iloveme | 302 | 400 |
| `iloveme://strava` | strava | — | 400 |
| `https://iloveme.nicholassutin.com/strava/callback` | that host | 400 | 400 |

Notes:

- One redirect URI serves every provider. `ASWebAuthenticationSession` delivers the
  callback to the session that started it, so a shared `oauth` host is unambiguous —
  and it matches the Callback URL already registered on the GitHub app.
- **Do not** set the domain to `iloveme.nicholassutin.com`. That would force the
  redirect back through the Worker and resurrect the `/strava/callback` bounce,
  which is otherwise dead code.

### ✅ Verified in the simulator 2026-08-29

Built signed, run on an iPhone 17 sim, Strava card tapped:

1. Connect button renders (the `.webRedirect` affordance).
2. `ASWebAuthenticationSession` presents "ILoveMe Wants to Use strava.com to Sign In".
3. Continue → **Strava's real login page loads**, not a redirect_uri error. This is
   the live confirmation that `iloveme://oauth` is accepted end to end. Re-verified
   after the domain changed from `iloveme` to `oauth`.
4. Dismissing the sheet returns the card to "Not connected", not an error —
   `ASWebAuthenticationSessionError.canceledLogin` is handled as a choice.

Not verified, because it cannot be until Worker secrets are set: the code→token
exchange. `POST /strava/exchange` returns 500 `server_misconfigured` in production
while `APP_SHARED_TOKEN` and `STRAVA_CLIENT_SECRET` are unset. Sign-in was not
completed — no credentials were entered.

### Strava also needs token refresh

Access tokens live **~6 hours**. `OAuthToken.isExpired` exists but nothing calls
it, so Strava cannot work without new refresh plumbing in `ServiceCard.load()` —
independent of the callback-domain question. Remaining for Strava, now that the callback question is closed:

1. ~~`CFBundleURLTypes`~~ — done, and verified in the built `.app`.
2. ~~`webRedirect` + `connectWebRedirect()`~~ — done, verified in the simulator.
3. ~~Refresh plumbing~~ — done: `ServiceCard.load()` refreshes through the relay
   before fetching when the token is expired. Untested until a real token exists.
4. **Worker secrets — the only thing left.**

```bash
cd worker
npx wrangler secret put STRAVA_CLIENT_SECRET --env production
npx wrangler secret put APP_SHARED_TOKEN     --env production   # openssl rand -hex 32
# STRAVA_CLIENT_ID is NOT a secret — it lives in wrangler.jsonc vars.
```

Then put the same shared token in `App/Secrets.plist` (gitignored — never commit it;
a public repo is worse than a binary, since git history is permanent):

```xml
<dict>
  <key>RelaySharedToken</key><string>…same value…</string>
  <key>RelayBaseURL</key><string>https://iloveme.nicholassutin.com</string>
</dict>
```

Without that file the Strava card says "Add App/Secrets.plist to enable the relay"
rather than offering a button that cannot work.

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
