Create a new skill named `clarify` (invocable as `/clarify`). Follow the repo's skill conventions;
consult `superpowers:writing-skills` and `skill-creator:skill-creator` before authoring, and validate
the result against them.

## Purpose

`clarify` rewrites dense, jargon-heavy, or poorly-sequenced prose into a self-contained explanation
that any competent reader can follow on one pass — without losing a single substantive detail.

It is a *rewrite* skill, not a summarize skill. Nothing important is dropped; the change is in
structure, sequencing, and self-containment.

## Invocation modes

The skill MUST support both, and detect which applies from the arguments:

1. **Preemptive** — `/clarify <text>` or `/clarify` with text pasted/attached/referenced (file path,
   PR body, Jira description, a quoted block). Rewrite that text.
2. **Retrospective** — `/clarify` with no text. Rewrite the most recent substantive assistant output
   in the conversation. Define "most recent substantive output" explicitly (last assistant message
   containing findings, an explanation, or a written deliverable — not tool chatter, not a one-line
   acknowledgement). If the target is genuinely ambiguous, ask exactly one question naming the two
   candidates; otherwise pick and state the choice in one line.

## Parameters — inferred by default, never prompted for

**The zero-argument invocation is the primary path.** `/clarify` alone must produce the right output
with no questions asked. Every parameter below is inferred from the content and the conversation;
an explicit value is an override, not a requirement. Parse overrides from natural language too
("clarify this for the Jira ticket", "shorter", "for a non-engineer") as well as `key: value` form.

| Parameter | Values |
|---|---|
| `target` | inline text, file path, `last`, `last:N` (Nth-from-last assistant message), URL/ticket ref |
| `audience` | `peer-engineer`, `cross-team`, `non-technical`, `executive` |
| `depth` | `tight` (≤150 words), `standard`, `full` (no cap) |
| `format` | `markdown`, `plaintext`, `slack`, `jira`, `pr-comment`, `commit-msg` |
| `shape` | `problem` (issue→cause→fix), `decision`, `howto`, `status` |

The skill MUST specify a deterministic inference rule per parameter, so two runs on the same input
choose the same values. Write each as an ordered signal list, first match wins:

- **`target`** — inline/attached text if present; else a file path or ticket/PR/URL reference in the
  arguments; else `last`.
- **`shape`** — a described failure, defect, or blocked behavior → `problem`. A recommendation,
  trade-off, or "which should we do" → `decision`. Ordered actions or a procedure → `howto`. Progress,
  what changed, what's pending → `status`. Mixed content → the shape matching the reader's actual
  question, and say which was chosen in no more than one short line.
- **`audience`** — infer from the stated or implied destination: a teammate on the same service →
  `peer-engineer`; a ticket comment, PR description, or another team → `cross-team`; a customer,
  support, or PM thread → `non-technical`; a leadership summary or status roll-up → `executive`.
  With no destination signal, use the *lowest* assumed-context level that still fits the content's
  technical density, because over-explaining costs less than an unreadable output.
- **`depth`** — scale to input substance, not input length: input with one claim → `tight`; a handful
  of related claims → `standard`; multiple independent findings, or an explicit "explain"/"walk me
  through" → `full`. Verbose input carrying one idea gets `tight`, not `standard`.
- **`format`** — infer from destination: Slack/chat → `slack`; Jira/ticket → `jira`; PR or code review
  → `pr-comment`; commit → `commit-msg`; a plaintext sink (email body, plain file, terminal paste) →
  `plaintext`; otherwise `markdown`.

When two or more inferred values are non-obvious *and* would materially change the output, state the
chosen set in one compact line before the rewrite (e.g. `cross-team · standard · problem`) so the
reader can correct it in a word. Never ask.

## Output contract

Default `problem` shape, for content describing a defect, risk, or blocker:

1. **One-sentence issue statement.** Names the affected surface, the failure, and the trigger
   condition. Concrete and falsifiable.
2. **Why it happens.** The mechanism, in causal order: what the system does, what it assumes,
   where the assumption breaks. Contrast the working case against the broken case explicitly
   ("this holds for X because …; it breaks for Y because …").
3. **What it means / impact.** Who or what is affected, and how badly.
4. **The fix.** Concrete, ordered, actionable. Say "unknown" where it is unknown rather than hedging.
5. **Notes** (optional, only if it carries real weight): caveats, scope limits, open questions.

