# iloveme-worker

The public website for the ILoveMe iOS app: homepage and privacy policy.

## Why this exists

Originally, to hold Strava's `client_secret` — Strava required one at token exchange
and refresh, and a secret compiled into an iOS binary is extractable.

**Strava was dropped** (its Developer Program requires a paid subscription on the
owning account), and with it went the only route that needed a secret. Every
remaining integration is secret-free: GitHub uses the device flow, Notion and
Pinterest use pasted tokens.

So this Worker now **holds no secrets and receives no user data**. It exists to serve
two static pages — the privacy policy is what Pinterest's app review requires, and it
has to live at a real URL.

If a provider ever needs a secret again, `git log` has the whole relay: routes, a
timing-safe bearer gate, and sanitised upstream errors.

## Why Hono

The whole surface is three JSON endpoints and one redirect — no UI, no SSR, no
pages. Astro and Svelte are site frameworks and would be a large mismatch. Plain
TypeScript is viable at this size, but Hono is zero-dependency (~14 kB), Workers-
native, gives typed `Env` bindings and middleware for the auth gate, and keeps the
routing readable if providers are added later.

## Layout

```
src/index.ts    app wiring, /health, 404 + error handlers
src/layout.ts   shared HTML shell + design tokens
src/home.ts     homepage
src/privacy.ts  privacy policy
```

## Setup

```bash
cd worker
npm install
npm run types
```

No `.dev.vars` and no secrets — there is nothing sensitive left to configure.

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

Both environments are named explicitly because wrangler warns when a deploy does not
state its target. The base `name` matches staging, so a bare `wrangler deploy` can
only ever land on staging — never production.

⚠️ `vars` are **not** inherited by named environments in wrangler. Every key must be
repeated per environment or it is simply absent there.

## Routes

| Route | Purpose |
|---|---|
| `GET /` | homepage |
| `GET /privacy` | privacy policy (Pinterest review requires a reachable URL) |
| `GET /health` | liveness; echoes the environment |

All public. Nothing here is authenticated, because nothing here is sensitive.

## The public pages

`/` and `/privacy` share one shell (`src/layout.ts`) so they cannot drift apart.
Fully self-contained — no external CSS, fonts, scripts or images, so there is one
request and nothing to block. Light and dark both come from `prefers-color-scheme`.

The homepage is deliberately honest: no App Store badge, no screenshots that do not
exist, no invented testimonials. The card preview is hand-built from the same visual
rules the iOS app uses, so it shows the real UI rather than a different product.

Both pages send `cache-control: public, max-age=3600`. Worth remembering while
iterating — a browser will happily serve the old page for an hour after a deploy.

## Verified 2026-08-29

Locally against `wrangler dev`: `/` and `/privacy` return 200 `text/html`, `/health`
reports its environment, and the removed `/strava/*` routes return 404. Production
dry-run shows two vars and no secrets. `tsc --noEmit` is clean.

## Not done

- The privacy policy is written to match what the app actually does, but it has not
  been reviewed by a lawyer.
- Nothing here is authenticated or rate-limited, because nothing here is sensitive
  or expensive. Reconsider both if a data route ever returns.
