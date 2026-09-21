# Phase 3 — Pre-PR self-review checklist

Every item below is a defect that actually shipped (or nearly shipped) in a real migration PR — most from the review of #4164 (review 5078708826). Run the whole list against your own diff before opening any PR; fix and re-run until clean.

1. **Route-table resolution per resource, under the CURRENT matcher's semantics.** Explicit resources need exact parameterized-template keys (greedy keys never apply to them — PLCR-4493: `GET /v1/agents/:agentId` denied despite `/v1/agents/*` existing). Trailing `{proxy+}` needs an exact or `/prefix/*` key per concrete subtree path — and bare prefixes (`GET /v1/agents`) never match `/prefix/*`. Unresolvable routes are an authorizer gap → `references/authorizer-gaps.md`. (#4164: users/organizations/roles/tenants trees 403'd; #4133 pre-fix: `policies/{policyId}` 403'd.)
2. **Authorizer pin.** If any greedy template exists, does the pinned `LambdaMap.GatewayAuthorizer.S3Key` include ts-lambda-core `c7bdff88`? Builds at `1.0.0-7a2145f` deny all wildcard templates.
3. **RBAC parity.** Diff each route's legacy `authScope` against its route-policies entry. Flag widening (tenants: tsAdmin → orgDirectory/view) and narrowing (userorg myAccount → administration).
4. **Method parity.** No `ANY` where legacy lists specific verbs; no invented methods (`DELETE /v1/users/{userId}` didn't exist).
5. **Route completeness.** Re-run the endpoint-env-var grep across all of `src/` — did every discovered route land in the diff? (#4164 missed `/v1/certificates/*`.)
6. **CORS.** Every browser-reachable resource has OPTIONS/MOCK; every OPTIONS method is in the Deployment's `DependsOn`. (All three of #4132/#4165/#4133 originally shipped without any.)
7. **Header hygiene.** `ts-on-behalf-of-actor-id: "''"` blanked on every integration.
8. **Query/response behavior drift.** Routes where legacy suppressed the query string or rewrote responses (login 401-normalization) — handled or explicitly flagged as accepted changes?
9. **Priority convention.** Listener priority = 100 + existing service priority, exactly; no squatting on another service's slot; no collision with in-flight branches. (#4164 used 105/106/107 instead of 106/107/108.)
10. **Deployment bump.** New logical-id suffix, all new methods in `DependsOn`, `Stage.DeploymentId` updated, description current.
11. **No redundant explicit DependsOn** in ts-platform.yaml where a `!GetAtt` already references the stack (Emil's rule).
12. **Byte-exact path case** everywhere (`dataRetention`, not `dataretention`).
13. **Diff hygiene.** `git diff` line count matches intent; no global-replace collateral in ts-platform.yaml; cfn-lint clean vs baseline.
14. **Admin-blindness check.** For each auth-affecting change, state how a NON-admin request behaves — the authorizer skips RBAC for ts-admins, so every RBAC defect above is invisible to admin-token testing.
15. **Wildcard-exposure check.** For each greedy table key a `{proxy+}` route rides, list what the legacy gateway blocked in that subtree (explicit 404s, unrouted paths) — anything newly reachable needs a MOCK 404 mirror (health `/v1/health/internal/{proxy+}`) or a flagged, accepted exposure. On every MOCK-404 subtree, verify its OPTIONS method also returns 404 with no CORS headers — a 200 preflight advertising the blocked verbs defeats the mirror (#4203 Copilot finding, fixed 91e24ebe2).
16. **Ship-with-dependency hygiene.** If any route ships unresolvable (authorizer gap), the PR is DRAFT with a DO-NOT-MERGE note naming the exact missing keys and unblock steps, and the predev3 verification comment lists the denied endpoints.
17. **Pattern verdict present and honest.** The PR body states the bucket (A/B/C) and lists every bucket-B route with its change plan and reference; no upload/WebSocket/streaming route is quietly proxied as if it were bucket A (`references/migration-patterns.md`).
18. **Verification artifacts exist.** Route-parity script pre-filled from the route table, non-admin authz checks, and the PACT/Playwright/upload checks that apply — or the PR says which were skipped and why (`references/verification-tests.md`).
