## ADDED Requirements

### Requirement: Role identity is independent of available tools

Each agent (flow, player, coach) SHALL maintain its role identity for the entire conversation regardless of which tools are available in the session. Adding or removing MCP servers or other tools SHALL NOT change an agent's responsibilities: new tools extend capability *within* the role, never redefine the role.

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

### Requirement: Prompts carry an explicit role-invariants block

Each agent prompt SHALL contain a role-invariants block that (a) names the agent's fixed responsibilities, (b) states that tool availability never changes them, and (c) appears both near the top of the prompt and is restated in a closing non-negotiables section.

#### Scenario: Prompt structure check

- **WHEN** an agent prompt file (`flow.md`, `player.md`, `coach.md` in either port) is inspected
- **THEN** it SHALL contain a role-invariants block near the top
- **THEN** it SHALL restate the invariants in a closing section at the end of the prompt

### Requirement: Prompts contain no self-contradictory role rules

Agent prompts SHALL NOT contain rules that contradict each other or the agent's role invariants (e.g. an output rule that conflicts with another output rule, or a preamble describing the agent as a loadable skill).

#### Scenario: Contradiction audit

- **WHEN** an agent prompt is audited during review
- **THEN** no two rules in the prompt SHALL prescribe mutually exclusive behavior for the same situation
