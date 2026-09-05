# .claude — Claude Code Port of the Agent System

## Purpose

Claude Code analog of the OpenCode agent system in `/.opencode/agents/`. Same roles and mediated workflow — global
orchestrator (`flow`), per-task orchestrator (`subflow`), executor (`player`), zero-tolerance reviewer (`coach`) —
expressed as Claude Code subagents in `agents/`.

## Ownership

- `agents/flow.md` — thin global orchestrator; composes a handoff per task and routes EVERY task to `subflow` via the
  Agent tool; never runs the mediated cycle itself
- `agents/subflow.md` — per-task ephemeral orchestrator; owns the whole mediated cycle (player → coach, N=N until
  APPROVE) and returns the approved result plus the handoff-file path
- `agents/player.md` — lazy executor; minimal code, zero scope creep; sole writer/reader of handoff files
- `agents/coach.md` — zero-tolerance reviewer; review only, no edit/write tools

## Local Contracts

### Source of truth

`/.opencode/agents/*.md` (OpenCode) is the reference implementation. Role bodies here mirror it; any behavior change
must land in both ports in the same change. This includes the prompt structure rules (terminal invariants, inline
`[PRIORITY:n]` markers, structure-first responses, core/reference split) — see `.opencode/AGENTS.md` for the full
contract.

### Session handoff (shared with the reference)

Fresh session per invocation, no resume — Claude Code's Agent tool has no resume/session-id parameter (verified in
v2.1.232 `AgentInput`), and the reference abandoned its resume path too, so both ports run the same rule: revision
prompts embed all prior coach findings verbatim (newest first), and inter-session context travels in a text handoff
file in the OS temp dir. `player` writes it on behalf of any write-less agent (a ROLE-level rule — `coach.md` here has
Bash, but the write stays player's); the next session's `player` reads it; orchestrators pass only the path plus their
own composed digest.

### Deliberate divergences from the OpenCode port

Dictated by the Claude Code subagent format (`.claude/agents/*.md` frontmatter):

- **`mode: primary/subagent` → separate frontmatter, shared body.** Claude Code has no `mode` field; `subflow.md` is a
  subagent purely by its `description` and by `flow.md` naming it in `tools: Agent(subflow, player, coach, Explore)`
  (registration ≠ invocability). `subflow.md`'s own allowlist omits self-recursion — `Agent(player, coach, Explore)`.
  Both files carry the same Claude-adapted flow core body (byte-identical after stripping frontmatter, mirroring the
  OpenCode byte-identity constraint) and share the reference tier at `.claude/reference/flow-reference.md`.
- **Reference tier lives in `.claude/reference/`, never in `agents/`.** Claude Code parses every `*.md` in `agents/`
  as an agent definition, so the core/reference split places `coach-reference.md` and `flow-reference.md` beside
  `agents/`, mirroring `.opencode/reference/`. Load triggers in the core bodies point at these paths, with
  `~/.claude/reference/` as the fallback for global installs (scripts install it there).
- **No `temperature`.** Claude Code frontmatter does not support it; the OpenCode per-role temperatures (flow 0.1, coach
  0.2, player 0.6) are dropped.
- **`permission` maps → `tools:` allowlists.** Delegation targets are restricted with the `Agent(a, b)` tool syntax;
  coach additionally has no Edit/Write, enforcing review-only. Flow's allowlist is explicit with no bare `*` wildcard
  (the `mcp__*` MCP passthrough remains, preserving MCP visibility for planning) and excludes
  Edit/Write/NotebookEdit/Bash — mirroring the reference's `edit: deny` + `bash: deny` for flow/subflow. The OpenCode
  `question`/`todowrite` removals map to Claude tool names `AskUserQuestion`/`TodoWrite` — neither appears in flow's
  `tools:` list.
- **Tool-layer enforcement lives only in the OpenCode port.** The OpenCode `permission:` maps physically enforce the
  deny-by-default allowlists (flow/subflow: `task`+`skill`+reference-scoped `read`, plus `question` on flow only).
  This port's `tools:` lists are NOT updated to mirror every OpenCode permission change — role behavior is carried by
  the prompt bodies, and the divergence is deliberate rather than drift.
- **Interactive question tool exists only in the OpenCode port.** The pre-implementation clarity gate in
  `.opencode/agents/flow.md` fires one batched round via the interactive `question` tool. This port has no such tool,
  so the same single round goes through the mediated fallback (player drafts → coach reviews → turn-ending delivery) —
  the ONLY case where flow delegates to player/coach itself; every task still routes to `subflow`. The
  one-round-per-top-level-request bound applies in both ports.
- **`@explore` → built-in `Explore` agent**, invoked via the Agent tool.
- **Flow calls Explore directly instead of via player for context-gathering.** The OpenCode reference now has flow
  delegating context-gathering to @explore directly via `subagent_type="explore"`. The Claude port mirrors this: flow
  calls the Explore agent directly (via `Agent(..., subagent_type="explore")`) rather than routing through player.
- **Delegation uses the `Agent` tool** (Claude Code's name for OpenCode's `task` tool); same
  `description`/`prompt`/`subagent_type` signature.
- **Frontmatter `description` is aligned with the reference** — all four (`flow`, `subflow`, `player`, `coach`) match
  `.opencode/agents/` verbatim.
- **MCP usage guidance synced from OpenCode reference** — flow delegates MCP work to player, player executes MCP tools,
  coach verifies via MCP. Both ports have equivalent guidance.

### Runtime notes

- Discovered automatically in this repo; install globally via `scripts/install.sh claude`.
- `flow` can run as the main session via `claude --agent flow`, or be invoked as a subagent.
- No other files belong in `agents/` — Claude Code parses every `*.md` there as an agent definition, which is why this
  doc lives one level up.

## Work Guidance

## Verification

## Child DOX Index
