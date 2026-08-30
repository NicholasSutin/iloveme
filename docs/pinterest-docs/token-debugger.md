# Token Debugger

Use the [Token Debugger](https://developers.pinterest.com/tools/debug-token) to see information about Pinterest API access tokens, so that you can troubleshoot access issues for your app users or yourself.

- Check to see if a token is expired.
- Determine if a token is invalid.
- Check scopes to determine whether a user has insufficient or excessive access to Pinterest API resources.
- See additional information that is relevant to the token or user.

## Check an access token

You can debug an OAuth2 access or refresh token under the following conditions:

- The token is for an app that is registered with Pinterest.
- The token is for your own account or that of your app users.
- The token is for accessing Version 5 of the Pinterest API.

To use the debugger:

1. Go to the [Token Debugger page](https://developers.pinterest.com/tools/debug-token/).
2. In the text box, enter the full token string, including the `pina` or `pinr` prefix.
3. Click **Debug**.

![Token debugger output](https://i.pinimg.com/originals/f0/cb/9f/f0cb9f7bf46f52c2cfadb3b25b960b98.png)

## Displayed token information

For supported tokens, the debugger displays the following fields. In some cases, the debugger displays error messages for certain fields.

| **Field**       | **Description**                                                                                                                                                                        | **Error message (if applicable)**                          |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Environment** | Environment in which the token can be used: - Production, which is used by all Pinterest users and advertisers - Sandbox, which developers use to test their Pinterest API integration | N/A                                                        |
| **App ID**      | ID of the app for which the token was created, also called the *Client ID*.                                                                                                            | *App is deactivated. Please submit appeal in Help Center.* |
| **User ID**     | ID of the Pinterest account associated with the token.                                                                                                                                 | *User is deactivated. Please reactivate your account.*     |
| **Created**     | Date and time of the token's creation.                                                                                                                                                 | N/A                                                        |
| **Expired**     | Date and time of the token's expiration.                                                                                                                                               | N/A                                                        |
| **Login State** | Whether the user session associated with the token is currently active (*Logged in*) or expired (*Logged out*).                                                                        | *Session is expired. Please generate a new token.*         |
| **Scopes**      | Permissions that your users give your app to act on their behalf within Pinterest.                                                                                                     | N/A                                                        |
