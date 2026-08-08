# Design

## Context

`flow` (primary) and `subflow` (subagent) are the orchestrators of the mediated agent system. Their prompts strictly forbid writing code, editing files, and running commands — but their frontmatter grants `permission: '*': allow`, so the prohibition is soft. Under skill/MCP context pressure (documented failure mode: skill-induced role capture) or with smaller models, the orchestrator can execute work itself, bypassing the player → coach cycle. The OpenCode SDK permission schema supports per-agent `allow`/`ask`/`deny` actions for `edit`, `bash`, `read`, `task`, and others — so the boundary can be enforced at the tool layer instead of relying on prompt compliance alone.

## Goals / Non-Goals

**Goals:**

- Make it *impossible* (tool-layer denial) for `flow`/`subflow` to modify files or run shell commands — execution becomes physically available only via `@player`
- Keep delegation (`task` tool), read-only tools (`read`/`grep`/`glob`), `skill`, `todowrite`, and `webfetch` fully available — the restriction must not break orchestration
- Preserve byte-identical prompt bodies between `flow.md` and `subflow.md` (frontmatter-only change)
- Mirror the restriction in the Claude port using its own enforcement mechanism (`tools:` allowlist)

**Non-Goals:**

- Denying read tools for the orchestrator — explore-first delegation stays prompt-level; hard-denying reads would break legitimate needs (loading skill files, reading the AGENTS.md chain, verifying delegated artifacts)
- Changing player, coach, or explore permissions — player keeps full execution rights, coach keeps its existing setup
- Prompt-body rewrites — the bodies already prohibit self-execution; this change only hardens enforcement

## Decisions

### 1. Enforce via `permission` map (`edit: deny`, `bash: deny`), not via `tools: false`

Frontmatter becomes:

```yaml
permission:
    '*': allow
    edit: deny
    bash: deny
```

**Rationale:** the `permission` block is the mechanism these files already use; `edit: deny` gates all file-modifying tools (edit/write/patch) and `bash: deny` gates shell execution, while every other tool stays allowed under the wildcard. A denial gives the model immediate, unambiguous feedback that execution is unavailable and it must delegate instead. (Verified at implementation time against OpenCode v1.18.10: denied tools are pruned from the model's tool schema, so a direct attempt surfaces as "tool unavailable"; delegation and read-only tools remain.)

**Alternative considered:** `tools: { edit: false, write: false, patch: false, bash: false }` — removes the tools from the model's tool list entirely. Rejected: the model loses visibility of why execution is unavailable (risking confused retry loops or workarounds), the diff is larger and less declarative, and keeping tools *visible but denied* is consistent with the role-persistence principle that flow keeps tool *awareness* for planning while never executing.

### 2. Scope of denial: exactly `edit` + `bash`, nothing else

Only file modification and shell execution are denied. `task` (delegation), `read`/`grep`/`glob` (read-only), `skill`, `todowrite`, `question`, and `webfetch` remain allowed. This matches the user's request precisely and keeps the restriction minimal — the narrower the denial set, the smaller the risk of breaking orchestration mechanics.

### 3. Claude port: explicit `tools:` allowlist, drop the `*` wildcard

Claude Code subagent frontmatter has no permission map, so the equivalent enforcement is an explicit allowlist. `.claude/agents/flow.md` changes from `tools: Agent(flow, player, coach, Explore), *` to:

```yaml
tools: Agent(flow, player, coach, Explore), Read, Glob, Grep, WebFetch, WebSearch, Skill, TodoWrite, mcp__*
```

Edit, Write, NotebookEdit, and Bash are simply absent — the tools are unavailable to the subagent. The `mcp__*` entry is a deliberate MCP passthrough: flow keeps MCP-tool *visibility* for planning while the role-persistence rules bar it from calling them directly (their execution is delegated to @player, exactly as in the OpenCode port where MCP tools remain visible under `'*': allow`). The divergence list in `.claude/AGENTS.md` (entry "`permission` maps → `tools:` allowlists") is updated to record that flow's allowlist now excludes edit/write/bash capabilities.

### 4. No prompt-body changes; DOX sync in the same change

The flow/subflow bodies already contain the "never write, never run commands" invariants, so bodies stay untouched and byte-identical between the two files (only frontmatter changes, which already differs by `mode`). Per the Port Synchronization contract, both ports land in the same change, and `.opencode/AGENTS.md` + `.claude/AGENTS.md` are updated to document the new permission contract.

## Risks / Trade-offs

- [Orchestrator hits a permission error mid-task and stalls] → The denial error is explicit and the prompt body already prescribes delegation as the response to any execution need; the error itself reinforces the correct recovery path (delegate to @player)
- [A legitimate orchestrator edge case needed edit/bash (e.g., quick scaffolding fix)] → Intentional trade-off: ALL execution goes through @player, no exceptions — that is the point of the change
- [Wildcard-vs-specific rule evaluation order differs across OpenCode versions] → The SDK schema (`PermissionConfig` with `'*'` extension key plus specific keys, specific beats wildcard) is verified against the vendored SDK in `.opencode/node_modules`; validation task re-checks at implementation time
- [Claude port drift: future tool additions re-grant edit via `*`] → The divergence entry and the spec requirement ("no bare `*` wildcard in flow's allowlist") make the invariant reviewable; coach review checklist catches reintroduction

## Migration Plan

No runtime migration. The change is frontmatter-only in three files plus doc updates. Users who installed the agents globally via `scripts/install.sh` re-run the installer to pick up the new definitions. Rollback: revert the frontmatter edits.

## Open Questions

- None — permission schema verified against the vendored OpenCode SDK; Claude port mechanism confirmed against the existing `.claude/agents/` format.
