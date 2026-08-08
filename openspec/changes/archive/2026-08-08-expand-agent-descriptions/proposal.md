# expand-agent-descriptions

## Why

The frontmatter `description` of each agent (`flow`, `subflow`, `player`, `coach`) is surfaced to other LLMs during MCP and subagent interactions — it is the only information a calling model sees when deciding which agent to invoke and when. The current descriptions are terse personality slogans (e.g. "Lazy programmer — minimal code, no explanations") that do not communicate each role's purpose, delegation contract, or selection criteria, so external models cannot route tasks reliably.

## What Changes

- Rewrite the frontmatter `description` of `flow`, `subflow`, `player`, and `coach` in `.opencode/agents/` (the reference port) so each description states: what the role does, when a calling LLM should delegate to it, what input it expects, and what it returns.
- Keep descriptions self-contained and port-free: no references to other agents by port-specific syntax, no OpenCode-only jargon that a foreign model cannot interpret.
- Mirror the expanded descriptions in the `.claude` port (`flow`, `player`, `coach`) where the port format allows; `.claude/AGENTS.md` already lists frontmatter `description` as port-owned, so any remaining divergence is recorded there rather than forced into sync.
- No behavioral changes: role bodies, modes, temperatures, and permissions stay untouched. Only the `description` frontmatter line changes.

## Capabilities

### New Capabilities

- `agent-descriptions`: Requirements for agent frontmatter descriptions — each role's description must fully communicate its purpose, delegation contract, expected input, and return value to a foreign LLM that has no other context about the system.

### Modified Capabilities

<!-- No requirement changes: existing specs that mention frontmatter descriptions (orchestrator-tool-restriction, prompt-examples) only constrain flow/subflow diffs and remain valid. -->

## Impact

- **Code**: `.opencode/agents/flow.md`, `.opencode/agents/subflow.md`, `.opencode/agents/player.md`, `.opencode/agents/coach.md` — frontmatter `description` only.
- **Docs**: `.claude/AGENTS.md` divergence list updated if the `.claude` port descriptions are aligned.
- **Consumers**: Any LLM interacting with these agents through MCP/subagent surfaces gets actionable routing information instead of slogans.
- **No breaking changes**: descriptions are metadata; runtime behavior of the multi-agent system is unchanged.
