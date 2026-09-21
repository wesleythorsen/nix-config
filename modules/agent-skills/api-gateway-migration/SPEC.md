Create (by REVISING the existing `api-gateway-migration` skill at ~/.claude/skills/api-gateway-migration —
update in place, don't create a duplicate) a production-grade skill that takes one API Gateway
migration ticket (children of epic PLCR-4374, e.g. PLCR-4496, PLCR-4506, PLCR-4509) and does all the
work needed to move it to Done on our Kanban board. Wes and David will run it for the remaining
PLCR-4374 tickets, and other teams will run it for their services — so it must be self-contained,
parameterized, and assume no memory of this project's history.

Before authoring anything, load `superpowers:writing-skills` and `skill-creator:skill-creator` and
validate the final skill against both. Follow the repo/user skill conventions already in
~/.claude/skills/ (e.g. the `clarify` skill): kebab-case name matching the directory, third-person
`description` stating what it does AND when to trigger (include natural-language triggers like
"migrate <service> to the new API gateway", "API-GW migration", a bare ticket key from the PLCR-4374
epic), an `argument-hint` in SKILL.md frontmatter (renders natively in current Claude Code — no
companion command file needed), lean SKILL.md (~1 page: triggers, parameters, workflow, hard rules),
and progressive disclosure via references/ files loaded per phase.

## Research phase (do this first, and cite what you find in the skill's references)

Mine the actual history rather than inventing a recipe:
1. This machine's PLCR-4374 sessions (there are several under the name "PLCR-4374", plus a
   code-review fork). Key artifacts to read on GitHub instead of transcripts:
   - Merged/open migration PRs in tetrascience/ts-cloudformation-service: #4009 (datalake — first,
     merged), #4132 (audit), #4165 (log-export), #4133 (data-retention), #4164 (David's user-org).
   - The full review of #4164 (review id 5078708826): 5 inline findings + 2 overview findings. Every
     finding is a failure mode this skill must prevent.
   - Emil Grama's devops feedback: discussion_r3912632873 on #4132 (explicit DependsOn redundant when
     a !GetAtt already references the stack) and the follow-up fixes (32b51976c/1f06d541d, a0e77c379,
     41ed18b3d).
   - predev3 legs: #4172, #4185, #4187, #4191 (branch/worktree/merge/verify pattern).
2. The legacy gateway repo ts-service-gateway-api: src/routes/<service>.ts (route tables),
   src/proxy/mapUrl.ts (pathSegmentsToDrop semantics), scripts/route-policies.ts in the authorizer
   (the RBAC oracle), and the authorizer's route-matcher.ts history (wildcard rejection, fixed in
   ts-lambda-core c7bdff88 / PLCR-4041).

## Core design philosophy — "pay attention", don't memorize

The skill must NOT hardcode every detail. Its first working step is always: fetch the MOST RECENTLY
MERGED migration PR and the current infrastructure/api-gateway.yaml + ts-platform.yaml on
origin/development, and treat those as the living template — replicate their current patterns for the
new service, diffing carefully. Conventions drift (deployment-id suffix ladder, priority table,
header lists); the merged code is the source of truth, the skill is the checklist of WHERE to look
and WHAT to compare. Encode the following as attention-points/verification questions, not as frozen
templates:

- **Route parity is sacred**: enumerate every legacy route for the service from
  ts-service-gateway-api verbatim — methods (never widen to ANY when legacy lists specific verbs),
  auth scopes, unauthenticated routes, subdomain variants, pathSegmentsToDrop / URL rewrites
  (log-export's mapper rewrites path AND query), query-string suppression, onResponse rewrites
  (e.g. POST /login normalizes non-200→401). Also sweep for routes in OTHER route files that proxy to
  the same backend (the /v1/certificates → user-org gap).
- **Explicit resources over {proxy+}**: route-policies.ts has parameterized keys (`:id`) that concrete
  paths can never match, and no greedy fallbacks; the pinned authorizer build may hard-reject
  wildcard templates. Explicit resources matching route-policies.ts verbatim sidestep both. If
  {proxy+} is ever used, both the route table AND the authorizer pin must be checked.
- **RBAC parity check**: diff legacy authScope per route against route-policies.ts entries — flag
  gates that got wider (the /v1/tenants tsAdmin loss) or narrower (userorg myAccount collapse).
- **CORS**: OPTIONS/MOCK method on every browser-reachable resource; calls carry ts-auth-token +
  x-org-slug so browsers always preflight; curl/Postman/admin tests never catch this.
- **Header hygiene**: blank `ts-on-behalf-of-actor-id: "''"` on every integration; copy the current
  context.authorizer.* header list from the latest merged example.
- **ALB listener priority = 100 + the service's existing ts-platform.yaml priority** (convention
  comment block lives in api-gateway.yaml); find the existing priority in services/<svc>.yaml +
  ts-platform.yaml, and check in-flight branches for collisions.
