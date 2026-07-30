## ADDED Requirements

### Requirement: Flow agent MCP usage guidance
The flow agent prompt SHALL include guidance that flow plans around MCP tools and delegates their use to player. Flow SHALL NOT call MCP tools directly; SHALL delegate MCP tool usage to player.

#### Scenario: Flow delegates MCP-using task to player
- **WHEN** the flow agent identifies a subtask that requires MCP tool usage
- **THEN** the flow SHALL delegate the subtask to the player agent

### Requirement: Subflow agent MCP usage guidance
The subflow agent prompt SHALL mirror flow's MCP usage guidance. Subflow SHALL plan around MCP tools and delegate their use to player.

#### Scenario: Subflow delegates MCP-using subtask to player
- **WHEN** the subflow agent identifies a subtask that requires MCP tool usage
- **THEN** the subflow SHALL delegate the subtask to the player agent, mirroring the flow agent's MCP delegation behavior

### Requirement: Player agent MCP usage guidance
The player agent prompt SHALL include guidance that player is the primary executor of MCP tools. Player SHALL use MCP tools directly to accomplish delegated tasks.

#### Scenario: Player uses MCP tool to complete a task
- **WHEN** the player agent receives a delegated task that requires MCP tool usage
- **THEN** the player SHALL use the appropriate MCP tools directly to accomplish the task

### Requirement: Coach agent MCP usage guidance
The coach agent prompt SHALL include guidance that coach uses MCP tools for verification. Coach SHOULD use MCP tools for verification when MCP tools relevant to the player's work are available.

#### Scenario: Coach uses MCP tool to verify player's work
- **WHEN** the coach agent reviews work performed by the player agent
- **THEN** the coach SHOULD use MCP tools to verify the correctness of the player's work when MCP tools relevant to the work are available

### Requirement: Two-port synchronization
MCP usage guidance SHALL be added to both .opencode/agents/ and .claude/agents/ ports. Both ports SHALL have equivalent MCP usage guidance for each agent role.

#### Scenario: Both ports have MCP guidance for flow agent
- **WHEN** MCP usage guidance is added to the flow agent prompt
- **THEN** the guidance SHALL be added to both the .opencode/agents/flow.md and .claude/agents/flow.md files with equivalent content
