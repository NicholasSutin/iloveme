# App registrations — status and exact values

Client IDs are public and safe to commit; paste them into that service's
`Services/Providers/<Name>Provider.swift` (`OAuthConfig(clientID: …)`).
**Secrets are not**, and none of them live in a file.

## There is no `.env`, and nothing needs one

Every credential this app uses is entered at runtime and stored in the iOS Keychain:
GitHub's via the device flow, Notion's and Pinterest's by pasting into the card.
Nothing is read from a file, an xcconfig, or the environment, so there is nothing to
put in one.

Three leftovers make it look otherwise. All are dead:

| Leftover | What it was | Status |
|---|---|---|
| `APP_SHARED_TOKEN` | authenticated the app to the Strava relay Worker | removed in `7db2dac` |
| `App/Secrets.plist` | carried that token into the app; gitignored | never regenerated |
| `.dev.vars` in `.gitignore` | where wrangler would put a Worker secret | no such secret exists |

**The shared secret you are remembering was Strava's**, added in `4b45717` and
deleted with the rest of Strava. It authenticated the app to a relay that no longer
exists. Nothing reads it; generating a new one would give you a value with no
consumer.

The `.gitignore` entries stay on purpose — they cost nothing and mean a returning
relay cannot leak on its first commit. An empty slot, not a missing value.

**The Worker holds no secrets either.** It serves the homepage and privacy policy;
that is all it does. `wrangler secret put` has nothing to receive.

## Where things stand — 2026-08-30

| Service | Registered | Client ID in code | Works? |
|---|---|---|---|
| **GitHub** | yes, device flow enabled | yes | **yes — done** |
| **Pinterest** | yes, approved | yes (`1606244`) | wired — **blocked: 2FA erroring** |
| **Notion** | n/a — internal token, nothing to register | n/a | **ready — paste a token per account** |
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

### BLOCKED 2026-08-30: two-factor auth will not enable

Pinterest mandates 2FA for the client-credentials grant, and enabling it currently
**errors on Pinterest's side** — not a mistake in the setup here. Until that clears,
the secret cannot be exchanged for a token, so the paste-the-secret path is
unavailable.

Nothing in the app is wrong or needs changing. Retry the setup below once 2FA
sticks.

### Interim: a portal token still connects the card

The 24-hour test token needs no 2FA, and the field accepts it. This is worth doing
even though it expires daily, because it exercises everything the secret path would
except the mint itself — the API calls, board and pin parsing, row rendering, the
rate-limit budget — against real data. Whatever the mint eventually returns flows
through exactly this code.

1. Portal → **My apps** → **Manage** → **Configure** → **Generate Access Tokens**
   (the production-limited button, **not** sandbox).
2. Paste it into the Pinterest card and Save.

The card takes either credential and tells them apart by prefix: Pinterest tags
every access token it issues `pina` / `pinc` / `pinr`, and app secrets carry no such
prefix (`PinterestProvider.isAccessToken`). A pasted token is stored as-is; a
pasted secret is exchanged for one. Expect the card to go red about a day later —
that is the 24-hour expiry, not a regression.

### Setup, once 2FA works

1. **Enable two-factor auth** on the Pinterest account.
2. Portal → **My apps** → **Manage** → copy the **app secret key**.
3. App → Pinterest card → paste into **App secret or token** → Save.

The app immediately exchanges it for a token, which doubles as validation: a wrong
secret shows **"Secret rejected — check it"** and is not stored. A correct one
shows your boards, and renews itself from then on.

Scopes requested at mint time are in `PinterestProvider.config` —
`boards:read`, `boards:read_secret`, `pins:read`, `pins:read_secret`. The `_secret`
pair includes secret boards; drop those two entries to exclude them.

### Secret boards: the portal token cannot see them

Two independent gates, and the interim token fails the first:

1. **Scope.** A portal token grants only `pins:read`, `boards:read`,
   `user_accounts:read` (`docs/pinterest-docs/quickstart-tools.md`) — no `_secret`
   pair. So while connected by portal token the card shows **public boards only**,
   and that is expected, not a bug. The minted token requests both `_secret` scopes,
   which the spec confirms are available to the client-credentials grant.
2. **Filter.** `GET /boards` takes `privacy` — `ALL | PUBLIC | PROTECTED | SECRET |
   PUBLIC_AND_SECRET` — and the OpenAPI spec documents **no default**. The provider
   omits it and takes whatever Pinterest defaults to.

