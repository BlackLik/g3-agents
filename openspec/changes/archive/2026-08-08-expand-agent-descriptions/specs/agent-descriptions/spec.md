# agent-descriptions

## ADDED Requirements

### Requirement: Descriptions are self-contained routing contracts

Each agent frontmatter `description` in `.opencode/agents/` SHALL state, without requiring any other system context: what the role does, when a calling LLM should delegate to it, what input it expects, and what it returns.

#### Scenario: Foreign LLM selects an agent from descriptions alone

- **WHEN** a model sees only the four agent names and descriptions (via MCP or a subagent surface) and a user task
- **THEN** the descriptions SHALL provide enough information to pick the correct agent (orchestration vs implementation vs review) without reading agent bodies

### Requirement: Descriptions avoid unresolvable references

Agent descriptions SHALL NOT contain references a foreign model cannot resolve, such as `@agent` mentions or port-specific jargon, unless the reference is defined inline within the description itself.

#### Scenario: No dangling agent references

- **WHEN** any description in `.opencode/agents/` is read in isolation
- **THEN** it SHALL NOT rely on `@`-mentions of other agents; peer agents SHALL be described by capability (e.g. "executor subagent", "reviewer subagent")

### Requirement: Flow and subflow descriptions carry the selection criterion

The descriptions of `flow` and `subflow` SHALL describe the same orchestration contract, and `subflow`'s description SHALL additionally state that it is the subagent-invocable variant to be used when a primary orchestrator already drives the session.

#### Scenario: Caller distinguishes flow from subflow

- **WHEN** a model must choose between `flow` and `subflow`
- **THEN** the two descriptions SHALL make clear that `flow` is the primary entry point and `subflow` is the nested-delegation variant

### Requirement: Descriptions fit tool-metadata budgets

Each agent description SHALL be a single paragraph of roughly 40–80 words so it can serve as MCP/tool metadata without excessive size.

#### Scenario: Description length check

- **WHEN** the four descriptions in `.opencode/agents/` are measured
- **THEN** each SHALL be one paragraph between 40 and 80 words

### Requirement: Only frontmatter descriptions change

The change SHALL modify only the `description` frontmatter line of each agent file; role bodies, `mode`, `temperature`, and `permission` fields SHALL remain byte-identical.

#### Scenario: Diff shows frontmatter-only edits

- **WHEN** the change is applied to `.opencode/agents/*.md`
- **THEN** the diff SHALL touch only `description:` lines in frontmatter
