# Phase 1b — Classify the service into a migration pattern

Before any CFN, put every enumerated route into exactly one bucket and state the service's overall bucket. This is what a consuming team needs to hear first: "is mine a lift-and-shift, or does it need code changes, or do we not know yet?" Report the bucket at the phase-1 gate alongside the route table.

## The three buckets

| Bucket | Meaning | What the skill does |
|---|---|---|
| **A · Lift-and-shift** | Every route is a plain proxy (verbatim, prefix-rewrite, or full-rewrite path mapping), JSON or small bodies, standard auth, no streaming. | Full automation: CFN, CORS, self-review, draft PR, predev3 leg, verification script. Audit, data-retention, log-export, user-org, health were all bucket A. |
| **B · Needs code changes** | At least one route cannot be a straight proxy through API Gateway. Known sub-types below. | Migrates the bucket-A routes normally; for each bucket-B route produces a **written change plan** (service files to touch, reference PR, verification) and, when the reference pattern exists, drafts the service-side change in a separate PR. Never silently proxies a route that can't work. |
| **C · Unknown / needs discussion** | Behavior the recipe has no pattern for, or evidence is contradictory. | Stops at the gate with the evidence and the specific question. Flagged in the PR and the ticket; escalated to Platform Core. |

## Bucket-B sub-types — detect these during enumeration

| Signal in the legacy gateway / backend | Sub-type | Why a plain proxy fails | Reference |
|---|---|---|---|
| `multipart/form-data`, `payload.maxBytes` > 10 MB, `output: 'stream'`, routes named upload/import/ingest, S3 `putObject` on request body | **Large upload** | API Gateway REST payload ceiling is 10 MB. | `references/presigned-upload.md` (fileinfo `/v1/datalake/upload*`, PLCR-4041, ts-lambda-core #3349) |
| `hapi-plugin-websocket`, `ws`/`socket.io`, `Upgrade: websocket` handling | **WebSocket** | REST API Gateway does not upgrade connections; needs a WebSocket API or a different edge. | No shipped pattern yet — bucket C until one exists; note the design doc lists WebSockets as a motivation. |
| `onResponse`/`onPreResponse` handlers that rewrite status/body (e.g. login → every non-200 becomes 401), custom error normalization | **Response rewrite** | HTTP_PROXY passes the backend response through untouched. | Options: move the rewrite into the service; or a non-proxy integration with response templates. Decide with the requester; document as a behavior change if dropped. |
| Legacy handler builds a fixed URI and **drops the client query string**, or re-appends selected params only | **Query-string suppression** | HTTP_PROXY forwards the query by default. | Per route: `RequestParameters` mapping that omits the query, or accept the change explicitly. |
| Streaming/long-poll responses, SSE, `timeout` > 29 s | **Long-running / streaming** | API Gateway integration timeout is 29 s (REST). | Bucket C unless the backend can be made async (job + poll). |
| Routes with `auth: false` that rely on the gateway to mint or read cookies/sessions (login, SSO callbacks, forgot-password) | **Unauthenticated session flow** | Authorizer-less `NONE` methods are fine, but cookie/session handling that lived in the Hapi gateway moves to the service or the authorizer. | Enumerate exactly which routes; check user-org's #4164 for the shipped login handling. |
| Backend trusts gateway-injected headers (`ts-on-behalf-of-actor-id`, `x-ts-*`) from any caller | **Header trust** | HTTP_PROXY forwards client headers verbatim. | Blank the header on the integration (already in cfn-authoring.md); if the service *needs* the header from internal callers, that's a service change — write it up. |

## How to report it

At the 🛑 phase-1 gate, add a one-line verdict above the route table:

> **Pattern: B (needs code changes).** 24 of 26 routes are lift-and-shift; `POST /v1/artifacts/upload` and `POST /v1/artifacts/{id}/content` are large-upload routes and need the presigned-URL flow (plan below). Nothing in bucket C.

Then, per bucket-B route, a short change plan: what the client does differently, which service files change, the reference PR to copy, and how it gets verified. Put the same verdict in the draft PR body under "Migration pattern" so reviewers and the consuming team see it without reading the diff.

## Survey mode (`--survey`)

When asked to survey a service (or all remaining PLCR-4374 services) without migrating: run phases 0–1b only, read-only, and return the bucket verdict + sub-types + route count per service, plus the likely owning team from `CODEOWNERS`. This is how "we asked Claude to scan the repos for patterns" gets backed by evidence rather than guesswork. Say plainly when a repo has behavior you couldn't classify.
