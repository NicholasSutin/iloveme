# Recipe Pins

Recipe Pins make it easy for Pinners to see exactly what a recipe entails without leaving Pinterest. Recipe Pins can include **title** **ingredients** **cooking times** **serving information** and **ratings**. We support `Schema.org` and `h-recipe` formats for marking up your pages.

## Schema.org

`Schema.org` tags are supported by Google and other search engines. If you use this format, you'll mark up your article in the `<body>` of the page using [https://schema.org/Recipe](https://schema.org/Recipe).
If you use the `Schema.org` format, we suggest that you still include your site name using the `og:site_name` Open Graph tag. `Schema.org` doesn't support a site name property.

> **Note:**
> Ratings are only supported via Schema.org and will only appear on iOS and Android devices at this time.

### Schema Recipe properties

```html
<meta property="og:site_name" content="letthebakingbeginblog.com" />
<div itemscope itemtype="http://schema.org/Recipe">
  <h1 itemprop="name">15 Minute Easy Margherita Flatbread Pizza</h1>
  <meta itemprop="url" content="http://myrecipesite.com/pineapple.html" />
  <span itemprop="totalTime">15 mins</span>
  <span itemprop="recipeYield">Serves 2</span>
  Ingredients:
  <span itemprop="ingredients">1 Naan bread</span>,
  <span itemprop="ingredients">3 pieces fresh mozzarella</span>,
  <span itemprop="ingredients">1 1/2 tbsp olive oil</span>,
  <span itemprop="ingredients">1 1/2 tbsp balsamic vinegar</span>,
  <span itemprop="ingredients">5 basil leaves</span>
  <span itemprop="ingredients">3 cloves garlic</span>
  <span itemprop="ingredients">1 tomato</span>
  <div itemprop="aggregateRating" itemscope itemtype="http://schema.org/AggregateRating">
    Rated <span itemprop="ratingValue">3.5</span>/5 based on
    <span itemprop="reviewCount">11</span> customer reviews
  </div>
</div>
```

### Supported Schema Recipe properties

#### Schema properties

| **Property**        | **Description**                                                                                                                                                                                                                 | **Required?** |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| **name**            | The name of the recipe. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                                                                                                         | **Required**  |
| **ingredients**     | The ingredients used in the recipe. Annotate each individual ingredient separately.                                                                                                                                             | **Required**  |
| **url**             | The canonical URL for the page. For example, `http://allrecipes.com/recipe/simple-white-cake/` (You can also specify canonical with standard HTML markup: `<link rel="canonical" href="..." />         `)                       | **Optional**  |
| **image**           | The URL for a high-resolution image of the recipe. You can add up to 6 images.                                                                                                                                                  | **Optional**  |
| **totalTime**       | The total time it takes to cook and prepare the recipe in ISO 8601 duration format (see https://wikipedia.org/wiki/ISO_8601).                                                                                                   | **Optional**  |
| **recipeYield**     | The quantity or servings made by this recipe (e.g., `5 servings` `Serves 4-6` or `Yields 10         burgers`).                                                                                                                  | **Optional**  |
| **aggregateRating** | The overall rating, based on a collection of reviews or ratings, of the item.                                                                                                                                                   | **Optional**  |
| **cookTime**        | The time it takes to cook the recipe, given in ISO 8601 duration format; Opens a new tab.                                                                                                                                       | **Optional**  |
| **prepTime**        | The time it takes to prep the recipe, given in ISO 8601 duration format; Opens a new tab. (Prep time is hands-on time, as opposed to cook time which may include periods when the cook's attention can be on other activities.) | **Optional**  |
| **relatedItem**     | A URL pointing to other related recipes from the same domain. You can add up to 6 related recipes.                                                                                                                              | **Optional**  |
| **description**     | The recipe description.                                                                                                                                                                                                         | **Optional**  |

## h-recipe

You can use the [`h-recipe`](https://microformats.org/wiki/h-recipe) open format for marking up your recipes on your site. With this format, you mark up your recipe in the body of the page. If you use `h-recipe`, we suggest that you still include your site name using the `og:site_name` Open Graph tag. Schema.org doesn't support a site name property.

### h-recipe properties

```html
<meta property="og:site_name" content="letthebakingbeginblog.com" />
<article class="h-recipe">
  <h1 class="p-name">15 Minute Easy Margherita Flatbread Pizza</h1>
  <img class="u-photo" src="<photo-source" />

  <h3>Ingredients</h3>
  <ul>
    <li class="p-ingredient">1 Naan bread</li>
    <li class="p-ingredient">3 pieces fresh mozzarella</li>
    <li class="p-ingredient">1 1/2 tbsp olive oil</li>
    <li class="p-ingredient">1 1/2 tbsp balsamic vinegar</li>
    <li class="p-ingredient">5 basil leaves</li>
    <li class="p-ingredient">3 cloves garlic</li>
    <li class="p-ingredient">1 tomato</li>
  </ul>
  <p>
    Takes <time class="dt-duration" datetime="1H">15 min</time>, serves
    <data class="p-yield" value="4">2</data>.
  </p>

  <h3>Instructions</h3>
  <ol class="e-instructions">
    <li>Press fresh garic and mix with oil.</li>
    <li>Brush the flatbread with half the oil mixture. Place in preheated oven for 5 minutes.</li>
    <li>
      Arange sliced mozzarella and tomato on flatbread. Place back in oven until cheese is melted
      and bubbly.
    </li>
    <li>Sprinkle with chopped basil.</li>
  </ol>
</article>
```

### Supported h-recipe classes

#### h-classes

| **Class**          | **Description**                                                                                                                        | **Required?** |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| **p-name**         | The name of the recipe. This title may be truncated, depending on length. All formatting and HTML tags will be removed.                | **Required**  |
| **p-ingredient**   | The ingredients used in the recipe. Annotate each individual ingredient separately.                                                    | **Required**  |
| **p-yield**        | The quantity or servings made by this recipe (e.g., `5 servings` `Serves 4-6` or `Yields 10         burgers`).                         | **Optional**  |
| **e-instructions** | The recipe instructions.                                                                                                               | **Optional**  |
| **dt-duration**    | The time it takes to cook the recipe, [expressed using microsyntax](https://developers.whatwg.org/common-microsyntaxes.html#durations) | **Optional**  |
| **u-photo**        | The URL for a high-resolution image of the recipe. Up to 6 images can be added.                                                        | **Optional**  |
| **p-summary**      | The recipe description.                                                                                                                | **Optional**  |
| **p-author**       | The person who wrote the recipe, [optionally embedded with h-card](http://microformats.org/wiki/h-card)                                | **Optional**  |
| **dt-published**   | The date the recipe was published in [microsyntax](https://developers.whatwg.org/common-microsyntaxes.html#durations)                  | **Optional**  |
| **p-nutrition**    | The nutritional information of the recipe (e.g., calories, fat, protein, carbohydrates, or dietary fiber).                             | **Optional**  |