Other shapes MUST be defined in the skill with the same rigor:
- `decision` — recommendation → reasoning → alternatives rejected and why → what would change the call.
- `howto` — outcome → prerequisites → numbered steps → verification.
- `status` — where things stand → what changed → what's blocked → next action.

## Hard rules

State these in the skill as non-negotiable:

1. **The output is a replacement, not a critique.** Never reference the input: no "the original text
   said", "as mentioned above", "to clarify the previous message", "this rewording". It reads as if
   written from scratch.
2. **Self-contained.** Resolve pronouns, acronyms, and internal shorthand on first use. Inline the
   one fact a reader would otherwise have to go find. A reader who has seen none of the preceding
   conversation must be able to follow it.
3. **Lossless on substance.** Every identifier, filename, line number, error string, ticket key,
   command, numeric value, and causal claim in the input survives into the output. Compress the
   framing, never the facts.
4. **Context-aware.** The skill may pull supporting facts from anywhere in the conversation — earlier
   findings, file paths already read, decisions already made — and fold them in as plain statements.
   It cites conversation context only as concrete facts, never as "see above".
5. **Cut what does not carry weight.** Remove hedging adverbs with no information, restated
   background, tangents, and figurative language. Keep hedges that encode genuine uncertainty.
6. **Preserve verbatim blocks.** Code, config, logs, commands, and quoted error text pass through
   unaltered.
7. **No preamble, no sign-off.** The output begins with the issue statement and ends when the content
   ends.

## Gold-standard example (include in the skill, before/after)

Use this as the calibration example. It is representative, not the skill's subject matter.

**Before:** a numbered finding reading roughly "endpoints using {proxy+} have RBAC issues because the
authorizer table lacks greedy matching, works for admins, breaks otherwise."

**After:**
> **Every endpoint registered with a `{proxy+}` path fails RBAC policy resolution for non-admin users.**
>
> The authorizer's route table matches paths literally — it has no greedy/wildcard matching, so a
> registered pattern like `/v1/foo/{proxy+}` never matches a real request path such as
> `/v1/foo/bar/baz`. With no matching route, no policy is resolved.
>
> `ts-admin` callers are unaffected: the authorizer short-circuits to allow before policy lookup runs.
> Every other role falls through to the default deny and receives a 403 on paths that should be
> permitted.
>
> Fix: add greedy segment matching to the route table so a `{proxy+}` pattern matches any remaining
> path suffix, and add a non-admin `{proxy+}` request to the authorizer test suite.

Point out in the skill what makes it better: the failure is named in the first sentence; the mechanism
is causal, not descriptive; the admin/non-admin contrast is stated instead of implied; the fix is
concrete.

## Discoverability — grayed-out argument hints on `/clarify`

Typing `/clarify` should surface the available arguments inline the way built-in commands do, so the
options are visible without reading the docs.

- Add an `argument-hint` field to the skill's frontmatter. Keep it short enough to render on one line
  in the terminal, with every parameter optional and clearly so — e.g.
  `argument-hint: [text|file|last] [audience] [depth] [format] [shape]`
- Verify it actually renders in this Claude Code build before declaring it done. If the skill loader
  ignores `argument-hint`, add a thin companion slash command at `.claude/commands/clarify.md` whose
  frontmatter carries `argument-hint` (and `description`) and whose body simply invokes the skill —
  this is the supported path for grayed-out hints, and it keeps the hint text in one place.
- Do not pad the hint with defaults or values. The hint advertises what *can* be passed; the skill
  infers everything unspecified. Its wording must not imply an argument is required.
- Mirror the same parameter list in the frontmatter `description`'s "when to use" clause so it is
  discoverable from `/skills` output too, and keep hint, description, and the parameter table in sync
  — a stale hint is worse than none.

## Modularity requirements

- Keep `SKILL.md` lean — trigger conditions, the parameter/inference table, the workflow, and the hard
  rules.
- Move the shape templates and worked examples into `references/` files loaded only when the relevant
  shape is selected (progressive disclosure).
- Put the pre-return self-check in its own `references/checklist.md`.
- No hardcoded project, repo, or domain specifics anywhere. The RBAC example is illustrative; the
  skill must work equally on a product spec, a research summary, or a customer email.

## Self-check before returning output

The skill must run this and fix any failure before emitting:

