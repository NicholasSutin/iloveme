# Quickstart tools

The Pinterest Developer Platform provides quickstart tools that help to streamline your development process, allowing you to focus on building innovative applications that leverage Pinterest's features.

## Before getting started

- Access to the Pinterest API requires you to have [business account](https://help.pinterest.com/business/article/get-a-business-account)
- To use our developer tools, your app must already be approved for access. Review the [Connect app guide](https://developers.pinterest.com/docs/getting-started/connect-app/) for details. Approved apps will have an active status and visible app secret in your apps management page.

## Test access tokens

Test Access tokens are special tokens that allow you to test certain endpoints without needing to go through the full OAuth flow.

**Key Features**

- Easy Testing: Quickly test API calls without requiring full OAuth authentication.
- Time-Saving: Speeds up the development process by eliminating repetitive authentication steps.

**Types of test tokens**

- Production limited tokens: generate a token with the following scopes `pins:read` `boards:read` and `user_accounts:read`
- Sandbox token: generate a token that will work against all scopes in our Sandbox environment only

**How to Get Started**

1. Log into your developer account and go to your [My apps](https://developers.pinterest.com/apps/) page
2. Select **Manage** on the app which you'd like to create a test token for
3. On the **Configure** tab, create a test token under the **Generate Access Token** section
4. Choose between a product-limited or sandbox token
5. Use the obtained test token in your API requests for testing purposes

![Generate token](https://i.pinimg.com/originals/33/c6/ea/33c6ea187c7087642e8e77b736331d91.png)

## Github quickstart

The [Pinterest API Quickstart GitHub repository](https://github.com/pinterest/api-quickstart/) contains code examples, scripts, and detailed instructions to help you integrate Pinterest's functionalities into your applications swiftly.

**Key features**

- Ready-to-use code examples
- Detailed setup instructions
- Scripts for common API tasks

## Postman Collection

Our Developer Platform team maintains a [Postman collection](https://www.postman.com/pinterest/workspace/pinterest-collections/overview) that includes predefined requests for every endpoint. If you have a Postman account, you can view the Pinterest workspace and begin making requests in a matter of minutes.

**Key features**

- Comprehensive collection of API endpoints: All endpoints are neatly organized and readily accessible within the collection
- Pre-configured requests: API requests in the collection are pre-configured with the necessary methods (GET, POST, PUT, DELETE), URL structures, and required headers and parameters

**How to get started**

Open the [Pinterest public Postman workspace](https://www.postman.com/pinterest/workspace/pinterest-collections/overview) to explore what's possible with the Pinterest API. If you're ready to make some API requests, you'll want to fork the collection into your Postman workspace. Here's how:

1. Fork the collection

- Navigate to the latest collection version in the workspace
- Click on the three dots next to the collection name
- Select **Create a fork**.
- Label the Fork and select a workspace

![Postman example](https://i.pinimg.com/originals/6a/49/19/6a4919a665535ee142aa2aba93a34bc5.png)

1. Generate an access token and add it to your workspace

- Select the **Pinterest Collection Header** within your personal workspace.
- View the **Authorization** tab.
- Update the callback URL (1) to match the redirect URL set on your app's [Manage page](https://developers.pinterest.com/apps/).
- Enter your Pinterest app ID (2) as the client ID.
- Enter your Pinterest app secret (3) as the client secret.
- Select **Get New Access Token** and go through the OAuth process.
- Select **Use Token**. You can optionally change the token name to something that makes sense to you.

## Additional resources

- [Developer tools: Pinterest SDK](https://developers.pinterest.com/docs/developer-tools/sdk/)
- [Developer tools: Sandbox environment](https://developers.pinterest.com/docs/developer-tools/sandbox/)
