# Design — tighten-agent-tool-permissions

## Context

The system ships two ports of the same role set: OpenCode (`.opencode/agents/*.md`, the reference
implementation, enforced via frontmatter `permission:`) and Claude Code (`.claude/agents/*.md`, prompt-mirrored,
frontmatter `tools:` lists not used for enforcement here). Bodies and permissions have drifted apart:

- **player** — body says "Bash for running things … Always show command output", frontmatter says `bash: deny`.
  Player literally cannot execute its own "run it, show the output" loop.
- **coach** — Step 0 says "run `git diff HEAD~1 HEAD`, `git diff --stat`, `git log --oneline -5`", frontmatter
  denies `bash`, `read`, and `grep`. Coach cannot see the diff it must review.
- **flow/subflow** — frontmatter is `'*': allow` minus a few denies; `lsp` is not denied, `question` leaks
  through the wildcard, `webfetch`/`websearch` are allowed even though the body says flow delegates all
  information gathering. The body line "You have no interactive question tool" is false at the tool layer.
- **docs** — `.opencode/AGENTS.md` describes an orchestrator allowlist (`task, list, skill, webfetch`) and
  "player has webfetch: allow" that match neither frontmatters nor bodies.
- **reference tier** — `reference/*.md` files sit behind `read: deny` for flow/subflow/coach, so the
  core/reference split cannot actually load its on-demand tier.

Two facts from the opencode source (`packages/opencode/src/agent/agent.ts`, `tool/edit.ts`) shape the design:

1. The built-in `explore` subagent already allows exactly `grep, glob, list, bash, webfetch, websearch, read`
   (everything else denied) — so explore can fetch web content, run `git diff`, and read files on behalf of
   the other agents. No custom explore agent is needed.
2. The `edit` tool does **not** require a prior `read` — so a hard `read: deny` on player/coach does not break
   their ability to edit files; content arrives via explore/cat output inside delegated prompts.

## Goals / Non-Goals

**Goals:**

- Tool layer enforces what the prompts already promise (no phantom capabilities, no missing ones).
- flow/subflow: minimal allowlist — `task` (restricted targets), `skill`, plus `question` at depth 0 only;
  explicit `lsp` deny; web tools denied (all information via `@explore`).
- player: terminal-first — `bash: allow`, `edit: allow`, `task` to `explore`/`player` only; everything else
  denied.
- coach: review-only — no `bash`/`edit`/`grep`/`glob`/`read` (except reference tier), `task` to
  `explore`/`coach` only; MCP passthrough kept for verification.
- One bounded pre-implementation `question` round at depth 0, with mediated fallback when no interactive tool
  exists (Claude port).
- Docs (`.opencode/AGENTS.md`, `.claude/AGENTS.md`) tell the truth after the change.

**Non-Goals:**

- Changing the Claude port's `tools:` frontmatter lists (enforcement divergence is documented instead).
- Adding a custom explore agent, or changing opencode's built-in explore.
- Any changes to `scripts/` install lists, `opencode.jsonc`, or runtime code.
- Reworking the retry-budget / escalation mechanics beyond adding the question gate.

## Decisions

### D1 — flow/subflow: `'*': deny` + explicit allowlist, `question` only at depth 0

**Choice:** Replace `'*': allow` with `'*': deny` and grant only `task`, `skill`, `question` (flow only), and a
reference-scoped `read`. Restrict `task` targets to `player`, `coach`, `explore`, `subflow`.

**Why:** The orchestrator's only outputs are delegations, review decisions, and (now) one question round.
Everything else — `bash`, `edit`, `grep`, `glob`, `list`, `webfetch`, `websearch`, `lsp`, `todowrite` — is
either forbidden by role or delegated. A deny-default makes the tool layer match the body, shrinks the tool
schema the model sees each turn, and removes the `lsp` hole. `question` is granted to flow (depth 0) only;
subflow always runs at depth ≥1 and stays without it, so user interaction cannot fan out from nested
orchestrators.

**Alternatives considered:** keep `'*': allow` and add more denies — rejected: wildcard keeps leaking future
tools and inflates schemas. Keep the "no interactive question tool" fiction — rejected: the body would keep
lying and the clarity gate could not exist.

### D2 — player: `bash: allow` + `task` restricted to `explore`/`player`, keep `'*': allow` for MCP