1. Does the first sentence alone tell the reader what is wrong (or what the recommendation is)?
2. Can this be understood with zero access to the conversation or the input text?
3. Does any sentence reference the input, the rewrite, or "above"? Delete it.
4. Is every identifier, number, path, and causal claim from the input still present?
5. Is any remaining sentence doing no work? Delete it.
6. Do the inferred `audience`, `depth`, `format`, and `shape` match the content and its destination —
   and would a second run on this same input infer the same four?

## Conventions compliance

- Frontmatter: `name` (kebab-case, matches directory), `argument-hint`, and a `description` written in
  third person stating both *what it does* and *when to use it*, including the retrospective
  no-argument case and natural-language triggers ("reword that", "say that more clearly", "make this
  understandable", "rephrase for the ticket").
- Imperative voice in the body; no time-sensitive statements; no "as of today".
- Document the interaction with any active output-style skill: `clarify` governs the *structure and
  self-containment* of the rewrite; a house style skill still governs tone and terseness. On conflict,
  the house style wins on tone, `clarify` wins on structure.
- Include an "Anti-patterns" section listing: summarizing instead of rewriting, adding a meta-preamble,
  dropping identifiers to shorten, inventing facts not present in the input or conversation, forcing
  `problem` shape onto content that is not a problem, and asking the user for a parameter the skill
  should have inferred.

## Deliverables

1. The skill directory with `SKILL.md` and its `references/` files.
2. The `argument-hint` wired up, plus the companion `.claude/commands/clarify.md` if the skill
   frontmatter alone does not render hints — and a note stating which path was used and that the hint
   was seen rendering.
3. A one-line summary of where it was installed and how to invoke it.
4. Three demonstration runs on content from this conversation: one preemptive, one retrospective, and
   one bare `/clarify` showing the inferred parameter line.
























Hi DevOps team, I've got 3 PRs in ts-cloudformation-service ready for review, all part of the our API Gateway migration ([PLCR-4374](https://tetrascience.atlassian.net/browse/PLCR-4374)). Same shape as the [datalake PR](https://github.com/tetrascience/ts-cloudformation-service/pull/4009) that was recently merged - each routes one service through the new AWS API Gateway:
- Audit - https://github.com/tetrascience/ts-cloudformation-service/pull/4132
- Log-export - https://github.com/tetrascience/ts-cloudformation-service/pull/4165
- Data-retention - https://github.com/tetrascience/ts-cloudformation-service/pull/4133

All three are cfn-lint clean and have been regression-tested through the gateway on predev3 (verification notes are in the PR comments). Appreciate a look when you get a chance!








Here's a rephrase — keeps it friendly but adds the two things your draft is missing: a concrete deadline and links so Rafael can act immediately without hunting:





Hey, how's it going? Quick ask, I've got 3 PRs in `ts-cloudformation-service` waiting on a devops review, and I'm trying to get them merged by tomorrow morning to close out my sprint work. They're all the same change applied to different services (API-GW migration, same shape as the datalake one that already merged in [#4009](https://github.com/tetrascience/ts-cloudformation-service/pull/4009)):

- Audit — https://github.com/tetrascience/ts-cloudformation-service/pull/4132
- Log-export — https://github.com/tetrascience/ts-cloudformation-service/pull/4165
- Data-retention — https://github.com/tetrascience/ts-cloudformation-service/pull/4133

I've deployed + verified all three on predev3, so hopefully a quick review. I posted in #squad_dev_ops earlier but figured I'd reach out directly given the timing. Is there anything I can do on my end to make the review easier — or if you're swamped, is there someone else I should ask? I know it's late notice so







Why these changes from your draft:

1. **Names the deadline** ("by tomorrow morning") — without it, "would really like to merge them" reads as no-rush and lands at the bottom of his queue. Framing it as "close out my sprint work" is honest without unloading the points/management stress on him.
2. **Reduces his effort to near zero** — links inline, "same change × 3 services," and "verified on predev3" tells him it's a low-risk, fast review before he even clicks.
3. **References the channel post** — explains why you're DMing without sounding like you're going around the team.
4. **Ends with an out** ("someone else I should ask?") — makes it easy for him to respond even if he can't do it, so you don't get silence again.



Could I get some eyes on these this morning as well? Each PR is the same change but for a different service. All verified on predev3.





https://tetrascience.slack.com/archives/C03DW8C46Q4/p1788275674440649


claude "Close Jira ticket [PLCR-4496](https://tetrascience.atlassian.net/browse/PLCR-4496) as Done. Context: audit-service API-GW migration; dev PR tetrascience/ts-cloudformation-service#4132 is MERGED; predev3 verified via PRs #4187 and #4191 (test-invoke-method: OPTIONS 200 + backend 401 'no api token found'). Steps:
1) Post a short completion comment linking PR #4132 and the predev3 verification, ending with the footer '*Drafted with AI assistance · reviewed, revised, and approved by Wes*'.
2) Ensure required close fields: Sprint = the board's active sprint, Story Points = keep existing (set 2 only if empty), SHA Risk Score (customfield_10896) = N/A (option 11239).
3) Transition with id 451 ('Closed'). Report exactly what was set and a link to the comment."








