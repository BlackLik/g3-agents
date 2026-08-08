# orchestrator-tool-restriction

## ADDED Requirements

### Requirement: OpenCode orchestrators deny edit and bash permissions

The `permission` frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL deny file modification and shell execution while allowing all other tools: `'*': allow` combined with `edit: deny` and `bash: deny`.

#### Scenario: flow.md frontmatter denies edit and bash

- **WHEN** the frontmatter of `.opencode/agents/flow.md` is inspected
- **THEN** `permission` SHALL contain `edit: deny` and `bash: deny`
- **THEN** all other tools SHALL remain allowed via `'*': allow`

#### Scenario: subflow.md carries identical restrictions

- **WHEN** the frontmatter of `.opencode/agents/subflow.md` is inspected
- **THEN** its `permission` block SHALL be identical to `.opencode/agents/flow.md`'s `permission` block

#### Scenario: flow attempts to edit a file

- **WHEN** flow attempts to invoke a file-modifying tool (edit, write, or patch)
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the change to `@player` via the Task tool

#### Scenario: flow attempts to run a shell command

- **WHEN** flow attempts to invoke the bash tool
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the command to `@player` via the Task tool

### Requirement: Delegation and read-only tools remain available

The restriction SHALL NOT remove or deny the orchestrator's delegation, read-only, or workflow tools: `task`, `read`, `grep`, `glob`, `list`, `skill`, `todowrite`, `question`, and `webfetch` SHALL remain allowed for `flow` and `subflow`.

#### Scenario: flow delegates via the Task tool

- **WHEN** flow invokes the Task tool with `subagent_type="player"`, `"coach"`, or `"explore"`
- **THEN** the call SHALL NOT be denied by the permission layer

#### Scenario: flow reads a file

- **WHEN** flow invokes a read-only tool (read, grep, or glob)
- **THEN** the call SHALL NOT be denied by the permission layer

### Requirement: Claude port enforces the same restriction via tools allowlist

The `tools:` frontmatter of `.claude/agents/flow.md` SHALL be an explicit allowlist that grants delegation and read-only tools without any file-modifying or shell tools: it SHALL NOT contain the bare `*` wildcard (the `mcp__*` MCP passthrough is permitted, preserving MCP-tool visibility for planning) and SHALL NOT include Edit, Write, NotebookEdit, or Bash; it SHALL include the Agent tool (with flow, player, coach, and Explore targets) and read-only tools.

#### Scenario: Claude flow has no edit, write, or bash tools

- **WHEN** the `tools:` frontmatter of `.claude/agents/flow.md` is inspected
- **THEN** it SHALL NOT contain the bare `*` wildcard, `Edit`, `Write`, `NotebookEdit`, or `Bash`
- **THEN** it SHALL contain `Agent(flow, player, coach, Explore)` and read-only tools, and MAY contain `mcp__*`

#### Scenario: Claude flow cannot invoke Write

- **WHEN** the Claude-port flow subagent attempts to invoke Write, Edit, or Bash
- **THEN** the tool SHALL be unavailable to the subagent

### Requirement: Prompt bodies are untouched by the restriction

The restriction SHALL be implemented in frontmatter only. The prompt bodies of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL remain byte-identical to each other, and `.claude/agents/flow.md`'s body SHALL change only if its frontmatter reference requires it.

#### Scenario: flow and subflow bodies stay byte-identical

- **WHEN** `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` are diffed after the change
- **THEN** only frontmatter lines SHALL differ (name, description, mode)

#### Scenario: Prompt invariants remain consistent with tool restriction

- **WHEN** the orchestrator prompt bodies are reviewed after the frontmatter change
- **THEN** the existing "never write code, never run commands" invariants SHALL still be present and SHALL NOT contradict the enforced permissions
