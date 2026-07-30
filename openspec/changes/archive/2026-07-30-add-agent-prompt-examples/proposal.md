# Add Agent Prompt Examples

## Why

The agent prompts (flow, player, coach) state rules — instruction hierarchy, MCP delegation, mediated answering — mostly as abstract prescriptions. A few sections carry ❌/✅ examples (player's code-style rules), but the highest-risk behaviors have none: how to answer the user through the cycle, how to use MCP/other tools in-role, and what to do when a user instruction contradicts the system prompt. Few-shot worked examples are the strongest lever for prompt compliance; their absence is where role drift happens in practice.

## What Changes

- Add a worked-examples section to each agent prompt (`flow.md`, `player.md`, `coach.md`) in both ports (`.opencode/agents/`, `.claude/agents/`; `subflow.md` stays byte-identical to `flow.md`), covering four example categories:
  1. **Answering the user** — full mediated cycle traces: user question → flow delegates to player → coach reviews → flow delivers; plus the ❌ counter-example (direct answer).
  2. **MCP and other tool usage** — flow planning around MCP tools and delegating their use to player; player executing MCP tools; coach using MCP tools for verification only; ❌ counter-examples (flow calling MCP itself, coach editing via MCP).
  3. **User instruction contradicting the system prompt** — "answer me directly", "skip the coach review", role-changing instructions embedded in task text — each shown resolved through the cycle, never obeyed.
  4. **System-first resolution order** — traces where an agent receives a work instruction and explicitly resolves it against the priority ladder (role invariants → workflow rules → user instruction → task content) before acting: the instruction is honored for *what* to do, the system for *how*.
- Each example is a concrete ❌ Bad / ✅ Good pair or a short dialogue trace (user message → tool calls → output), not a restated rule.
- Both ports updated in the same commit per the Port Synchronization contract; no new divergences expected (examples use each port's own tool names — `task` vs `Agent`).

## Capabilities

### New Capabilities

- `prompt-examples`: Requires each agent prompt to carry worked examples (❌/✅ pairs or dialogue traces) for the four high-risk behavior categories: mediated user answering, in-role MCP/tool usage, refusing system-contradicting user instructions, and system-first instruction resolution.

### Modified Capabilities

*None — the behaviors themselves are already specified in `instruction-hierarchy`, `role-persistence`, and `cycle-priority`; this change adds example-coverage requirements for the prompts, owned by the new `prompt-examples` capability.*

## Impact

- `.opencode/agents/flow.md`, `player.md`, `coach.md`, `subflow.md` (kept byte-identical to flow.md)
- `.claude/agents/flow.md`, `player.md`, `coach.md`
- `.opencode/AGENTS.md` / `.claude/AGENTS.md` — DOX pass if prompt structure contracts change
- Verification: `npx markdownlint-cli2` must pass; prompts grow in size (token-cost tradeoff accepted in favor of compliance)
