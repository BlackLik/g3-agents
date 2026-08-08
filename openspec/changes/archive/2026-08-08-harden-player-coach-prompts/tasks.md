# Tasks: harden-player-coach-prompts

## 1. Lever 1 — terminal placement of role invariants

- [x] 1.1 Restructure `.opencode/agents/player.md`: make the closing non-negotiables block the terminal content,
  self-sufficient (implement only, return upward, never answer the user)
- [x] 1.2 Restructure `.opencode/agents/coach.md` the same way (review only, binary verdict, never edit files)
- [x] 1.3 Restructure `.opencode/agents/flow.md` the same way (delegate only, never answer the user directly, every
  response is a `task` tool call) and mirror the body byte-identically to `subflow.md`
- [x] 1.4 Mirror 1.1–1.3 in `.claude/agents/` in the same commit (Port Synchronization)

## 2. Lever 2 — explicit priority markers

- [x] 2.1 Add `[PRIORITY:1]` markers to every role invariant and `[PRIORITY:2]` to every workflow rule in
  `.opencode/agents/flow.md`, `player.md`, and `coach.md`, replacing prose-only hierarchy declarations; mirror flow's
  body to `subflow.md`
- [x] 2.2 Remove or rewrite any prose that contradicts a rule's marker; markers are authoritative
- [x] 2.3 Mirror in `.claude/agents/` in the same commit

## 3. Lever 3 — structure-first responses

- [x] 3.1 Add the structure-first rule to flow/subflow: every response is an actual `task` tool call with no plain-text
  preamble; reasoning lives inside the delegated prompt or is not emitted
- [x] 3.2 Add the structure-first rule to coach: review output opens with `## Summary` as first content; reasoning lives
  inside format sections
- [x] 3.3 Add the structure-first rule to player: return output opens with its mandated return structure
- [x] 3.4 Mirror in `.claude/agents/` in the same commit

## 4. Lever 4 — core/reference split for oversized prompts (coach and flow)

- [x] 4.1 Extract coach's bulk catalogs (AI-trace 5-category analysis, vulnerability catalog, anti-pattern catalog,
  worked examples) from `.opencode/agents/coach.md` into a coach reference-tier file
- [x] 4.2 Extract flow's bulk material (worked examples, failure-recovery examples, embedded player/coach role
  definitions) from `.opencode/agents/flow.md` into a flow reference-tier file; mirror the new core body
  byte-identically to `subflow.md`
- [x] 4.3 Reduce each core tier to at most ~10 discrete rules (flow: delegate-only, task-call-only, structure-first;
  coach: review-only, binary verdict, never edit code, structure-first) plus explicit triggers stating when to load
  the reference tier
- [x] 4.4 Mirror the split in `.claude/agents/` in the same commit

## 5. Closeout

- [x] 5.1 Update `.opencode/AGENTS.md` (prompt-structure rules: terminal invariants, markers, core/reference split for
  coach and flow) and `.claude/AGENTS.md` divergence list if any port differs
- [x] 5.2 Run `npx markdownlint-cli2` from the repo root — must pass with 0 errors
- [x] 5.3 Run `openspec validate harden-player-coach-prompts` and confirm the change is ready to archive
- [x] 5.4 Hand off to the user for manual self-check of role adherence across all four agents

## 6. Reference tier distribution

- [x] 6.1 Install/uninstall scripts (`install.sh`, `uninstall.sh`, `install.ps1`, `uninstall.ps1`) copy and remove the
  `reference/` dirs beside `agents/` for both ports, global and local targets
- [x] 6.2 Register the `agent-reference` alias in `opencode.jsonc` so OpenCode advertises the reference tier's resolved
  path and usage description into agent context
- [x] 6.3 Add installed fallback paths (`~/.config/opencode/reference/`, `~/.claude/reference/`) to the load triggers
  in all four core prompts; re-mirror `subflow.md` byte-identically
- [x] 6.4 Sync DOX for the new behavior: `scripts/AGENTS.md` file lists and path mapping, `.opencode/AGENTS.md` prompt
  structure rules, `.claude/AGENTS.md` divergence list
