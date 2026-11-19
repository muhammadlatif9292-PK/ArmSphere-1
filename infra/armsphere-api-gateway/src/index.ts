/**
 * armsphere-api-gateway — Cloudflare Workers edge gateway
 *
 * Routes requests to:
 *   1. env.UPSTREAM_URL (Cloud container, e.g. Render / Koyeb / Cloud Run)
 *   2. env.ARMSPHERE_API_PRIVATE (VPC Service binding / local tunnel fallback)
 *
 * Edge Caching Rules (GET only):
 *   - /organizations: 300s (5 minutes)
 *   - /rankings/leaderboard: 120s (2 minutes)
 *   - /tournaments/events: 60s (1 minute)
 */

export interface Env {
  /** Optional Workers VPC Service binding (for local tunnel fallback) */
  ARMSPHERE_API_PRIVATE?: Fetcher;
  /** Direct cloud upstream URL (e.g. https://armsphere-api.onrender.com) */
  UPSTREAM_URL?: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const normalizedPath = url.pathname.replace(/^\/api\/v1/, "");

    // Edge Caching: Check cache for public read-only GET requests on targeted paths
    const isCacheableGet =
      request.method === "GET" &&
      !request.headers.has("Authorization") && // Only cache public unauthenticated queries
      (normalizedPath === "/organizations" ||
       normalizedPath.startsWith("/rankings/leaderboard") ||
       normalizedPath === "/tournaments/events");

    let cacheKey: Request | null = null;
    const cache = caches.default;

    if (isCacheableGet) {
      cacheKey = new Request(url.toString(), request);
      const cached = await cache.match(cacheKey);
      if (cached) {
        const cachedRes = new Response(cached.body, cached);
        cachedRes.headers.set("X-ArmSphere-Edge-Cache", "HIT");
        return cachedRes;
      }
    }

    // Forward to Cloud Upstream or VPC Tunnel
    let upstreamRes: Response;
    if (env.UPSTREAM_URL) {
      const base = env.UPSTREAM_URL.replace(/\/$/, "");
      const targetUrl = base + url.pathname + url.search;
      upstreamRes = await fetch(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body,
        // @ts-ignore
        duplex: "half",
      });
    } else if (env.ARMSPHERE_API_PRIVATE) {
      const targetUrl = "http://127.0.0.1:4000" + url.pathname + url.search;
      const proxyReq = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body,
        // @ts-ignore
        duplex: "half",
      });
      upstreamRes = await env.ARMSPHERE_API_PRIVATE.fetch(proxyReq);
    } else {
      return new Response(JSON.stringify({ error: "No upstream configured" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    // If cacheable and returned 200 OK, store in Cloudflare Edge Cache
    if (isCacheableGet && cacheKey && upstreamRes.status === 200) {
      let ttl = 60;
      if (normalizedPath === "/organizations") {
        ttl = 300; // 5 minutes
      } else if (normalizedPath.startsWith("/rankings/leaderboard")) {
        ttl = 120; // 2 minutes
      } else if (normalizedPath === "/tournaments/events") {
        ttl = 60; // 1 minute
      }

      const resToCache = new Response(upstreamRes.clone().body, upstreamRes);
      resToCache.headers.set("Cache-Control", `public, max-age=${ttl}, s-maxage=${ttl}`);
      resToCache.headers.set("X-ArmSphere-Edge-Cache", "MISS");
      ctx.waitUntil(cache.put(cacheKey, resToCache.clone()));
      return resToCache;
    }

    const res = new Response(upstreamRes.body, upstreamRes);
    res.headers.set("X-ArmSphere-Edge-Cache", "BYPASS");
    return res;
  },
} satisfies ExportedHandler<Env>;
