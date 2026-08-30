# Pinterest SDK

> **Note:**
> The Python client is currently launched and open to the public. There may be minor API changes in future releases.

The Pinterest SDK currently offers a Python library that supports campaign management and simplifies authentication and error handling. We will be adding additional functionality and additional languages over time.

Please submit your feedback [here](https://forms.gle/kLoNk4mhoNDUB1vHA/)

## Introduction

The Pinterest SDK is hosted on [GitHub](https://github.com/pinterest/pinterest-python-sdk/) and [PyPi](https://pypi.org/project/pinterest-api-sdk/).

[Documentation](https://developers.pinterest.com/docs/developer-tools/sdk/)

See the [README](https://github.com/pinterest/pinterest-python-sdk/#readme) on GitHub in the SDK package for information on installation, getting started, setting your environment variables, examples/use cases, and model documentation.

### Prerequisites

- You must use Python 3.7 or greater
- You must have an active app
- You must have an access token

## Supported features

The Python SDK supports ad campaign creation and management, specifically:

- Creating and managing campaigns, ad groups, and ads
- Setting ads targeting using keywords
- Creating and updating customer lists and audiences

Learn more about:

- Ad campaign management
- Targeting

## Examples

### Create a campaign

```python
from pinterest.ads.campaigns import Campaign

campaign = Campaign.create(
    ad_account_id="123456",
    name="SDK Test Campaign",
    objective_type="AWARENESS",
    daily_spend_cap=10,
)
```

### Create an ad group

```python
from pinterest.ads.ad_groups import AdGroup

AD_ACCOUNT_ID = "123456"
CAMPAIGN_ID = "22334455"

ad_group = AdGroup.create(
    ad_account_id=AD_ACCOUNT_ID,
    campaign_id=CAMPAIGN_ID,
    billable_event="IMPRESSION",
    name="My first adgroup from SDK",
)
```

### Create an ad

```python
from pinterest.ads.ads import Ad

AD_ACCOUNT_ID = "12345"
AD_GROUP_ID = "3333444"
PIN_ID = "44445555"

ad = Ad.create(
    ad_account_id=AD_ACCOUNT_ID,
    ad_group_id=AD_GROUP_ID,
    creative_type="REGULAR",
    pin_id=PIN_ID,
    name="My SDK AD",
    status="ACTIVE",
)
```

### Add customer list

```python
from pinterest.ads.customer_lists import CustomerList

AD_ACCOUNT_ID = "12345"

customer_list = CustomerList.create(
    ad_account_id=AD_ACCOUNT_ID,
    name="SDK Test Customer List",
    records="test@pinterest.com,test@example.com",
    list_type="EMAIL",
)
```

### Add keywords

```python
from pinterest.ads.keywords import Keyword

AD_ACCOUNT_ID = "12345"
AD_GROUP_ID = "22334455"

keyword = Keyword.create(
    ad_account_id=AD_ACCOUNT_ID,
    parent_id=AD_GROUP_ID,
    value="baby shoes",
    match_type="BROAD",
    bid=1000,
)
```

### Add audience

```python
from pinterest.ads.audiences import Audience

AD_ACCOUNT_ID = "12345"

audience = Audience.create(
    ad_account_id=AD_ACCOUNT_ID,
    name="SDK Test Audience",
    rule=dict(
        engager_type=1
    ),
    audience_type="ENGAGEMENT",
    description="SDK Test Audience Description",
)
```

## Support

For any issues with this SDK, [contact us through the Help Center](https://help.pinterest.com/contact). (For more information on opening a help ticket, see Getting Help)

## Additional Resources

Additional information about campaigns and campaign management can be found in:

- The ads management section of the API documentation
- The API reference
- The campaign structure [help article](https://help.pinterest.com/business/article/campaign-structure)
- The create and edit a campaign [help article](https://help.pinterest.com/business/article/set-up-your-campaign)
- The campaign objectives [help article](https://help.pinterest.com/business/article/campaign-objectives)
- The campaign budgets [help article](https://help.pinterest.com/business/article/set-up-campaign-budgets)
