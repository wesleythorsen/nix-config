# Phase 5 — predev3 regression leg

Backport the dev-PR changes to predev3, deploy, and verify the gateway path end-to-end. predev3 backport PRs are self-merged per team convention (after the title check passes).

## Backport

1. `git fetch origin --prune` first — predev3 moves fast and backport branches get deleted after merge.
2. Fresh worktree: `git worktree add .worktrees/<TICKET>-predev3 -b <TICKET>-predev3 origin/predev3`.
3. Compute the delta by **content diff, not `git log`** — predev3 backports are squash-merged, so commit ancestry lies about what's already landed. Diff the relevant files between `origin/predev3` and your dev branch; earlier backports may already carry most of the migration, leaving only your newest commits to apply.
4. Cherry-pick when clean; when conflicts interleave with other services' blocks, splice the section from the dev branch instead (take the whole service section verbatim, keep predev3's neighbors, swap `DependsOn` entries precisely).
5. predev3's Deployment logical-id ladder is independent of development's — bump from whatever predev3 currently has.
6. `cfn-lint`, commit, push.

## PR + merge

- PR base `predev3`. Title must match `^[A-Z]+-\d+: ` — ONE ticket key; slash-joined lists fail the title-checker (use "(incl. PLCR-XXXX)" for extras).
- Repo disallows merge commits: `gh pr merge --squash` after the `check` job passes.
- Deploy (`Deployment ts-predev3` workflow) triggers automatically on merge; watch it by run id only if the user asked for monitoring.

## Verify in-environment

AWS profile `predev3`, region **us-east-2**, rest api `ts-predev3-gateway-api` (discover the id via `aws apigateway get-rest-apis`). Then `aws apigateway test-invoke-method` per route class from phase 1:

- `OPTIONS` on a browser-reachable resource → 200 with `Access-Control-Allow-*` headers (proves the MOCK).
- One real route per rewrite class → the **backend's** auth error (e.g. `401 {"message":"no api token found"}`) — proves integration → VPC link → ALB rule (`ts-target-service` header) → path rewrite all work and a real endpoint answered.
- A negative authz case → expect deny.
- `aws apigateway get-resources` → confirm every expected resource/method exists and nothing unexpected (e.g. a leftover `{proxy+}`) remains.

**test-invoke-method bypasses the authorizer**, so it can't prove RBAC. For auth verification use real HTTPS calls with a NON-admin token — ts-admins skip RBAC entirely and mask every policy defect.
