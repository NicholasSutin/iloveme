import { shell } from "./layout";

/**
 * Public homepage.
 *
 * Deliberately honest: no App Store badge, no screenshots that do not exist, no
 * invented testimonials. The card preview below is hand-built from the same
 * visual rules the iOS app uses, so it represents the real UI rather than a
 * mockup of a different product.
 */
const CSS = `
.hero{padding:2rem 0 .5rem}
.tagline{font-size:1.15rem;color:var(--muted);margin:0 0 1.5rem;max-width:34rem}
.pill{display:inline-block;font-size:.78rem;letter-spacing:.02em;color:var(--accent);
  background:var(--accent-soft);border-radius:999px;padding:.3rem .7rem;margin-bottom:1.25rem}

/* Preview built from the app's own card rules */
.preview{margin:2rem 0 .5rem;display:grid;gap:.75rem}
.card{background:var(--card);border-radius:var(--radius);padding:1rem;
  border:1px solid var(--rule)}
.card-head{display:flex;align-items:center;gap:.5rem;margin-bottom:.6rem}
.card-title{font-weight:620;font-size:.95rem}
.chip{margin-left:auto;display:inline-flex;align-items:center;gap:.4rem;
  font-size:.75rem;color:var(--muted)}
.dot{width:7px;height:7px;border-radius:50%;background:var(--accent)}
.dot.grey{background:var(--muted);opacity:.5}
.row{display:flex;align-items:baseline;justify-content:space-between;
  font-size:.88rem;padding:.18rem 0}
.row span:last-child{color:var(--muted);font-variant-numeric:tabular-nums}
.glyph{display:flex;color:var(--muted);flex:none}
.glyph svg{display:block}

.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(13rem,1fr));gap:.75rem;
  margin:1rem 0 0;padding:0;list-style:none}
.grid li{background:var(--card);border:1px solid var(--rule);border-radius:12px;
  padding:.85rem .95rem;margin:0}
.grid strong{display:block;font-size:.9rem;margin-bottom:.15rem}
.grid span{color:var(--muted);font-size:.83rem}
.note{color:var(--muted);font-size:.9rem}
`;

/** Minimal stroke icons standing in for the app's SF Symbols. Inline, so there is
 *  nothing external to fetch and they inherit colour from the surrounding text. */
const ICONS: Record<string, string> = {
  steps: '<path d="M2 12h3l2-6 3 12 2-6h4"/>',
  github: '<path d="M8 5l-4 5 4 5"/><path d="M12 5l4 5-4 5"/>',
  notion: '<rect x="4" y="3" width="12" height="14" rx="2"/><path d="M7.5 7.5h5M7.5 10.5h5M7.5 13.5h3"/>',
};

function icon(name: keyof typeof ICONS): string {
  return `<span class="glyph"><svg viewBox="0 0 20 20" width="16" height="16" fill="none" ` +
    `stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" ` +
    `aria-hidden="true">${ICONS[name]}</svg></span>`;
}

const BODY = `
<main class="wrap">
  <section class="hero">
    <span class="pill">iPhone &middot; Lock Screen &amp; Home Screen widgets</span>
    <h1>Your day, in one quiet place.</h1>
    <p class="tagline">A personal health and wellness dashboard. Your day's walking
    and workouts from Apple Health, next to the things you already track somewhere
    else — with nothing shouting at you.</p>
  </section>

  <section class="preview" aria-label="Preview of the app's cards">
    <div class="card">
      <div class="card-head">${icon("steps")}
        <span class="card-title">Health</span>
        <span class="chip"><span class="dot"></span>Updated 09:12</span></div>
      <div class="row"><span>Steps</span><span>8,412</span></div>
      <div class="row"><span>Distance</span><span>6.14 km</span></div>
      <div class="row"><span>Flights climbed</span><span>12</span></div>
      <div class="row"><span>Walking speed</span><span>4.8 km/h</span></div>
      <div class="row"><span>Workouts this week</span><span>3</span></div>
    </div>
    <div class="card">
      <div class="card-head">${icon("github")}
        <span class="card-title">GitHub</span>
        <span class="chip"><span class="dot"></span>Updated 09:12</span></div>
      <div class="row"><span>Last 7 days</span><span>41</span></div>
      <div class="row"><span>Last 30 days</span><span>168</span></div>
    </div>
    <div class="card">
      <div class="card-head">${icon("notion")}
        <span class="card-title">Notion</span>
        <span class="chip"><span class="dot grey"></span>Not connected</span></div>
      <div class="row"><span>No pages shared yet</span><span>&mdash;</span></div>
    </div>
  </section>
  <p class="note">Every card is plain text. No charts you have to decode, no streaks to break.</p>

  <h2>What it pulls together</h2>
  <ul class="grid">
    <li><strong>Apple Health</strong><span>Steps, distance, flights climbed, walking
      speed and step length, plus your workout count — all from the phone's own
      sensors, no watch required.</span></li>
    <li><strong>GitHub</strong><span>Contributions over the last 7 and 30 days.</span></li>
    <li><strong>Notion</strong><span>Your most recently edited pages.</span></li>
    <li><strong>Pinterest</strong><span>Boards and the pins inside them.</span></li>
  </ul>

  <h2>Private by construction, not by promise</h2>
  <ul>
    <li>Health data never leaves your device — not to us, not to anyone.</li>
    <li>Access tokens are stored in the iOS Keychain, on your phone.</li>
    <li>Every connection is read-only. The app cannot post, edit or delete anything.</li>
    <li>No accounts, no analytics, no tracking, no advertising.</li>
    <li>There is no user database. We run no server that stores your information.</li>
  </ul>
  <p class="note">There is no exception and no asterisk. The app talks to each service
  directly from your phone, and no server of ours sits in between — the
  <a href="/privacy">privacy policy</a> says so in full.</p>

  <h2>Where it is up to</h2>
  <p>ILoveMe is an independent project, actively being built, and is not on the App Store.
  This page exists so the app has a home and a privacy policy while its integrations are
  being wired up.</p>
</main>
`;

export function homePage(): string {
  return shell({
    title: "ILoveMe — a quiet personal health dashboard",
    description:
      "A personal health and wellness dashboard for iPhone. Walking activity and " +
      "workouts from Apple Health alongside GitHub, Notion and Pinterest. " +
      "Private by construction.",
    body: BODY,
    css: CSS,
  });
}
