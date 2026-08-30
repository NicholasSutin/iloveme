# Error codes

In an API request response, you may encounter an error or warning. Each has a number and an associated description.

Many errors not covered here are specific to a particular endpoint. For more details, see the [API reference](https://developers.pinterest.com/docs/api/v5/introduction/)

## Customer list errors

| **Endpoint**          | **Code**              | **Description**                           |
| --------------------- | --------------------- | ----------------------------------------- |
| Create customer lists | 2740                  | MALFORMATTED_USER_LIST                    |
|                       | 2741                  | NO_VALID_USER_LIST                        |
| Get customer lists    | 2742                  | EXCEEDED_MAX_USER_LISTS_PER_REQUEST_LIMIT |
| Get customer list     | Http status 404, 1001 | Customer list could not be found          |
|                       | 1018                  | USER_LIST_NOT_FOUND                       |
|                       | 2741                  | NO_VALID_USER_LIST                        |
| Update customer list  | 2740                  | MALFORMATTED_USER_LIST                    |
|                       | 2741                  | NO_VALID_USER_LIST                        |
|                       | 1018                  | USER_LIST_NOT_FOUND                       |

## Audience errors

| **Endpoint**   | **Code**              | **Description**                                                                   |
| -------------- | --------------------- | --------------------------------------------------------------------------------- |
| List audiences | 1019                  | For privacy reasons, all audiences must contain a minimum of 100 matched Pinners. |
|                | 1020                  | PINNER_LIST_NOT_FOUND                                                             |
|                |                       | PINNER_LIST_DELETED                                                               |
| Get audience   | Http status 404, 1000 | Audience could not be found.                                                      |

## Shopping errors

| **Code** | **Message**                                                                                                                                                                                                                                             |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 109      | Google Product Category is invalid. Google Product Category must follow the correct Google Product Category taxonomy.                                                                                                                                   |
| 112      | Availability is missing from product metadata. Possible values should be one of: - in stock - out of stock - preorder                                                                                                                                   |
| 113      | The Price field is malformed. - Check that you are correctly sending a price of the form: <number> <currency>. - Examples of valid prices include '1.00USD' and '1.00 USD'. - Do not include any currency symbols.                                      |
| 114      | Title length is over 500 characters. - We only use the first 500 characters. - Reduce the title length to under 500 characters.                                                                                                                         |
| 115      | Description length is over 10,000 characters. - We only use the first 10,000 characters. - Reduce the description length to under 10,000 characters.                                                                                                    |
| 117      | Gender value is not readable by Pinterest systems. Specify gender as one of these: - male - female - unisex                                                                                                                                             |
| 118      | The Age group value is not readable by Pinterest systems. Specify Age group as one of these: - newborn - infant - toddler - kids - adult                                                                                                                |
| 119      | The Size type value is not readable by our systems. Specify as one of these: - regular - petite - plus - big and tall - maternity                                                                                                                       |
| 125      | Sale price is improperly formatted or the sale price provided is higher than the original price of the item. Sale price must be lower than the original price.                                                                                          |
| 126      | Google Product Category is only one or two levels deep for this product, when an additional level of specificity is available.                                                                                                                          |
| 130      | The Tax value is not readable by Pinterest systems. Instead use instead four sub-attributes: country:region:rate(required):tax_ship. - All colons are required, even for blank values.                                                                  |
| 131      | The shipping value you have provided is not readable by the Pinterest system. Use 4 sub-attributes: country:region:service:price. - All colons are required, even for blank attributes.                                                                 |
| 132      | The shipping weight value you have provided is not readable by our system.                                                                                                                                                                              |
| 133      | The multipack value you have provided is not readable by our system.                                                                                                                                                                                    |
| 134      | The Adwords redirect link is formatted incorrectly or does not begin with "http" or "https".                                                                                                                                                            |
| 135      | The Adwords redirect link is malformed. Check that it is a valid url.                                                                                                                                                                                   |
| 141      | The Adult value you have provided is not readable by our systems. Please specify adult as true, false, yes or no for all affected items.                                                                                                                |
| 144      | The expiration date value you have provided is not readable by our system.                                                                                                                                                                              |
| 145      | The availability date value you have provided is not readable by our system.                                                                                                                                                                            |
| 146      | The sale date value you have provided is not readable by our system.                                                                                                                                                                                    |
| 147      | The Weight unit value you have provided is not readable by our systems. Please specify weight unit as lb, oz or kg for all affected items.                                                                                                              |
| 148      | The Is Bundle value you have provided is not readable by our systems. Please specify is bundle as true, false, yes or no for all affected items.                                                                                                        |
| 149      | The updated time value you have provided is not readable by our system.                                                                                                                                                                                 |
| 151      | Price is missing from product metadata. - Check that you are correctly sending a price of the form: <number> <currency>. - Examples of valid prices include '1.00USD' and '1.00 USD'. - Do not include any currency symbols.                            |
| 153      | Custom label length is over 1000 characters. We have removed this field from your item. Reduce the custom label length to under 1000 characters.                                                                                                        |
| 154      | Product type length is over 1000 characters. We have removed this field from your item. Reduce the product type length to under 1000 characters.                                                                                                        |
| 158      | `google_product_category` is invalid. The column is optional but we encourage users to follow the correct Google Product Category taxonomy.                                                                                                             |
| 160      | The condition of the item is invalid. The column is optional but we encourage users to specify the value in new, used or refurbished.                                                                                                                   |
| 161      | Your iOS deep link for this item ID is invalid.                                                                                                                                                                                                         |
| 162      | Your Android deep link for this item ID is invalid.                                                                                                                                                                                                     |
| 163      | Some availability values were formatted incorrectly and have been automatically corrected.                                                                                                                                                              |
| 164      | Some condition values were formatted incorrectly and have been automatically corrected.                                                                                                                                                                 |
| 165      | Some gender values were formatted incorrectly and have been automatically corrected.                                                                                                                                                                    |
| 166      | Some age_group values were formatted incorrectly and have been automatically corrected.                                                                                                                                                                 |
| 167      | Some size_type values were formatted incorrectly and have been automatically corrected.                                                                                                                                                                 |
| 168      | Some of your utm_source values were formatted incorrectly. Those values have been automatically corrected to Pinterest in order to ensure accurate UTM attribution.                                                                                     |
| 169      | Your item's currency doesn't match the usual currency for the location where your products are sold or shipped.                                                                                                                                         |
| 170      | The minimum advertised price field is malformed. - Check that you are correctly sending a minimum advertised price of the form: <number> <currency>. - Examples of valid value include '1.00USD' and '1.00 USD'. - Do not include any currency symbols. |
| 4023     | Your item doesn't meet Pinterest's merchant guidelines, so it will not be published.                                                                                                                                                                    |
