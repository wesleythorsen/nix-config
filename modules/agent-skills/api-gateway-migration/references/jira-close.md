# Phase 6 — Finish and Jira close

## Development PR

🛑 With Wes's confirmation: mark the draft PR **ready for review**, move the Jira ticket to **Code review**. Never merge to `development` yourself — that happens only after Wes + a coworker approve, outside this skill. Devops (#squad_dev_ops, e.g. Emil — EU-morning hours) reviews ts-cloudformation-service PRs; a threaded Slack nudge with "also send to channel" is the accepted escalation after ~a day of silence.

## Jira transitions (PLCR project)

- Move through the board states as work progresses (In Progress → Code review → …). Only transition when the user confirms, or a standing instruction covers it.
- **Closing as Done requires three fields set or the transition fails silently/errors:**
  - Sprint (current sprint)
  - Story Points
  - SHA Risk Score — `customfield_10896`; option id `11239` ("N/A") is valid for Tasks
  - The Done transition is **"Closed", transition id 451**.
- Post a findings/verification comment on the ticket before closing when the work included in-environment verification — link the dev PR, the predev3 PR, and the verification evidence (the `test-invoke-method` results). Attribution footer applies:
  `*Drafted with AI assistance · reviewed, revised, and approved by Wes*`

## Acceptance criteria recap (every PLCR-4374 child ticket)

1. Authorizer routes explicit — no wildcards (or both wildcard preconditions verified and Wes signed off).
2. CFN includes API-GW resources/methods, CORS OPTIONS, **and** the ALB listener rule at the 100+N priority.
3. Full regression through the gateway on predev3, including a negative authz case.
