# Phase 2 — Author the CFN

Work in a worktree off `origin/development` at `.worktrees/<TICKET>/`. Copy patterns from the **latest merged** migration in `infrastructure/api-gateway.yaml` — not from memory, not from this file.

## infrastructure/api-gateway.yaml

**Resources & methods**
- Explicit resources per route, `AuthorizationType: CUSTOM` + the gateway authorizer, `HTTP_PROXY` over the VPC link, static `ts-target-service: '<service>'` header, and the current `context.authorizer.*` header block copied from the newest merged method (the list drifts — copy, don't retype).
- **Explicit resources vs `{proxy+}` is a decision procedure, not a style default — the route table decides.** Read the CURRENT matcher (`lambdas/gatewayAuthorizer/src/routes/route-matcher.ts` in ts-lambda-core — check which branch carries it) and the current route table, then apply its semantics:
  - Explicit resources resolve by exact parameterized-TEMPLATE lookup only (`GET /v1/agents/:agentId` needs that literal key; greedy keys are never consulted for explicit templates).
  - A single TRAILING `{proxy+}` resolves by the CONCRETE request path: exact key first, then most-specific greedy (`/a/b/*` before `/a/*`). The greedy walk never matches a bare prefix (`GET /v1/agents` will not hit `/v1/agents/*`) and never a top-level `/v1/*`.
  - Greedy anywhere except trailing position — or more than one — is always denied.
  - So: table has exact keys for your routes → explicit resources (audit/data-retention pattern). Table has only a `/prefix/*` greedy key for the subtree → trailing `{proxy+}` (datalake/health pattern; explicit resources would DENY). Neither → an authorizer gap: `references/authorizer-gaps.md`.
  - Either way the pinned `LambdaMap.GatewayAuthorizer.S3Key` must be a build whose matcher supports what you use — builds at `1.0.0-7a2145f` reject ALL wildcard templates (fixed in `c7bdff88`, PLCR-4041). 🛑 confirm the choice with the requester.
- **API Gateway forbids two variable siblings under one parent** — `{proxy+}` cannot sit beside `{agentId}`. When a literal-param resource already occupies the variable slot (agent: log-export's `{agentId}` rewrites), the subtree needs `/{agentId}/{proxy+}` nesting plus explicit resources for the bare paths.
- **Don't let a greedy table key newly expose blocked backend paths.** If the legacy gateway explicitly 404'd a sub-path (health's `/internal/*` Boom.notFound) that a wildcard table entry would now allow through, add a `{proxy+}` MOCK integration returning the same 404 to mirror the block. **The subtree's OPTIONS method must 404 too** (no CORS headers): the legacy gateway 404s every verb there, and a 200 preflight advertising `Allow-Methods: GET` re-exposes the blocked routes to browsers. Caught by Copilot on #4203 (PLCR-4492), fixed in 91e24ebe2 — copy that shape.
- Path params: declare `RequestParameters: method.request.path.<name>: true` and map into the integration URI.
- **Blank `ts-on-behalf-of-actor-id: "''"` on every integration.** HTTP_PROXY forwards unmapped client headers; at least one backend (data-retention) honors this header from non-internal callers, letting any JWT holder forge the recorded actor.
- **CORS: an `OPTIONS` method with a `MOCK` integration on every browser-reachable resource**, returning `Access-Control-Allow-{Headers,Methods,Origin}` — copy the current header values from the newest merged example. curl/Postman/integration tests never preflight; only real browsers do, so a missing OPTIONS ships green and breaks the UI at cutover.
- **ALB listener rule: priority = 100 + the service's existing private-ALB priority** (the convention comment block lives above the listener rules in api-gateway.yaml). Find the existing priority via the `Priority` parameter in `services/<svc>.yaml` and its value in `ts-platform.yaml`. Known-correct examples: datalake 4→104, audit 14→114, data-retention 20→120, log-exporter 23→123. Then check every in-flight sibling branch (`git branch -r`, grep `Priority: 1[0-9][0-9]`) for collisions — CloudFormation fails the whole stack on a duplicate priority. 🛑 confirm allocation with Wes if any sibling PR is open.
- **Deployment resource:** bump the logical-id suffix (`DeploymentV2` → `DeploymentV3` → …) whenever routes/methods change; add **every** new method — OPTIONS included — to its `DependsOn`; update `Stage.DeploymentId` and the Description. A missed bump deploys green but never publishes the routes. Sibling PRs all rename this resource; last-to-merge rebases — coordinate the suffix ladder.

## services/<svc>.yaml

Add `Outputs.TargetGroupArn` (copy the pattern from a migrated service).

## ts-platform.yaml

- Pass `<Svc>TargetGroupArn: !GetAtt <NestedStackLogicalName>.Outputs.TargetGroupArn` into the ApiGateway stack's parameters.
- **Do NOT add the service to the ApiGateway stack's `DependsOn`** — the `!GetAtt` already creates the dependency implicitly (devops rule from Emil Grama, #4132 discussion_r3912632873; explicit entries get review pushback).
- Never global-replace in this file: service logical ids recur in many unrelated `DependsOn` lists. After editing, `git diff` and verify the change count matches intent exactly.

## Validate

`cfn-lint` on every changed file vs its baseline (only new finding tolerated: `W3005`). Keep the diff minimal — stable names/paths, no refactors.
