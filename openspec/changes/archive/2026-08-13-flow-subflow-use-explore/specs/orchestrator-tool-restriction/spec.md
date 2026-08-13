# orchestrator-tool-restriction

## MODIFIED Requirements

### Requirement: Delegation and read-only tools remain available

The restriction SHALL NOT remove or deny the orchestrator's delegation and workflow tools: `task`, `list`,
`skill`, `todowrite`, `question`, and `webfetch` SHALL remain allowed for `flow` and `subflow`. The `read`,
`grep`, and `glob` tools SHALL NOT be available to orchestrator agents — all codebase content exploration SHALL
be delegated to `@explore`.

#### Scenario: flow delegates via the Task tool

- **WHEN** flow invokes the Task tool with `subagent_type="player"`, `"coach"`, or `"explore"`
- **THEN** the call SHALL NOT be denied by the permission layer

#### Scenario: flow reads a file

- **WHEN** flow needs to read file contents or search the codebase
- **THEN** flow SHALL delegate the read to `@explore` via the Task tool
- **THEN** flow SHALL NOT invoke `read`, `grep`, or `glob` directly

#### Scenario: flow lists directory contents

- **WHEN** flow invokes the `list` tool to see directory contents
- **THEN** the call SHALL NOT be denied by the permission layer

## ADDED Requirements

### Requirement: OpenCode orchestrators use explicit allowlist

The `permission` frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL use an explicit
allowlist of permitted tools instead of `'*': allow`. The allowlist SHALL include `task`, `list`, `skill`,
`todowrite`, `question`, `webfetch` and SHALL exclude `read`, `grep`, `glob`, `edit`, `bash`, and any
file-modifying or shell tools.

#### Scenario: flow.md frontmatter uses explicit allowlist

- **WHEN** the frontmatter of `.opencode/agents/flow.md` is inspected
- **THEN** `permission` SHALL contain an explicit list of allowed tools
- **THEN** `'*': allow` SHALL NOT be present
- **THEN** `edit: deny` and `bash: deny` SHALL still be present

### Requirement: Claude port removes Read/Grep/Glob from tools allowlist

The `tools:` frontmatter of `.claude/agents/flow.md` SHALL remove `Read`, `Grep`, and `Glob` from the explicit allowlist.

#### Scenario: Claude flow has no Read/Grep/Glob tools

- **WHEN** the `tools:` frontmatter of `.claude/agents/flow.md` is inspected
- **THEN** it SHALL NOT contain `Read`, `Grep`, or `Glob`
- **THEN** it SHALL still contain `Agent(flow, player, coach, Explore)` and `mcp__*`
