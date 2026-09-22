/**
 * armsphere-api-gateway — Cloudflare Workers thin proxy
 *
 * Routes all requests to the private ArmSphere API origin
 * via the Workers VPC Service binding (armsphere-api-private).
 *
 * Rules:
 *   - No business logic
 *   - No auth injection
 *   - No caching
 *   - Preserves: method, pathname, query string, body, all request headers
 *   - Returns: upstream status, body, headers verbatim
 */

export interface Env {
  /** Workers VPC Service binding — routes to armsphere-api-private → tunnel → 127.0.0.1:4000 */
  ARMSPHERE_API_PRIVATE: Fetcher;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Build the forwarded URL: preserve pathname + query, target the private origin
    const targetUrl = "http://127.0.0.1:4000" + url.pathname + url.search;

    const proxyReq = new Request(targetUrl, {
      method:  request.method,
      headers: request.headers,
      body:    request.body,
      // @ts-ignore — Cloudflare Workers streaming body duplex hint
      duplex:  "half",
    });

    return env.ARMSPHERE_API_PRIVATE.fetch(proxyReq);
  },
} satisfies ExportedHandler<Env>;
