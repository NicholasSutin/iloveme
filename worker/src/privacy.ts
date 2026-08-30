import { shell } from "./layout";

/**
 * Public privacy policy.
 *
 * Pinterest's app review requires a reachable privacy-policy URL, and it is
 * served from the app's own hostname rather than separate static hosting because
 * this Worker already owns it.
 *
 * Written against what the app actually does. Since Strava was dropped there is no
 * server-side relay at all, so no app data of any kind passes through our
 * infrastructure — which the policy now says plainly rather than carrying a
 * now-false exception.
 */
const EFFECTIVE_DATE = "29 August 2026";

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
    <li><strong>Health data.</strong> Daily activity summaries read from Apple
      HealthKit, only after you grant permission in the system prompt, and only for
      the categories you approve: steps, walking and running distance, flights
      climbed, active energy, exercise minutes, resting heart rate, time asleep, and
      a count of workouts.</li>
    <li><strong>Connected services.</strong> If you connect one, the app reads a narrow,
      read-only slice: GitHub contribution counts, Notion page titles and edit dates,
      Pinterest board and pin names.</li>
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
  <p>Requests go directly from your device to the service you connected — GitHub,
  Notion or Pinterest — carrying your access token so they can identify you. Nothing
  is proxied, and no server of ours sits in between.</p>
  <p><strong>We operate no server that receives your data.</strong>
  <code>iloveme.nicholassutin.com</code> serves this page and the app's homepage, and
  nothing else. Earlier versions relayed a Strava sign-in through it; Strava has been
  removed from the app and that relay no longer exists.</p>

  <h2>What we do not do</h2>
  <ul>
    <li>No analytics, telemetry, crash reporting or tracking of any kind.</li>
    <li>No advertising, and no advertising identifiers.</li>
    <li>We do not sell, rent or share your data with anyone.</li>
    <li>No profiling and no automated decision-making.</li>
  </ul>

  <h2>Third parties</h2>
  <p>Connecting a service means that service also handles your data under its own policy:
  <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement">GitHub</a>,
  <a href="https://www.notion.com/privacy">Notion</a>,
  <a href="https://policy.pinterest.com/privacy-policy">Pinterest</a>.
  Cloudflare hosts this website; because the app sends it no data, Cloudflare
  processes none of yours on our behalf.</p>

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
