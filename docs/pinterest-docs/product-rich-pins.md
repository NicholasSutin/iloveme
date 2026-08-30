# Product Pins

Product Pins make it easier for Pinners to see information about things you sell and include pricing, availability and buy location. Product Pins are different from Buyable Pins because although they make information about your product readily available on Pinterest, they do not let a user buy the product directly from Pinterest.

Product Pins must link to the product landing page where a customer can actually purchase the product. Please don't use them if your website just shows products that must be purchased on another site.

We support Open Graph and Schema.org formats for marking up your pages. If you are using a Shopify website, then your page already has the correct metadata and is ready for validation.

## Open Graph

If you use Open Graph format, you'll provide information about your article in the `<head>` tag of your article page. Open Graph format only works for pages with a single product.

You can copy and paste this example text into your page's `<head>` tag. Just change the value of `content` to match your page.

### Open Graph Properties tag

```html
<meta property="og:type" content="product" />
<meta property="og:title" content="Technology Will Save Us Gamer DIY Kit" />
<meta
  property="og:description"
  content="One of the permanent installations in the collection of Humble Masterpieces at the Museum of Modern Art in New York, this DIY gamer kit from London-based company Technology Will Save Us is equal parts gadget and design classic."
/>
<meta
  property="og:url"
  content="http://www.urbanoutfitters.com/urban/catalog/productdetail.jsp?id=37075900"
/>
<meta property="og:site_name" content="Urban Outfitters" />
<meta property="product:price:amount" content="98.00" />
<meta property="product:price:currency" content="USD" />
<meta property="og:availability" content="instock" />
```

### Open Graph properties

