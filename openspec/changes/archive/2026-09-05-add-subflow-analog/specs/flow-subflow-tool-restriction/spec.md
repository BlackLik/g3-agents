# flow-subflow-tool-restriction (delta)

## MODIFIED Requirements

### Requirement: Claude port removes Read/Grep/Glob from tools allowlist

The `tools:` frontmatter of `.claude/agents/flow.md` and `.claude/agents/subflow.md` SHALL exclude `Read`, `Grep`, and
`Glob` from the explicit allowlist. `flow.md` SHALL name `subflow` in its `Agent(...)` list
(`Agent(subflow, player, coach, Explore)`) and SHALL NOT name `flow` (no self-recursion); `subflow.md` SHALL omit
`subflow` from its own `Agent(...)` list (`Agent(player, coach, Explore)`).

#### Scenario: Claude orchestrators have no Read/Grep/Glob tools

- **WHEN** the `tools:` frontmatter of `.claude/agents/flow.md` or `.claude/agents/subflow.md` is inspected
- **THEN** it SHALL NOT contain `Read`, `Grep`, or `Glob`
- **THEN** `flow.md` SHALL contain `Agent(subflow, player, coach, Explore)` and `mcp__*`
- **THEN** `subflow.md` SHALL contain `Agent(player, coach, Explore)` — no `subflow` self-recursion

#### Scenario: Claude flow cannot invoke Read

- **WHEN** the Claude-port flow or subflow subagent attempts to invoke Read, Grep, or Glob
- **THEN** the tool SHALL be unavailable to the subagent
