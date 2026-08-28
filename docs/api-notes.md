# API Notes — Strava / Notion / Pinterest / GitHub

Researched 2026-08-28 against official docs. Target: personal iOS app (Swift, no backend yet) doing OAuth from the client. Every claim carries its source URL; anything not confirmed from an official source is marked **UNVERIFIED**.

## TL;DR

| Provider | Secret required for token exchange? | Viable native-app flow (no embedded secret) | Review/approval gate? |
|---|---|---|---|
| **Strava** | **Yes** — `client_secret` is a required POST param; no PKCE | **None — needs a backend proxy** for token exchange + refresh | No app review documented; default rate limits apply |
| **Notion** | **Yes** — HTTP Basic `client_id:client_secret`; no PKCE on the public-connection flow | **None — needs a backend proxy**. Personal escape hatch: an internal connection token / Personal Access Token (no OAuth at all) | No review for internal connections/PATs; public connections are self-serve in the Developer portal |
| **Pinterest** | **Yes** — HTTP Basic `client_id:client_secret`; no PKCE | **None — needs a backend proxy** | **Yes** — even Trial access requires app approval; Standard access requires a further review + demo video |
| **GitHub** | Web flow: **yes, even with PKCE**. **Device flow: no secret needed** | **Device authorization flow** (enable it in app settings) — fully viable without a secret; refresh also works secret-free for device-flow tokens | No review; just register an OAuth app and enable device flow |