| **Property**             | **Description**                                                                                                                                                                                                                                                                                                         | **Required?** |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| og:type                  | Must take the value of `product` or `og:product`                                                                                                                                                                                                                                                                        | Required      |
| og:title                 | The product name. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                                                                                                                       | Required      |
| product:price:amount     | The product price (without any currency sign, e.g., `6.50`).                                                                                                                                                                                                                                                            | Required      |
| product:price:currency   | The [currency code](http://www.xe.com/iso4217.php/).                                                                                                                                                                                                                                                                    | Required      |
| og:site_name             | The store name (e.g., `Etsy`). Using this field is strongly suggested.                                                                                                                                                                                                                                                  | Optional      |
| og:url                   | The canonical URL for the page. For example, `http://www.etsy.com/listing/83934917/chocolate-raspberry-drizzle-body-lotion` (You can also specify canonical with standard HTML markup: `<link rel="canonical" href="..." />         `)                                                                                  | Optional      |
| og:description           | The product description. This may be truncated, depending on length. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                                         | Optional      |
| og:price:standard_amount | If the product is on sale, this is the non-sale price.                                                                                                                                                                                                                                                                  | Optional      |
| og:brand                 | The brand name of the product (e.g., `Lucky Brand`).                                                                                                                                                                                                                                                                    | Optional      |
| og:availability          | The current availability of the product. Possible values include `instock` `preorder` `backorder` (or `pending` meaning it will be back in stock soon) `out of stock` or `discontinued` (discontinued items won't be a part of a daily scrape and marking them as discontinued will decrease the load on your servers). | Optional      |

### Open Graph 2

| **Class**                    | **Description**                                                                                                                                                                                                                                                                                                          | **Required?**                               |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| og:image                     | The URL for a high-resolution image of the product. You can add up to 6 og:image tags.                                                                                                                                                                                                                                   | Optional                                    |
| og:price:start_date          | If the product is on sale, the start time of the sale in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                                                                                    | Optional                                    |
| og:price:end_date            | If the product is on sale, the end time of the sale in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                                                                                      | Optional                                    |
| og:see_also                  | The URL for a related product from the same domain. You can add up to six (6) og:see_also tags.                                                                                                                                                                                                                          | Optional                                    |
| og:referenced                | The canonical URL for referenced items in the product. The referenced item does not need to be on the same domain as the original article. For example, you might reference a page where a product feature is further described. You can add up to six (6) og:referenced tags.                                           | Optional                                    |
| og:upc, og:ean or og:isbn    | An ID that uniquely identifies the product within your site. (UPC stands for Universal Product Code; EAN stands for European Article Number; ISBN stands for International Standard Book Number)                                                                                                                         | Optional                                    |
| og:availability:destinations | The countries the product can be shipped to. Use [ISO 3166-1 alpha-2](https://wikipedia.org/wiki/ISO_3166-1_alpha-2/) country codes. If the product is available anywhere in the world, use `All`. Multiple countries can be listed.                                                                                     | Optional                                    |
| product:expiration_time      | The date a product will no longer be available. The date should be in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                                                                       | Optional                                    |
| product:gender               | The gender to which the product is marketed. Possible values include `male` `female` and `unisex`.                                                                                                                                                                                                                       | Optional                                    |
| product:color                | The color or colors a product is available in (e.g., hazel). You can specify all available colors.                                                                                                                                                                                                                       | Optional                                    |
| product:color:map            | The standardized version of product colors. This is required for each product:color that is included. Possible values include `beige` `black` `blue` `bronze` `brown` `gold` `green` `gray` `metallic` `multicolored` `off-white` `orange` `pink` `purple` `red` `silver` `transparent` `turquoise` `white` or `yellow`. | Optional; required if product:color is used |
| product:color:image          | The URL for a high-resolution image of the product with a specific color. Multiple images can be provided for different colors.                                                                                                                                                                                          | Optional                                    |
| og:rating                    | An aggregated rating for the product (e.g., 4.5).                                                                                                                                                                                                                                                                        | Optional                                    |
| og:rating_scale              | The maximum value (integer) of the ratings scale (e.g., 5). Required if og:rating is provided.                                                                                                                                                                                                                           | Optional; required if og:rating is used     |
| og:rating_count              | The total number of ratings (integer) (e.g., 113).                                                                                                                                                                                                                                                                       | Optional                                    |

## Schema.org

**Schema.org** tags are supported by Google and other search engines. If you use this format, you'll mark up your product in the `<body> ` of the page using the schema found at [Schema.org/Product](https://schema.org/Product). Schema.org supports multiple products and offers on the same page.

If you use the Schema.org format, we suggest that you still include your site name using the `og:site_name ` Open Graph tag. Schema.org doesn't support a site name property.

### Schema.org Properties tag

```html
<meta property="og:site_name" content="FAMSF Store" />
<div itemscope itemtype="http://schema.org/Product">
  <meta itemprop="name" content="de Young Copper Bookmark" />
  <meta itemprop="url" content="http://shop.famsf.org/do/product/BK5160" />
  <meta itemprop="image" content="http://shop.famsf.org/images/111111.jpg" />
  <meta itemprop="image" content="http://shop.famsf.org/images/222222.jpg" />
  <span itemprop="description">
    Our signature bookmark derived from the de Young's unique architecture and copper exterior.
    Measures 5 3/4'' x 1 1/4''. FAMSF Exclusive.
  </span>
  <div itemprop="color" itemscope itemtype="http://schema.org/ProductColor">
    <span itemprop="name">Aqua</span>
    <meta itemprop="map" content="blue" />
    <meta itemprop="image" content="http://cdn-i3.farfetch.com/B.jpg" />
  </div>
  <div itemprop="color" itemscope itemtype="http://schema.org/ProductColor">
    <span itemprop="name">Rose</span>
    <meta itemprop="map" content="red" />
    <meta itemprop="image" content="http://cdn-i3.farfetch.com/B.jpg" />
  </div>
  <a itemprop="relatedItem" href="http://shop.famsf.org/do/product/444444"></a>
  <a itemprop="relatedItem" href="http://shop.famsf.org/do/product/222222"></a>
  <a itemprop="relatedItem" href="http://shop.famsf.org/do/product/333333"></a>
  <div itemprop="offers" itemscope itemtype="http://schema.org/Offer">
    <span itemprop="price">$15.00</span>
    <meta itemprop="priceCurrency" content="USD" />
    <meta
      itemprop="availability"
      itemtype="http://schema.org/ItemAvailability"
      content="http://schema.org/InStock"
    />
  </div>
</div>
```

## Schema.org Properties

| **Property** | **Description**                                                                                                                                                                                                                | **Required?** |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- |
| url          | The canonical URL for the page. For example, `http://www.etsy.com/listing/83934917/chocolate-raspberry-drizzle-body-lotion` (You can also specify canonical with standard HTML markup: `<link rel="canonical" href="..." /> `) | Required      |
| name         | The product name. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                              | Required      |
| description  | The product description. This may be truncated, depending on length. All formatting, line breaks and HTML tags will be removed.                                                                                                | Optional      |
| brand        | The brand name of the product (e.g., `Lucky Brand`).                                                                                                                                                                           | Optional      |

| **Property**      | **Description**                                                                                                                                                                                                                                                                 | **Required?** |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| productId         | An ID that uniquely identifies the product within your site.                                                                                                                                                                                                                    | Optional      |
| image             | The URL for a high-resolution image of the product. You can add up to 6 images.                                                                                                                                                                                                 | Optional      |
| relatedItem       | The URL for a related product from the same domain. You can add up to 6 images.                                                                                                                                                                                                 | Optional      |
| referencedItem    | The canonical URL for referenced items in the product. The referenced item does not need to be on the same domain as the original article. For example, you might reference a page where a product feature is further described. You can add up to 6 og:referenced tags.        | Optional      |
| productExpiration | The date a product will expire (no longer be available). The date should be in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                     | Optional      |
| gender            | The gender to which the product is marketed. Possible values include `male` `female` and `unisex`.                                                                                                                                                                              | Optional      |
| color             | The color of the product.                                                                                                                                                                                                                                                       | Optional      |
| aggregateRating   | An overall rating for the product (e.g., 4.5). [See link for more information](http://schema.org/AggregateRating). You must include a ratingValue for the rating to appear. If you don't include bestRating and worstRating, then Schema.org will assume 5 and 1, respectively. | Optional      |

### Schema.org Offer Properties

| **Property**       | **Description**                                                                                                                                                                                                                                                                                                                                                                              | **Required?** |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| name               | The offer name. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                                                                                                                                                                                              | Optional      |
| description        | The offer description. This may be truncated, depending on length. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                                                                                                                | Optional      |
| sku                | An ID that uniquely identifies the offer within your site.                                                                                                                                                                                                                                                                                                                                   | Optional      |
| price              | The product price (without any currency sign, e.g., `6.50`).                                                                                                                                                                                                                                                                                                                                 | Required      |
| priceCurrency      | The [currency code](http://www.xe.com/iso4217.php/) (e.g., `USD`).                                                                                                                                                                                                                                                                                                                           | Required      |
| standardPrice      | If the product is on sale, this is the non-sale price (without a currency symbol, e.g., 10.00).                                                                                                                                                                                                                                                                                              | Optional      |
| availability       | The current availability of the product. Possible values include `http://schema.org/InStock` `http://schema.org/OnlineOnly` `http://schema.org/InStoreOnly` `http://schema.org/OutOfStock` `http://schema.org/PreOrder` and `http://schema.org/Discontinued` (discontinued items won't be a part of a daily scrape and marking them as discontinued will decrease the load on your servers). | Optional      |
| availabilityStarts | If the product is on sale, the start time of the sale in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                                                                                                                                                        | Optional      |
| availabilityEnds   | If the product is on sale, the end time of the sale in [ISO 8601 date format](http://wikipedia.org/wiki/ISO_8601/).                                                                                                                                                                                                                                                                          | Optional      |
| eligibleRegion     | The countries the product can be shipped to. Use [ISO 3166-1 alpha-2](http://wikipedia.org/wiki/ISO_3166-1_alpha-2/) country codes. If the product is available anywhere in the world, use `All`. You can list.                                                                                                                                                                              | Optional      |
