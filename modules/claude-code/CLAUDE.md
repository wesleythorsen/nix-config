# Working with Wes

Work-specific facts (employer, identifiers, repos, environments, status scripts) live in the project's own CLAUDE.md. This file holds only how Wes wants Claude to work, anywhere.

These are guidelines. Deviate when there is a good reason, and say so in one line.

## Output contract

- Lead with the answer. Status questions get at most 8 lines, one fact per line, then stop; explanation only when asked.
- A reader with no prior context must be able to follow: first mention of any PR, ticket, service, acronym, or coined label carries a 3–6 word gloss.
- Every PR, ticket, or document reference is a markdown link; the ticket key sits beside each PR. Bullets use `*`. Real headings or none, never bold pseudo-headings.
- Lists of PRs for people: `1. [TICKET-123](ticket-url): title` then `   * [repo PR #N](pr-url)`. Standup: one `*` bullet per ticket, 3–6 words, grouped Done / In review / Next / Blocked, tracker status verified first.
- Drafts for coworkers: name the audience in one word (team / company / manager / reviewer), then the full draft inline, sized to that audience. Plain English, no apologies, no cleverness. Reprint the full draft whenever asked; never point to "above".
- A newly found release gap (missing backport, unfixed consumer) is its own message headed `NEW GAP:` with the evidence command, repeated at the top of every status until a PR exists.
- Text that will be read aloud: no tables, conversational sentences.

## Verification before any claim

- "Ready", "merged", "done", "safe to post", "nothing left": run the project's status and readiness checks first and cite the output. CI green is not the gate; zero unresolved review threads is.
- Any list of "all" PRs, consumers, or branches is derived with paginated queries at answer time, never recalled from earlier in the session or from memory.
- Label external-state claims `verified (<command>)` or `unverified`. "Tested" means exercised in a deployed environment, not unit tests.
- A PR Claude wrote goes to the team only after: a high-effort self-review with company context considered, every bot review thread fixed or answered with the reason and resolved, and coworker threads left for the coworker to resolve.
- Before a bulk ticket change, print one line per ticket (key · current → proposed · evidence) and wait. A Claude-scaffolded draft PR is not "In Progress"; keep one ticket In Progress per workstream.

## Permissions

- Always fine: reading anything, local edits, tests, commits, worktrees, pushing to Wes's own PR branches, fixing review comments, opening draft PRs, ticket status transitions and field edits on Wes's own tickets after the per-ticket line above, read-only CLI calls.
- Show the exact text or action and wait for a yes: chat sends, ticket/PR/wiki comments or page edits, ticket creation, email sends, flipping a PR to ready, merges, anything on other people's tickets, branches, or PRs. The permission prompt is that question; answer it with the full text visible.
- Never add or change text after Wes approved a draft. If a standing rule requires an addition, it is in the draft he sees.
- Attribution: GitHub and ticket comments Claude posts end with `*Drafted with AI assistance · reviewed, revised, and approved by Wes*`. Chat posts carry no attribution line (the chat client labels them). Messages Wes sends himself carry none.

## Tooling

- Preload MCP tools in one ToolSearch `select:` call.
- Ask tracker and wiki APIs for explicit fields; ask chat APIs for concise output; meeting notes: summaries first, full transcripts only on request.
- First `permission_error` or 403 from a claude.ai connector: stop retrying that server, say "reconnect <server> in /mcp", and continue with the other sources.
- The shell is zsh with aliases: `ls` is eza, `find` is bfs, `=`-expansion is on, no word splitting. Write loops as `bash -c '…'`, avoid `==`/`===` tokens, quote globs.
- Append every posted URL, ticket transition, PR state change, and decision to `~/.claude/handoffs/<yyyy-mm-dd>-<topic>.md` as it happens; answer "where are we" from that file plus the project's status script, not from recall.
