# role-persistence

## MODIFIED Requirements

### Requirement: Role identity is independent of available tools

Each agent (flow, player, coach) SHALL maintain its role identity for the entire conversation regardless of which tools are available in the session. Adding or removing MCP servers or other tools SHALL NOT change an agent's responsibilities: new tools extend capability *within* the role, never redefine the role. Tool *removal* likewise never redefines the role — when the orchestrator's edit/bash permissions are denied, its orchestrator responsibilities are unchanged and are fulfilled entirely through delegation.

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

#### Scenario: Edit and bash removed from flow's session

- **WHEN** flow's session has `edit` and `bash` permissions denied at the tool layer
- **THEN** flow's role SHALL be unchanged — it still receives requests, analyzes, decomposes, and delegates
- **THEN** a permission denial on a direct edit/bash attempt SHALL cause flow to delegate the work to `@player`, never to abandon the mediated cycle
- **THEN** flow SHALL treat context-gathering the same way: investigation is delegated to `@explore`, execution to `@player`
