import { Hono } from "hono";

/**
 * Static privacy policy, served from the app's own hostname.
 *
 * Pinterest (and any future app review) requires a reachable privacy policy URL.
 * It lives here rather than on separate hosting because this Worker already owns
 * iloveme.nicholassutin.com — no extra project, no extra deploy target.
 *
 * Self-contained: no external CSS, fonts or scripts.
 */
const EFFECTIVE_DATE = "28 August 2026";

function page(contactEmail: string): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — ILoveMe</title>
<style>
  :root { color-scheme: light dark; --fg:#16181d; --muted:#5b6270; --bg:#fff; --rule:#e4e6eb; }
  @media (prefers-color-scheme: dark) {
    :root { --fg:#e8eaed; --muted:#a0a6b3; --bg:#14161a; --rule:#2b2f37; }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 2.5rem 1.25rem 5rem; background: var(--bg); color: var(--fg);
    font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  main { max-width: 42rem; margin: 0 auto; }
  h1 { font-size: 1.75rem; margin: 0 0 .35rem; letter-spacing: -.02em; }
  h2 { font-size: 1.05rem; margin: 2.25rem 0 .6rem; letter-spacing: -.01em; }
  .meta { color: var(--muted); font-size: .9rem; margin: 0 0 2rem; padding-bottom: 1.25rem;
          border-bottom: 1px solid var(--rule); }
  ul { padding-left: 1.15rem; }
  li { margin: .3rem 0; }
  a { color: inherit; text-underline-offset: 2px; }
  code { font-size: .9em; background: color-mix(in srgb, var(--fg) 8%, transparent);
         padding: .1em .35em; border-radius: 4px; }
  footer { margin-top: 3rem; padding-top: 1.25rem; border-top: 1px solid var(--rule);
           color: var(--muted); font-size: .875rem; }
</style>
</head>
<body>
<main>
  <h1>Privacy Policy</h1>
  <p class="meta">ILoveMe for iOS · Effective ${EFFECTIVE_DATE}</p>

  <p>ILoveMe is a personal dashboard app. It shows your step count alongside data from
  services you choose to connect. It has no accounts, no analytics, and no advertising.</p>

  <h2>What the app accesses</h2>
  <ul>
    <li><strong>Health data.</strong> Step count for the current day, read from Apple
      HealthKit, only after you grant permission in the system prompt.</li>
    <li><strong>Connected services.</strong> If you connect one, the app reads a narrow,
      read-only slice: Strava activity counts and distance, GitHub contribution counts,
      Notion page titles and edit dates, Pinterest board and pin names.</li>
    <li><strong>Access tokens</strong> for the services you connect.</li>
  </ul>
  <p>The app requests read-only scopes. It never writes to, posts to, or modifies any
  connected account.</p>

  <h2>Where it is stored</h2>
  <ul>
    <li><strong>On your device only.</strong> Tokens are stored in the iOS Keychain. Your
      step count is stored in a private app group container so the widget can display it
      while the device is locked.</li>
    <li>Health data is never transmitted off your device — not to us, not to anyone.</li>
    <li>Data fetched from connected services is held in memory to draw the screen and is
      not written to disk.</li>
    <li>There is no user database. We operate no server that stores your information.</li>
  </ul>

  <h2>What leaves your device</h2>
  <p>Requests go directly from your device to the service you connected — Strava, GitHub,
  Notion or Pinterest — carrying your access token so they can identify you.</p>
  <p>One exception: <strong>Strava sign-in</strong>. Strava requires a client secret that
  cannot be safely stored inside an app, so the sign-in step is relayed through
  <code>iloveme.nicholassutin.com</code>, operated by us on Cloudflare. That relay adds the
  secret and passes the response straight back to your device. It does not store your
  authorization code, your tokens, or any of your Strava data. Its logs record request
  paths, status codes and error messages for debugging — never tokens or personal data.</p>

  <h2>What we do not do</h2>
  <ul>
    <li>No analytics, telemetry, crash reporting or tracking of any kind.</li>
    <li>No advertising, and no advertising identifiers.</li>
    <li>We do not sell, rent or share your data with anyone.</li>
    <li>No profiling and no automated decision-making.</li>
  </ul>

  <h2>Third parties</h2>
  <p>Connecting a service means that service also handles your data under its own policy:
  <a href="https://www.strava.com/legal/privacy">Strava</a>,
  <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement">GitHub</a>,
  <a href="https://www.notion.com/privacy">Notion</a>,
  <a href="https://policy.pinterest.com/privacy-policy">Pinterest</a>.
  Cloudflare processes requests to the Strava sign-in relay as our infrastructure provider.</p>

  <h2>Keeping and deleting data</h2>
  <ul>
    <li>Tokens are kept until you disconnect that service or delete the app.</li>
    <li>Disconnecting a service erases its token from the Keychain immediately.</li>
    <li>Deleting the app removes everything it stored, including the step snapshot.</li>
    <li>You can also revoke access from the service's own settings at any time.</li>
  </ul>

  <h2>Children</h2>
  <p>ILoveMe is not directed at children under 13, and we do not knowingly collect their
  information.</p>

  <h2>Changes</h2>
  <p>If this policy changes, the effective date above changes with it.</p>

  <h2>Contact</h2>
  <p>Questions about this policy: <a href="mailto:${contactEmail}">${contactEmail}</a></p>

  <footer>ILoveMe is an independent personal project. It is not affiliated with,
  endorsed by, or sponsored by Strava, GitHub, Notion, Pinterest or Apple.</footer>
</main>
</body>
</html>`;
}

export const privacy = new Hono<{ Bindings: Env }>();

privacy.get("/privacy", (c) =>
  c.html(page(c.env.CONTACT_EMAIL), 200, {
    "cache-control": "public, max-age=3600",
  }),
);
