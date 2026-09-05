# Design — fix-agent-tool-allowlists

## Context

Claude Code `tools:` frontmatter is allowlist-only (no deny mechanism, no path scoping), while the OpenCode reference
uses permission maps with per-tool denies. Porting OpenCode's `'*': allow` + deny-list for coach/player apparently
became "explicit list + trailing `*`" — but in Claude Code a bare `*` grants every tool, so both agents currently run
with ALL tools. For player that is close to intended (player is the broad-tool executor). For coach it defeats the
review-only contract: Edit/Write are live, and `.claude/AGENTS.md` falsely documents them as absent.

Current lines:

- `coach.md`: `tools: Read, Bash, Glob, Grep, WebFetch, WebSearch, Skill, Agent(Explore, coach), *`
- `player.md`: `tools: Read, Edit, Write, Bash, Glob, Grep, WebFetch, WebSearch, Skill, Agent(Explore, player), *`

OpenCode reference for coach (net effect of its permission map): task(explore, coach) + read of `*/reference/*.md` +
MCP; `bash`, `edit`, `grep`, `glob`, `webfetch`, `websearch`, `skill` all denied. Coach's shared body already forbids
the same at prompt level ("Review work uses no `bash`/`git`, `grep`, or broad file reads of your own") and routes
exploration through Explore delegation.

## Goals / Non-Goals

**Goals:**

- Coach review-only enforced at the tool layer in the Claude port, mirroring the OpenCode reference denies.
- No bare `*` wildcard in any agent allowlist; MCP passthrough only via the narrow `mcp__*` pattern flow already uses.
- `.claude/AGENTS.md` divergence list and session-handoff note match reality.

**Non-Goals:**

- No body changes in either port (bodies already state the rules; only enforcement changes).
- No OpenCode file changes (already compliant; the spec codifies it as the reference).
- No change to player's `Read`/`Glob`/`Grep`/`WebFetch`/`WebSearch`/`Skill` — the reference denies read/grep/glob for
  player, but that divergence predates this fix and changing it alters player's working style. Left as-is.
- No change to flow/subflow (already covered by `orchestrator-tool-restriction` / `flow-subflow-tool-restriction`).

## Decisions

- **Coach allowlist = `Read, Agent(Explore, coach), mcp__*`.** Drop `Bash`/`Glob`/`Grep`/`WebFetch`/`WebSearch`/
  `Skill` along with `*`, not just `*`: each of these is denied for coach in the OpenCode reference, and the shared
  body already forbids their use, so keeping them would preserve a port divergence with zero function. Alternative
  considered — remove only `*` and keep the old explicit list — rejected: leaves Bash, which can mutate files, so
  "review-only at the tool layer" would still be false.
- **Keep `Read` unscoped.** Claude `tools:` cannot express the reference's `read: */reference/*.md`-only grant. Coach
  needs Read for its reference tier (`.claude/reference/coach-reference.md`) and for inspecting diffs/files under
  review. Documented as a divergence.
- **Keep `mcp__*` on coach.** The reference's `'*': allow` base permits MCP tools, and the synced "MCP usage" guidance
  expects coach to verify player's MCP claims. Role invariants (PRIORITY:1, role does not change with tool list) guard
  against MCP write misuse — same guard the reference relies on.
- **Player: `*` → `mcp__*` only.** Minimal fix; player is the intended broad-tool executor, so the explicit list
  stays. The bare `*` is replaced with the same narrow MCP passthrough flow uses, keeping MCP reachable without an
  all-tools grant.
- **Update `.claude/AGENTS.md` in the same change** (Port Synchronization rule): rewrite the "permission maps →
  tools allowlists" divergence bullet to state the new coach allowlist and the unscoped-Read divergence, and fix the
  session-handoff parenthetical that says "`coach.md` here has Bash" (it no longer will; the player-writes-handoffs
  rule becomes tool-enforced for coach, not just ROLE-level).

## Risks / Trade-offs

- [Coach can no longer run `git diff` itself] → Already the documented workflow: the diff arrives in the review
  handoff, and history/context gathering is delegated to Explore (the body's own worked example). No behavior change
  for a compliant coach; a non-compliant one now fails closed.
- [MCP tools may include write-capable operations] → Unchanged from the reference design; guarded by PRIORITY:1 role
  invariants and the MCP-verification-only rule in the body. Tool-layer denial of MCP writes is not expressible with
  `mcp__*` granularity without enumerating servers; out of scope.
- [Unscoped Read is wider than the reference's reference-tier-only read] → Accepted platform limitation, recorded in
  the divergence list. Read is non-mutating, so review-only is preserved.
- [Docs drift] → The change touches `.claude/AGENTS.md` in the same commit; markdownlint gate stays at 0 errors.
