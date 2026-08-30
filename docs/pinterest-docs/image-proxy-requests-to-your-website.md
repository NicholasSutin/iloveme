# Image proxy requests to your website

If you are a webmaster or server administrator, you may notice incoming HTTP requests originating from the Pinterest platform instead of directly from your site's visitors, who originated the requests. Pinterest uses an image proxy, a backend service that securely routes images from third-party websites through a controlled proxy before displaying them in user-generated content.

Learn here how to identify and handle image proxy requests to your site.

## Why we use an image proxy

By using an image proxy, we provide several benefits to you and your users:

- **Content Security Policy (CSP) compliance:** Modern security policies restrict embedding third-party images directly. The image proxy allows us to enforce stricter CSP rules and still enable image rendering.
- **Security and privacy:** Using an image proxy offers protection several ways:
  
  - It prevents leakage of user IP addresses to external image hosts.
  - It prevents hotlinking abuse by controlling access to third-party images.
  - It ensures all images pass through a secure validation process.
- **Performance:** Using a proxy centralizes image requests for faster image delivery.

## How it works

See how our image proxy interacts with your site and your users:

1. When creating a Pin, a Pinner includes an image from a third-party website (your site).
2. Instead of loading directly from the original source, our system modifies the image URL, replacing it with a proxy URL.
3. The image proxy fetches the image from your host and streams it to the user, so you see the request coming from Pinterest instead of the user.

## Identify requests from Pinterest image proxy

Use the following methods to identify image requests from our proxy:

### Check the User-Agent header

Requests from our image proxy include a custom User-Agent string to indicate that they originate from our platform, for example:

```text
Mozilla/5.0 (Pinterest Image Proxy/1.0; +https://www.pinterest.com/image-proxy.html)
```

> **Note:**
> We recommend allowing requests from this User-Agent to avoid blocking legitimate image requests.

### Note referrer header behavior

For further understanding about our image proxy requests, note the following:

- We do not pass direct user referrer information.
- The original user's referrer may not be visible, as requests come from our proxy.
- The request originates from our servers, not the end user's device.
- If you need to track how images are being used, you can monitor requests coming from our proxy's domain.

## Handle image proxy requests

You do not need to take action with image proxy requests unless you want to do the following:

- Allow requests from our proxy if your site visitors report that images are being blocked.
- Monitor request frequency if you are concerned about bandwidth usage.

### Block hotlinks

If your site implements hotlink protection, you may need to adjust rules with server-side access controls to allow our proxy service to retrieve images while still blocking unauthorized third-party use.

### Restrict access

You may want to restrict request access to your site to save bandwidth, control how your images are used, or have analytics reflect only direct visits to your site. We recommend rate limiting instead of outright blocking of access, which may break image rendering for Pinners and advertisers on our platform.

## Get help

If you have more questions about how our image proxy works, contact your Pinterest representative, or file a Support request:

1. Go to [Get more help](https://help.pinterest.com/contact) in Help Center.
2. Select **Creators and creative tools**.
3. Select **Create or edit Pins** and click **Continue**.
4. Enter or provide requested information in each form, clicking **Continue** to advance to the next form. Then click **Submit** on the last form.

## See also

If you have concerns about image use or any other related issues, see our [content request policies](https://help.pinterest.com/article/get-started-with-the-content-claiming-portal).
