# App registrations — exact values

Everything the code needs; each portal is a ~2-minute manual task. Paste the resulting
client ID into that service's `Services/Providers/<Name>Provider.swift`
(`OAuthConfig(clientID: …)`). Client IDs are public — safe
to commit. SECRETS ARE NOT: never paste a client secret into the app or repo; they
go in the future Worker proxy (`wrangler secret put`).

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

## Pinterest  (expect an approval wait — Trial access is reviewed)
https://developers.pinterest.com/apps/
- Create app: ILoveMe, personal/prototyping purpose
- Redirect URI: iloveme://oauth
- Request Trial access (can read real boards/pins; 1,000 req/day cap)
- Shortcut while waiting: the portal can mint a test token without OAuth —
  paste-in support can be added like Notion's if wanted.
Then: Client ID → `PinterestProvider.swift`. Secret → Worker only.

## Notion — deliberately NOT registered (per instruction)
When ready: notion.so/profile/integrations → internal integration, Read content
capability → share chosen pages with it → paste token into the app's Notion card.
