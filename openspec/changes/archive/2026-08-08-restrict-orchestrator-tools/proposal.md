# Proposal

## Why

The orchestrator's "never write, never run commands" rule is currently enforced only by prompt text, while `flow` and `subflow` run with `permission: '*': allow`. Under skill/MCP context pressure or with smaller models, the orchestrator can and does execute work itself (writes files, runs bash) instead of delegating — a role-capture failure that prompt rules alone cannot prevent. Tool-level enforcement makes the delegation boundary hard: with `edit`/`bash` denied, execution is physically only possible through `@player`, and investigation through `@explore`.

## What Changes

- **Deny `edit` and `bash` permissions for `flow` and `subflow`** in `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` frontmatter: `permission` becomes `'*': allow` + `edit: deny` + `bash: deny` (file-modifying tools — write/edit/patch — and shell execution are blocked)
- **Mirror the restriction in the Claude port**: `.claude/agents/flow.md` `tools:` allowlist drops the bare `*` wildcard and excludes Edit/Write/Bash/NotebookEdit, keeping only Agent + read-only tools plus the `mcp__*` MCP passthrough (no subflow in this port — documented divergence)
- **No prompt-body changes**: both ports' bodies already prohibit writing code and running commands; this change moves enforcement from prompt level to tool level, keeping flow.md/subflow.md bodies byte-identical
- **Update DOX**: `.opencode/AGENTS.md` (permissions contract) and `.claude/AGENTS.md` (divergence list entry for the new tools allowlist)

## Capabilities

### New Capabilities

- `orchestrator-tool-restriction`: Tool-level enforcement that `flow`/`subflow` cannot modify files or run shell commands — frontmatter permissions deny `edit` and `bash` in OpenCode, and the Claude port's tools allowlist excludes equivalent capabilities, while delegation (task/Agent) and read-only tools remain available

### Modified Capabilities

- `role-persistence`: Extend "role identity is independent of available tools" to cover tool *removal* — when flow's session lacks edit/bash capability, its role is unchanged and unimpaired: it delegates all execution to @player and investigation to @explore

## Impact

- **Agent frontmatter**: `.opencode/agents/flow.md`, `.opencode/agents/subflow.md` (permission map), `.claude/agents/flow.md` (tools allowlist)
- **Docs**: `.opencode/AGENTS.md`, `.claude/AGENTS.md` divergence list
- **Specs**: 1 new capability spec, 1 delta spec (`role-persistence`)
- **Player/explore/coach prompts**: no changes — they already receive delegated work
- **Behavior**: any direct write/bash attempt by the orchestrator now fails at the tool layer, surfacing a permission error instead of silently violating the workflow; delegation via Task/Agent tool is unaffected