**Choice:** Add `bash: allow`, keep `edit: allow`, restrict `task` to `explore` and `player`. Deny `read`,
`grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, `skill`, `question`, `todowrite`. Keep `'*': allow` so
MCP tools still pass through.

**Why:** "Writes only code, works through the terminal." Bash is how player runs/verifies code and does
pinpoint viewing of files already named by the task or by explore (`cat`, `sed -n`). Broad search stays with
`@explore`. Denying `read`/`grep`/`glob`/`webfetch`/`websearch` removes duplicate surfaces that pull raw files
into player's context (token economy) and matches the explore-first rule already in the body. `read: deny` is
safe because opencode's `edit` does not require a prior read. MCP passthrough is preserved because player is
the designated MCP executor.

**Alternatives considered:** also deny MCP (flip to `'*': deny`) — rejected: breaks the documented
"player executes MCP" contract. Allow `read` for reference files — unnecessary: player has no reference tier.

### D3 — coach: no bash/grep/glob/read; diff arrives via `@explore`; MCP passthrough kept

**Choice:** Deny `edit`, `bash`, `grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, `skill`, `question`,
`todowrite`. Allow `task` to `explore`/`coach` only, and a reference-scoped `read`. Keep `'*': allow` so MCP
verification tools still pass through.

**Why:** Coach's job is verdicts, not execution. Step 0's `git diff`/`git log` is read-only shell work —
exactly what the built-in `explore` (bash allowed) can do. So coach asks explore once ("run `git diff …`,
return verbatim"), then runs the A–E detection categories over the diff text in its own context. Beyond-diff
context is one aggregated explore query. Removing `bash` also closes the "coach runs mutating commands" hole.
MCP is kept because coach verifies player's MCP claims by re-running them (verification, not mutation).

**Alternatives considered:** let coach keep `bash` just for `git diff` — rejected: unscoped bash is a bigger
surface than the single use case justifies, and explore already covers it. Drop MCP (`'*': deny`) — rejected:
kills the documented MCP-verification capability.

### D4 — Pre-implementation clarity gate: one bounded `question` round at depth 0

**Choice:** After the analysis phase (and any explore pass), before the first `@player` delegation: if flow is
materially blocked — ambiguous success criteria, a destructive/irreversible choice, or missing access — it asks
**one** round via the `question` tool. This is the single sanctioned exception to "every response is a task
call". Escalations (retry-budget exhaustion) stay mediated. When no interactive question tool exists (Claude
port), the round goes through the mediated cycle as before.

**Why:** Guessing wrong on ambiguous tasks wastes far more tokens than one upfront question. Bounding to one
round at depth 0 keeps it from becoming an interrogation and stops nested subflows from each firing questions.

**Alternatives considered:** assumptions-only (status quo) — rejected: that's the token waste the user wants
to remove. Questions at every depth — rejected: question storms from nested orchestrators.

### D5 — Reference tier reachable via scoped `read`

**Choice:** Grant flow/subflow/coach `read: { '*': deny, '*/reference/*.md': allow }`.

**Why:** The core/reference split only works if those agents can load their on-demand tier. A narrow path
grant reaches the files without opening general file reading. The opencode `references` config already
whitelists these dirs for `external_directory`, so the grant works for global installs too.

**Alternatives considered:** route reference loading through `@explore` — rejected: adds a task hop and
~12–16 KB through explore's context on every load for no real isolation gain. Open `read` fully — rejected:
reintroduces the raw-file context bloat the deny is meant to prevent.

### D6 — Body + docs updates in both ports; subflow body stays byte-identical to flow

**Choice:** Edit flow/subflow/player/coach bodies in both ports with the new rules (question gate,
explore-routed info gathering, player terminal-first, coach explore-sourced diff, A–E over diff text). Update
reference tiers ("scan the diff text for…", add a question-gate worked example). Rewrite
`.opencode/AGENTS.md`'s "Orchestrator tool restriction" and add the gate; record divergences in
`.claude/AGENTS.md` (enforcement only in opencode port; interactive question tool only in opencode port).
`subflow.md` body remains byte-identical to `flow.md`.

**Why:** Prompt structure rules and port-sync require both ports to carry the same role behavior; DOX requires
docs to reflect the new contracts.

## Risks / Trade-offs

- **Player can't `read` a file it wasn't told about** → Mitigation: task prompts and explore already name
  targets; `cat`/`sed -n` via bash covers pinpoint viewing; anything broader is a new explore query.
- **Coach depends on explore returning the full diff verbatim** → Mitigation: the delegation explicitly asks
  for verbatim output; explore's `bash`/`read` allow it. Large diffs already get split by concern at depth.
- **`question` at depth 0 could be overused** → Mitigation: hard cap of one round per top-level request, only
  when materially blocked; assumptions-first remains the default.
- **Scoped `read` glob (`*/reference/*.md`) might not match an unusual install path** → Mitigation: pattern
  matches the installed layout (`<base>/reference/*.md`); verified against the `references` whitelist.
- **`.claude` port gains rules without tool enforcement** → Mitigation: documented as a deliberate divergence;
  prompt-level rules still apply.

## Migration Plan

No runtime/data migration. Steps: update the four opencode frontmatters; edit the four bodies in both ports;
update both reference tiers; DOX-pass both AGENTS.md files. Rollback = revert the commit. Existing installed
copies update on next `scripts/install.sh` run.

## Open Questions

- None blocking. (Resolved: reference loading → scoped `read`, D5; coach MCP → kept, D3.)
