# iloveme-worker

Token-exchange proxy for the ILoveMe iOS app.

## Why this exists

Exactly one reason: **Strava requires a `client_secret` at token exchange and at
every refresh**, offers no PKCE public-client flow and no device flow, and a secret
compiled into an iOS binary is extractable. The secret lives here instead.

Nothing else needs it. GitHub uses the device flow (secret-free), and Notion and
Pinterest use pasted long-lived tokens. Add a route only if that changes.

**Proxy, not vending.** The secret is attached to the upstream request here and is
never returned to the app. See LIBRARIES.md for why vending is unacceptable.

## Why Hono

The whole surface is three JSON endpoints and one redirect — no UI, no SSR, no
pages. Astro and Svelte are site frameworks and would be a large mismatch. Plain
TypeScript is viable at this size, but Hono is zero-dependency (~14 kB), Workers-
native, gives typed `Env` bindings and middleware for the auth gate, and keeps the
routing readable if providers are added later.

## Layout

```
src/index.ts    app wiring, /health, 404 + error handlers
src/layout.ts   shared HTML shell + design tokens for the public pages
src/home.ts     homepage
src/privacy.ts  privacy policy
src/auth.ts     timing-safe shared-token middleware
src/strava.ts   Strava exchange / refresh / callback
```

One file per provider, mirroring `Services/Providers/` in the iOS app.

## Setup

```bash
cd worker
npm install
npm run types          # generates worker-configuration.d.ts (gitignored)
cp .dev.vars.example .dev.vars   # then fill in real values
```

`npm run types` reads `.dev.vars` **keys** to type the secrets on `Env`, which is
why the example file is committed and the real one is not.

## Secrets

Never in `wrangler.jsonc`, never in source.

```bash
npx wrangler secret put STRAVA_CLIENT_SECRET --env staging
npx wrangler secret put APP_SHARED_TOKEN     --env staging
npx wrangler secret put STRAVA_CLIENT_ID     --env staging
# repeat with --env production
```

Generate the shared token with `openssl rand -hex 32`.

## Environments

| Env | Worker name | URL |
|---|---|---|
| staging | `iloveme-app` | `iloveme-app.<subdomain>.workers.dev` |
| production | `iloveme` | `iloveme.nicholassutin.com` (custom domain) |

```bash
npm run check              # dry-run staging
npm run deploy:staging
npm run deploy:production
```

Both environments are named explicitly because wrangler warns when a deploy does
not state its target. The base `name` matches staging, so a bare `wrangler deploy`
can only ever land on staging — never production.

Production's custom domain requires the `nicholassutin.com` zone to already exist
in this Cloudflare account; `custom_domain: true` then creates and manages the DNS
record.

⚠️ `vars` are **not** inherited by named environments in wrangler. Every key must be
repeated per environment or it is simply absent there.

## Routes

| Route | Auth | Purpose |
|---|---|---|
| `GET /` | none | homepage |
| `GET /health` | none | liveness; echoes the environment |
| `GET /privacy` | none | public privacy policy (Pinterest review requires it) |
| `GET /strava/callback` | none | 302 → `iloveme://oauth?code=…` |
| `POST /strava/exchange` | bearer | `{code}` → Strava token JSON |
| `POST /strava/refresh` | bearer | `{refresh_token}` → fresh token JSON |

`/strava/callback` is public because Strava redirects the *browser* there, and a
browser carries no shared secret. It performs no exchange and holds no secret — it
only converts an https redirect into the app's custom scheme, which is necessary
because `ASWebAuthenticationSession` can intercept custom schemes but never https.

**It may not be needed at all.** Run the callback-domain experiment in
`docs/registration.md` first: if Strava accepts a bare `iloveme` callback domain,
the redirect stays entirely in the app and this route can be deleted.

## Deploying for the Pinterest privacy-policy URL

Pinterest will not accept an app registration without a reachable privacy policy.
That page is served here, so this Worker must be deployed before Pinterest can be
registered — even though nothing about Pinterest routes through it.

**No secrets are required for this.** `/privacy` and `/health` never touch them, and
the auth middleware only runs on `/strava/*`. Deploy first, add secrets when Strava
is actually wired.

```bash
npm run deploy:production
# then give Pinterest: https://iloveme.nicholassutin.com/privacy
```

`nicholassutin.com` is already on Cloudflare (verified 2026-08-28) and
`iloveme.nicholassutin.com` is unused, so `custom_domain: true` will create the DNS
record itself. Nothing needs doing by hand.

## The public pages

`/` and `/privacy` share one shell (`src/layout.ts`) so they cannot drift apart.
Fully self-contained — no external CSS, fonts, scripts or images, so there is one
request and nothing to block. Light and dark both come from `prefers-color-scheme`.

The homepage is deliberately honest: no App Store badge, no screenshots that do not
exist, no invented testimonials. The card preview is hand-built from the same visual
rules the iOS app uses, so it shows the real UI rather than a different product.

Both pages send `cache-control: public, max-age=3600`. Worth remembering while
iterating — a browser will happily serve the old page for an hour after a deploy.

## Security posture

The `Authorization: Bearer <APP_SHARED_TOKEN>` gate is a **speed bump, not access
control**. The token ships inside the iOS app and is extractable; anyone who pulls
it can spend the Strava quota. It exists to stop drive-by traffic against a public
URL.

The control that actually holds on iOS is **App Attest** (`DCAppAttestService`).
Add per-IP rate limiting and a Strava-side spend cap regardless.

Comparison uses `crypto.subtle.timingSafeEqual` over SHA-256 digests of both sides,
so it cannot short-circuit on a length mismatch.

## Verified 2026-08-28

Run locally against `wrangler dev`:

- `/health` → `{"ok":true,"environment":"staging"}`
- `/strava/callback?code=abc&state=xyz` → 302 `iloveme://oauth?code=abc&state=xyz`
- `/strava/callback?error=access_denied` → 302 with the error forwarded
- no token → 401; wrong token → 401
- valid token, missing or malformed body → 400 `missing_code`
- valid token + code → real Strava round trip, which rejected the placeholder
  secret and came back as a sanitized `{"error":"Authorization Error"}` (401)
- unknown route → 404
- **no secret value appeared anywhere in the logs**

Both environments pass `wrangler deploy --dry-run`, and `tsc --noEmit` is clean.

## Not done

- Never deployed — no Cloudflare resources created.
- The privacy policy is written to match what the app actually does, but it has not
  been reviewed by a lawyer.
- No rate limiting yet.
- No App Attest verification.
- The iOS side has no `webRedirect` affordance and no refresh plumbing, so nothing
  calls these routes yet. See the root README.
