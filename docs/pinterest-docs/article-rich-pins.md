# Article Pins

Article Pins let users know that they're clicking on a page with original content that tells a story.

> **Note:**
> Article Pins include a headline, author, and story description.

- We support Open Graph and Schema.org formats for marking up your pages.

## Open Graph

If you use Open Graph format, you can copy and paste this example text into your page's `<head>` tag. Just change the content for each `meta property` to match your page.

### Example: Open Graph properties

```html
<head>
  <meta property="og:type" content="article" />
  <meta property="og:title" content="Exploring Kyoto's Sagano Bamboo Forest - CNN.com" />
  <meta property="og:description" content="A constant inclusion on lists of "forests to see before you die," here's how to see the real thing." />
  <meta property="og:url" content="http://www.cnn.com/2014/08/11/travel/sagano-bamboo-forest/" />
  <meta property="og:site_name" content="CNN.com" />
  <meta property="article:published_time" content="2014-08-12T00:01:56+00:00" />
  <meta property="article:author" content="CNN Karla Cripps" />
</head>
```

Supported Open Graph properties

### Supported properties

| **Property**          | **Description**                                                                                                                                                                                                                                               | **Required?**                             |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| og:type               | Must take the value of `article` or `blog`                                                                                                                                                                                                                    | Required                                  |
| og:title              | The article title. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                                                            | Required                                  |
| og:description        | The article description or summary. This may be truncated, depending on length. All formatting, line breaks and HTML tags will be removed.                                                                                                                    | Required                                  |
| og:site_name          | The site name (e.g., `the Guardian`). Using this field is strongly suggested.                                                                                                                                                                                 | Optional                                  |
| og:url                | The canonical URL for the page. For example, `http://www.theguardian.com/travel/2013/sep/17/top-10-national-parks-california` (You can also specify canonical with standard HTML markup: `&lt;link rel="canonical"         href="..."/&gt;`)                  | Optional                                  |
| og:image              | The URL for a high-resolution image related to the article. You can add up to six (6) og:image tags.                                                                                                                                                          | Optional                                  |
| og:see_also           | A URL pointing to other related articles from the same domain. You can add up to six (6) og:see_also tags.                                                                                                                                                    | Optional                                  |
| og:referenced         | The canonical URL for a referenced item in the article. The referenced page doesn't need to be on the same domain as the original article. For example, you might reference a page where a product can be purchased or a page that further describes a place. | Optional                                  |
| article:modified_time | The date the article was last modified. The time should be in ISO 8601 date format; Opens a new tab.                                                                                                                                                          | Optional                                  |
| article:section       | The article section name. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                          | Optional                                  |
| article:tag           | The article tags or keywords. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                      | Optional                                  |
| og:rating             | An aggregated rating for something mentioned in the article (e.g., 4.5).                                                                                                                                                                                      | Optional                                  |
| og:rating_scale       | The maximum value (integer) of the ratings scale (e.g., 5). Required if og:rating is provided.                                                                                                                                                                | Optional. Required if og:rating is given. |
| og:rating_count       | The total number of ratings (integer) (e.g., 113).                                                                                                                                                                                                            | Optional                                  |

## Schema.org

Schema.org tags are supported by Google and other search engines. If you use this format, mark up your article in the `body` of the page using `[schema.org/Article](http://schema.org/Article)`.

> **Note:**
> If you use the Schema.org format, include your site name using the `og:site_name` Open Graph tag. Schema.org doesn't support a site name property.

### Example: Schema properties

```html
<meta property="og:site_name" content="Example Site" />
<div itemscope itemtype="http://schema.org/Article">
<meta itemprop="url" content="http://www.cnn.com/2014/08/11/travel/sagano-bamboo-forest/" />
<span itemprop="name" content="Exploring Kyoto's Sagano Bamboo Forest - CNN.com" />
by <span itemprop="author" content="CNN Karla Cripps" />
<img itemprop="image" src="http://www.example.com/2013/article_image.png" alt="
Kyoto Forest" />
<span itemprop="description">A constant inclusion on lists of forests to see before you die, here's how to see the real thing.</span>
<div itemprop="relatedItem" itemscope itemtype="http://schema.org/Article">
<a itemprop="url" href="http://www.example.com/2013/09/older_article.html">
</div>
<div itemprop="realatedItem" itemscope itemtype="http://schema.org/Article">
<a itemprop="url" href="http://www.example.com/2013/08/different_article.html">
</div>
<span itemprop="datePublished" content="2014-08-12T00:01:56+00:00"></span>
</div>
```

### Supported Schema properties

#### Article Pin schema properties

| **Property**    | **Description**                                                                                                                                                                                                                                                | **Required?** |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| url             | Canonical URL for the page, for example `http://www.example.com/2013/10/article.html`. (You can also specify canonical with standard HTML markup: `<link rel="canonical" href="..." />         `.)                                                             | Required      |
| name            | The article title. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                                                             | Required      |
| description     | The article description or summary. This may be truncated, depending on length. All formatting, line breaks and HTML tags will be removed.                                                                                                                     | Required      |
| datePublished   | The date the article was first published. The time should be in ISO 8601 date format (see http://wikipedia.org/wiki/ISO_8601).                                                                                                                                 | Optional      |
| image           | The URL for a high-resolution image related to the article. You can add up to 6 images.                                                                                                                                                                        | Optional      |
| author          | The article author. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                                 | Optional      |
| articleSection  | The article section name. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                           | Optional      |
| keywords        | The article tags or keywords. All formatting, line breaks and HTML tags will be removed.                                                                                                                                                                       | Optional      |
| wordCount       | The number of words in the text of the article (as an integer).                                                                                                                                                                                                | Optional      |
| aggregateRating | An aggregated rating for something mentioned in the article. For more information, see Schema.org’s aggregateRating article at http://schema.org/AggregateRating.                                                                                              | Optional      |
| relatedItem     | A URL pointing to other related articles from the same domain.                                                                                                                                                                                                 | Optional      |
| referencedItem  | The canonical URL for a referenced item in the article. The referenced page does not need to be on the same domain as the original article. For example, you might reference a page where a product can be purchased or a page that further describes a place. | Optional      |
