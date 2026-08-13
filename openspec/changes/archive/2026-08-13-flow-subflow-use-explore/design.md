# Context

Flow and subflow agents are the orchestrator agents in the OpenCode multi-agent system. They delegate work to
@player (executor), @coach (reviewer), and @explore (codebase investigation). Currently, their frontmatter uses
`'*': allow` with `edit: deny` and `bash: deny`, which means Read/Grep/Glob tools remain technically available
even though their prompt bodies instruct them to delegate codebase exploration to @explore.

The existing `orchestrator-tool-restriction` spec enforces the edit/bash denial but explicitly lists
read/grep/glob as allowed tools. The `context-delegation` spec establishes the explore-first principle. This
change aligns the permission model with the stated behavior.

## Goals / Non-Goals

**Goals:**

- Remove Read/Grep/Glob from flow and subflow tool access in both OpenCode and Claude ports
- Update the orchestrator-tool-restriction spec to reflect the new tool restrictions
- Keep all other existing restrictions (edit/bash deny) intact
- Keep prompt bodies untouched — they already correctly instruct delegation to @explore

**Non-Goals:**

- Not changing player, coach, or explore agent tool access
- Not rewriting flow/subflow prompt bodies
- Not changing the explore-first principle or context-delegation spec
- Not adding new capabilities beyond tool restriction

## Decisions

### Decision 1: Explicit allowlist over wildcard-with-exceptions

Switch from `'*': allow` with individual denies to an explicit allowlist of permitted tools.

**Rationale**: An explicit allowlist is more maintainable and auditable — it's immediately clear what tools are
available without scanning for deny overrides. It also prevents accidentally allowing new tools that get added to
the system later (since `'*'` would catch them).

**Alternatives considered**:

- Keep `'*': allow` and add `read: deny`, `grep: deny`, `glob: deny` — simpler diff but less secure; any future
  tool added to the system would be auto-allowed.
- Keep `'*': allow` and rely on prompt-level prohibition — already proven insufficient since the tools are
  available and create temptation.

### Decision 2: Allowed tools for flow/subflow

The explicit allowlist for flow and subflow SHALL contain: `task`, `list`, `skill`, `todowrite`, `question`, `webfetch`.

**Rationale**:

- `task` — primary delegation tool (required for orchestration)
- `list` — directory listing (needed to discover file structure without reading contents)
- `skill` — loading skill instructions
- `todowrite` — progress tracking
- `question` — asking user for input
- `webfetch` — external research (needed for planning)

Read, Grep, and Glob are explicitly excluded — all codebase content exploration goes through @explore.

### Decision 3: Claude port mirrors the restriction

The Claude port's tools allowlist (`.claude/agents/flow.md`) SHALL remove Read, Grep, and Glob from the explicit allowlist.

**Rationale**: Both ports must enforce the same restriction for consistency. The Claude port already uses an
explicit allowlist (no bare `*`), so this is a straightforward removal.

## Risks / Trade-offs

- **[Risk]** Flow/subflow may need to read a specific file in an emergency — **Mitigation**: They delegate to
  @explore, which returns the content. The explore agent is designed for this.
- **[Risk]** Existing archived changes or specs reference flow/subflow using read/grep/glob — **Mitigation**:
  Those references are in prompt bodies which remain untouched; the restriction is only in frontmatter
  permissions.
- **[Risk]** The `list` tool still allows filesystem discovery without @explore — **Trade-off**: `list` only
  reveals file/directory names, not contents. Full content reading requires @explore. This is consistent with the
  context-delegation spec's carve-out for "narrow refinement" after an explore pass. If a task needs to
  understand file structure, flow should still delegate to @explore first; `list` is for quick orientation only.
