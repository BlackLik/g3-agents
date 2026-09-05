# orchestrator-tool-restriction (delta)

## MODIFIED Requirements

### Requirement: OpenCode orchestrators deny edit and bash permissions

The `permission` frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL use a deny-by-default
base (`'*': deny`) with an explicit allowlist. The allowlist SHALL contain: `task` (restricted to the `player`,
`coach`, `explore`, and `subflow` targets), `skill`, and a `read` grant scoped to reference-tier files only
(`*/reference/*.md`). `flow` (primary, depth 0) SHALL additionally contain `question: allow`; `subflow` SHALL NOT.
`edit`, `bash`, `grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, and `todowrite` SHALL be denied.

#### Scenario: flow.md frontmatter denies edit and bash

- **WHEN** the frontmatter of `.opencode/agents/flow.md` is inspected
- **THEN** `permission` SHALL contain `'*': deny` with an explicit allowlist (no `'*': allow`)
- **THEN** `task` SHALL be allowed for the `player`, `coach`, `explore`, and `subflow` targets only
- **THEN** `skill` and `question` SHALL be allowed
- **THEN** `read` SHALL be denied except for `*/reference/*.md`
- **THEN** `edit`, `bash`, `grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, and `todowrite` SHALL be denied

#### Scenario: subflow.md carries identical restrictions

- **WHEN** the frontmatter of `.opencode/agents/subflow.md` is inspected
- **THEN** its `permission` block SHALL match `.opencode/agents/flow.md`'s except that `question: allow` is absent

#### Scenario: flow.md frontmatter grants question, subflow.md does not

- **WHEN** the frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` are compared
- **THEN** `flow.md` SHALL contain `question: allow`
- **THEN** `subflow.md` SHALL NOT contain `question: allow`

#### Scenario: flow attempts to edit a file

- **WHEN** flow attempts to invoke a file-modifying tool (edit, write, or patch)
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the change to `@player` via the Task tool

#### Scenario: flow attempts to run a shell command

- **WHEN** flow attempts to invoke the bash, webfetch, websearch, or lsp tool
- **THEN** the tool layer SHALL deny the call with a permission error
- **THEN** flow SHALL recover by delegating the work to `@player` or `@explore` via the Task tool

### Requirement: Delegation and read-only tools remain available

The restriction SHALL NOT remove the orchestrator's delegation and workflow tools: `task` (targets `player`, `coach`,
`explore`, `subflow`) and `skill` SHALL remain allowed for `flow` and `subflow`, and a `read` grant scoped to
`*/reference/*.md` SHALL remain for loading the reference tier. The `grep`, `glob`, `list`, `webfetch`, `websearch`,
and `todowrite` tools SHALL NOT be available to orchestrator agents — all codebase content exploration and web
information gathering SHALL be delegated to `@explore`. User interaction SHALL follow the `clarity-gate` capability:
`flow` (depth 0) MAY use the interactive `question` tool for one bounded round; `subflow` SHALL NOT.

#### Scenario: flow delegates via the Task tool

- **WHEN** flow invokes the Task tool with `subagent_type="player"`, `"coach"`, `"explore"`, or `"subflow"`
- **THEN** the call SHALL NOT be denied by the permission layer
- **WHEN** flow invokes the Task tool with any other subagent type
- **THEN** the call SHALL be denied

#### Scenario: flow reads a file

- **WHEN** flow needs file contents, codebase search, or web content
- **THEN** flow SHALL delegate the gathering to `@explore` via the Task tool
- **THEN** flow SHALL NOT invoke `read`, `grep`, `glob`, `webfetch`, or `websearch` directly
- **THEN** the sole `read` exception SHALL be files under `*/reference/*.md`

#### Scenario: flow loads its reference tier

- **WHEN** a core-tier load trigger fires and flow reads `reference/flow-reference.md`
- **THEN** the scoped `read` grant SHALL allow the call

#### Scenario: flow needs user input

- **WHEN** flow (depth 0) is materially blocked per the `clarity-gate` capability
- **THEN** flow MAY invoke the interactive `question` tool for one bounded round
- **WHEN** a subflow (depth ≥1) needs user input
- **THEN** it SHALL NOT have the `question` tool and SHALL follow the mediated fallback

## REMOVED Requirements

### Requirement: Claude port enforces the same restriction via tools allowlist

**Reason**: Tool enforcement now lives only in the OpenCode port. The Claude port carries the same role behavior at the
prompt level, but its `tools:` allowlist is not updated to mirror every OpenCode permission change; this divergence is
documented in `.claude/AGENTS.md`.

**Migration**: None — the Claude port's existing `tools:` allowlist (already excluding Edit/Write/NotebookEdit/Bash)
remains in place; role behavior is carried by the prompt bodies.

### Requirement: Claude port flow has no interactive question tool

**Reason**: Folded into the general "enforcement only in the OpenCode port" decision. Whether the Claude port's
allowlist technically includes an interactive question tool is no longer normative; the `clarity-gate` capability
defines Claude-port clarification behavior (mediated fallback) at the prompt level.

**Migration**: None — the Claude-port prompt body routes clarification through the mediated cycle regardless of tool
availability.

### Requirement: Prompt bodies are untouched by the restriction

**Reason**: This change intentionally edits the prompt bodies (clarity gate, explore-routed information gathering,
removal of the false "no interactive question tool" line), so the invariant no longer holds. The byte-identity
constraint between `flow.md` and `subflow.md` bodies is preserved as its own rule below.

**Migration**: None — bodies are updated in both ports; `flow.md`/`subflow.md` bodies remain byte-identical.

## ADDED Requirements

### Requirement: flow and subflow bodies remain byte-identical

The prompt bodies of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` SHALL remain byte-identical to each
other after any change; only frontmatter lines (name, description, mode, permission) MAY differ.

#### Scenario: Bodies stay byte-identical after the change

- **WHEN** `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` are diffed after stripping frontmatter
- **THEN** the bodies SHALL be identical

#### Scenario: Prompt invariants remain consistent with tool restriction

- **WHEN** the orchestrator prompt bodies are reviewed after the frontmatter change
- **THEN** the role invariants ("never write code, never run commands, never answer directly") SHALL still be present
- **THEN** the clarity-gate rule SHALL be the only sanctioned non-`task` output and SHALL NOT contradict the invariants
