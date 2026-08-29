import { createMiddleware } from "hono/factory";

/**
 * Constant-time secret comparison.
 *
 * Both sides are hashed to a fixed 32 bytes first, so the comparison can never
 * short-circuit on a length mismatch — length alone leaks through timing with a
 * plain `===`.
 */
async function secretsMatch(presented: string, expected: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const [a, b] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(presented)),
    crypto.subtle.digest("SHA-256", encoder.encode(expected)),
  ]);
  return crypto.subtle.timingSafeEqual(a, b);
}

/**
 * Requires `Authorization: Bearer <APP_SHARED_TOKEN>`.
 *
 * This is a SPEED BUMP, not access control. The token ships inside the iOS app
 * and is extractable from the binary; anyone who pulls it can spend the Strava
 * quota. It exists to stop drive-by traffic against a public URL.
 *
 * The control that actually holds on iOS is App Attest (DCAppAttestService) —
 * see LIBRARIES.md. Add per-IP rate limiting and a Strava-side spend cap
 * regardless of which is in place.
 */
export const requireAppToken = createMiddleware<{ Bindings: Env }>(async (c, next) => {
  const expected = c.env.APP_SHARED_TOKEN;
  if (!expected) {
    // Fail closed: an unset secret must never mean "allow everyone".
    console.error(JSON.stringify({ event: "auth.misconfigured", reason: "APP_SHARED_TOKEN unset" }));
    return c.json({ error: "server_misconfigured" }, 500);
  }

  const header = c.req.header("Authorization") ?? "";
  const presented = header.startsWith("Bearer ") ? header.slice("Bearer ".length) : "";

  if (presented === "" || !(await secretsMatch(presented, expected))) {
    // Never log the presented value.
    console.warn(JSON.stringify({ event: "auth.rejected", path: new URL(c.req.url).pathname }));
    return c.json({ error: "unauthorized" }, 401);
  }

  await next();
});
