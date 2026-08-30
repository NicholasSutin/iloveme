# Create boards and Pins

Content on Pinterest takes the form of boards and Pins. We recommend reviewing our guide on [Pinterest entities](https://developers.pinterest.com/docs/key-concepts/pinterest-entities/) for more details on how Pins and boards relate to each other. A few key points are:

- Pins are saved on boards
- Boards may have subsections
- Pins can therefore be saved on a board or a board's subsection
- When a merchant uploads a [catalog](https://developers.pinterest.com/docs/work-with-catalogs/shopping-overview/) Pins are created in bulk from the items on the catalog

> **Note:**
> Pinterest is a place for insipiration and positivity, if you are a creator, help us keep Pinterest a safe place for our Pinners by reviewing our [creator code](https://create.pinterest.com/creator-code/).

## Features supported

- Image and video Pins
- Product tagging on organic Pins

## Before you begin

Make sure you do the following before creating boards and Pins:

- Connect your [app](https://developers.pinterest.com/docs/getting-started/connect-app/).
- Generate an [access token](https://developers.pinterest.com/docs/getting-started/set-up-authentication-and-authorization/) with the following scopes:
  
  - `boards:read`
  - `boards:write`
  - `pins:read`
  - `pins:write`

## Creating and managing Pins and boards

The following endpoints allow an app to create and manage boards & Pins on behalf of an authenticated Pinterest user.

### Boards

- [`boards/get`](https://developers.pinterest.com/docs/api/v5/boards-get)
- [`boards/list_pins`](https://developers.pinterest.com/docs/api/v5/boards-list_pins)
- [`boards/create`](https://developers.pinterest.com/docs/api/v5/boards-create)
- [`boards/update`](https://developers.pinterest.com/docs/api/v5/boards-update)
- [`boards/delete`](https://developers.pinterest.com/docs/api/v5/boards-delete)

### Board sections

- [`board_sections/list`](https://developers.pinterest.com/docs/api/v5/board_sections-list)
- [`board_sections/create`](https://developers.pinterest.com/docs/api/v5/board_sections-create)
- [`board_sections/update`](https://developers.pinterest.com/docs/api/v5/board_sections-update)
- [`board_sections/delete`](https://developers.pinterest.com/docs/api/v5/board_sections-delete)
- [`board_sections/list_pins`](https://developers.pinterest.com/docs/api/v5/board_sections-list_pins)

### Pins

- [`pins/get`](https://developers.pinterest.com/docs/api/v5/pins-get)
- [`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create)
- [`pins/save`](https://developers.pinterest.com/docs/api/v5/pins-save)
- [`pins/delete`](https://developers.pinterest.com/docs/api/v5/pins-delete)

### Volume limits for boards and Pins

To keep Pinterest running smoothly, there's a limit to the total number of Pins, boards, and follows we can store for accounts.

- **Boards**: up to 2,000 boards of any type (public, private, and secret), including group boards you didn't create
- **Pins**: up to 200,000 Pins including secret Pins and your Pins on group boards for personal accounts

### Creating Pins

We've recently simplified our organic Pin formats to image or video Pins. Create a new image or video Pin with [`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create).

> **Note:**
> Video Pins may require additional processing time after creation. While processing normally takes only a few seconds, you may see an incorrect value for the `creative_type` field until the processing finishes. For example, `creative_type` of REGULAR while processing, and then VIDEO after processing is complete.

We recommend using the [`pins/save`](https://developers.pinterest.com/docs/api/v5/pins-save) endpoint whenever you or your users are curating Pins. This will prevent users from meeting their entity limits unnecessarily. Pins can be saved to multiple boards.

## Creating Idea ads

While this guide is not focused on how to create ads, if you are interested in creating an Idea ad later there are a few things you'll need to take note of when creating the root organic Pin. Idea ads can only be created from image or video Pins. To create a Pin which can later be promoted into an Idea ad, take the following steps:

1. Make a request to [`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create)
2. Within the `media_source` object, set `is_standard` to `false`

> **Note:**
> Documentation for the `is_standard` field can be viewed for applicable `source_types` when you expand the `media_source` options in our API reference.

## Creating video Pins

To create video Pins, provide a video and a cover image.

### Step 1: Register your intent to upload a video

- Call the [`/media/create`](https://developers.pinterest.com/docs/api/v5/-media-create) endpoint to register your video. This declares your intention to upload a video to Pinterest.
- In the response, you will receive a `media_id`, `upload_url`, and a list of `upload_parameters`.

```bash
curl --location --request POST 'https://api.pinterest.com/v5/media' \
  --header 'Content-Type: application/json' \
  --data-raw '{"media_type": "video"}'
```

### Step 2: Upload the video file to the Pinterest Media AWS bucket

- Make a POST request to the `upload_url` provided in step 1.
- In the body of the request please set `Content-Type` to `multipart/form-data`, and provide all of the `upload_parameters` you received in Step 1 as key-value pairs.
- In this step you will also include the video file (.mp4/.mov/.m4v).
- No Bearer Authorization is needed for this step.
- A successful call will return a `204 No Content`.

```bash
curl --location --request POST 'https://pinterest-media-upload.s3-accelerate.amazonaws.com/' \
  --form 'x-amz-date="20221012T154547Z"' \
  --form 'x-amz-signature="{x-amz-signature}"' \
  --form 'x-amz-security-token="{x-amz-security-token}"' \
  --form 'x-amz-algorithm="AWS4-HMAC-SHA256"' \
  --form 'key="uploads/17/4d/be/2:video:704109860400394553:5258848560742447767"' \
  --form 'policy="{policy}"' \
  --form 'x-amz-credential="{x-amz-credential}"' \
  --form 'Content-Type="multipart/form-data"' \
  --form 'file=@"/filePath/video_file.MOV"'
```

### Step 3: Confirm upload

- Check that your video file uploaded successfully by calling the [`media/get`](https://developers.pinterest.com/docs/api/v5/media-get) endpoint.
- Include the `media_id` from step 1.
- Once you receive a succeeded status you can proceed to step 4.

```bash
curl --location --request GET 'https://api.pinterest.com/v5/media/{media_id}'
```

### Step 4: Create Pin

- The final step is to create a pin with the video file you uploaded to AWS.
- Call the [`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create) endpoint.
- Provide the following parameters in the body of the request within the `media_source` object:

1. **source_type**: `video_id`
2. **cover_image_url**: some `image url`
3. **media_id**: `media_id` from Step 1

> **Warning:**
> A valid image url must be provided to avoid a 400 Bad Request.

```bash
curl --location --request POST 'https://api.pinterest.com/v5/pins' \
  --header 'Content-Type: application/json' \
  --data-raw '{
  "title": "pin_title",
  "description": "Your description here",
  "board_id": "pinterest_board_id",
  "media_source": {
    "source_type": "video_id",
    "cover_image_url": "image.jpg",
    "media_id": "media_id"
  }
}'
```

- Once you create the video Pin, both the video and cover image will be copied and stored on Pinterest's servers.

> **Note:**
> If the video Pin is successfully created, you will receive a 201 Created response along with the Pin ID.

## Create an ad-only Pin

[`pins/create`](https://developers.pinterest.com/docs/api/v5/pins-create)A Pin makes up the content of a Pinterest ad, which is also referred to as a *promoted Pin*. To make a Pin usable as an ad, make it an ad-only Pin, which prevents it from being saved by other Pinners or distributed organically.

To make a Pin ad-only, save it to a protected Ad-only Pins board when creating or updating it. This ensures that the Pin does not appear on your public profile.

#### Request parameters to keep in mind

These code examples reflect the use case of setting up an image Pin to use later as an ad. See the Pin [create](https://developers.pinterest.com/docs/api/v5/pins-create)/[update](https://developers.pinterest.com/docs/api/v5/pins-update) endpoints for all required and optional parameters.

| **Parameter**                                                                                 | **Description**                                                                                                                                                                                                                                                                                                                                                          |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `link` string                                                                                 | The URL that users visit when they click the Pin image on the Pin page.                                                                                                                                                                                                                                                                                                  |
| `account_id` string                                                                           | Account that owns the Pin and, later, the ad based on the Pin. If you do not pass `ad_account_id`, the Pin will belong to the user account associated with the API access token. If you do pass `ad_account_id`, the platform verifies if you own the account or have [shared access](https://developers.pinterest.com/docs/work-with-ads/share-business-access/) to it. |
| `title` string                                                                                | The text that Pinterest users see below the Pin preview and the Pin page when users click the preview.                                                                                                                                                                                                                                                                   |
| `decription` string                                                                           | The Pin's descriptive text users read when they go to the Pin page.                                                                                                                                                                                                                                                                                                      |
| `board_id` string                                                                             | Unique identifier for the board that would include the Pin. If you create an ad-only Pin by setting `is_removable` to `true`, the Pin is automatically added to an "*Ad-only Pins*" board, so you do not have to specify a board ID in this case.                                                                                                                        |
| `media_source.source_type` string                                                             | The media format for the Pin. The type you specify will cause additional parameters to be required, as indicated in the Pin create/update endpoints. In this example, the specified type is `image_url`, which means the Pin is an image from a third-party website.                                                                                                     |
| `media_source.url` string **Required** for certain media source types, including `image_url`. | The URL of the Pin image from the third-party website.                                                                                                                                                                                                                                                                                                                   |
| `media_source.is_standard` boolean                                                            | Whether the image Pin is standard or simple. Only applies to certain media_source types, including `image_url`. For a Pin that you want to promote as an [idea ad](https://help.pinterest.com/business/article/idea-ads-with-paid-partnerships), set to `false`. Set to `true` if you do not have access to the feature for creating simplified Pins. (Beta)             |
| `is_removable` boolean                                                                        | Set to `true` to make the Pin ad-only, which automatically adds it to a protected "Ad-only Pins" board, so that you can use it for an ad. When you make a Pin ad-only, you do not have to assign it to a board by passing a `board_id`.                                                                                                                                  |

#### Request example

```json
{
  "link": "https://{example.com}/",
  "title": "Tree",
  "description": "Tree photo",

  "media_source": {
    "source_type": "image_url",
    "url": "https://{url_path}/{image_file_name_with_extension}",
    "is_standard": true
  },
  "is_removable": true
}
```

#### Response fields to note for ad-only Pins

Again, this response example reflects the use case of setting up an image Pin to use later as an ad.

See the Pin [create](https://developers.pinterest.com/docs/api/v5/pins-create)/[update](https://developers.pinterest.com/docs/api/v5/pins-update) endpoints for all returned fields.

| **Parameter**             | **Description**                                                                                                                                                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `has_been_promoted`       | Whether the Pin has been promoted (`true`) or not (`false`). Promoting a Pin, means using it as an ad. If you have not yet created an ad with the Pin, this value is `false`.                                                          |
| `board_id`                | Identifier for board that the Pin has been added to. If you create an ad-only Pin without adding it to a specific board, it automatically is added to an Ad-only Pins board. So, the `board_id` will be that of an Ad-only Pins board. |
| `id`                      | Identifier for the Pin you created. You will pass this `id` when you [create an ad](https://developers.pinterest.com/docs/work-with-ads/managing-ads/#step-3-create-an-ad) with that Pin.                                              |
| `media.media_type.images` | Versions of the Pin in different dimensions as it is rendered in different locations, such as the thumbnail and the Pin's page.                                                                                                        |
| `board_owner.username`    | Pinterest account user name of owner of the board that includes the Pin. If you create an ad-only Pin without adding it to a specific board, it automatically is added to an Ad-only Pins board, which you own.                        |

#### Response example

```json
{
  "has_been_promoted": false,
  "link": "https://www.pinterest.com/",
  "board_section_id": null,
  "alt_text": null,
  "product_tags": [],
  "title": "Tree",
  "dominant_color": null,
  "board_id": "123456123456123456",
  "is_standard": true,
  "note": "",
  "board_owner": {
    "username": "exampleuser"
  },
  "media": {
    "media_type": "image",
    "images": {
      "150x150": {
        "width": 150,
        "height": 150,
        "url": "https://i.pinimg.com/150x150/70/95/a8/1234abcd1234abcd1234abcd1234abcd.jpg"
      },
      "400x300": {
        "width": 400,
        "height": 300,
        "url": "https://i.pinimg.com/400x300/70/95/a8/1234abcd1234abcd1234abcd1234abcd.jpg"
      },
      "600x": {
        "width": 402,
        "height": 536,
        "url": "https://i.pinimg.com/564x/70/95/a8/1234abcd1234abcd1234abcd1234abcd.jpg"
      },
      "1200x": {
        "width": 402,
        "height": 536,
        "url": "https://i.pinimg.com/1200x/70/95/a8/1234abcd1234abcd1234abcd1234abcd.jpg"
      }
    }
  },
  "is_removable": true,
  "id": "654321654321654321",
  "creative_type": "REGULAR",
  "description": "Tree photo",
  "created_at": "2025-05-21T01:13:01",
  "pin_metrics": null,
  "is_owner": true,
  "parent_pin_id": null
}
```

## Additional Resources

### Creators

- [Creator Code](https://business.pinterest.com/creator-code/): Pinterest is building a positive online space for creators. That's why we launched the Creator Code: our commitment to kindness.
- [Creative best practices](https://business.pinterest.com/creative-best-practices/): best practices to help Creators be successful on Pinterest.
- [Creator newsletter](https://business.pinterest.com/creator-newsletter/) - Stay up to date with what Pinterest Creators are talking about through our newsletter or join our Creator community.
- [Spam and abuse](https://developers.pinterest.com/docs/key-concepts/best-practices/#monitoring-spam-and-abuse): tips on protecting your app from being misused by spammers. All API partners are subject to our Spam and abuse monitoring program.
- [Pin specs](https://help.pinterest.com/business/article/pinterest-product-specs/): recommended Pin specs to help your users' content stand out.
- [Claim your social accounts](https://help.pinterest.com/article/claim-your-account/): Instructions for Pinners and businesses to claim their Instagram, Etsy, or YouTube accounts.
- [Pinterest partners](https://business.pinterest.com/pinterest-partners/): From content scheduling to innovative creative tools, check out what our Pinterest Partners have built on our API.
