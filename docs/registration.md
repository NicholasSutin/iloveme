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
The HealthKit card was expanded instead: workouts this week, walking/running
distance, exercise minutes and active energy cover some of the same ground from data
the phone already has.

**To bring it back:** subscribe on the account owning the API application, reactivate
it in the API Settings Dashboard, then recover from `git log` — commit `4871d9d` has
the provider, relay client, `webRedirect` affordance and Worker routes intact.

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