If secret boards are still missing once 2FA lands and the token is minted, gate 2 is
the cause and `privacy=ALL` on the `/boards` request is the one-line fix. It is
deliberately not added in advance: passing it with a token that lacks
`boards:read_secret` risks a 403 that would break the working portal-token setup, to
fix a problem that may not exist.

### Verified 2026-08-30

Against the live endpoint with a deliberately wrong secret, the app got
`401 {"code":2,"message":"Authentication failed."}` — a 401 rather than a 400,
meaning Pinterest parsed the request and rejected only the credential. The request
shape (Basic auth, `grant_type`, scope encoding) is therefore confirmed correct end
to end; the real secret is the only untested variable.

---

## Notion — READY TO CONNECT (two accounts, pasted tokens)

### What to pick in the portal

The developer portal (`app.notion.com/developers` → **New connection**) asks for an
authentication method. **Choose Access token, not OAuth.** OAuth is the wrong tool
here for reasons recorded below — and, importantly, it would not remove a single
step of what follows.

Do this **once per Notion account**, personal and work:

1. New connection → **Access token** → **Internal**, in that account's workspace.
2. Capability: **Read content** only. Nothing else is used, and least privilege is
   the whole reason the privacy policy can claim the app is read-only.
3. Copy the token.
4. In Notion, open each page you want on the dashboard → **Connections** → add the
   integration. Nothing is visible to it until you do; `/v1/search` returns only
   pages shared with that connection.
5. In the app, paste the token into the matching card — **Notion · Personal** or
   **Notion · Work** — and Save.

An internal connection token does not expire. (Don't confuse it with a *personal
access token*, which does — 7/30/90/180 days or 1 year, per `docs/api-notes.md`
§2.2. If a Notion card ever says "Token expired", that is what happened.)

### Why there are two Notion cards

**A Notion credential is scoped to one workspace.** Personal and work are separate
Notion accounts, so they need a token each — there is no single credential that
spans both, and OAuth does not change that: an OAuth install issues one bot token
per workspace too.

So the app models a card as an *account*, not a service:

- `ServiceAccount` = a `ServiceKind` plus an optional label.
- `NotionProvider.accounts` declares `Personal` and `Work`; every other provider
  inherits the default of one unlabelled account and is unchanged.
- The Keychain is keyed by `ServiceAccount.id` — `notion/Personal`, `notion/Work`,
  and plain `github` / `pinterest` as before, so nothing already stored moved.

Adding a third Notion account is one entry in `NotionProvider.accounts`. **Renaming
an existing label orphans its stored token** — the label is part of the Keychain
key. The card goes back to "Not connected"; paste the token again and it is fine.

### Why not OAuth — decided 2026-08-30

The question was whether to paste tokens now and submit a public connection for
review in parallel. Verdict: **paste now, and don't start OAuth until it buys
something.** OAuth's only real benefit is letting *other people* sign in, and the
app has one user.

What OAuth would cost, in the order that matters:

| | Access token (now) | OAuth |
|---|---|---|
| Notion review | none | yes — the Authorization URL only appears after a public connection is submitted |
| Server | none | the Worker must hold `client_secret` again |
| Token upkeep | none — it doesn't expire | refresh with **rotating** refresh tokens |
| Redirect URI | none | https only, so Associated Domains + an `apple-app-site-association` route |
| Privacy policy | true as written | must stop saying no server sits in between |
| Two accounts | two cards | still two cards |

1. **Refresh is the real work, not the review.** Notion's refresh returns a new
   access token *and a new refresh token*, and no `expires_in` is documented
   (`docs/api-notes.md` §2.1). So refreshing must be reactive on a 401, and the new
   pair must be persisted atomically — lose it and that workspace is locked out for
   good. No refresh plumbing exists in the app: commit `7db2dac` deleted the only
   one there ever was.
2. **The redirect leg is gone too.** That same commit removed `webRedirect`,
   `TokenRelay`, `AppSecrets`, `AuthSession`, `CFBundleURLTypes` and
   `OAuthConfig.redirectScheme`. The old note here claiming the migration was "one
   line plus one Worker route" was written before that and is no longer true.
3. **The review itself looks cheap.** Public connections are self-serve in the
   portal; the 5–10 business-day security review is for *listing in the gallery*,
   which this app does not need. A public connection can be created and used
   without being listed.

If it is ever started: pick installation scope **Any workspace**. It cannot be
changed after creation, and "Selected workspaces only" is not gallery-eligible — so
the restrictive choice would have to be thrown away on the very day OAuth starts
paying for itself.
