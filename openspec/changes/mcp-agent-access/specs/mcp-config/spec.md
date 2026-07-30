## ADDED Requirements

### Requirement: MCP server definitions in opencode.json
The system SHALL support defining MCP servers in an `opencode.json` file at the repository root. Each MCP server definition SHALL conform to the JSON schema specified below.

#### JSON Schema for MCP server definitions in opencode.json

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "string (required — the executable to launch)",
      "args": ["string (array of command-line arguments)"],
      "env": { "KEY": "value" },
      "disabled": false,
      "autoApprove": ["tool-name-1", "tool-name-2"]
    }
  }
}
```

Field semantics:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `command` | string | yes | — | The executable path or name to launch the MCP server |
| `args` | array of strings | no | — | Command-line arguments passed to the executable |
| `env` | object (string → string) | no | `{}` | Environment variables set for the server process |
| `disabled` | boolean | no | `false` | When `true`, the server is registered but not started |
| `autoApprove` | array of strings | no | `[]` | Tool names that skip user confirmation |

Each key under `mcpServers` is a user-chosen server name (string). At least one server entry SHALL be present when `mcpServers` is defined.

Note: `args` required-ness is TBD pending research task 5.1. The standard MCP convention treats `args` as optional.

#### Scenario: Configure a stdio MCP server
- **WHEN** the user adds an MCP server entry with a `command`, `args`, and optional `env` to `opencode.json`
- **THEN** the system SHALL register the server and make its tools available to all agents

### Requirement: MCP tool discovery by all agents
Player and coach agents SHALL be able to discover and use MCP tools defined in opencode.json. Flow and subflow agents SHALL be able to discover MCP tools but SHALL NOT invoke them (they operate under a `*: deny` permission model that blocks tool invocation). MCP tools SHALL appear alongside native tools in the agent's available toolset.

#### Scenario: Agent lists available tools including MCP tools
- **WHEN** an agent enumerates its available tools after MCP servers are configured
- **THEN** the agent SHALL list MCP-provided tools alongside its native tools

### Requirement: MCP configuration validation
The system SHALL validate MCP server configuration on load. Invalid configurations SHALL produce specific, testable error messages.

#### Scenario: Invalid MCP server configuration produces error
- **WHEN** the user provides an MCP server definition missing a required field (e.g., no `command`)
- **THEN** the system SHALL reject the configuration
- **AND** the error message SHALL include the MCP server name
- **AND** the error message SHALL include the specific field name that is missing or invalid
- **AND** the error message SHALL be logged at ERROR level
