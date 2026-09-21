---
name: api-gateway-migration
description: Migrate one TetraScience service's routes from the homegrown Node gateway (ts-service-gateway-api) to the new AWS API Gateway and shepherd the ticket to Done — route enumeration, CFN authoring, self-review, draft PR, predev3 regression leg, and Jira close. Use when the user says "migrate <service> to the new API gateway", "API-GW migration", hands over a child ticket of epic PLCR-4374 (e.g. PLCR-4496/4506/4509), or references the migration recipe/template (PLCR-4596). Scope is parameterized — a bare ticket or service name runs the full flow with confirmation gates; "survey", "dev PR only", "predev3 leg only", or "close the ticket" run one phase. Classifies each service as lift-and-shift, needs-code-changes (presigned-URL uploads, WebSockets, response rewrites), or unknown, and leaves verification artifacts behind.
argument-hint: "[ticket|service] [--survey|--dev-only|--predev3-only|--jira-close|--full]"
---

# API Gateway Migration (PLCR-4374 recipe)

Migrate one service from the old homegrown gateway to AWS API Gateway. Inputs: **ticket key** and/or **service name** (infer one from the other — the ticket names the service; confirm the mapping). Proven end-to-end on PLCR-4506 (log-export, PR #4165); reference PRs in ts-cloudformation-service: #4009 (datalake, first), #4132 (audit, verbatim paths), #4133 (dataRetention, /api prefix rewrite + explicit resources), #4165 (log-export, full path+query rewrite), #4203 (health, PLCR-4492 — trailing-proxy pattern + MOCK-404 mirror), #4205 (agent, PLCR-4493 — variable-sibling nesting + ship-with-dependency for authorizer gaps), #4164 (user-org — its review, id 5078708826, is the canonical defect catalog this recipe exists to prevent).

## Scope parameter

Default (`--full`, or no flag): all phases in order, stopping at every 🛑 gate. `--dev-only` stops after the draft development PR. `--predev3-only` runs just the backport/verify leg (assumes the dev PR exists). `--jira-close` runs just the Jira finish. `--survey` runs phases 0–1b read-only for one service or every remaining PLCR-4374 child and reports pattern bucket, sub-types, route count, and likely owner (`references/migration-patterns.md`). Parse natural-language equivalents ("just get me a draft PR", "run the predev3 leg", "which of the 17 are lift-and-shift?").

## What this skill does and does not do — say it up front

**Does:** route enumeration, pattern classification, CFN for every proxy-able route (CORS, header hygiene, priority, deployment bump), self-review, draft PR, predev3 backport + in-environment verification, verification artifacts the team keeps, Jira close. **Also handles** the known code-change patterns by producing a written change plan and — on request — the service-side draft PR (`references/presigned-upload.md`, `references/migration-patterns.md`).

**Does not:** production rollout. After the dev PR merges, the owning team still enables the service's gateway feature flag per environment, tests in UAT, and watches its own dashboards. It also cannot classify behavior it has never seen — bucket C stops and asks. Tell the requester this at the start so nobody hears "run the skill and you're done."

## Core principle: pay attention, don't memorize

Conventions drift — deployment-id suffixes, priority tables, header lists, CORS header contents. **The most recently merged migration PR and the current `infrastructure/api-gateway.yaml` + `ts-platform.yaml` on `origin/development` are the living template; this recipe only tells you where to look and what to compare.** Phase 0 of every run: `git fetch origin`, list merged PRs touching `infrastructure/api-gateway.yaml` (newest first), and read the newest merged migration's diff end-to-end before writing anything. When this file and the merged code disagree, the merged code wins — and note the drift to Wes.

## Phases

Read the phase's reference file when you reach it — not before.

0. **Learn the current template** (above). Then fetch the Jira ticket; map service → repo artifacts: `services/<svc>.yaml`, the nested-stack logical name in `ts-platform.yaml` (**confirm, don't guess**), the internal host in `services/web.yaml`. Identify the **owning team** from the backend repo's `CODEOWNERS` (root, `.github/`, or `docs/`); if none, from the dominant recent committers — record it on the ticket so PLCR-4374 children can be reassigned to the right squad.
1. **Enumerate legacy routes** — `references/route-enumeration.md`. Output: a route table (method, public path, auth scope, backend URI after rewrite, query/response quirks) Wes confirms before any CFN is written.
1b. **Classify the pattern** — `references/migration-patterns.md`. Every route lands in bucket A (lift-and-shift), B (needs code changes — large upload, WebSocket, response rewrite, query suppression, streaming, session flow, header trust), or C (unknown). Bucket-B routes get a change plan (large uploads: `references/presigned-upload.md`); bucket-C routes stop here. 🛑 JUDGMENT GATE: route table + pattern verdict confirmed together.
2. **Author the CFN** — `references/cfn-authoring.md`. Worktree off `origin/development` under `.worktrees/<TICKET>/`, minimal diff, no drive-by refactors.
3. **Self-review** — run every item in `references/review-checklist.md` against your own diff before any PR. Fix failures; re-run until clean.
4. **Draft PR** — 🛑 ask before pushing/opening. Draft PR against `development`; PR title must match `^[A-Z]+-\d+: ` (one ticket key, no slash lists); attribution footer on the PR body and any coworker-visible comment: `*Drafted with AI assistance · reviewed, revised, and approved by Wes*`.
5. **predev3 regression leg** — `references/predev3-leg.md`. 🛑 ask before the predev3 push/PR/merge (unless the user pre-authorized it, e.g. "merge and deploy on predev3 like before").
5b. **Verification artifacts** — `references/verification-tests.md`. Leave behind the route-parity script pre-filled from the route table, non-admin authorization checks, a PACT provider run through the gateway when the service already has PACT, a Playwright smoke when it has UI, and the upload-flow check for bucket-B upload routes. Separate PR when it touches a repo the CFN PR doesn't (🛑 before opening).
6. **Finish** — 🛑 confirm, then mark the dev PR ready for review, move the Jira ticket per `references/jira-close.md`. Never merge to `development` yourself — that happens only after Wes + coworker approval.

## Hard rules

- No pushes, PRs, merges, Slack posts, or Jira transitions without the phase's explicit go-ahead (a standing instruction from Wes covering that phase counts).
- Route parity is sacred: never widen methods (no `ANY` where legacy lists verbs), never drop a route, never change auth semantics silently. Any intentional behavior change is flagged to Wes as its own line item.
- Never edit `ts-platform.yaml` with global find/replace — logical ids like `AuditService` recur in many unrelated `DependsOn` lists (this exact mistake deleted two unrelated entries once; net-diff-check every edit).
- Routes the authorizer table cannot resolve are handled per `references/authorizer-gaps.md` (fix-table-first vs ship-with-dependency — 🛑 decision gate); for any other contradiction with this recipe (unexpected mapper behavior, priority conflict), stop and report with the evidence rather than improvising.
- `cfn-lint` clean before every commit that touches CFN (user install: `~/Library/Python/3.9/bin/cfn-lint`); compare findings against the file's baseline — the only tolerated new finding is the conventional `W3005`.
