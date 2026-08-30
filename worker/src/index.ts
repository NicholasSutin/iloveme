import { Hono } from "hono";
import { homePage } from "./home";
import { privacyPage } from "./privacy";

/**
 * ILoveMe's public face: homepage and privacy policy.
 *
 * It once also relayed Strava's token exchange, which needed a client_secret an iOS
 * binary cannot hold. Strava was dropped — its Developer Program requires a paid
 * subscription on the owning account — and with it went the only route that needed
 * a secret. Every remaining integration is secret-free: GitHub uses the device
 * flow, Notion and Pinterest use pasted tokens.
 *
 * So this Worker now holds no secrets at all. If a provider ever needs one again,
 * `git log` has the relay: routes, timing-safe bearer gate, and sanitised errors.
 */
const app = new Hono<{ Bindings: Env }>();

app.get("/health", (c) => c.json({ ok: true, environment: c.env.ENVIRONMENT }));

// Public pages. Cached at the edge for an hour — they are fully static, so the
// only cost of a change is waiting out the TTL.
const PAGE_HEADERS = { "cache-control": "public, max-age=3600" } as const;

app.get("/", (c) => c.html(homePage(), 200, PAGE_HEADERS));
app.get("/privacy", (c) => c.html(privacyPage(c.env.CONTACT_EMAIL), 200, PAGE_HEADERS));

app.notFound((c) => c.json({ error: "not_found" }, 404));

// Explicit handler rather than ctx.passThroughOnException(), which would hide
// failures instead of reporting them.
app.onError((err, c) => {
  console.error(JSON.stringify({ event: "unhandled_error", message: err.message }));
  return c.json({ error: "internal_error" }, 500);
});

export default app;