- **Deployment resource**: bump the logical-id suffix (DeploymentV2→V3→…) whenever routes change, add
  every new method (incl. OPTIONS) to DependsOn, update Stage's DeploymentId + description.
- **No redundant explicit DependsOn**: if the ApiGateway stack already references the service via
  !GetAtt <Service>.Outputs.TargetGroupArn, do NOT add the service to DependsOn (Emil's rule). More
  generally: when editing ts-platform.yaml, never sed globally — logical ids repeat in many
  DependsOn lists.
- **Validation**: cfn-lint clean (user install: ~/Library/Python/3.9/bin/cfn-lint).
- **Repo/PR conventions**: worktrees under .worktrees/<TICKET>/; PR title must match
  `^[A-Z]+-\d+: ` (no slash-joined ticket lists); repo allows squash only; draft dev PR for Wes's
  review before marking ready; attribution footer on coworker-visible posts:
  `*Drafted with AI assistance · reviewed, revised, and approved by Wes*`.
- **predev3 regression leg**: branch off origin/predev3 in a fresh .worktrees/ worktree, cherry-pick
  or splice (backports are squashed, so use content diffs not git log to compute the delta), PR to
  base predev3, self-merge after the title check, deploy runs automatically, then verify with
  `aws apigateway test-invoke-method` (profile predev3, region us-east-2, rest api
  ts-predev3-gateway-api): OPTIONS→200 with Access-Control headers, a real route → the backend's
  auth error (e.g. 401 "no api token found") proving integration+VPC-link+ALB-rule+rewrite work.
  CRITICAL: verify with a NON-admin token path too — the authorizer skips RBAC for ts-admins, so
  admin smoke tests mask every RBAC defect.
- **Jira leg**: move the ticket through the board; closing as Done requires SHA Risk Score,
  Story Points, and Sprint set (transition id 451 = "Closed"; SHA Risk Score field customfield_10896,
  N/A=11239 valid for Tasks).

## Skill shape requirements

- Parameterized: positional ticket key and/or service name; inferred where possible (service name
  from the ticket); optional flags for scope (e.g. dev-PR-only vs full predev3 leg vs jira-close),
  parsed from natural language as well as flags. Zero-config default = full end-to-end run with
  review checkpoints before anything outward-facing (PR ready-for-review, merges, Jira transitions,
  Slack posts). Never post/merge/transition without an explicit gate the user confirms.
- `argument-hint: [ticket|service] [scope] [--dev-only|--predev3-only|--full]` (tune to what you
  actually implement; keep hint, description, and parameter table in sync).
- SKILL.md holds the workflow skeleton + hard rules; references/ holds per-phase playbooks
  (route-enumeration.md, cfn-authoring.md, review-checklist.md, predev3-leg.md, jira-close.md) loaded
  only when that phase runs, plus a self-check checklist run before opening each PR — built from the
  #4164 review findings (proxy+/RBAC, authorizer pin, CORS, on-behalf-of, priorities, DependsOn,
  method widening, missing sibling routes, query/response behavior drift).
- No hardcoded service specifics; datalake/audit/log-export/data-retention/user-org appear only as
  worked examples or citations.
- Validate per writing-skills before declaring done (at minimum: description triggering quality, a
  dry-run of the skill's research phase against an already-merged ticket like PLCR-4506 to confirm
  the instructions reproduce the actual merged diff).

Deliverables: the updated skill directory, a one-line install/invoke summary, and a dry-run report
showing the skill's checklist catching at least three of the historical defects when pointed at the
pre-fix state of #4164 or #4133.