---
name: clarify
description: Rewrite dense, jargon-heavy, or poorly-sequenced prose into a self-contained explanation any competent reader can follow in one pass — without dropping a single identifier, number, or causal claim. Use when the user invokes /clarify, says "reword that", "say that more clearly", "make this understandable", "rephrase for the ticket", or wants a clearer version of any text (a finding, PR comment, Jira description, status update, spec, or explanation). With no arguments it rewrites the most recent substantive assistant output. Optional arguments, all inferred when omitted — target (text|file|last), audience (peer-engineer|cross-team|non-technical|executive), depth (tight|standard|full), format (markdown|plaintext|slack|jira|pr-comment|commit-msg), shape (problem|decision|howto|status).
argument-hint: "[text|file|last] [audience] [depth] [format] [shape]"
---

# Clarify

Rewrite prose so a competent reader who has seen none of the surrounding context can follow it in one left-to-right pass. This is a rewrite, not a summary: preserve every material fact, identifier, number, causal claim, and genuine uncertainty — but restructure freely. The result should read like a capable engineer explaining something concisely to another capable engineer who lacks the first engineer's local context.

## Resolve the target

First match wins:

1. Inline or attached text in the arguments → rewrite that text.
2. A file path, PR/ticket reference, or URL → read it, rewrite its content.
3. Otherwise → the most recent **substantive** assistant output (findings, an explanation, a written deliverable — not tool chatter or acknowledgements). `last:N` targets the Nth-from-last.

If the target is genuinely ambiguous between two candidates, ask one question naming both. Otherwise pick and state the choice in one line.

## Infer parameters — never ask

`/clarify` alone must produce the right output with no questions. Explicit values, whether `key: value` or natural language ("for the Jira ticket" → jira, "shorter" → tight, "for a non-engineer" → non-technical), override inference.

- **audience** — from the destination: same-service teammate → `peer-engineer`; ticket comment, PR, or another team → `cross-team`; customer/support/PM → `non-technical`; leadership roll-up → `executive`. No signal → assume the least shared context that still fits the content (over-explaining costs less than an unreadable output).
- **depth** — scale to substance, not input length: one claim → `tight` (≤150 words); a handful of related claims → `standard`; many independent findings or an explicit "walk me through" → `full`.
- **format** — from the destination: `slack`, `jira`, `pr-comment`, `commit-msg`, `plaintext`, otherwise `markdown`.
- **shape** — see Shapes below.

When inferred values are non-obvious and would materially change the output, state them in one compact line before the rewrite (`cross-team · standard · problem`) so the reader can correct them in a word.

## Workflow

1. Resolve the target; infer the parameters.
2. Inventory the material facts: identifiers, numbers, paths, error strings, commands, causal claims, genuine uncertainty. Every item survives into the output.
3. Decide what the reader can reasonably be assumed to know. You may know things because you inspected code, ran tools, or investigated — the reader does not. Establish issue-specific context in the output, or confirm the audience already has it. Never write from hidden investigation context. This matters most for code-review findings and summaries produced after background-agent work.
4. Rewrite using the principles below. Reorder, merge, split, and reframe freely — never preserve bad source ordering just because it was the input ordering.
5. Apply the matching shape as a loose skeleton.
6. Run the self-check; fix every failure.
7. Emit only the replacement text.

## Writing principles

Local clarity comes from the reader-expectation approach (Gopen & Swan) and the given-new principle:

- **Given → new.** Start each sentence or unit from information already established (or safely assumed), then add the new thing. The output must make sense prospectively, during the first read — never require the reader to reach the end and reinterpret the beginning.
- **Orient before concluding.** Lead with the important result when that opening is understandable from the reader's current context. "The new model-card endpoint will initially return 404s because nothing currently publishes `MODEL_CARD.md`" orients; "The endpoint ships dark" compresses past comprehension. Never force a headline that only becomes clear later — widen the opening until it stands alone.
- **Prerequisites first.** Prefer familiar → specific, simple → detailed, prerequisite → dependent. A natural sequencing preference, not an algorithm.
- **Make relationships apparent.** If the truth is "A causes B; C supports B; therefore D", do not emit "A. B. C. D." Attach evidence to the claim it supports. A few extra words that preserve a causal or evidential link beat terse phrasing the reader must reconstruct — but don't mechanically sprinkle transition words.
- **Distrust opaque compression.** Shorthand like "ships dark", "the path is dead", "cheap fix", "same story here" is acceptable only when established context already makes it obvious. Literal clarity beats clever compression.

## Shapes

Loose skeletons, not templates — include the elements that exist, roughly in this order, and let the principles above override the ordering when needed:

- **problem** — what's wrong and where → why (the mechanism, in causal order; contrast the working case against the broken one) → impact → fix (say "unknown" where it's unknown).
- **decision** — the recommendation → why it wins → each rejected alternative with the concrete reason it lost → what would flip the call.
- **howto** — the outcome → prerequisites → numbered steps with exact, copy-pasteable commands and paths → the verification that proves it worked.
- **status** — where things stand → what changed, identifiers attached → what's blocked and on whom → the single next action.

For mixed content, pick the shape matching the reader's actual question.

## Hard rules

- Replacement, not critique: never reference the input or the conversation ("as mentioned above", "the original text said"). Conversation context enters as plain statements of fact.
- Lossless on substance: everything in the fact inventory survives. Keep hedges that encode real uncertainty — deleting them manufactures confidence. Cut hedging that carries no information, restated background, and tangents.
- Code, config, logs, commands, and quoted error text pass through verbatim.
- No invented facts or causal relationships.
- No preamble, no sign-off.

## Self-check

1. Does the opening make sense when first encountered, without relying on information introduced later?
2. Does each new statement connect to context the reader already has?
3. Is it clear why each important statement follows from the previous one?
4. Are all material facts, uncertainty, identifiers, and causal relationships preserved?
5. Is any jargon, shorthand, or compressed conclusion doing work that should be stated plainly?
6. Can anything be removed without losing meaning or logical continuity?

## Example

**Before** (a review finding; the PR number was known from the conversation, not the input — fold such context in as plain fact):

> The endpoint ships dark. Nothing publishes MODEL_CARD.md yet — the ai-workflow cookiecutter template doesn't include one and none of the 17 local ts-ai-workflow repos have one. Every real artifact will 404 on files/modelcard until publisher/template work lands. Worth confirming that sequencing is tracked on PLCR-4690.

**After:**

> PR #758 adds API support for serving `MODEL_CARD.md` from AI-workflow artifacts, but nothing currently publishes that file: the `ai-workflow` cookiecutter template does not generate it, and none of the 17 local `ts-ai-workflow` repositories contains one. As a result, `files/modelcard` will return 404s for real artifacts until the publisher/template work lands. Before approving, confirm that PLCR-4690 intentionally tracks that dependency and rollout sequence.

The reader is oriented (what the PR adds) before any conclusion; "ships dark" became a literal statement; the evidence (template + 17 repos) sits next to the claim it supports; the 404 consequence follows visibly from the cause; and every identifier survived.
