import { shell } from "./layout";

/**
 * Public privacy policy.
 *
 * Pinterest's app review requires a reachable privacy-policy URL, and it is
 * served from the app's own hostname rather than separate static hosting because
 * this Worker already owns it.
 *
 * Written against what the app actually does, including the awkward parts: the
 * Strava relay does transit codes and tokens, and it does log request metadata.
 * Both are stated rather than glossed as "we never see your data".
 */
const EFFECTIVE_DATE = "28 August 2026";

const CSS = `
.policy{padding:1.5rem 0 0}
.meta{color:var(--muted);font-size:.9rem;margin:0 0 2rem;padding-bottom:1.25rem;
  border-bottom:1px solid var(--rule)}
.policy h2:first-of-type{margin-top:1.5rem}
`;

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function privacyPage(contactEmail: string): string {
  const email = escapeHtml(contactEmail);
  return shell({
    title: "Privacy Policy — ILoveMe",
    description: "How the ILoveMe iPhone app handles your health and connected-service data.",
    css: CSS,
    body: `
<main class="wrap policy">
  <h1>Privacy Policy</h1>
  <p class="meta">ILoveMe for iOS &middot; Effective ${EFFECTIVE_DATE}</p>

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
  <p>Questions about this policy: <a href="mailto:${email}">${email}</a></p>
</main>`,
  });
}
