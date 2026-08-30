# Pagination

Use pagination to manage and retrieve large datasets efficiently. When you enable pagination in your API requests, you specify the number of returned records to be displayed in a visual chunk, or "*page*".

## Apply pagination to a request

To paginate data returned in a request, include the following parameters in the request:

| **Parameter** | **Type** | **Description**                                                                                                                                |
| ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `page_size`   | Integer  | Number of records returned in a page. - Default is `25`. - Maximum is `250`.                                                                   |
| `bookmark`    | String   | The text to use as a startng point for retrieving data on the next page. Derived from preceding request that includes a `page_size` parameter. |

> **Note:**
> To determine if an endpoint supports pagination, look it up in the [API reference](https://developers.pinterest.com/docs/api/v5/introduction) to see if it includes the `page_size` and `bookmark` parameters.

### Example

See a list of Pins in a board, limiting displayed records to 50 on a page:

#### Request

```bash
curl --location --request GET 'https://api.pinterest.com/boards/\{board_id\}/pins?page_size=50'
```

#### Response

```json
{
  "items": [
    {} // List of the first 50 pins
  ],
  "bookmark": "string" // Query parameter to use to get the next set of items
}
```

To see the next 50 Pins, take the value returned in the `bookmark` attribute of the preceding response and set it as the `bookmark` query parameter in the next request.

#### Request

```text
https://api.pinterest.com/v5/boards/{board_id}/pins/?page_size=50
```

#### Response

```json
{
  "items": [
    {} // This will be a list of the next 50 items in the response to your request
  ],
  "bookmark": "string" // This is the query parameter to use to get the next set of items
}
```

Repeat the request, each time using the value returned for the `bookmark` attribute in the preceding response.

On the final page, the `bookmark` value in the response is `null`.
