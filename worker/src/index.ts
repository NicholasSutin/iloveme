import { Hono } from "hono";
import { homePage } from "./home";
import { privacyPage } from "./privacy";
import { strava } from "./strava";

/**
 * ILoveMe's public face and its Strava token relay.
 *
 * Two jobs, deliberately in one Worker because they share a hostname:
 *
 * 1. The public site — homepage and privacy policy. The policy is what Pinterest's
 *    app review requires; neither page needs a secret, so this can ship long
 *    before any OAuth work is finished.
 * 2. Strava token exchange and refresh. Strava requires a client_secret, and a
 *    secret in an iOS binary is extractable. GitHub uses the device flow, and
 *    Notion and Pinterest use pasted tokens, so neither needs a route here.
 */
const app = new Hono<{ Bindings: Env }>();

app.get("/health", (c) => c.json({ ok: true, environment: c.env.ENVIRONMENT }));

// Public pages. Cached at the edge for an hour — they are fully static, so the
// only cost of a change is waiting out the TTL.
const PAGE_HEADERS = { "cache-control": "public, max-age=3600" } as const;

app.get("/", (c) => c.html(homePage(), 200, PAGE_HEADERS));
app.get("/privacy", (c) => c.html(privacyPage(c.env.CONTACT_EMAIL), 200, PAGE_HEADERS));

app.route("/strava", strava);

app.notFound((c) => c.json({ error: "not_found" }, 404));

// Explicit handler rather than ctx.passThroughOnException(), which would hide
// failures instead of reporting them.
app.onError((err, c) => {
  console.error(JSON.stringify({ event: "unhandled_error", message: err.message }));
  return c.json({ error: "internal_error" }, 500);
});

export default app;