**llms.txt availability** (checked 2026-08-28 at each docs root):
- `developers.strava.com` — **No** (`/llms.txt` and `/llms-full.txt` both 404)
- `developers.notion.com` — **Yes, both** (`/llms.txt` and `/llms-full.txt`, plain text; every doc page is also fetchable as raw markdown by appending `.md`)
- `developers.pinterest.com` — **No** (`/llms.txt` → HTTP 500; `/llms-full.txt` → 200 but it's the HTML SPA shell, not a real llms file)
- `docs.github.com` — **Yes** (`/llms.txt`, markdown; it points at machine-readable docs APIs, e.g. `https://docs.github.com/api/article/body?pathname=...`; `/llms-full.txt` 404)

---

## 1. Strava

Source of truth: https://developers.strava.com/docs/authentication/ , https://developers.strava.com/swagger/swagger.json

### 1.1 OAuth mechanics
- **Authorization endpoint:** `GET https://www.strava.com/oauth/authorize` (web) and `GET https://www.strava.com/oauth/mobile/authorize` (mobile-optimized). iOS note: if the Strava app is installed you can deep-link (`strava` must be added to `LSApplicationQueriesSchemes` in Info.plist); otherwise use `ASWebAuthenticationSession`. — https://developers.strava.com/docs/authentication/
- **Token endpoint:** `POST https://www.strava.com/oauth/token`, `application/x-www-form-urlencoded`. — https://developers.strava.com/docs/authentication/
- **Token exchange params:** `client_id`, `client_secret` (required), `code`, `grant_type=authorization_code`. — https://developers.strava.com/docs/authentication/
- **Response JSON fields:** `token_type` ("Bearer"), `access_token`, `expires_at` (epoch seconds), `expires_in` (seconds), `refresh_token`, `scope` (space-delimited), `athlete` (summary athlete object on initial exchange). — https://developers.strava.com/docs/authentication/
- **Refresh flow:** same endpoint, params `client_id`, `client_secret` (required), `grant_type=refresh_token`, `refresh_token`. Access tokens are short-lived (~6 hours per `expires_in`). — https://developers.strava.com/docs/authentication/
- Revocation: `POST https://www.strava.com/oauth/revoke` with HTTP Basic client credentials (recommended as of 2026-06-01; legacy `POST /oauth/deauthorize` with `access_token`). — https://developers.strava.com/docs/authentication/

### 1.2 Secret / PKCE / device flow
- `client_secret` is **required** for both code exchange and refresh. PKCE is **not mentioned anywhere** in the auth docs; no device flow exists. — https://developers.strava.com/docs/authentication/
- **Conclusion: none — needs a backend proxy.** There is no secret-free flow; a native app must route token exchange and refresh through a server that holds the secret.

### 1.3 Scopes (read activities)
From https://developers.strava.com/docs/authentication/ (scope param of the authorize URL):
- `activity:read` — activities visible to Everyone/Followers
- `activity:read_all` — adds "Only You" activities and privacy-zone data
- (also available: `read`, `read_all`, `profile:read_all`, `profile:write`, `activity:write`)

### 1.4 Data endpoints
Base URL `https://www.strava.com/api/v3` — https://developers.strava.com/swagger/swagger.json

**Athlete stats (total distance):** `GET /athletes/{id}/stats` (operation `getStats`; `id` "Must match the authenticated athlete" — get it from the `athlete.id` in the token response or `GET /athlete`). Response `ActivityStats` fields: `all_ride_totals`, `all_run_totals`, `all_swim_totals`, `ytd_*_totals`, `recent_*_totals` (last 4 weeks), `biggest_ride_distance`, `biggest_climb_elevation_gain`. Each `*_totals` is an `ActivityTotal`: `count`, `distance` (meters, float), `moving_time` (s), `elapsed_time` (s), `elevation_gain` (m), `achievement_count`. All-time total distance = sum of `all_ride_totals.distance + all_run_totals.distance + all_swim_totals.distance` (only these three sports are rolled up). — https://developers.strava.com/swagger/swagger.json , https://developers.strava.com/swagger/activity_stats.json , https://developers.strava.com/swagger/activity_total.json

**List activities with date filters:** `GET /athlete/activities` (operation `getLoggedInAthleteActivities`), query params:
- `after` — epoch seconds; activities after this time
- `before` — epoch seconds; activities before this time
- `page` (default 1), `per_page` (default 30)
— https://developers.strava.com/swagger/swagger.json

There are no named "today/week/month" params — compute epoch bounds client-side:
- today: `after` = local midnight epoch
- this week: `after` = start-of-week epoch
- this month: `after` = first-of-month epoch
(then sum each activity's `distance` field; `ytd_*` in stats covers year-to-date without paging).

### 1.5 Rate limits (15-min polling)
Defaults per application: **overall 200 requests / 15 min, 2,000 / day; "non-upload" endpoints (all reads) 100 requests / 15 min, 1,000 / day**. 15-min windows reset at :00/:15/:30/:45; daily resets midnight UTC. Over-limit → HTTP 429. Usage headers: `X-RateLimit-Limit`, `X-RateLimit-Usage`, `X-ReadRateLimit-Limit`, `X-ReadRateLimit-Usage` (each "15-min, daily" comma pairs). — https://developers.strava.com/docs/rate-limits/
Polling every 15 min (≈96 polls/day, a few requests each) fits comfortably.

---

## 2. Notion

Source of truth: https://developers.notion.com/llms.txt (index); pages fetched as `.md`.

### 2.1 OAuth mechanics (public connection flow)
- **Authorization endpoint:** `https://api.notion.com/v1/oauth/authorize` with params `client_id`, `redirect_uri`, `response_type=code`, `owner=user`. — https://developers.notion.com/guides/get-started/authorization
- **Token endpoint:** `POST https://api.notion.com/v1/oauth/token`
  - Auth: **HTTP Basic** — base64 of `CLIENT_ID:CLIENT_SECRET` in the `Authorization` header
  - Body: **JSON** (`Content-Type: application/json`): `{"grant_type":"authorization_code","code":"...","redirect_uri":"..."}` (`redirect_uri` required iff it was passed on the authorize URL or multiple redirect URIs are configured)
  — https://developers.notion.com/guides/get-started/authorization , https://developers.notion.com/reference/create-a-token
- **Response JSON fields:** `access_token`, `refresh_token`, `token_type` ("bearer"), `bot_id`, `workspace_id`, `workspace_name`, `workspace_icon`, `owner` (user object), `duplicated_template_id`, `request_id`. **No `expires_in` field is documented** — no access-token TTL is published in the token responses. — https://developers.notion.com/guides/get-started/authorization , https://developers.notion.com/reference/create-a-token
- **Refresh flow:** same endpoint `POST /v1/oauth/token`, same HTTP Basic auth, JSON body `{"grant_type":"refresh_token","refresh_token":"nrt_..."}`. Returns a **new access token and new refresh token** (same response shape; `refresh_token` is nullable in the schema). — https://developers.notion.com/reference/refresh-a-token , https://developers.notion.com/guides/get-started/authorization

### 2.2 Secret / PKCE / device flow
- Token exchange **requires the client secret** (HTTP Basic). PKCE is documented only for the **Notion MCP** OAuth flow ("Connect a custom MCP client to Notion MCP with OAuth 2.0 and PKCE" — https://developers.notion.com/guides/mcp/build-mcp-client), **not** for the public REST API connection flow. No device flow.
- **Conclusion: none — needs a backend proxy** for the OAuth flow. **However**, for a personal single-user app you can skip OAuth entirely: use an **internal connection token** or a **Personal Access Token** ("Create and use personal access tokens for user-scoped API access"; PAT expiration chosen at creation: 7/30/90/180 days or 1 year, default 1 year). Paste it into the app's settings instead of embedding anything. — https://developers.notion.com/guides/get-started/personal-access-tokens , https://developers.notion.com/guides/get-started/authorization
- Notion has **no OAuth scopes** on the public API; access is governed by the connection's **capabilities** (Read content / Update content / Insert content / Read comments / user info), configured in the Developer portal, plus which pages the user shares. For read-only use: **"Read content"** capability. — https://developers.notion.com/reference/capabilities

### 2.3 Versioning
- `Notion-Version` header is **required** on all REST requests; **current latest version: `2026-03-11`**. — https://developers.notion.com/reference/versioning ("The most recent `Notion-Version` is 2026-03-11")

### 2.4 Data endpoints
**List pages sorted by last_edited_time:** `POST https://api.notion.com/v1/search` with headers `Authorization: Bearer <token>`, `Notion-Version: 2026-03-11`, body:
```json
{
  "filter": { "property": "object", "value": "page" },
  "sort": { "timestamp": "last_edited_time", "direction": "descending" },
  "page_size": 100
}
```
`sort.timestamp` only supports `last_edited_time`; `direction` is `ascending`/`descending`; pagination via `start_cursor`/`has_more`/`next_cursor`; `filter.value` is `page` or `data_source`. Only content **shared with the connection** is returned. — https://developers.notion.com/reference/post-search

**Favorites sidebar:** **Confirmed NOT exposed.** A full-text search of the complete official docs corpus (`https://developers.notion.com/llms-full.txt`, 1.75 MB covering every endpoint) contains **zero occurrences of "favorite"**. There is no Favorites endpoint in the API reference. Closest workarounds: have the user tag pages, or use search sorted by `last_edited_time` as a "recent pages" proxy. — https://developers.notion.com/llms-full.txt (absence of evidence in the official index; the claim "no Favorites API" is an inference from that absence, not an explicit official statement)

### 2.5 Rate limits (15-min polling)
- **Per connection: average 3 requests/second** (bursts allowed) plus a per-workspace limit; exceeding either → HTTP 429 `"rate_limited"` with `Retry-After` header (seconds) and `additional_data.rate_limit_reason` (`public_api_request_rate_limit` or `public_api_space_request_rate_limit`). Also handle 529 `"service_overload"` like a 429. — https://developers.notion.com/reference/request-limits
- A search call every 15 minutes is far below limits.

---

## 3. Pinterest

Source of truth: https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/ and Pinterest's official OpenAPI spec (github.com/pinterest/api-description, `v5/openapi.json`, API version 5.28.0).

### 3.1 OAuth mechanics
- **Authorization endpoint:** `https://www.pinterest.com/oauth/` with params `client_id` (App ID), `redirect_uri` (must exactly match a registered URI), `response_type=code`, `scope` (comma- or space-separated, at least one), `state` (optional, CSRF). — https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/
- **Token endpoint:** `POST https://api.pinterest.com/v5/oauth/token`
  - Auth: **HTTP Basic** — `Authorization: Basic base64(client_id:client_secret)`
  - Body: `application/x-www-form-urlencoded`: `grant_type=authorization_code`, `code=...`, `redirect_uri=...` (+ optional `continuous_refresh=true` — only relevant for apps created before 2025-09-25)
  — https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/ ; grant types enum `authorization_code | refresh_token | client_credentials` per the official OpenAPI spec (pinterest/api-description v5)
- **Response JSON fields:** `access_token` (prefix `pina`), `refresh_token` (prefix `pinr`), `token_type` ("bearer"), `expires_in` (2592000 = 30 days), `refresh_token_expires_in`, `scope`. — https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/
- **Refresh flow:** same endpoint + Basic auth, body `grant_type=refresh_token&refresh_token=pinr...`. Apps created **on/after 2025-09-25** automatically get a **continuous refresh token**: 60-day expiration, refreshable indefinitely (each refresh returns a new one; response includes `refresh_token_expires_at`, Unix time). The legacy 365-day hard-limit refresh token is no longer supported. Refresh the access token before its 30-day expiry. — https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/ and the `/oauth/token` operation description in the official OpenAPI spec

### 3.2 Secret / PKCE / device flow
- Token exchange **requires the client secret** (HTTP Basic). **No mention of PKCE anywhere** in the auth docs or the OpenAPI spec; no device flow.
- **Conclusion: none — needs a backend proxy.** (Trial-access apps can also generate a test token in the developer portal "without setting up the OAuth flow" — usable for personal prototyping; see 3.5.)

### 3.3 Scopes (read boards + pins)
From the official OpenAPI spec securitySchemes (pinterest/api-description v5) and the auth docs:
- `boards:read` — "See your public boards, including group boards you join"
- `pins:read` — "See your public Pins"
- Secret content needs `boards:read_secret` / `pins:read_secret`.

### 3.4 Data endpoints (v5)
Base URL `https://api.pinterest.com/v5`, `Authorization: Bearer <token>`.
- **List user's boards:** `GET /v5/boards` (op `boards/list`; scope `boards:read`). Query params: `bookmark` (cursor), `page_size`, `privacy` filter, `ad_account_id`. — official OpenAPI spec, path `/boards`
- **List pins in a board:** `GET /v5/boards/{board_id}/pins` (op `boards/list_pins`; scopes `boards:read` + `pins:read`). Query params: `bookmark`, `page_size`, `creative_types`, `pin_metrics`, `ad_account_id`. — official OpenAPI spec, path `/boards/{board_id}/pins`
- Pagination is bookmark-based: pass the `bookmark` value from the previous response.

### 3.5 Trial/sandbox access vs review
- **Every app is reviewed before any access**: "If approved for API use, your app receives Trial access." Trial apps can generate a token to test the API **without setting up the OAuth flow**. — https://developers.pinterest.com/docs/getting-started/access-tiers/ (also surfaced at /docs/key-concepts/access-tiers/)
- **Trial access CAN read real data**: "Reading boards: Yes", "Reading Pins: Yes". Restriction is on writes: "all Pins and Boards created with Trial access are only visible to their creator as Sandbox entities." — https://developers.pinterest.com/docs/key-concepts/access-tiers/
- **Standard access** (for real products/users) requires a second review: app already approved for Trial, compliance with Developer Guidelines, and "a video recording of your app completing an action using the Pinterest API"; requests reviewed each business day, decision by email. — https://developers.pinterest.com/docs/key-concepts/access-tiers/
- Net for this project: expect an approval step just to get Trial; Trial is sufficient for reading your own boards/pins.

### 3.6 Rate limits (15-min polling)
- **Trial:** 1,000 requests **per day per app** (all requests; the `org_read` category — "Fetching user accounts, boards, board sections, or Pins" — is also 1,000/day on Trial).
- **Standard:** 100 requests/second/user/app overall; `org_read` category 1,000 requests **per minute per user per app**.
- Headers: `x-ratelimit-limit`, `x-ratelimit-remaining`, `x-ratelimit-reset` (seconds to reset).
— https://developers.pinterest.com/docs/reference/rate-limits/
- 15-min polling = 96 polls/day. On Trial that leaves ~10 requests per poll cycle across boards + per-board pin listings — workable for a handful of boards, but budget carefully.

---

## 4. GitHub

Source of truth: docs.github.com (fetched via its official Article Body API) and the official public GraphQL schema.

### 4.1 OAuth mechanics
- **Authorization endpoint:** `GET https://github.com/login/oauth/authorize`. Params include `client_id`, `redirect_uri`, `scope`, `state`, and PKCE params `code_challenge` + `code_challenge_method=S256` ("Strongly recommended"; `plain` not supported). — https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- **Token endpoint:** `POST https://github.com/login/oauth/access_token`. Params: `client_id` (Required), **`client_secret` (Required)**, `code` (Required), `redirect_uri` (strongly recommended), `code_verifier` (required if `code_challenge` was sent). Send `Accept: application/json` to get JSON instead of the default form-encoded body. — same URL
- **Response JSON fields:** `access_token`, `scope`, `token_type` ("bearer"). If the app uses expiring tokens **or you requested the `offline_access` scope**, also: `refresh_token`, `expires_in` (28800 = 8 h), `refresh_token_expires_in` (15897600 ≈ 6 months). — same URL
- **Refresh flow:** `POST https://github.com/login/oauth/access_token` with `grant_type=refresh_token`, `refresh_token`, `client_id`, and `client_secret` — but `client_secret` is "**Required unless the token was generated using the device flow**". Refresh rotates both tokens; scopes can't be changed on refresh; invalid/expired refresh token → `bad_refresh_token`. — same URL

### 4.2 Secret / PKCE / device flow — the critical answer
- **Web application flow: PKCE is supported but does NOT remove the secret requirement** — `client_secret` is still listed Required on the token exchange. So the web flow alone is not a public-client flow. — https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- **Device authorization flow (RFC 8628): fully supported and needs NO client_secret** ("The `client_secret` is not needed for the device flow"). Must be enabled in the app's settings first. Steps:
  1. `POST https://github.com/login/device/code` with `client_id` (+ `scope`) → `device_code` (40 chars), `user_code` (8 chars, XXXX-XXXX), `verification_uri` (`https://github.com/login/device`), `expires_in` (900 s), `interval` (min seconds between polls, typically 5)
  2. Show the user `user_code`, open `https://github.com/login/device`
  3. Poll `POST https://github.com/login/oauth/access_token` with `client_id`, `device_code`, `grant_type=urn:ietf:params:oauth:grant-type:device_code`, honoring `interval` (errors: `authorization_pending`, `slow_down` (+5 s), `expired_token`, `access_denied`)
  — https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow
- **Conclusion: viable without a secret — use the device flow** (and request `offline_access` if you want refresh tokens; device-flow tokens refresh without a secret). This is the only one of the four providers that works secret-free from a native client.

### 4.3 Scope (read user contribution data)
- `read:user` — "Grants access to read a user's profile data." (`user` is the broader read/write scope; `user:email`, `user:follow` are subsets.) — https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
- `offline_access` — "Requests an expiring access token and a refresh token, even if your OAuth app is not configured to use expiring tokens." — same URL
- UNVERIFIED nuance: the public contribution calendar of any user is generally readable with any valid token regardless of scope; `read:user` is the documented profile-read scope and the safe choice (needed for private-contribution visibility on your own profile).

### 4.4 GraphQL: user-wide commit counts
- **Endpoint:** `POST https://api.github.com/graphql` with header `Authorization: bearer TOKEN` (Bearer also accepted). — https://docs.github.com/en/graphql/guides/forming-calls-with-graphql
- **Query** (field names verified against the official public schema, https://docs.github.com/public/fpt/schema.docs.graphql):

```graphql
query($from: DateTime, $to: DateTime) {
  viewer {
    contributionsCollection(from: $from, to: $to) {
      contributionCalendar {
        totalContributions
        weeks {
          firstDay
          contributionDays {
            date
            contributionCount
            contributionLevel
            weekday
          }
        }
      }
    }
  }
}
```
(Use `user(login: "NAME")` instead of `viewer` for another user.) Schema facts: `contributionsCollection(from: DateTime, to: DateTime, organizationID: ID)` — `from` "defaults to a year ago" if omitted; `to` "defaults to the current time or one year from the provided from argument". `ContributionCalendar` has `totalContributions: Int!`, `weeks: [ContributionCalendarWeek!]!`; each week has `firstDay: Date!` and `contributionDays: [ContributionCalendarDay!]!`; each day has `date: Date!`, `contributionCount: Int!`, `contributionLevel`, `weekday: Int!`, `color: String!`. The from→to window is therefore at most one year per query. — https://docs.github.com/public/fpt/schema.docs.graphql
- `contributionsCollection` also exposes `totalCommitContributions`, `restrictedContributionsCount`, etc., if you want commits-only counts (same schema file).
- **REST fallback:** there is **no REST endpoint for the contribution calendar** — it's GraphQL-only. Approximations via REST: `GET /search/commits?q=author:USERNAME+author-date:>=YYYY-MM-DD` (commit search; https://docs.github.com/en/rest/search/search#search-commits — note search endpoints have their own tighter rate limits) or `GET /users/{username}/events` (recent public events only; https://docs.github.com/en/rest/activity/events). UNVERIFIED detail: the events feed is limited to ~90 days/300 events. Recommendation: use GraphQL.

### 4.5 Rate limits (15-min polling)
- **GraphQL primary limit: 5,000 points/hour per user** (user token, incl. OAuth-app tokens on the user's behalf). A small query like the one above costs ~1 point (minimum per request). Check via the `rateLimit { limit remaining resetAt }` field or `/rate_limit`. Secondary limit: max 2,000 points/min to the GraphQL endpoint. — https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api
- **REST primary limit: 5,000 requests/hour** for authenticated user tokens (60/hour unauthenticated); secondary: 900 points/min per REST endpoint. — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- Device-flow polling has its own micro-limit: respect `interval` (5 s, +5 s after `slow_down`); 50 verification-code submissions/hour per app. — https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#rate-limits-for-the-device-flow
- One GraphQL call every 15 min ≈ 96 points/day — negligible.

---

## Architecture takeaway for the iOS app

- **GitHub** is the only provider usable purely client-side today: register an OAuth app, enable the **device flow**, request `read:user` (+ `offline_access` for refresh tokens), and never touch a secret.
- **Strava, Notion, Pinterest** all require the client secret at the token endpoint (Strava: form param; Notion/Pinterest: HTTP Basic) and offer **no PKCE public-client or device flow** on their public APIs → each needs a tiny token-exchange/refresh **backend proxy** (a single serverless function per provider is enough), or:
  - **Notion personal-use shortcut:** skip OAuth; let the user paste an internal-connection token / Personal Access Token (expires up to 1 year).
  - **Pinterest personal-use shortcut:** Trial-access apps can generate a test token from the developer portal without OAuth (Trial can read real boards/pins; 1,000 requests/day cap).
  - Strava has no documented secret-free shortcut; its secret must live server-side.
