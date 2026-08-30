# Schema standardization of optional nullable fields

We are updating our API schema to omit optional fields with `null` values in JSON response payloads. These changes could impact your integration, depending on whether, or how, you ingest optional fields with `null` values.

## Why are we doing this?

We are implementing schema standardizations for API performance improvements such as smaller payload size and reduced ambiguity about whether a field is missing or intentionally set to `null`.

## Which fields are being changed?

We are gradually applying this standard to all endpoints with optional fields that return `null`.

## What do the updated payloads look like?

Example endpoint: [`product_group_promotions/list`](https://developers.pinterest.com/docs/api/v5/product_group_promotions-list)

### Preceding the schema update

Nullable optional fields that were not included in the request are returned as `null`.

```json
{
  "items": [
    {
      "data": {
        "id": "2680059592705",
        "ad_group_id": "2680059592705",
        "catalog_product_group_id": "1231235",
        "status": "ACTIVE",
        "creative_type": "REGULAR",

        "catalog_product_group_name": null,
        "tracking_url": null
      },
      "exceptions": null
    }
  ]
}
```

### As of the schema update

Nullable optional fields that were not included in the request are omitted.

```json
{
  "items": [
    {
      "data": {
        "id": "2680059592705",
        "ad_group_id": "2680059592705",
        "catalog_product_group_id": "1231235",
        "status": "ACTIVE",
        "creative_type": "REGULAR"
      }
    }
  ]
}
```

## What should you do to manage this change?

Review how your implementation handles `null` values for optional fields. Update your internal validation to accept omissions of these types of fields in your endpoint responses.

We are applying this standard to endpoints on an ongoing basis and plan to apply it to all public Pinterest API endpoints over time. We recommend that you make any necessary adjustments as soon as possible.

## Get help

If you have any questions or need help during the migration process, please reach out to your Sales or Business Development Partner, or submit a Support request:

1. Go to [Get more help](https://help.pinterest.com/contact#no-back) in the Help Center.
2. Under **Pinterest API and Developer Tools**, select **API Technical Support** and click **Continue**.
3. On the next page, select **Pinterest API v5** and click **Continue**.
4. Provide requested information.
