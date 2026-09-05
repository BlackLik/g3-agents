# Fix agent tool allowlists (coach/player, Claude port)

## Why

The `tools:` allowlists of `.claude/agents/coach.md` and `.claude/agents/player.md` end with a bare `*` wildcard, which
grants ALL tools and makes the explicit list before it meaningless. For coach this silently grants Edit/Write —
directly contradicting the documented divergence ("coach additionally has no Edit/Write, enforcing review-only" in
`.claude/AGENTS.md`) and coach's own "read-only in effect" description. Review-only is currently enforced by prompt
text alone, not at the tool layer.

## What Changes

- **coach (Claude port)**: replace the allowlist with a tool-layer review-only set — `Read, Agent(Explore, coach),
  mcp__*`. This removes the bare `*` and drops `Bash`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Skill`, aligning with
  the OpenCode reference (which denies `bash`, `edit`, `grep`, `glob`, `webfetch`, `websearch`, `skill` for coach) and
  with coach's own body rule ("Review work uses no `bash`/`git`, `grep`, or broad file reads of your own").
- **player (Claude port)**: replace the trailing bare `*` with `mcp__*` (the same MCP passthrough pattern flow already
  uses). The rest of player's explicit list is unchanged.
- **`.claude/AGENTS.md`**: update the "Deliberate divergences" bullet on permission maps → tools allowlists, and the
  session-handoff parenthetical that currently states "`coach.md` here has Bash".
- **OpenCode port**: no file changes — its permission maps already enforce these restrictions; the new spec codifies
  them as the reference the Claude port mirrors.
- Explicitly out of scope: player's `Read`/`Glob`/`Grep` availability in the Claude port (the OpenCode reference denies
  them for player). That is a pre-existing, separate divergence; changing it would alter player's working style and is
  not part of this fix.

## Capabilities

### New Capabilities

- `coach-player-tool-restriction`: tool-layer allowlists for the non-orchestrator subagents — coach is review-only at
  the tool layer in both ports (no edit/write/bash-capable tools; delegated exploration via Explore; MCP for
  verification only), and player's Claude-port allowlist is explicit with an `mcp__*` passthrough instead of a bare
  `*` wildcard.

### Modified Capabilities

None — no existing spec covers coach/player tool allowlists (`orchestrator-tool-restriction` and
`flow-subflow-tool-restriction` cover flow/subflow only), and their requirements are unchanged.

## Impact

- `.claude/agents/coach.md` — frontmatter `tools:` line only; body untouched.
- `.claude/agents/player.md` — frontmatter `tools:` line only; body untouched.
- `.claude/AGENTS.md` — divergence list and session-handoff note updated to match.
- `.opencode/**` — untouched (already compliant; source of truth for the restriction).
- Runtime effect: coach sessions lose the ability to mutate files or run shell commands at the tool layer; coach's
  handoff writes already route through player (ROLE-level rule), so no workflow breaks. Player keeps MCP access via
  `mcp__*`.
- Verification: `npx markdownlint-cli2` must stay at 0 errors.
