# Why

Flow and subflow agents currently have Read/Grep/Glob tools available via `'*': allow` in their frontmatter
permissions, even though their prompt bodies instruct them to delegate codebase exploration to @explore. This
creates a gap between stated behavior and actual capability — the tools are there, creating temptation to use
them directly instead of routing through @explore. The existing `orchestrator-tool-restriction` spec explicitly
lists read/grep/glob as allowed, which contradicts the explore-first principle established in the
`context-delegation` spec.

## What Changes

- Remove Read/Grep/Glob from flow and subflow tool access by switching from `'*': allow` to an explicit allowlist
  that excludes these tools
- Update the `orchestrator-tool-restriction` spec to remove read/grep/glob from the allowed tools for orchestrator agents
- Flow and subflow prompt bodies remain untouched — they already instruct delegation to @explore; only the
  frontmatter permission model changes
- The Claude Code port (`.claude/`) receives the equivalent restriction in its tools allowlist

## Capabilities

### New Capabilities

- `flow-subflow-tool-restriction`: Tool-level enforcement that flow and subflow agents cannot use Read/Grep/Glob
  directly — all codebase exploration must go through @explore

### Modified Capabilities

- `orchestrator-tool-restriction`: Remove read/grep/glob from the allowed tools for orchestrator agents (flow,
  subflow). The delegation and read-only tools list changes from `task, read, grep, glob, list, skill, todowrite,
  question, webfetch` to `task, list, skill, todowrite, question, webfetch`.

## Impact

- `.opencode/agents/flow.md` — frontmatter permission change: replace `'*': allow` with explicit allowlist excluding read/grep/glob
- `.opencode/agents/subflow.md` — frontmatter permission change: same as flow
- `.claude/agents/flow.md` — Claude port equivalent: remove read/grep/glob from tools allowlist
- `openspec/specs/orchestrator-tool-restriction/spec.md` — update allowed tools list, remove read/grep/glob
