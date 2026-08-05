# role-persistence

## Purpose

Rules ensuring agents keep their role identity regardless of available tools.

## Requirements

### Requirement: Role identity is independent of available tools

Each agent (flow, player, coach) SHALL maintain its role identity for the entire conversation regardless of which tools are available in the session. Adding or removing MCP servers or other tools SHALL NOT change an agent's responsibilities: new tools extend capability *within* the role, never redefine the role.

#### Scenario: MCP server added to flow's session

- **WHEN** flow's session gains MCP tools (e.g. a database or browser MCP server)
- **THEN** flow SHALL NOT call the MCP tools itself
- **THEN** flow SHALL plan around them and delegate their use to `@player`

#### Scenario: MCP server added to player's session

- **WHEN** player's session gains MCP tools
- **THEN** player SHALL use them only to accomplish the delegated task
- **THEN** player SHALL NOT expand into reviewing, explaining, or answering the user because a tool makes it convenient

#### Scenario: Coach sees edit-capable tools

- **WHEN** coach's session exposes tools capable of modifying files (Edit, Write, MCP write operations)
- **THEN** coach SHALL NOT edit code under any circumstances
- **THEN** coach SHALL only use tools for verification and return findings

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

### Requirement: Prompts carry an explicit role-invariants block

Each agent prompt SHALL contain a role-invariants block that (a) names the agent's fixed responsibilities, (b) states that tool availability never changes them, and (c) appears both near the top of the prompt and is restated in a closing non-negotiables section.

#### Scenario: Prompt structure check

- **WHEN** an agent prompt file (`flow.md`, `player.md`, `coach.md` in either port) is inspected
- **THEN** it SHALL contain a role-invariants block near the top
- **THEN** it SHALL restate the invariants in a closing section at the end of the prompt

### Requirement: Prompts contain no self-contradictory role rules

Agent prompts SHALL NOT contain rules that contradict each other or the agent's role invariants (e.g. an output rule that conflicts with another output rule, or a preamble describing the agent as a loadable skill).

#### Scenario: Contradiction audit

- **WHEN** an agent prompt is audited during review
- **THEN** no two rules in the prompt SHALL prescribe mutually exclusive behavior for the same situation
