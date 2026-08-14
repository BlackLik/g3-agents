# orchestrator-tool-restriction

## MODIFIED Requirements

### Requirement: OpenCode orchestrators deny edit and bash permissions

The `permission` frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL deny file
modification and shell execution while using an explicit allowlist of permitted tools: `task`, `list`, `skill`,
and `webfetch` SHALL be allowed; `edit: deny` and `bash: deny` SHALL be present. The `question` and `todowrite`
tools SHALL NOT be in the allowlist.

#### Scenario: flow.md frontmatter denies edit and bash

- **WHEN** the frontmatter of `.opencode/agents/flow.md` is inspected
- **THEN** `permission` SHALL contain `edit: deny` and `bash: deny`
- **THEN** `permission` SHALL contain an explicit allowlist of `task`, `list`, `skill`, `webfetch`
- **THEN** `'*': allow` SHALL NOT be present
- **THEN** `question` and `todowrite` SHALL NOT be present

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

The restriction SHALL NOT remove or deny the orchestrator's delegation and workflow tools: `task`, `list`,
`skill`, and `webfetch` SHALL remain allowed for `flow` and `subflow`. The `read`, `grep`, `glob`, `question`,
and `todowrite` tools SHALL NOT be available to orchestrator agents — all codebase content exploration SHALL be
delegated to `@explore`, and user interaction SHALL follow the `clarification-policy` capability.

#### Scenario: flow delegates via the Task tool

- **WHEN** flow invokes the Task tool with `subagent_type="player"`, `"coach"`, or `"explore"`
- **THEN** the call SHALL NOT be denied by the permission layer

#### Scenario: flow reads a file

- **WHEN** flow needs to read file contents or search the codebase
- **THEN** flow SHALL delegate the read to `@explore` via the Task tool
- **THEN** flow SHALL NOT invoke `read`, `grep`, or `glob` directly

#### Scenario: flow needs user input

- **WHEN** flow needs clarification from the user
- **THEN** flow SHALL NOT invoke an interactive question tool
- **THEN** flow SHALL escalate via a mediated delivery per the `clarification-policy` capability

## ADDED Requirements

### Requirement: Claude port flow has no interactive question tool

The `tools:` frontmatter of `.claude/agents/flow.md` SHALL NOT include any tool whose purpose is asking the user
an interactive question (e.g., AskUserQuestion) or managing todo lists. User interaction in the Claude port
SHALL follow the `clarification-policy` capability.

#### Scenario: Claude flow allowlist inspected

- **WHEN** the `tools:` frontmatter of `.claude/agents/flow.md` is inspected
- **THEN** no interactive user-question tool and no todo-list tool SHALL be present
- **THEN** it SHALL still contain `Agent(flow, player, coach, Explore)` and MAY contain `mcp__*`
