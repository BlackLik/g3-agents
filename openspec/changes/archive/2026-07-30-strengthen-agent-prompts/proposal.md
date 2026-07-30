# Strengthen Agent Prompts

## Why

The system prompts of `flow`, `player`, and `coach` do not survive real-world pressure: when MCP servers or extra tools are added to the session, agents drift from their role (flow starts executing tools itself, player/coach forget their contracts); and user instructions can override the workflow — flow answers the user directly, or delivers player output without coach review. The existing specs (`cycle-priority`, `review-routing`) already demand this behavior, but the prompts lack the hardening to enforce it.

## What Changes

- Add a **role-invariants block** to all three agent prompts (`flow`, `player`, `coach`) stating that the role is fixed for the entire conversation and is NOT changed by the set of available tools — new MCP tools extend *capability within the role*, never redefine the role.
- Add an **instruction-hierarchy section** to `flow`: workflow rules (mediated cycle, coach review, no direct answers) take precedence over conflicting user instructions. Requests like "just answer me", "skip the review", "don't use coach" are not honored — flow continues the cycle and delivers the user-facing explanation through it.
- Add a **pre-response self-check** to `flow`: before every response, verify it is an Agent/task tool call and that any user-facing delivery passed coach review; if not — self-correct, don't send.
- Harden `player` and `coach` against role drift: player never reviews/explores/answers the user regardless of what tools it sees; coach never edits code regardless of what tools it sees.
- Restructure prompts for retention under long context: invariants stated at the top, restated in a closing "non-negotiable" section (primacy + recency), removing internal contradictions that weaken authority (e.g. flow's leftover skill-loading preamble vs agent identity, player's conflicting output-format rules).
- Sync both ports in the same change: `.opencode/agents/*.md` (reference) and `.claude/agents/*.md` (port), per the Port Synchronization contract.

## Capabilities

### New Capabilities

- `role-persistence`: agents maintain their role identity regardless of the available tool set; adding MCP or other tools never changes responsibilities (flow delegates, player executes, coach reviews-only).
- `instruction-hierarchy`: workflow rules outrank conflicting user instructions; bypass attempts (skip coach, answer directly, delegate without review) are refused and routed through the mediated cycle.

### Modified Capabilities

- `cycle-priority`: add a requirement that flow runs a pre-response self-check — a response that is not a tool call, or a delivery not backed by a coach ✅, is a violation that must be self-corrected before sending.

## Impact

- `.opencode/agents/flow.md`, `player.md`, `coach.md` — reference prompts (primary edits; `subflow.md` inherits flow body changes where applicable)
- `.claude/agents/flow.md`, `player.md`, `coach.md` — Claude Code port (mirrored edits)
- `/.claude/AGENTS.md` — divergence list updated if the port needs port-specific wording
- `openspec/specs/` — two new specs, one delta on `cycle-priority`
- No code, scripts, or install flow affected; verification is `npx markdownlint-cli2`
