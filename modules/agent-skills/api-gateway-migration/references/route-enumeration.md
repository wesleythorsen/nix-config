# Phase 1 — Enumerate legacy routes

Goal: a complete, Wes-confirmed route table before any CFN exists. Wrong or missing routes here become 404s, silent 403s, or security regressions at cutover.

## Where routes live

1. Start at `ts-service-gateway-api/src/routes/<service>.ts`.
2. Then grep **all of `src/`** for the service's endpoint env var (e.g. `USER_ORG_SERVICE_ENDPOINT`). Routes proxying to your backend live in other files: log-export's routes live in `agent.ts` / `data-acquisition.ts` via `logExportUrlMapper.ts`; `/v1/certificates/*` lives in `certificates.ts` but proxies to user-org (the gap that David's user-org PR #4164 missed). Never stop at the obvious file.
3. Cross-check against the authorizer's route table (the RBAC oracle) in ts-service-gateway-api — grep the repo for `route-policies` rather than trusting a path (it moved from `scripts/route-policies.ts` to `src/auth/rbac/route-policies.ts` in PLCR-4692; generator: `scripts/generate-route-policies.mjs`). Entries there for paths you haven't enumerated mean you missed a route; routes you found that the table cannot resolve are an **authorizer gap** — classify and handle it per `references/authorizer-gaps.md` (fix-table-first vs ship-with-dependency), never by silently dropping the route.

## What to record per route

| Column | Why |
|---|---|
| Method(s), exactly | Never widen to `ANY`: legacy has no `DELETE /v1/users/{userId}`; `ANY` would create one. |
| Public path, byte-exact case | `dataRetention` is camelCase; the authorizer matches byte-exact. |
| Auth: scope or unauthenticated | Legacy `authScope` (e.g. `[Policy.tsAdmin]` on `/v1/tenants`) vs the route-policies entry — flag any widening (tenants lost its ts-admin gate in #4164) or narrowing (userorg myAccount routes collapsed onto `administration`). Unauthenticated routes (login/logout/forgot-password, subdomain variants) get `AuthorizationType: NONE`. |
| Backend URI after rewrite | Read the **actual mapper code** (`src/proxy/mapUrl.ts`, `pathSegmentsToDrop`, service-specific mappers). Classify: **verbatim** (audit), **/api/v1 prefix rewrite** (dataRetention: `/v1/dataRetention/<rest>` → `/api/v1/<rest>`), or **full rewrite** (log-export: path collapses to `/logs/{export,requests,config}`, path param moves into the query string as `resourceId` + static `resourceType`). |
| Query-string behavior | Legacy unauthenticated handlers build fixed URIs and DROP the client query except where explicitly re-appended (only `/login/sso` variants). HTTP_PROXY forwards queries by default — document each route where that differs, and decide (with Wes) whether to suppress. |
| Response rewrites | e.g. legacy `POST /login` `onResponse` rewrites every non-200 to 401. A plain proxy loses that; flag it. |
| Browser-reachable? | Drives the CORS OPTIONS method in phase 2. Calls carrying `ts-auth-token`/`x-org-slug` are non-simple → browsers always preflight. |

## Pattern signals to record while you enumerate

Flag any route showing: multipart/large bodies or S3 puts (large upload), WebSocket upgrades, `onResponse` rewrites, fixed-URI handlers that drop the query string, streaming or >29 s handlers, cookie/session flows on unauthenticated routes, or backend trust in gateway-injected headers. These decide the pattern bucket in `references/migration-patterns.md`.

## 🛑 Judgment gate

Present the table plus mapper-code snippets as evidence, with your classification per route. Get Wes's confirmation before writing CFN. Wrong classification = 404s that only appear at cutover.
