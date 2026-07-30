## Why

No MCP servers are configured and no agent has MCP tool access. As the project grows, agents need access to external tools (Langflow, databases, APIs, etc.) through MCP. Without MCP support, every new integration requires custom code or manual steps. Making MCP tools available to all agents — with role-specific prompting — enables the existing orchestration pattern to extend naturally to external systems: flow/subflow plans and delegates, player executes, coach verifies.

## What Changes

- **MCP server configuration**: Add `opencode.json` with MCP server definitions so all agents discover and use MCP tools
- **Agent prompt updates**: Update `flow.md`, `subflow.md`, `player.md`, `coach.md` with role-specific MCP usage guidance:
  - flow/subflow: plans around MCP tools, delegates their use to player, does not call MCP tools directly
  - player: uses MCP tools directly to do the work
  - coach: checks/verifies player's work through MCP tools
- **Permission updates**: Update agent tool permission configurations to grant MCP tool access to player agent

## Capabilities

### New Capabilities

- `mcp-config`: Configure MCP servers in opencode.json so all agents can discover and use them
- `agent-mcp-prompts`: Update agent prompt files (flow.md, subflow.md, player.md, coach.md) with role-specific MCP usage guidance
- `agent-mcp-permissions`: Update agent tool permission configurations to grant MCP tool access to player agent

### Modified Capabilities

*(None — all capabilities are new)*

## Impact

- **`opencode.json`** (new): MCP server definitions
- **`.opencode/agents/flow.md`**: Add MCP usage guidance — planning/delegation role, does not call MCP tools directly
- **`.opencode/agents/subflow.md`**: Mirror flow.md changes
- **`.opencode/agents/player.md`**: Add MCP usage guidance — primary MCP tool executor
- **`.opencode/agents/coach.md`**: Add MCP usage guidance — verification through MCP tools
- **`.claude/agents/flow.md`**: Mirror OpenCode port changes
- **`.claude/agents/player.md`**: Mirror OpenCode port changes
- **`.claude/agents/coach.md`**: Mirror OpenCode port changes
- **`.opencode/AGENTS.md`**: Update Work Guidance section
- **`.claude/AGENTS.md`**: Update divergences list if needed
- **Root `AGENTS.md`**: Update if project-level workflow rules change
