import { Hono } from "hono";
import { strava } from "./strava";

/**
 * ILoveMe token-exchange proxy.
 *
 * Exists for one reason: Strava requires a client_secret at token exchange and
 * refresh, and a secret in an iOS binary is extractable. GitHub uses the device
 * flow, and Notion and Pinterest use pasted tokens, so neither needs a route
 * here — add one only if that changes.
 */
const app = new Hono<{ Bindings: Env }>();

app.get("/health", (c) => c.json({ ok: true, environment: c.env.ENVIRONMENT }));

app.route("/strava", strava);

app.notFound((c) => c.json({ error: "not_found" }, 404));

// Explicit handler rather than ctx.passThroughOnException(), which would hide
// failures instead of reporting them.
app.onError((err, c) => {
  console.error(JSON.stringify({ event: "unhandled_error", message: err.message }));
  return c.json({ error: "internal_error" }, 500);
});

export default app;
