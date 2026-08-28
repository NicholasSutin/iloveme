# App registrations — exact values

Everything the code needs; each portal is a ~2-minute manual task. Paste the resulting
client ID into that service's `Services/Providers/<Name>Provider.swift`
(`OAuthConfig(clientID: …)`). Client IDs are public — safe
to commit. SECRETS ARE NOT: never paste a client secret into the app or repo; they
go in the future Worker proxy (`wrangler secret put`).

## GitHub — DONE (2026-08-28). Client ID in GitHubProvider.swift; device flow live.
## GitHub  → makes the app fully live (device flow, no secret needed)
https://github.com/settings/applications/new
- Application name: ILoveMe
- Homepage URL: https://github.com/NicholasSutin
- Callback URL: iloveme://oauth
- [x] Enable Device Flow          ← required
- [ ] Expire user access tokens   ← uncheck (no refresh plumbing yet; personal app)
Then: copy the Client ID → `GitHubProvider.swift`. Ignore/never generate need for the secret.

## Strava  (client ID useful now; token exchange still waits on the Worker)
https://www.strava.com/settings/api
- Application name: ILoveMe
- Category: Data Importer (any fits)
- Website: https://github.com/NicholasSutin
- Authorization Callback Domain: localhost   ← verify in the form's hint whether a
  bare custom scheme is allowed; docs are silent on scheme redirects for this field
Then: copy Client ID → `StravaProvider.swift`. Leave the secret on the page —
it will be entered ONLY into the Worker later.

### Status 2026-08-28: Client ID in place (175321). Callback domain = `localhost`.

`localhost` was accepted by the form, but it is a PLACEHOLDER and cannot work as-is.
Strava matches `redirect_uri` against the registered callback domain, and ours is
`iloveme://oauth` — host `oauth`, not `localhost`. Expect rejection.

Two ways out, cheapest first:

1. **Try callback domain = `iloveme`.** If Strava accepts a bare custom scheme, the
   redirect stays in the app and the Worker is needed ONLY for token exchange +
   refresh. Test this before writing any redirect machinery.
2. **Otherwise the Worker hosts the redirect and bounces**, because
   `ASWebAuthenticationSession` can only intercept custom schemes, never https:
   `Strava → https://<worker>/strava/callback?code=… → 302 → iloveme://oauth?code=…`
   Callback domain then becomes the Worker's hostname.

Also note Strava access tokens live ~6 hours, so refresh is mandatory, not optional —
see README "Not built (deliberate)".

## Pinterest  (expect an approval wait — Trial access is reviewed)
https://developers.pinterest.com/apps/
- Create app: ILoveMe, personal/prototyping purpose
- Redirect URI: iloveme://oauth
- Request Trial access (can read real boards/pins; 1,000 req/day cap)
- Shortcut while waiting: the portal can mint a test token without OAuth —
  paste-in support can be added like Notion's if wanted.
Then: Client ID → `PinterestProvider.swift`. Secret → Worker only.

## Notion — use the ACCESS TOKEN, not OAuth
notion.so/profile/integrations → **internal integration**, Read content capability
→ share chosen pages with it → paste token into the app's Notion card.

**Why not OAuth**, despite it offering per-user sign-in: Notion's token exchange
requires `client_secret` (HTTP Basic) and the public REST API has no PKCE, so OAuth
would put Notion behind the same Worker as Strava for zero benefit while this is a
single-user app. OAuth also does not save the page-sharing step — both paths make you
choose which pages the integration sees.

Revisit when the app has users other than Nick. The migration is one line in
`NotionProvider.swift` (`.pastedToken` → `.webRedirect`) plus one Worker route.
