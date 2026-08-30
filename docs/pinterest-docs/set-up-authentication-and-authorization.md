# Set up authentication and authorization

Pinterest API services are only available to authenticated and authorized users.

Make sure your API requests on a user"s behalf include a current access token that identifies the user and defines your permissions, or scopes, for using the API on their behalf.

## Before you begin

Make sure you have the following items before you generate an access token:

| **What you need**             | **Why you need it**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | **How to get it**                                                                                                                                                                                                                                                                                                       |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Your app ID and client secret | You will provide these as credentials when requesting an OAuth access token.                                                                                                                                                                                                                                                                                                                                                                                                                                           | First, [Register your app](https://developers.pinterest.com/docs/getting-started/connect-app/). Then, find your [app ID](https://developers.pinterest.com/docs/faqs/faqs/#how-do-i-find-a-client-id-or-app-id) and [client secret ](https://developers.pinterest.com/docs/faqs/faqs/#how-do-i-find-my-apps-secret-key). |
| Redirect URI                  | References your app's site, where Pinterest will send the user and an authorization code after the user authorizes your app in [Step 1](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-1-redirect-the-user-to-the-pinterest-oauth-page). You will later provide the redirect URI in [Step 3](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-3-get-the-access-token), when requesting the OAuth access token. | When you register your app, you provide at least one redirect URI. See [Configure your app's redirect URI](https://developers.pinterest.com/docs/getting-started/connect-app/#configure-your-apps-redirect-uri) to learn more.                                                                                          |
| OAuth grant type selection    | The grant type determines how your app authenticates and acquires authorization to access protected resources.                                                                                                                                                                                                                                                                                                                                                                                                         | Learn about [grant types](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#which-grant-type-should-you-use). Then, select one.                                                                                                                                            |
| Scope(s) selection            | Scopes are the permissions your users give your app to act on their behalf within Pinterest. Each scope allows your app to make different API requests, such as for creating ads or viewing secret boards.                                                                                                                                                                                                                                                                                                             | Learn about [scopes](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#which-scopes-do-you-need). Then select the ones you need.                                                                                                                                           |

## Generate an access token

Take the following three steps to generate a token with the [Authorization Code grant](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#authorization-code-grant).

For the [Client Credentials grant](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#client-credentials-grant), take only [Step 3](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-3-get-the-access-token).

### Step 1: Redirect the user to the Pinterest OAuth page

Prompt the user to click a link that redirects them to `https://www.pinterest.com/oauth/` with the following parameters:

| **Parameter**                  | **Description**                                                                                                                                                                                                                                                                                                                                                            |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `client_id`   **Required**     | Unique ID for your app, also referred to as *App ID*. See [Before you begin](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#before-you-begin).                                                                                                                                                                             |
| `redirect_uri`   **Required**  | Redirect URI registered for your app. Must exactly match the value as registered with Pinterest. See [Before you begin](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#before-you-begin).                                                                                                                                  |
| `response_type`   **Required** | Type of credential you want the authorization server to return after the user authenticates and authorizes your app. Set to literal string `code`.                                                                                                                                                                                                                         |
| `scope`   **Required**         | Permission granted with the access token. At least one is required. Separate multiple scopes with spaces or commas. For example, to include the scopes `boards:read` and `pins:read`, set `scope` to `boards:read,pins:read` or `boards:read pins:read`.                                                                                                                   |
| `state`   **Optional**         | Any string value you define, appended to your redirect URI as part of the request query string during the OAuth transaction. Commonly used to prevent [cross-site request forgery](https://datatracker.ietf.org/doc/html/rfc6749/#section-10.12). Learn more from the [Open Worldwide Application Security Project (OWASP)](https://owasp.org/www-community/attacks/csrf). |

#### Example request to the OAuth page

```text
https://www.pinterest.com/oauth/?client_id=1234567&redirect_uri=https://example.com/&response_type=code&scope=ads:read,ads:write,boards:read,pins:read&state=hello
```

If the user is not yet logged in to Pinterest, they see a login page. Otherwise, they see a page to approve access for your app with your requested scopes.

![OAuth authorization page](https://i.pinimg.com/originals/cd/32/8f/cd328ff3f6de66f0a53f97b8c38285db.png)

### Step 2: Receive the authorization code with your redirect URI

After the user authorizes your app, we send them to the `redirect_uri` you specified in the [preceding step](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-1-redirect-the-user-to-the-pinterest-oauth-page) with the following parameters:

| **Parameter** | **Description**                                                                                                                                                                                                                                                                               |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `code`        | Code to be exchanged for an access token.                                                                                                                                                                                                                                                     |
| `state`       | Should match the string you entered in the [redirect request](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-1-redirect-the-user-to-the-pinterest-oauth-page). A non-matching string could indicate a cross-site request forgery attack. |

For example: the following redirect URI…

`https://www.example.com/oauth/pinterest/oauth_response/`

…results in a callback request like the following:

`https://www.example.com/oauth/pinterest/oauth_response/?code={code}&state={your_optional_string}`

### Step 3: Get the access token

For the [Authorization Code grant](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#authorization-code-grant), you will exchange the code you received in your redirect URI for an access token.

For the [Client Credentials grant](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#client-credentials-grant), you will request the token without exchanging any code.

Call the access token endpoint using the following guidelines:

[`oauth/token`](https://developers.pinterest.com/docs/api/v5/oauth-token)> **Note:**
> Try out this endpoint with the [Pinterest Postman collection](https://www.postman.com/pinterest/pinterest-collections/collection/egt1crl/pinterest-rest-api-latest). On the collection site, select **OAuth** under **Pinterest REST API (latest)** in the left navigation panel. Then select **Generate access token**.

#### Authentication

Use HTTP Basic Authentication:

- Username: `client_id`
- Password: `client_secret`

#### Authorization Header

Authorization: `Basic {base64-encoded_string_made_of client_id:client_secret}`

For example, if your `client_id` is `123` and your `client_secret` is `456`, the base64 encoding of `123:456` is `MTIzOjQ1Ng==`. So, your header would be: `Authorization: Basic MTIzOjQ1Ng==`

#### Request Body Parameters

Use the following parameters for the Authorization Code grant:

| **Parameter**                       | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `code`   **Required**               | Authorization code returned in [preceding step](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-2-receive-the-authorization-code-with-your-redirect-uri).                                                                                                                                                                                                                                                                                                                                     |
| `redirect_uri`   **Required**       | Redirect URI used during registration, which must match exactly.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `grant_type`   **Required**         | Set this to `authorization_code`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `continuous_refresh`   **Optional** | Only applicable to apps created before **September 25, 2025**. Set to `true` to return a [continuous refresh token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#refresh-token-grant). > **Warning:** > Pinterest no longer supports the legacy refresh token (365-day expiration, hard limit) If your app was created on or after **September 25, 2025**, disregard this parameter, as you are automatically using the continuous refresh token (60-day expiration, refreshable indefinitely). |

Use the following parameters for the Client Credentials grant:

| **Parameter**                | **Description**                                                                                                                                                                                                                                  |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `scope`   **Required**       | Permission granted with the access token. At least one is required. Separate multiple scopes with spaces or commas. For example, to include the scopes `boards:read` and `pins:read`, enter: `boards:read,pins:read` or `boards:read pins:read`. |
| `grant_type`    **Required** | Set this to `authorization_code`.                                                                                                                                                                                                                |

#### Example Requests

Authorization Code grant request:

```bash
curl -X POST https://api.pinterest.com/v5/oauth/token \
  --header 'Authorization: Basic {base64-encoded_string_made_of client_id:client_secret}' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=authorization_code' \
  --data-urlencode 'code={your_code}' \
  --data-urlencode 'redirect_uri=http://localhost/' \
  --data-urlencode 'continuous_refresh=true'
```

> **Note:**
> If you want to use an OAuth token in the Sandbox environment, you can generate a Sandbox token by inserting `-sandbox` into the request URL path. The first line of the request example would appear as follows: `curl -X POST https://api-sandbox.pinterest.com/v5/oauth/token`. Learn more about [Using Sandbox.](https://developers.pinterest.com/docs/developer-tools/sandbox/)

Client Credentials grant request:

```bash
curl -X POST https://api.pinterest.com/v5/oauth/token \
  --header 'Authorization: Basic {base64-encoded_string_made_of client_id:client_secret}' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode 'scope=boards:read,pins:read'
```

#### Example response

Authorization Code grant response (Note the `pina` prefix for the access token.):

```json
{
  "access_token": "{access_token_string_with_'pina'_prefix}",
  "refresh_token": "{refresh_token_string_with_'pinr'_prefix}",
  "response_type": "authorization_code",
  "token_type": "bearer",
  "expires_in": 2592000,
  "refresh_token_expires_in": 31536000,
  "scope": "boards:read boards:write pins:read"
}
```

Client Credentials grant response: (Note the `pinc` prefix for the access token.):

```json
{
  "access_token": "{access_token_string_with_'pinc'_prefix}",
  "response_type": "client_credentials",
  "token_type": "bearer",
  "expires_in": 2592000,
  "scope": "boards:read catalogs:read catalogs:write pins:read"
}
```

#### Response fields

The response includes the following fields:

| **Field**                  | **Description**                                                                                                                                                               |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `access_token`             | Token used to authenticate API requests.                                                                                                                                      |
| `refresh_token`            | Token used to obtain a new access token without requiring user interaction.                                                                                                   |
| `token_type`               | Type of token returned in the request. For example, the type `bearer` can be used by the client to authenticate requests to the API without requiring additional credentials. |
| `expires_in`               | Lifetime of the access token in seconds.                                                                                                                                      |
| `refresh_token_expires_in` | Lifetime of the refresh token in seconds.                                                                                                                                     |
| `scope`                    | Permissions granted with the access token.                                                                                                                                    |

## Use and manage tokens

See this section for guidance on using tokens, keeping them up to date and addressing invalid tokens.

### Use a token

When calling the Pinterest API, include the access token in the request header as part of the key-value pair for authorization. For the key `Authorization`, enter the value `Bearer {your_token}`, as in the following example:

```bash
curl https://api.pinterest.com/v5/user_account --header 'Authorization: Bearer 123'
```

If the access token has expired or is invalid, the request returns the following:

- Status code: `HTTP 401`
- API error code: `2`

### Inspect a token

To see information about a token, such as whether it is still valid or has the appropriate set of scopes, use the [Token Debugger](https://developers.pinterest.com/docs/developer-tools/token-debugger/).

### Store a token

*Authorization Code grants only*

You can store the access token, so that you do not have to keep repeating the flow for token generation. See the [Pinterest API Quickstart guide](https://github.com/pinterest/api-quickstart/#oauth-20-authorization) to learn about two methods for storing the token:

- As a JSON file
- As an environmental variable

### Refresh a token

*Authorization Code grants only*

Refresh your access token before it expires-–within 30 days (2592000 seconds) after it is issued–-to ensure uninterrupted access for your app users.

> **Warning:**
> Pinterest only supports the continuous refresh token (60-day expiration, refreshable indefinitely) and no longer supports the legacy refresh token (365-day expiration, hard limit).

[`oauth/token`](https://developers.pinterest.com/docs/api/v5/oauth-token)#### Request body parameters

| **Parameter**                  | **Description**                                                                                                                                                                                                                        |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `refresh_token`   **Required** | Full refresh token string, starting with `pinr`, which was returned when you [requested the access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-3-get-the-access-token). |
| `grant_type`   **Required**    | Set to the literal string `refresh_token`.                                                                                                                                                                                             |
| `scope`   **Optional**         | One or more scopes. Include this parameter to get an access token with a subset of the scopes originally granted                                                                                                                       |

#### Example request

```bash
curl -X POST https://api.pinterest.com/v5/oauth/token \
  --header 'Authorization: Basic {base64-encoded_string_made_of client_id:client_secret}' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=refresh_token' \
  --data-urlencode 'refresh_token={your_refresh_token}' \
  --data-urlencode 'scope=boards:read'
```

#### Example response for a continuous refresh token

A successful request returns a new access token and a continuous refresh token. The JSON includes the same fields that are returned in a [request for an access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#step-3-get-the-access-token), with the addition of the `refresh_token_expires_at` field, which indicates the refresh token's expiration date in Unix time.

In the following example, the value `1730227664` converts to `October 29, 2024`.

```json
{
  "access_token": "{access_token_string_with_'pina'_prefix}",
  "response_type": "refresh_token",
  "token_type": "bearer",
  "expires_in": 2592000,
  "scope": "boards:read",
  "refresh_token": "{refresh_token_string_with_'pinr'_prefix}",
  "refresh_token_expires_in": 5184000,
  "refresh_token_expires_at": 1730227664
}
```

#### Response fields

| **Parameter**   | **Description**                                                                                                                                                               |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `access_token`  | Token used to authenticate API requests.                                                                                                                                      |
| `response_type` | Set to literal string `code`.                                                                                                                                                 |
| `token_type`    | Type of token returned in the request. For example, the type `bearer` can be used by the client to authenticate requests to the API without requiring additional credentials. |
| `expires_in`    | Lifetime of the access token in seconds.                                                                                                                                      |
| `scope`         | Permissions granted with the access token.                                                                                                                                    |

Repeat these steps before 60 days in order to keep the continuous refresh token valid.

> **Note:**
> Once the refresh token has expired, you will need to explicitly request access again by repeating the Authorization Code flow.

### Replace an invalid token

When calling a Pinterest endpoint, you may occasionally receive an *Authentication failed* error, indicating that a token no longer works.

Tokens may become invalid for a number of reasons, and Pinterest does not always notify you if that has happened. The most common reasons for token invalidation are:

- The account user has changed their username or password.
- The [Github Secret Scanner program](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#github-secret-scanner-program) discovered that the token was leaked.

If your token becomes invalid, generate a new one by repeating the [Authorization Code flow](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#generate-an-access-token).

## Reset the app secret key

Your app's secret key, the client-secret, is a unique identifier from which tokens are generated. If its secret key becomes public, you should reset the key on the **My apps** page.

Reset your app's secret key:

1. Go to [My apps](https://developers.pinterest.com/apps/).
2. In the **Configure** tab, select **Reset app secret**.
3. Select **Reset** in the confirmation pop-up window.
4. Reveal and copy the new app secret key.

After you change a secret key, existing access tokens continue to work. However, you cannot generate any more access tokens using the old secret key.

## Which grant type should you use?

The Pinterest API supports three grant types, which are methods for authenticating your app and acquiring authorization to access protected resources. The type you choose will affect how you [generate an access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#generate-an-access-token).

Our implementation of grant types and access tokens follows OAuth 2.0 specifications. To learn more about OAuth and grant types, see the [OAuth 2.0 Authorization Framework RFC](https://datatracker.ietf.org/doc/html/rfc6749/).

### Authorization Code grant

**What this type is for:** This grant type is designed for web apps that access a user's data on behalf of that user. It is the only grant type that gives you access to the full range of capabilities offered by the Pinterest API. It requires user authentication.

Authorization Code is the most secure grant type because:

- The user must explicitly approve the scopes requested by your app.
- The user's credentials are never shared with the client (your app) directly.
- The access token is sent directly to the client server, not the user's browser, minimizing risk of token exposure.

**When to use it:** Use this grant type if you are building an app to be used by multiple, independent end users, or customers.

**How it works:**

![OAuth Authorization Code flow](https://i.pinimg.com/originals/7a/b5/80/7ab58042378c804f409e6499712d38d3.png)

1. A user clicks a button in your app to connect to their Pinterest account.
2. Your app redirects the user to our OAuth page. If the user is not logged into Pinterest they will be prompted to do so first.
3. The OAuth page prompts the user to give access to your app with your requested scopes.
4. The user approves access.
5. The user is redirected to your app with an authorization code (passed as a query parameter).
6. Your app calls the OAuth server with the authorization code, requesting an access token.
7. The OAuth server returns an access token.
8. Your app accesses the Pinterest API using the token on behalf of the user.

### Client Credentials grant

> **Note:**
> Two-factor authentication is required for this grant type. [Learn how to enable it for your app.](https://help.pinterest.com/article/two-factor-authentication)

**What this type is for:** This grant type is designed for situations when the client (your app) is acting on its own behalf, not a user. This means that the access token generated from this grant type is on behalf of the current app owner. It is suitable for machine-to-machine communication, where backend services authenticate and interact with APIs without user involvement.

**What you can access:** With this grant type, you cannot use certain endpoints that provide read/write access to more sensitive data. To find out if an endpoint is accessible with a Client Credentials token:

1. Go to the [API reference](https://developers.pinterest.com/docs/api/v5/introduction) page for that endpoint.
2. Check if **Client Credentials** is listed in the **Authorizations** section.

Also, note the necessary [scopes](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#which-scopes-do-you-need) for accessing the endpoint.

![Client Credentials authorization](https://i.pinimg.com/originals/59/31/56/5931562ca0651b5601a1f2a53f9af7a8.png)

**When to use it:** Use this grant type to access the API with your own credentials to:

- Get started faster using the API and trying out the endpoints before you access it on behalf of your users.
- Automate API calls for your developer account by setting up CRON jobs.

> **Note:**
> Because the Client Credentials flow does not require a manual authorization approval step, it is less secure. Make sure to store your client secret securely.

**How it works:**

![Client Credentials flow](https://i.pinimg.com/originals/0f/96/d7/0f96d7adcc91b9ac646746792d1d5df9.png)

1. Your app requests an access token from the Pinterest OAuth server.
2. The OAuth server returns an access token.
3. Your app accesses the Pinterest API, using the access token on behalf of your own account.

### Refresh Token grant

**What this type is for:** This grant type allows a client to exchange a refresh token for a new access token before the current access token has expired, without requiring the user to re-authenticate.

**When to use it:** Use this grant type to obtain a new access token before the current one expires.

**How it works:**

![Refresh Token flow](https://i.pinimg.com/originals/b0/34/5a/b0345ac5a040adeca43c57cb265362a3.png)

1. Your app requests a new access token from the Pinterest OAuth server with the refresh token that you obtained when first generating an access token.
2. The OAuth server returns a new access token.
3. Your app accesses the Pinterest API, using the new access token.

> **Warning:**
> Pinterest only supports the continuous refresh token (60-day expiration, refreshable indefinitely) and no longer supports the legacy refresh token (365-day expiration, hard limit).

## Which scopes do you need?

Scopes are the permissions your users give your app to act on their behalf within Pinterest. Each scope allows your app to make different API requests, such as for creating ads or viewing secret boards.

As a security best practice, request the minimum number of scopes from your users to meet their business needs. Limiting their API permissions mitigates risk to them and your organization in case your app is compromised. Consider starting with a few essential scopes and request more later as needed.

### Scope types and syntax

We provide two types of scopes:

- **Read** scopes allow users to see information related to an entity without taking any action.
- **Write scopes** allow users to take actions related to an entity. When requesting a write scope, consider also requesting the associated read scope if you need information about the affected entity to take action. For example, to create a pin on a board, you need the ID of the board or board section, which you can get from a read scope.

When specifying scopes during token creation, use the syntax `{entity}:read` or `{entity}:write`, and separate multiple scopes with commas or single spaces.

Examples:

`ads:read,ads:write,boards:read,boards:write`

`ads:read ads:write boards:read boards:write`

### Available scopes

See what read and write scopes enable you to do with each entity:

| **Entity**      | `read` **permissions**                                                                                    | `write` **permissions**                                                                                 |
| --------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `ads`           | See all data related to advertising, such as ads, ad groups and campaigns.                                | Create, update or delete ads, ad groups and campaigns.                                                  |
| `billing`       | See all of your billing data, such as your billing profile.                                               | Create, update or delete billing data.                                                                  |
| `biz_access`    | See all business access data.                                                                             | Create, update or delete business access data.                                                          |
| `boards`        | See public boards, including group boards, with `boards:read` or secret boards with `boards:read_secret`. | Create, update or delete public boards with `boards:write` or secret boards with `boards:write_secret`. |
| `catalogs`      | See all catalog data.                                                                                     | Create, update or delete catalogs.                                                                      |
| `pins`          | See public pins with `pins:read` or secret pins with `pins:read_secret`.                                  | Create, update or delete public pins with `pins:write` or secret pins with `pins:write_secret`.         |
| `user_accounts` | See user accounts and followers.                                                                          | Update user accounts and followers.                                                                     |

## Token security considerations: Github secret scanner program

Pinterest participates in GitHub's secret scanning partner program, which alerts our security team if a Pinterest access token has been leaked in a developer's code commit.

Our API tokens, such as access and refresh tokens, are secrets that developers should not share in their code or repos. A developer hosting their code on GitHub may unintentionally expose tokens in their code. If the code repo is public, anyone on the internet can see and copy the exposed tokens, which is a significant security risk.

As a partner in the program, Pinterest provides GiHub secret patterns to scan for our token format. When they detect a leaked token, they notify us.

In response, Pinterest revokes the token's access and advises the developer and user of the app to reconnect their account to the app.

### What can I expect if I receive an email?

The secret scanning alert is a free service from GitHub for public repositories on GitHub.com. If a token is leaked for an app you own, all contact emails associated with the app, including the user account associated with the leaked token, receive an email notification about the exposure. The exposed token's access is revoked within 24 hours.

If you receive an email, we recommend you take immediate action to secure your GitHub repo and re-establish your app's connection with the impacted account.

**Resources on OAuth 2.0:**

- [The OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749/#section-4.4.2)
- [OAuth.net's "Getting Started"](https://oauth.net/getting-started/)
- [OAuth Redirects](https://www.oauth.com/oauth2-servers/redirect-uris/)
- [Validating redirect URIs](https://www.oauth.com/oauth2-servers/redirect-uris/redirect-uri-validation/)

**Next:** [Make an API call](https://developers.pinterest.com/docs/getting-started/make-an-api-call/)
