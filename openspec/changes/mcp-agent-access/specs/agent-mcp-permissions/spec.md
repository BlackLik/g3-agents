## ADDED Requirements

### Requirement: Flow agent MCP tool permissions
Flow agent SHALL have MCP tools visible in its tool list for discovery purposes. Flow's `*: deny` permission model SHALL be preserved — `*: deny` blocks INVOCATION of MCP tools, not VISIBILITY. Flow agent SHALL be prevented from invoking MCP tools due to `*: deny`.

#### Scenario: Flow can see MCP tools but is prompted not to use them directly
- **WHEN** an MCP server is configured and flow agent loads
- **THEN** flow agent SHALL have MCP tools visible in its tool list but SHALL be unable to invoke them (blocked by `*: deny`) and SHALL be prompted to delegate MCP tool use to player

### Requirement: Subflow agent MCP tool permissions
Subflow agent SHALL mirror flow's MCP tool permissions — MCP tools visible but controlled via prompting.

#### Scenario: Subflow can see MCP tools but is prompted not to use them directly
- **WHEN** an MCP server is configured and subflow agent loads
- **THEN** subflow agent SHALL have the same MCP tool visibility as flow (visible but invocation blocked by `*: deny`) and SHALL be prompted to delegate MCP tool use to player

### Requirement: Player agent MCP tool permissions
Player agent SHALL have full MCP tool access. Player's existing `*: allow` permission model already covers MCP tools — no permission changes needed for the OpenCode port. In the Claude port, player SHALL have explicit `tools:` allowlist entries that override `*: deny` for specific MCP tools required by player tasks.

#### Scenario: Player uses MCP tool without permission errors
- **WHEN** player agent calls an MCP tool during task execution
- **THEN** player SHALL successfully invoke the MCP tool without encountering permission-related errors

### Requirement: Coach agent MCP tool permissions
Coach agent SHALL have MCP tool access for verification purposes. Coach's existing `*: allow` permission model already covers MCP tools — no permission changes needed.

#### Scenario: Coach uses MCP tool for verification without permission errors
- **WHEN** coach agent calls an MCP tool to verify player's work
- **THEN** coach SHALL successfully invoke the MCP tool without encountering permission-related errors

### Requirement: Claude Code port permission parity
Claude Code port agents SHALL have equivalent MCP tool access. Claude Code's `tools:` allowlists SHALL include MCP tools according to the following criteria:
   - Tools SHALL be added to the Claude port `tools:` allowlist only when they are required by a player task
   - Each tool entry SHALL specify the exact tool name as defined in the MCP server configuration
   - Tools SHALL be reviewed for removal from the allowlist during each change's closeout phase

NOTE: Updating the Claude port `tools:` allowlist IS a permission change. This overrides the `*: deny` default for specific MCP tools. The design.md statement "no permission changes needed" applies only to the OpenCode port (where `*: allow` already covers MCP tools), not to the Claude port.

#### Scenario: Claude Code player can access MCP tools
- **WHEN** an MCP server is configured and Claude Code player agent loads
- **THEN** Claude Code player SHALL have MCP tools available in its `tools:` allowlist and SHALL be able to invoke them
