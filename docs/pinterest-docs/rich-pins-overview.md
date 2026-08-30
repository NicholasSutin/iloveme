# About Rich Pins

Rich Pins show metadata right on the Pin itself, giving Pinners a richer experience and increasing engagement. Information in a Rich Pin is independent of the Pin description, ensuring that important information is always tied to the Pin.

## Types of Rich Pins

There are three types of Rich Pins:

- Article
- Product
- Recipe

> **Note:**
> Rich Pins work by displaying metadata from marked-up pages on your website.

## Applying for Rich Pins

Once you've applied for Rich Pins, any content on your site with metadata will turn into a Rich Pin when a user saves it.

## Setup

Setting up Rich Pins requires you to add rich metadata tags to the content on your site.

### Add metadata to your content

To see what kind of metadata is available for each type of Rich Pin, check out our topics on [article](https://developers.pinterest.com/docs/web-features/article-rich-pins/) [product](https://developers.pinterest.com/docs/web-features/product-rich-pins/) and [recipe](https://developers.pinterest.com/docs/web-features/recipe-rich-pins/) Pins.

Generally, the most common formats are Open Graph and Schema.org. If you add metadata for multiple types of Rich Pins to your page, the type of Pin that appears will be based on priority. The priority of Rich Pin data is:

1. Product Pins
2. Recipe Pins
3. Article Pins

### Opt out

If you don't want content from your site to show up as Rich Pins, simply include the following tag in the `head` section of your pages:

```html
<meta name="pinterest-rich-pin" content="false" />
```

> **Note:**
> This tag only applies to Rich Pins. It isn't the same thing as the no-pin image attribute, which stops people from saving the specified image from your site to Pinterest.
