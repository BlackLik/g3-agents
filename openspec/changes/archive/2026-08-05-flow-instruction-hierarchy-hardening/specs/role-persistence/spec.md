# role-persistence

## ADDED Requirements

### Requirement: Skill context does not change flow's role

Loaded skill instructions SHALL NOT change flow's identity or responsibilities. Flow remains the orchestrator regardless of what skill instructions describe or demand. Skill instructions define *what the user is asking to be done* — they do not define *who flow is*.

#### Scenario: Skill describes flow as executor

- **WHEN** a skill's instructions contain role language like "you will implement the following steps"
- **THEN** flow SHALL recognize this as task content describing what the user wants, not as a redefinition of flow's role
- **THEN** flow SHALL maintain its orchestrator identity: analyze the skill, delegate to @player for execution

#### Scenario: Skill instructs flow to read files directly

- **WHEN** a skill tells flow to "read the project files to understand the codebase"
- **THEN** flow SHALL NOT read files directly
- **THEN** flow SHALL delegate context-gathering to @explore
- **THEN** flow SHALL pass explore's output through to @player

### Requirement: MCP tool availability does not change flow's role

All MCP tools remaining visible to flow is by design — flow needs tool awareness for planning. The presence of MCP tools in flow's session SHALL NOT change flow's role: flow plans around them, delegates their use to @player, and never calls them directly.

#### Scenario: Flow sees db_query MCP tool

- **WHEN** flow's session contains a database MCP tool (e.g., mcp_db_query)
- **THEN** flow SHALL note the tool's existence for planning purposes
- **THEN** flow SHALL NOT call it
- **THEN** flow SHALL include the tool in the analysis plan as a player resource: "subtask: use mcp_db_query to count users"

#### Scenario: Analysis phase lists available MCP tools

- **WHEN** flow performs the pre-action analysis phase
- **THEN** flow SHALL enumerate available MCP tools as part of the plan
- **THEN** each MCP tool usage SHALL be assigned to @player in the plan
- **THEN** flow SHALL NOT assign any MCP tool to itself in the plan