claude "Use the Artifact tool with action read_db (db_op list) on https://claude.ai/code/artifact/e81009a4-da99-43f7-ab06-e9b75517eacf collection queue. For every doc with status queued: execute its prompt field as an independent task, running independent ones as parallel subagents. After each finishes, write_db update queue/<docId> to status done with a short result field. Finish with a one-screen summary of every action and outcome."












































1. a 
   2. 






Very good with the board! But I have some changes I'd like you to make:
1. I'd like the whole board to be seamlessly connected to claude Code
    1. The board should be "connected" to a single claude code **session**
        1. there should be a way to change the model and effort for the underlying claude code session via the board UI
        2. Using a single session should help with cross-ticket communication, since all work items ultimately are managed by this single session.
        3. Each individual work item prompt should get run as a subtask under the single board session (maybe simply prepend the user input with "/subtask"? idk if it's that simple).
    2. each work item should have it's own text editor (just like they do now), but
        1. the input should resemble a CLI terminal, and the user should modify their prompt as if it was a terminal input
             1. but don't get too realistic with this, I should be able to interact with input more like a normal textbox
             2. for example: mouse selection with copy paste, move cursor location with mouse, enter key adds new line and doesn't submit, etc etc.
         2. there should be a way to "run" or "submit" the prompt (button and maybe ctrl+enter?) and have it create a subtask under the current session.
         3. the output of the subtask should be able to be viewed in the same editor window
             1. should be streamed back as it comes in, but polling is ok too (the input/output boxes are almost like a TTY interface)
         4. Similar to what is currently implemented, there should automatically be (at least one) suggested action (prompt) to complete the next step of getting the work item in question closer to the finish line.
             1. Maybe you can think of something fancy for displaying multiple suggestions, any new and cool UI components out there?
    3. Each work item tile should have a "..." menu button which exposes some options
        1. one of which is "refresh", which will check to see what the status of the underlying work item is and update the work item UI to reflect that (for example if the claude code artifact is "done", then the work item should be marked as done, and visa-versa)
        2. another option is "steer" mode, which allows user to edit the current suggested prompt/action by typing simple text guidance commands. For example, the suggested action/prompt might say "push changes, create PR, notify teammates on slack", but I don't want it to notify coworkers, so I can click "..." -> "steer" and then in a floating textbox type something like "draft notifications only" (enter key) and the next suggestion would be something like "push changes, create PR, and draft a notification message but do not send". This can be repeated to quickly and incrementally "steer" the work item to do the right thing.
        3. I just thought of a super cool idea just like steer mode, but for creating a prompt from scratch. Just like "steer" mode you iteratively enter short commands that modify the prompt state. Maybe to be even faster there is like a selection bank of predefined "commands" or "command categories" or "command intents" (for example "update Jira status", "create child task", could be under a categorically nested database of command "templates", and when the user selects one it recursively asks for more information to fill in the prompt template and at any point you can steer it from there. IDK these are just thoughts out loud - come up with something creative and most of all useful!
    4. Each subtask tile should run concurrently, and the UI should reflect that (for example the work item card is 100% complete, but there are 3 subtasks, one of which is still "in progress")
        1. Come up with some creative concept for how to display progress and subtask status in a way that is intuitive and easy to understand
        2. same for displaying progress (prompt progress and work item progress to completion).
        3. maybe like a graph node-edge structure could be an optional display mode that lets you see the subtasks and their status more clearly and how they relate to each other, and what steps are needed for each to complete.
2. Add sound effects to help me stay focused and know when I have new notifications, etc.