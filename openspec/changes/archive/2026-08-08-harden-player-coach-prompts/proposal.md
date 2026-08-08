# Proposal: harden-player-coach-prompts

## Why

The whole mediated system — `@flow`/`@subflow` orchestration plus the player→coach pair — depends on small/cheap models
obeying role invariants ("flow never answers directly", "player never answers the user directly", "coach never writes
code"), and today those invariants break under adversarial or merely long prompts. Instruction-following research (SIFo,
IFScale, Instruction Stacking Collapse, Control Illusion, IFEval CoT studies) identifies three measurable causes that
all apply to our current prompts: positional decay (rules far from the generation point are forgotten), non-linear
follow-rate collapse as the number of simultaneous rules grows (~96% at 1 rule → 20–60% at 20 rules), and
chain-of-thought actively harming simple structural constraints. Every agent prompt is in the degradation zone:
`coach.md` and `flow.md` are both 500+ lines with 20+ normative rules, invariants placed mid-document, and priority
expressed only in prose.

## What Changes

- Move the role-invariants / non-negotiables block to the terminal position of all four agent prompts (`flow.md`,
  `subflow.md`, `player.md`, `coach.md`) in both ports, so the critical rules sit immediately before the generation
  point.
- Split `coach.md` and `flow.md` (both 500+ lines) into a core prompt (always loaded role-critical rules) and a
  reference tier loaded on demand, capping the number of simultaneously active normative rules; `subflow.md` inherits
  flow's split mechanically (byte-identity constraint).
- Replace prose-only priority declarations ("Level 1 > Level 2 > ...") with explicit inline priority markers (e.g.
  `[PRIORITY:1] Never write or edit code.`) attached to each rule in every agent prompt, starting with role
  invariants.
- Require structure-first responses for constrained outputs: flow's response IS a `task` tool call with no plain-text
  preamble; coach reviews and player returns open directly with the mandated structure (e.g. `## Summary`), with no
  free-form reasoning before it.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `role-persistence`: Requirements change from "invariants appear near the top and are restated at the end" to
  terminal-placement across all agent prompts, add a prompt-size budget with a core/reference split for the oversized
  prompts (coach, flow), and add structure-first response rules for constrained outputs.
- `instruction-hierarchy`: The prose-declared priority levels gain mandatory explicit inline priority markers on each
  rule in every agent prompt; the hierarchy expression becomes machine-checkable rather than paragraph-shaped.

## Impact

- **Prompts**: all four agent prompts — `.opencode/agents/{flow,subflow,player,coach}.md` and the `.claude/agents/`
  port. Every role-body change must land in both ports in the same commit per Port Synchronization, and every
  `flow.md` edit must keep `subflow.md` byte-identical.
- **Specs**: modified deltas for `role-persistence` and `instruction-hierarchy`.
- **Distribution**: install/uninstall scripts (both `.sh`/`.ps1` pairs) install and remove the reference tier beside
  `agents/` for both ports (global and local targets); `opencode.jsonc` registers the `agent-reference` alias so
  OpenCode advertises the tier's resolved path and usage description into agent context.
- **DOX**: `.opencode/AGENTS.md` (prompt structure rules), `.claude/AGENTS.md` (divergence list), `scripts/AGENTS.md`
  (file lists, path mapping) and root `AGENTS.md` updated where prompt structure rules or the child index change;
  `npx markdownlint-cli2` must pass.
- **Verification**: no automated benchmark — the user self-checks role adherence after implementation.
- **No breaking changes** to the delegation architecture, tool permissions, or the mediated cycle itself — this change
  hardens how existing rules are expressed.
