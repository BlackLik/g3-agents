# Tasks — MCP Agent Access

## 1. MCP Configuration

- [x] 1.1 Create `opencode.json` at repo root with MCP server definitions (stdio, http types)
- [x] 1.2 Validate `opencode.json` loads correctly with `opencode check` or equivalent

## 2. Agent Prompt Updates — OpenCode Port

- [x] 2.1 Update `.opencode/agents/flow.md` with MCP usage guidance (plan around MCP tools, delegate to player, SHALL NOT call MCP tools directly)
- [x] 2.2 Update `.opencode/agents/subflow.md` with MCP usage guidance (mirror flow — plan/delegate, avoid direct calls)
- [x] 2.3 Update `.opencode/agents/player.md` with MCP usage guidance (primary MCP tool executor)
- [x] 2.4 Update `.opencode/agents/coach.md` with MCP usage guidance (verify player's work through MCP tools)

## 3. Agent Prompt Updates — Claude Code Port

- [x] 3.1 Update `.claude/agents/flow.md` with MCP usage guidance (plan/delegate, SHALL NOT call MCP tools directly)
- [x] 3.2 Update `.claude/agents/player.md` with MCP usage guidance (primary executor)
- [x] 3.3 Update `.claude/agents/coach.md` with MCP usage guidance (verification through MCP)

## 4. Agent Permission Updates

- [x] 4.1 Verify all three agent permission configs (flow/subflow deny, player/coach allow, Claude port allowlists) are correct and consistent

## 5. MCP Schema Research

- [x] 5.1 Research and document OpenCode's exact MCP server configuration JSON schema by examining opencode source code or configuration validation logic

## 6. Documentation & Closeout

- [x] 6.1 Update `.opencode/AGENTS.md` with MCP workflow guidance
- [x] 6.2 Update `.claude/AGENTS.md` divergences list — MUST update if MCP-related divergences exist
- [x] 6.3 Update root `AGENTS.md` if project-level workflow rules change

## 7. Verification Strategy

- [x] 7.1 Unit tests for MCP config parsing
- [x] 7.2 Integration tests for MCP tool discovery
- [x] 7.3 Permission model verification tests
- [x] 7.4 Prompt behavior verification
