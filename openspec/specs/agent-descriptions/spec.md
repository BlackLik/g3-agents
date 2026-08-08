# agent-descriptions

## Purpose

Agent frontmatter `description` fields in `.opencode/agents/` act as self-contained routing contracts: they let a
foreign LLM pick the correct agent from names and descriptions alone, without reading agent bodies or resolving
port-specific references.

## Requirements

### Requirement: Descriptions are self-contained routing contracts

Each agent frontmatter `description` in `.opencode/agents/` SHALL state, without requiring any other system context:
what the role does, when a calling LLM should delegate to it, what input it expects, and what it returns.

#### Scenario: Foreign LLM selects an agent from descriptions alone

- **WHEN** a model sees only the four agent names and descriptions (via MCP or a subagent surface) and a user task
- **THEN** the descriptions SHALL provide enough information to pick the correct agent (orchestration vs implementation
  vs review) without reading agent bodies

### Requirement: Descriptions avoid unresolvable references

Agent descriptions SHALL NOT contain references a foreign model cannot resolve, such as `@agent` mentions or
port-specific jargon, unless the reference is defined inline within the description itself.

#### Scenario: No dangling agent references

- **WHEN** any description in `.opencode/agents/` is read in isolation
- **THEN** it SHALL NOT rely on `@`-mentions of other agents; peer agents SHALL be described by capability (e.g.
  "executor subagent", "reviewer subagent")

### Requirement: Flow and subflow descriptions carry the selection criterion

The descriptions of `flow` and `subflow` SHALL describe the same orchestration contract, and `subflow`'s description
SHALL additionally state that it is the subagent-invocable variant to be used when a primary orchestrator already drives
the session.

#### Scenario: Caller distinguishes flow from subflow

- **WHEN** a model must choose between `flow` and `subflow`
- **THEN** the two descriptions SHALL make clear that `flow` is the primary entry point and `subflow` is the
  nested-delegation variant

### Requirement: Descriptions follow the five-part structured format

Each agent frontmatter `description` in `.opencode/agents/` SHALL be composed of five labeled segments in fixed order:

1. **Purpose** — exactly one sentence stating what the agent does, independent of any task context.
2. **Guidelines** — when to delegate ("Use when…") and how the agent behaves ("You should…" or equivalent behavioral
   cues).
3. **Parameters** — the input the agent expects, with semantics and format stated explicitly (e.g. a delegated task with
   scope, success criteria, output format, and `(depth: N)` marker), not merely a type.
4. **Limitations** — known constraints and edge cases (e.g. recursion depth caps, what the agent refuses to do).
5. **Side effects** — an explicit statement of whether invocation writes, deletes, or sends data, or is read-only in
   effect.

#### Scenario: Structure check

- **WHEN** any description in `.opencode/agents/` is parsed
- **THEN** it SHALL contain the five segments Purpose, Guidelines, Parameters, Limitations, Side effects in that order,
  each identifiable by its label

#### Scenario: Purpose is context-independent

- **WHEN** the Purpose segment of any description is read in isolation
- **THEN** it SHALL be a single sentence that fully states the role's function without referencing the current task or
  other agents by `@`-mention

#### Scenario: Parameters carry format semantics

- **WHEN** the Parameters segment describes an input
- **THEN** it SHALL state the input's semantics and expected format explicitly (scope, success criteria, output format,
  depth marker), not just "a task"

#### Scenario: Side effects are explicit

- **WHEN** the Side effects segment of any description is read
- **THEN** it SHALL state explicitly whether the agent writes/deletes files, runs mutating commands, sends data, or has
  no externally visible mutations beyond its returned result

### Requirement: Descriptions fit tool-metadata budgets

Each agent description SHALL be a single YAML folded scalar of five labeled segments (per the structured-format
requirement) totaling roughly 80–150 words, so it can serve as MCP/tool metadata without excessive size.

#### Scenario: Description length check

- **WHEN** the four descriptions in `.opencode/agents/` are measured
- **THEN** each SHALL be one folded scalar between 80 and 150 words containing all five labeled segments

### Requirement: Only frontmatter descriptions change

The change SHALL modify only the `description` frontmatter line of each agent file; role bodies, `mode`, `temperature`,
and `permission` fields SHALL remain byte-identical.

#### Scenario: Diff shows frontmatter-only edits

- **WHEN** the change is applied to `.opencode/agents/*.md`
- **THEN** the diff SHALL touch only `description:` lines in frontmatter
