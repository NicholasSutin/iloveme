# Make an API call

Confirm whether you have access to the API by making a successful request.

First, ensure you've:

1. Completed the steps to [connect your app](https://developers.pinterest.com/docs/getting-started/connect-app/) and have been approved for access.
2. Recently created an [access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#generate-an-access-token). If it's expired, you'll need to [refresh it](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#refreshing-and-storing-tokens).

Use the following command to make a request to the [`pins/list`](https://developers.pinterest.com/docs/api/v5/pins-list). This will return a list of pins in your account.

```bash
curl --location --request GET 'https://api.pinterest.com/v5/pins' \
  --header 'Authorization: Bearer YOUR_TOKEN' \
  --header 'Content-Type: application/json'
```

It should return a JSON response with a list of pins. If you have no pins, it will return an empty array, like so:

```json
{ "items": [], "bookmark": null }
```

**Congratulations!** You've made your first successful API call!

Keep exploring our docs and see what else is possible with the Pinterest API.
