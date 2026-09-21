# Phase 5b — Verification artifacts the migration leaves behind

`test-invoke-method` proves the CloudFormation path once, by hand. A migration also leaves behind repeatable checks so the consuming team, QE, and the eventual production flag-flip have something to run. Produce these in the service's own repo (or `ts-tests-aux-services` when the service has no test home), in a separate PR when they touch a repo the CFN PR doesn't.

## 1. Route-parity script (always)

Generate `scripts/verify-apigw-routes.sh` (template: Platform Core's `verify-apigw-routes.sh`) pre-filled from the phase-1 route table: one `OPTIONS` check per browser-reachable resource expecting `200+` CORS headers, one real route per rewrite class expecting the backend's own 401, every legacy-blocked prefix expecting the MOCK 404, and the `--audit <prefix>` resource-tree listing. Parameterized by profile / region / REST API id so the same script runs on predev3, UAT, and production. Check it in next to the service; link it from the PR body and the Jira verification comment.

## 2. Authorization checks with a non-admin token (always)

Because `test-invoke-method` bypasses the authorizer, add real HTTPS calls: for each distinct `resource:action` the routes require, one call with a non-admin user that **has** the permission (expect the backend's response) and one that **lacks** it (expect 403 from the authorizer). Implement as a small Jest/Vitest spec or a shell script that takes `TS_AUTH_TOKEN` from the environment — never commit tokens. Admin tokens prove nothing here.

## 3. Contract test (when the service already has PACT)

If `package.json` carries a `pact` config (see the ts-lib-pact-broker conventions — provider name, broker `pact-broker.internal`, the reusable verify workflow), add a **provider-verification run through the new gateway base URL** so the existing consumer contracts are verified against the migrated path, not just the direct service URL. The interactions already exist; the only change is `providerBaseUrl` pointing at the gateway with a `ts-auth-token` state handler. Do not author new consumer contracts as part of a migration — that's the consumer's work.

## 4. Browser smoke (when the service has UI)

For services with UI surfaces, add one Playwright spec that loads the relevant page with the service's gateway feature flag ON and asserts (a) the page renders, (b) at least one XHR to the new gateway host returned 2xx, and (c) no CORS error in the console. This is the check that catches the missing-OPTIONS class of defect that curl-based tests cannot. Put it wherever the repo's existing Playwright suite lives; skip if there is none and say so.

## 5. Upload-flow check (bucket-B large-upload routes only)

Per `presigned-upload.md`: intent endpoint → presigned PUT of a small fixture → validation Lambda success log → object at final destination. Script it; run it against predev3.

## Reporting

The Jira verification comment lists, per artifact: path in repo, how to run it, what it proved on predev3 (with the run output or a link). The dev PR body gets a "How to verify" section pointing at the same. Attribution footer as usual.
