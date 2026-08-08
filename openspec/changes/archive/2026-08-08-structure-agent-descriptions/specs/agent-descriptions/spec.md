# agent-descriptions (delta)

## ADDED Requirements

### Requirement: Descriptions follow the five-part structured format

Each agent frontmatter `description` in `.opencode/agents/` SHALL be composed of five labeled segments in fixed order:

1. **Purpose** — exactly one sentence stating what the agent does, independent of any task context.
2. **Guidelines** — when to delegate ("Use when…") and how the agent behaves ("You should…" or equivalent behavioral cues).
3. **Parameters** — the input the agent expects, with semantics and format stated explicitly (e.g. a delegated task with scope, success criteria, output format, and `(depth: N)` marker), not merely a type.
4. **Limitations** — known constraints and edge cases (e.g. recursion depth caps, what the agent refuses to do).
5. **Side effects** — an explicit statement of whether invocation writes, deletes, or sends data, or is read-only in effect.

#### Scenario: Structure check

- **WHEN** any description in `.opencode/agents/` is parsed
- **THEN** it SHALL contain the five segments Purpose, Guidelines, Parameters, Limitations, Side effects in that order, each identifiable by its label

#### Scenario: Purpose is context-independent

- **WHEN** the Purpose segment of any description is read in isolation
- **THEN** it SHALL be a single sentence that fully states the role's function without referencing the current task or other agents by `@`-mention

#### Scenario: Parameters carry format semantics

- **WHEN** the Parameters segment describes an input
- **THEN** it SHALL state the input's semantics and expected format explicitly (scope, success criteria, output format, depth marker), not just "a task"

#### Scenario: Side effects are explicit

- **WHEN** the Side effects segment of any description is read
- **THEN** it SHALL state explicitly whether the agent writes/deletes files, runs mutating commands, sends data, or has no externally visible mutations beyond its returned result

## MODIFIED Requirements

### Requirement: Descriptions fit tool-metadata budgets

Each agent description SHALL be a single YAML folded scalar of five labeled segments (per the structured-format requirement) totaling roughly 80–150 words, so it can serve as MCP/tool metadata without excessive size.

#### Scenario: Description length check

- **WHEN** the four descriptions in `.opencode/agents/` are measured
- **THEN** each SHALL be one folded scalar between 80 and 150 words containing all five labeled segments
