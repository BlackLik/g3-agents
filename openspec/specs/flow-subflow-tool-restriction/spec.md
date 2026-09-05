# flow-subflow-tool-restriction

## Purpose

Enforce that flow and subflow agents cannot use Read/Grep/Glob tools directly — all codebase exploration must be
delegated to @explore via the Task tool. This aligns the frontmatter permission model with the explore-first
principle established in the context-delegation spec.

## Requirements

### Requirement: Flow and subflow SHALL NOT have Read/Grep/Glob tools

The `permission` frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL use an explicit
allowlist that excludes `read`, `grep`, and `glob`. The allowed tools SHALL be: `task`, `list`, `skill`,
`webfetch`. The `question` and `todowrite` tools SHALL NOT be in the allowlist.

#### Scenario: flow.md frontmatter uses explicit allowlist without read/grep/glob

- **WHEN** the frontmatter of `.opencode/agents/flow.md` is inspected
- **THEN** `permission` SHALL NOT contain `'*': allow`
- **THEN** `permission` SHALL contain an explicit list of allowed tools
- **THEN** `read`, `grep`, and `glob` SHALL NOT be in the allowed tools list
- **THEN** `question` and `todowrite` SHALL NOT be in the allowed tools list
- **THEN** `task`, `list`, `skill`, `webfetch` SHALL be in the allowed tools list

#### Scenario: subflow.md carries identical restrictions

- **WHEN** the frontmatter of `.opencode/agents/subflow.md` is inspected
- **THEN** its `permission` block SHALL be identical to `.opencode/agents/flow.md`'s `permission` block

#### Scenario: flow attempts to use grep directly

- **WHEN** flow attempts to invoke the `grep` tool
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the search to `@explore` via the Task tool

#### Scenario: flow attempts to read a file directly

- **WHEN** flow attempts to invoke the `read` tool
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the read to `@explore` via the Task tool

### Requirement: Claude port removes Read/Grep/Glob from tools allowlist

The `tools:` frontmatter of `.claude/agents/flow.md` and `.claude/agents/subflow.md` SHALL exclude `Read`, `Grep`, and
`Glob` from the explicit allowlist. `flow.md` SHALL name `subflow` in its `Agent(...)` list
(`Agent(subflow, player, coach, Explore)`) and SHALL NOT name `flow` (no self-recursion); `subflow.md` SHALL omit
`subflow` from its own `Agent(...)` list (`Agent(player, coach, Explore)`).

#### Scenario: Claude orchestrators have no Read/Grep/Glob tools

- **WHEN** the `tools:` frontmatter of `.claude/agents/flow.md` or `.claude/agents/subflow.md` is inspected
- **THEN** it SHALL NOT contain `Read`, `Grep`, or `Glob`
- **THEN** `flow.md` SHALL contain `Agent(subflow, player, coach, Explore)` and `mcp__*`
- **THEN** `subflow.md` SHALL contain `Agent(player, coach, Explore)` — no `subflow` self-recursion

#### Scenario: Claude flow cannot invoke Read

- **WHEN** the Claude-port flow or subflow subagent attempts to invoke Read, Grep, or Glob
- **THEN** the tool SHALL be unavailable to the subagent
