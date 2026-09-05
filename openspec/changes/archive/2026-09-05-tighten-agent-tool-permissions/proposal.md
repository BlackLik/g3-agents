# Proposal — tighten-agent-tool-permissions

## Why

Agent permissions and prompt bodies in the OpenCode port are out of sync with the actual tool layer, and the
mismatch costs both correctness and tokens:

- `player` is instructed to "run it — show the output" via bash, but its frontmatter sets `bash: deny`, so it
  physically cannot run or verify anything it writes.
- `coach`'s Step 0 says to run `git diff HEAD~1 HEAD`, `git diff --stat`, `git log`, yet `bash`, `read`, and
  `grep` are all denied — coach cannot obtain the diff it exists to review.
- `flow`'s frontmatter has no `lsp: deny`, no `question: allow`, and no explicit deny for `webfetch`/`websearch`;
  the body claims "You have no interactive question tool" while `question` leaks through the `'*': allow`
  wildcard. Every wasted tool in the allowlist also inflates the tool schemas the model sees every turn.
- `.opencode/AGENTS.md` describes an orchestrator allowlist (`task, list, skill, webfetch`) that does not match
  the real frontmatters — the docs lie.
- Reference-tier files (`reference/*.md`) are unreachable under `read: deny`, so the core/reference split cannot
  function as designed without a workaround.

Verified against opencode source (`packages/opencode/src/agent/agent.ts`): the built-in `explore` subagent
already has exactly the tool surface this change wants (`grep/glob/list/bash/webfetch/websearch/read` allowed,
everything else denied), and opencode's `edit` tool does not require a prior `read` — so a hard `read: deny` on
player/coach is safe.

## What Changes

- **flow** (opencode): `'*': deny` base; allow only `task` (restricted to `player`, `coach`, `explore`,
  `subflow`), `skill`, and `question`. Narrow `read` grant limited to `*/reference/*.md`. Explicit denies for
  `lsp`, `webfetch`, `websearch`, `todowrite`, `bash`, `edit`, `grep`, `glob`, `list`.
- **subflow** (opencode): identical to flow but **without** `question` — user-facing questions happen only at
  depth 0.
- **player** (opencode): keep `'*': allow` (MCP passthrough), add `bash: allow` (terminal-first execution),
  keep `edit: allow`, restrict `task` to `explore`/`player` only. Deny `read`, `grep`, `glob`, `list`, `lsp`,
  `webfetch`, `websearch`, `skill`, `question`, `todowrite`.
- **coach** (opencode): keep `'*': allow` for MCP verification; restrict `task` to `explore`/`coach` only.
  Deny `edit`, `bash`, `grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, `skill`, `question`,
  `todowrite`. Narrow `read` grant limited to `*/reference/*.md`.
- **flow/subflow/player/coach bodies** (both ports): add a pre-implementation clarity gate — after the
  analysis phase, one bounded `question` round at depth 0 when materially blocked (ambiguous success criteria,
  destructive choice, missing access). This is the single exception to "every response is a task call";
  escalations stay mediated. Remove the false "You have no interactive question tool" line.
- **flow/subflow bodies** (both ports): route all information gathering — codebase *and* web
  (webfetch/websearch) — through `@explore`; flow itself has no information tools.
- **player body** (both ports): "writes only code, works through the terminal" — bash for running things and
  for pinpoint viewing of already-named files (`cat`/`sed -n`); any broad search goes through `@explore`.
- **coach body** (both ports): Step 0 rewritten — obtain `git diff`/`git log` via one `@explore` task; run the
  A–E detection categories over the diff text in coach's own context; any beyond-diff context is one
  aggregated `@explore` query.
- **reference tiers** (`coach-reference.md`, both ports): "Grep for …" wording → "scan the diff text for …";
  `flow-reference.md` (both ports): add a worked example for the question gate.
- **`.opencode/AGENTS.md`**: rewrite "Orchestrator tool restriction" to the real allowlist; drop the stale
  "player has webfetch: allow"; document the question gate and coach's explore-only diff access.
- **`.claude/AGENTS.md`**: record the divergences — tool enforcement lives only in the opencode port
  (`tools:` lists unchanged); the interactive question tool exists only in the opencode port, so the Claude
  port's question round still goes through the mediated cycle.
- **`.claude/agents/*.md`**: mirror the same body changes with Agent-tool naming; frontmatters unchanged.

## Capabilities

### New Capabilities

- `clarity-gate`: Pre-implementation clarification via the interactive `question` tool at depth 0, bounded to
  one round, with mediated fallback when no interactive tool exists.

### Modified Capabilities

- `orchestrator-tool-restriction`: allowlist becomes `task` (restricted targets) + `skill` + `question` +
  reference-scoped `read`; `lsp`/`webfetch`/`websearch` denied; body claims and docs made truthful.
- `context-delegation`: web information gathering also delegates to `@explore`; flow holds no information
  tools.
- `coach-fresh-review`: Step 0 obtains the diff via `@explore`; A–E detection runs over the diff text in
  coach's context.

## Impact

- `.opencode/agents/flow.md`, `subflow.md`, `player.md`, `coach.md` — frontmatter permissions + body edits
  (flow/subflow bodies stay byte-identical).
- `.claude/agents/flow.md`, `player.md`, `coach.md` — mirrored body edits only.
- `.opencode/reference/flow-reference.md`, `coach-reference.md` and `.claude/reference/*` — wording/worked
  example updates.
- `.opencode/AGENTS.md`, `.claude/AGENTS.md` — contract and divergence updates (DOX pass).
- `scripts/` install lists unchanged; `opencode.jsonc` unchanged; no runtime code changes.
