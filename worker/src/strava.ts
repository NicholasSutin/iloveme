import { Hono } from "hono";
import { requireAppToken } from "./auth";

/**
 * Strava token exchange and refresh.
 *
 * Strava requires `client_secret` on both the initial code exchange and every
 * refresh, and offers no PKCE public-client or device flow — which is the entire
 * reason this Worker exists. See docs/api-notes.md §1.2.
 *
 * PROXY, NOT VENDING: the secret is added here and never travels to the app.
 */
const TOKEN_ENDPOINT = "https://www.strava.com/oauth/token";

/** Access tokens last ~6 hours, so the app must call /refresh, not re-authorise. */
async function requestToken(
  env: Env,
  params: Record<string, string>,
): Promise<{ status: number; body: unknown }> {
  const upstream = await fetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      accept: "application/json",
    },
    body: new URLSearchParams({
      client_id: env.STRAVA_CLIENT_ID,
      client_secret: env.STRAVA_CLIENT_SECRET,
      ...params,
    }),
  });

  // Token responses are small and bounded, so reading in full is safe here.
  const text = await upstream.text();
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    console.error(JSON.stringify({ event: "strava.unparsable", status: upstream.status }));
    return { status: 502, body: { error: "upstream_unparsable" } };
  }

  if (!upstream.ok) {
    // Surface Strava's status and its own error field, nothing more — the raw
    // body is not echoed, so a secret can never round-trip through an error.
    const message =
      typeof parsed === "object" && parsed !== null && "message" in parsed
        ? String((parsed as { message: unknown }).message)
        : "token_request_failed";
    console.error(JSON.stringify({ event: "strava.rejected", status: upstream.status, message }));
    return { status: upstream.status, body: { error: message } };
  }

  return { status: 200, body: parsed };
}

export const strava = new Hono<{ Bindings: Env }>();

strava.use("/exchange", requireAppToken);
strava.use("/refresh", requireAppToken);

strava.post("/exchange", async (c) => {
  const body = await c.req.json<{ code?: string }>().catch(() => null);
  const code = body?.code;
  if (!code) return c.json({ error: "missing_code" }, 400);

  const result = await requestToken(c.env, { code, grant_type: "authorization_code" });
  return c.json(result.body as Record<string, unknown>, result.status as 200);
});

strava.post("/refresh", async (c) => {
  const body = await c.req.json<{ refresh_token?: string }>().catch(() => null);
  const refreshToken = body?.refresh_token;
  if (!refreshToken) return c.json({ error: "missing_refresh_token" }, 400);

  const result = await requestToken(c.env, {
    refresh_token: refreshToken,
    grant_type: "refresh_token",
  });
  return c.json(result.body as Record<string, unknown>, result.status as 200);
});
