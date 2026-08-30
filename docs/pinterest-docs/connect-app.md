# Connect app

There are a few steps you need to take in order to connect your first app.

1. Login or [create a business account](https://help.pinterest.com/business/article/create-an-advertiser-account). This is the account you will use to administer your app.
2. Verify your account's email address
3. Go to [**My apps**](https://developers.pinterest.com/apps/) and click through to accept our Developer Terms of Service

Once you've completed these requirements we'll ask for more details to register your app.

## Register your app details to get your app ID and secret key

While logged into the Pinterest account you want to use to administer your app complete the following steps:

![my app image](https://i.pinimg.com/originals/e4/98/6e/e4986eb1bdb46c112f33a67ab8945990.png)

1. Select **Connect app** and complete our request form with your app information.
2. Submit your request for trial access.

Application requests are reviewed each business day. As soon as your app has been reviewed you will receive an email notification letting you know if your app has been approved or denied access.

If your app is approved for [Trial access](https://developers.pinterest.com/docs/key-concepts/access-tiers/), you can log into your account and manage your app details on your My apps page. In your My apps view, you'll be able to find details such as your unique app ID and app secret.

[Review our guide on access tiers](https://developers.pinterest.com/docs/key-concepts/access-tiers/) for more details on the application process and what to expect with each level of access.

## Configure your app's redirect URI

We accept multiple redirect URIs when configuring your app. The value given for redirect_uri during OAuth authorization will be matched against the redirect URIs listed in your app profile. They must be an exact match to avoid any exceptions. The specified redirect URI must not cause the responding server to send a secondary redirect to yet another URI.

![redirect uri image](https://i.pinimg.com/originals/2d/e2/38/2de2385546de5e98ae5c62f5acffb4c3.png)

1. Go to **My apps** and select **Manage** for the app you want to configure.
2. On the **Configure** tab scroll to the **Redirect URIs** section and enter your desired URI
3. Select **Add** to save your changes

## Build a working authentication flow based on OAuth 2

For full details on the OAuth process, review our guide on [Scopes & Authentication](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/).

The basic flow is as follows:

1. Make an authorization request to our OAuth page in your browser
2. Handle the OAuth redirect to the appropriate location (e.g. localhost for testing)
3. Exchange the authorization code for an access token
4. Store the access token and refresh it as needed

## Helpful resources

We offer a range of Developer tools to help you get started with the Pinterest API quickly.

- [API Quickstart](https://developers.pinterest.com/docs/developer-tools/quickstart-tools/): Quickly get code samples and scripts with our API quickstart repo.There you can:
  
  - Put your app ID and app secret key in an environment script file
  - Run the sample environment set-up script and verify the results
- [Python SDK](https://developers.pinterest.com/docs/developer-tools/sdk/): Our SDK currently offers a Python library that supports campaign management and simplifies authentication and error handling. Check it out here
- [Product limited tokens](https://developers.pinterest.com/docs/developer-tools/quickstart-tools/): Once your app is approved for Trial access you can generate a token to test the API without setting up the Oauth flow.Test tokens expire after 24 hours and allow you to explore certain endpoints faster.
- [Sandbox](https://developers.pinterest.com/docs/developer-tools/sandbox/): Our sandbox environment allows you to make test calls without impacting the Pinterest product environment.[Learn more about which endpoints support Sandbox and our Shopping Sandbox environment](https://developers.pinterest.com/docs/developer-tools/sandbox/).

**Next:** [Set up authentication and authorization](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/)
