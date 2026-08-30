# Sandbox

Use Sandbox to test your integration with Pinterest API v5 without affecting your production data. After successful testing, you can update your code to point your API calls to the production environment.

## What you can do in Sandbox

You can make API calls in Sandbox to the following endpoints with a Trial or Standard [access tier](https://developers.pinterest.com/docs/key-concepts/access-tiers/).

You can view boards and Pins you create in Sandbox when you visit your own Pinterest user profile in the Pinterest mobile apps or on Pinterest.com.

Endpoints that appear in the following lists are available in Sandbox.

*About this list:*

- *We structured this list to reflect the left-panel navigation of the API reference.*
- *We check for updates on a quarterly basis (Most recent update: **August 12, 2025**)*.

### Pins and boards

#### Pins

- [`pins/list`](https://developers.pinterest.com/docs/api/v5/pins-list)
- [`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create)
- [`pins/get`](https://developers.pinterest.com/docs/api/v5/pins-get)
- [`pins/delete`](https://developers.pinterest.com/docs/api/v5/pins-delete)
- [`pins/update`](https://developers.pinterest.com/docs/api/v5/pins-update)

#### Boards

- [`boards/list`](https://developers.pinterest.com/docs/api/v5/boards-list)
- [`boards/create`](https://developers.pinterest.com/docs/api/v5/boards-create)
- [`boards/get`](https://developers.pinterest.com/docs/api/v5/boards-get)
- [`boards/update`](https://developers.pinterest.com/docs/api/v5/boards-update)
- [`boards/delete`](https://developers.pinterest.com/docs/api/v5/boards-delete)
- [`boards/list_pins`](https://developers.pinterest.com/docs/api/v5/boards-list_pins)
- [`board_sections/list`](https://developers.pinterest.com/docs/api/v5/board_sections-list)
- [`board_sections/create`](https://developers.pinterest.com/docs/api/v5/board_sections-create)
- [`board_sections/update`](https://developers.pinterest.com/docs/api/v5/board_sections-update)
- [`board_sections/delete`](https://developers.pinterest.com/docs/api/v5/board_sections-delete)
- [`board_sections/list_pins`](https://developers.pinterest.com/docs/api/v5/board_sections-list_pins)

> **Warning:**
> Do not create a Sandbox Pin with a group board. Although the Pin would only be only visible to you, the board owner may receive a notification that a Pin was created, resulting in confusion. [Learn more about boards.](https://developers.pinterest.com/docs/key-concepts/pinterest-entities/#boards)

##### Media

- [`media/list`](https://developers.pinterest.com/docs/api/v5/media-list)
- [`media/create`](https://developers.pinterest.com/docs/api/v5/media-create)
- [`media/get`](https://developers.pinterest.com/docs/api/v5/media-get)

#### User accounts

- [`user_account/get`](https://developers.pinterest.com/docs/api/v5/user_account-get)
- [`linked_business_accounts/get`](https://developers.pinterest.com/docs/api/v5/linked_business_accounts-get)
- [`followers/list`](https://developers.pinterest.com/docs/api/v5/followers-list)
- [`boards_user_follows/list`](https://developers.pinterest.com/docs/api/v5/boards_user_follows-list)
- [`follow_user/update`](https://developers.pinterest.com/docs/api/v5/follow_user-update)
- [`user_account/followed_interests`](https://developers.pinterest.com/docs/api/v5/user_account-followed_interests)

### Campaign management

#### Ad accounts

- [`ad_accounts/list`](https://developers.pinterest.com/docs/api/v5/ad_accounts-list)
- [`ad_accounts/create`](https://developers.pinterest.com/docs/api/v5/ad_accounts-create)
- [`ad_accounts/get`](https://developers.pinterest.com/docs/api/v5/ad_accounts-get)
- [`ad_account/analytics`](https://developers.pinterest.com/docs/api/v5/ad_account-analytics)
- [`sandbox/delete`](https://developers.pinterest.com/docs/api/v5/sandbox-delete) Only available in Sandbox.
- [`ad_account_targeting_analytics/get`](https://developers.pinterest.com/docs/api/v5/ad_account_targeting_analytics-get)
- [`templates/list`](https://developers.pinterest.com/docs/api/v5/templates-list)

#### Campaigns

- [`campaigns/list`](https://developers.pinterest.com/docs/api/v5/campaigns-list)
- [`campaigns/create`](https://developers.pinterest.com/docs/api/v5/campaigns-create)
- [`campaigns/update`](https://developers.pinterest.com/docs/api/v5/campaigns-update)
- [`campaigns/analytics`](https://developers.pinterest.com/docs/api/v5/campaigns-analytics)
- [`campaign_targeting_analytics/get`](https://developers.pinterest.com/docs/api/v5/campaign_targeting_analytics-get)
- [`campaigns/get`](https://developers.pinterest.com/docs/api/v5/campaigns-get)

#### Ad groups

- [`ad_groups/list`](https://developers.pinterest.com/docs/api/v5/ad_groups-list)
- [`ad_groups/create`](https://developers.pinterest.com/docs/api/v5/ad_groups-create)
- [`ad_groups/update`](https://developers.pinterest.com/docs/api/v5/ad_groups-update)
- [`ad_groups/analytics`](https://developers.pinterest.com/docs/api/v5/ad_groups-analytics)
- [`ad_groups_targeting_analytics/get`](https://developers.pinterest.com/docs/api/v5/ad_groups_targeting_analytics-get)
- [`ad_groups/audience_sizing`](https://developers.pinterest.com/docs/api/v5/ad_groups-audience_sizing)
- [`ad_groups/get`](https://developers.pinterest.com/docs/api/v5/ad_groups-get)
- [`ad_groups_bid_floor/get`](https://developers.pinterest.com/docs/api/v5/ad_groups_bid_floor-get)

#### Ads

- [`ad_previews/create`](https://developers.pinterest.com/docs/api/v5/ad_previews-create) Visible to you in Sandbox but not live or
  visible to Pinterest users.
- [`ads/list`](https://developers.pinterest.com/docs/api/v5/ads-list)
- [`ads/create`](https://developers.pinterest.com/docs/api/v5/ads-create)
- [`ads/update`](https://developers.pinterest.com/docs/api/v5/ads-update)
- [`ads/analytics`](https://developers.pinterest.com/docs/api/v5/ads-analytics)
- [`ad_targeting_analytics/get`](https://developers.pinterest.com/docs/api/v5/ad_targeting_analytics-get)
- [`ads/get`](https://developers.pinterest.com/docs/api/v5/ads-get)

#### Labels

- [`labels/create`](https://developers.pinterest.com/docs/api/v5/labels-create)
- [`labels/list`](https://developers.pinterest.com/docs/api/v5/labels-list)
- [`labels/update`](https://developers.pinterest.com/docs/api/v5/labels-update)

### Targeting

#### Keywords

- [`keywords/get`](https://developers.pinterest.com/docs/api/v5/keywords-get)
- [`keywords/create`](https://developers.pinterest.com/docs/api/v5/keywords-create)
- [`keywords/update`](https://developers.pinterest.com/docs/api/v5/keywords-update)
- [`country_keywords_metrics/get`](https://developers.pinterest.com/docs/api/v5/country_keywords_metrics-get)
- [`trending_keywords/list`](https://developers.pinterest.com/docs/api/v5/trending_keywords-list)

### Ad formats

#### Lead forms

- [`lead_forms/list`](https://developers.pinterest.com/docs/api/v5/lead_forms-list)
- [`lead_form/get`](https://developers.pinterest.com/docs/api/v5/lead_form-get)

#### Lead ads

- [`ad_accounts_subscriptions/post`](https://developers.pinterest.com/docs/api/v5/ad_accounts_subscriptions-post)

### Billing

#### Billing

- [`ssio_accounts/get`](https://developers.pinterest.com/docs/api/v5/ssio_accounts-get)
- [`ssio_insertion_order/create`](https://developers.pinterest.com/docs/api/v5/ssio_insertion_order-create)
- [`ssio_insertion_order/edit`](https://developers.pinterest.com/docs/api/v5/ssio_insertion_order-edit)
- [`ssio_insertion_orders_status/get_by_ad_account`](https://developers.pinterest.com/docs/api/v5/ssio_insertion_orders_status-get_by_ad_account)
- [`ssio_insertion_orders_status/get_by_pin_order_id`](https://developers.pinterest.com/docs/api/v5/ssio_insertion_orders_status-get_by_pin_order_id)
- [`ssio_order_lines/get_by_ad_account`](https://developers.pinterest.com/docs/api/v5/ssio_order_lines-get_by_ad_account)

#### Order lines

- [`order_lines/list`](https://developers.pinterest.com/docs/api/v5/order_lines-list)
- [`order_lines/get`](https://developers.pinterest.com/docs/api/v5/order_lines-get)

#### Terms of service

- [`terms_of_service/get`](https://developers.pinterest.com/docs/api/v5/terms_of_service-get)

### Business access

#### Business access invite

- [`respond_business_access_invites`](https://developers.pinterest.com/docs/api/v5/respond_business_access_invites)

#### Business access relationships

- [`get/business_employers`](https://developers.pinterest.com/docs/api/v5/get-business_employers)
- [`delete_business_membership`](https://developers.pinterest.com/docs/api/v5/delete_business_membership)

### Others

#### Advanced auction

- [`advanced_auction_items_get/post`](https://developers.pinterest.com/docs/api/v5/advanced_auction_items_get-post)
- [`advanced_auction_items_submit/post`](https://developers.pinterest.com/docs/api/v5/advanced_auction_items_submit-post)

#### Integrations

- [`integrations_logs/post`](https://developers.pinterest.com/docs/api/v5/integrations_logs-post)

#### OAuth

- [`oauth/token`](https://developers.pinterest.com/docs/api/v5/oauth-token)
- [`token/revoke`](https://developers.pinterest.com/docs/api/v5/token-revoke)

#### Resources

- [`ad_account_countries/get`](https://developers.pinterest.com/docs/api/v5/ad_account_countries-get)
- [`delivery_metrics/get`](https://developers.pinterest.com/docs/api/v5/delivery_metrics-get)
- [`lead_form_questions/get`](https://developers.pinterest.com/docs/api/v5/lead_form_questions-get)
- [`metrics_ready_state/get`](https://developers.pinterest.com/docs/api/v5/metrics_ready_state-get)
- [`interest_targeting_options/get`](https://developers.pinterest.com/docs/api/v5/interest_targeting_options-get)
- [`targeting_options/get`](https://developers.pinterest.com/docs/api/v5/targeting_options-get)

#### Terms

- [`terms_related/list`](https://developers.pinterest.com/docs/api/v5/terms_related-list) Logically related terms.
- [`terms_suggested/list`](https://developers.pinterest.com/docs/api/v5/terms_suggested-list) Search terms often entered together.

### Shopping

#### Catalogs

- [`catalogs/list`](https://developers.pinterest.com/docs/api/v5/catalogs-list)
- [`catalogs/create`](https://developers.pinterest.com/docs/api/v5/catalogs-create)
- [`catalogs/available_filter_values`](https://developers.pinterest.com/docs/api/v5/catalogs-available_filter_values)

#### Feeds

- [`feeds/list`](https://developers.pinterest.com/docs/api/v5/feeds-list)
- [`feeds/create`](https://developers.pinterest.com/docs/api/v5/feeds-create)
- [`feeds/get`](https://developers.pinterest.com/docs/api/v5/feeds-get)
- [`feeds/update`](https://developers.pinterest.com/docs/api/v5/feeds-update)
- [`feeds/delete`](https://developers.pinterest.com/docs/api/v5/feeds-delete)
- [`feeds/ingest`](https://developers.pinterest.com/docs/api/v5/feeds-ingest)
- [`feed_processing_results/list`](https://developers.pinterest.com/docs/api/v5/feed_processing_results-list)
- [`items_issues/list`](https://developers.pinterest.com/docs/api/v5/items_issues-list)

#### Product groups

- [`catalogs_product_groups/delete_many`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-delete_many)
- [`catalogs_product_groups/create_many`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-create_many)
- [`catalogs_product_groups/list`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-list)
- [`catalogs_product_groups/create`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-create)
- [`catalogs_product_groups/get`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-get)
- [`catalogs_product_groups/delete`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-delete)
- [`catalogs_product_groups/update`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-update)
- [`catalogs_product_groups/product_counts_get`](https://developers.pinterest.com/docs/api/v5/catalogs_product_groups-product_counts_get)
- [`catalogs_product_group_pins/list`](https://developers.pinterest.com/docs/api/v5/catalogs_product_group_pins-list)
- [`products_by_product_group_filter/list`](https://developers.pinterest.com/docs/api/v5/products_by_product_group_filter-list)

#### Items

- [`items/post`](https://developers.pinterest.com/docs/api/v5/items-post)
- [`items_batch/post`](https://developers.pinterest.com/docs/api/v5/items_batch-post)
- [`items_batch/get`](https://developers.pinterest.com/docs/api/v5/items_batch-get)

## Sandbox limitations

Use Sandbox only for your own ad account, associated entities, Pins and boards.

Also, note that entities in your Sandbox environment are separate from entities in your production environment. For example, you cannot use a Pin in Sandbox to create an ad in production.

You cannot do the following in Sandbox, although some of these capabilities may be supported in the future:

- Create video Pins.
- Create or manage shopping ads.
- Test business access.
- Simulate the ads auction, feed status checks, conversion upload, or bulk editing.

## Start using Sandbox

### Step 1. Set up your app

If you have not yet set up your app to work with Pinterest, follow the instructions on the [app setup page](https://developers.pinterest.com/docs/getting-started/connect-app/) to connect and configure an app.

### Step 2. Generate a Sandbox access token

To use Sandbox, you need a specific token, which is tied to your Pinterest user account. You cannot use the Sandbox token in your production environment, nor can you use a production token for Sandbox.

#### Generate a token on your app management page

You can generate a Sandbox token quickly and easily on your app management page. The token lasts 30 days, after which, you could generate a new one if necessary.

1. Go to the [My Apps page](https://developers.pinterest.com/apps/).
2. Select **Manage** for the app you want to give Sandbox access.
3. In the **Configure** tab, scroll down to the **Generate Access Token** section.
4. Select **Sandbox** as the environment.
5. Click **Generate token**.
6. Copy the generated token, to use in Sandbox API calls.

#### Generate a token using the OAuth flow

You can also generate a Sandbox token using the [OAuth flow](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#generate-an-access-token). This could be useful if you want to continuously refresh the token for long-term testing in Sandbox. Also, with an OAuth token, you can select specific scopes.

When calling [`oauth/token`](https://developers.pinterest.com/docs/api/v5/oauth-token) you would insert `-sandbox` in the URL request path as in the following example:

`curl -X POST https://api-sandbox.pinterest.com/v5/oauth/token \`

See the full guide for [generating an access token using the OAuth flow](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/#generate-an-access-token).

### Step 3 (If necessary): Generate a Sandbox advertiser ID

If you need to call any endpoints in Sandbox that require an `advertiser_id`, create one specifically for Sandbox, because your production ID will not be recognized in that environment.

[`ad_accounts/create`](https://developers.pinterest.com/docs/api/v5/ad_accounts-create)> **Note:**
> Any parameters and code examples that appear in this section support this use case, but may not represent the full endpoint specification. See the endpoint reference page for the comprehensive spec.

#### Example request

Note that the request URL includes `-sandbox`.

```bash
curl --request POST \
  --url https://api-sandbox.pinterest.com/v5/ad_accounts \
  --header 'authorization: Bearer pina_ABCD1234...' \
  --header 'content-type: application/json' \
  --data '{
  "name": "Sandbox ad account"
}'
```

#### Example response

The endpoint returns an advertiser ID for Sandbox in the `id` field.

```json
{
  "id": "549768356618",
  "name": "Sandbox ad account",
  "owner": {
    "username": "my-name",
    "id": "878976189681867089"
  },
  "country": "US",
  "currency": "USD",
  "permissions": [],
  "created_time": 1778860038,
  "updated_time": 1778860038
}
```

### Step 4. Start making Sandbox requests

Making API calls in Sandbox is identical to making calls in production, except that the subdomain in the endpoint path is `api-sandbox.`.

#### Example

`GET https://api-sandbox.pinterest.com/v5/boards --header 'Content-Type: application/json' --header 'Authorization: Bearer [SANDBOX-TOKEN]'`

## Switch to production

When you finish testing your integration, do the following to switch from Sandbox to the production environment:

### Delete Sandbox ad accounts

Delete any ad accounts you created in Sandbox.

[`sandbox/delete`](https://developers.pinterest.com/docs/api/v5/sandbox-delete)(Only available for Sandbox IDs)

Calling this endpoint deletes the ad account and any child entities, including campaigns, ad groups, and ads.

#### Example request

```bash
curl --request DELETE \
  --url https://api-sandbox.pinterest.com/v5/ad_accounts/549768356618/sandbox \
  --header 'authorization: Bearer pina_ABCD1234...'
```

#### Example success response

```json
204 -- Successfully deleted ad account
```

#### Example failure responses

```json
403 -- not authorized to access ad_account
```

```
404 -- ad account not found
```

### Delete Sandbox Pins and boards

[`pins/delete`](https://developers.pinterest.com/docs/api/v5/pins-delete)[`boards/delete`](https://developers.pinterest.com/docs/api/v5/boards-delete)### Switch to a production advertiser ID

For any endpoints that require the `advertiser_id` parameter, make sure you have an ID for a production
environment. If you need to generate one, follow [Step 3](https://developers.pinterest.com/docs/developer-tools/sandbox/#step-3-if-necessary-generate-an-sandbox-advertiser-id), but remove `-sandbox` from the request URL.

Example: ` --url https://api.pinterest.com/v5/ad_accounts \`

### Switch to a production token

Use a production token in your API calls. Learn how to [generate an access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/) for all the endpoints you will need to use in production.

### Remove "-sandbox" from your requests

- Remove `-sandbox` from your endpoint URLs, so that the subdomain is `api.`.

Example: `GET https://api.pinterest.com/v5/boards --header 'Content-Type: application/json' --header 'Authorization: Bearer [PRODUCTION-TOKEN]'`
