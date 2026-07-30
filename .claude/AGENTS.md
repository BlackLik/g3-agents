# .claude — Claude Code Port of the Agent System

## Purpose

Claude Code analog of the OpenCode agent system in `/.opencode/agents/`. Same roles and mediated workflow — orchestrator (`flow`), executor (`player`), zero-tolerance reviewer (`coach`) — expressed as Claude Code subagents in `agents/`.

## Ownership

- `agents/flow.md` — orchestrator; delegates via the Agent tool, recurses into itself for complex tasks
- `agents/player.md` — lazy executor; minimal code, zero scope creep
- `agents/coach.md` — zero-tolerance reviewer; review only, no edit/write tools

## Local Contracts

### Source of truth

`/.opencode/agents/*.md` (OpenCode) is the reference implementation. Role bodies here mirror it; any behavior change must land in both ports in the same change.

### Deliberate divergences from the OpenCode port

Dictated by the Claude Code subagent format (`.claude/agents/*.md` frontmatter):

- **No `subflow.md`.** Claude Code has no per-file `mode: primary/subagent` split and allows nested Agent calls, so `flow` recurses into itself (`Agent(flow, player, coach, explore)`). Depth rules (terminal at `depth: 2`) are unchanged and tracked via `(depth: N)` in prompts.
- **No `temperature`.** Claude Code frontmatter does not support it; the OpenCode per-role temperatures (flow 0.1, coach 0.2, player 0.6) are dropped.
- **`permission` maps → `tools:` allowlists.** Delegation targets are restricted with the `Agent(a, b)` tool syntax; coach additionally has no Edit/Write, enforcing review-only.
- **`@explore` → built-in `Explore` agent**, invoked via the Agent tool.
- **Flow calls Explore directly instead of via player for context-gathering.** The OpenCode reference now has flow delegating context-gathering to @explore directly via `subagent_type="explore"`. The Claude port mirrors this: flow calls the Explore agent directly (via `Agent(..., subagent_type="explore")`) rather than routing through player.
- **Delegation uses the `Agent` tool** (Claude Code's name for OpenCode's `task` tool); same `description`/`prompt`/`subagent_type` signature.
- **`flow.md` drops the skill-loading preamble** ("Load this skill FIRST" block, "activates this skill" wording) — here it is an agent definition, not a skill. The port also removes the `🎯 Orchestrator:` visual-prefix convention throughout the body (Self-Correction Protocol, Tool Call Enforcement) — delegation is enforced via Agent tool calls only.
- **Frontmatter `description` is port-owned** — may diverge from the reference.
- **MCP usage guidance synced from OpenCode reference** — flow delegates MCP work to player, player executes MCP tools, coach verifies via MCP. Both ports have equivalent guidance.

### Runtime notes

- Discovered automatically in this repo; install globally via `scripts/install.sh claude`.
- `flow` can run as the main session via `claude --agent flow`, or be invoked as a subagent.
- No other files belong in `agents/` — Claude Code parses every `*.md` there as an agent definition, which is why this doc lives one level up.

## Work Guidance

## Verification

## Child DOX Index
