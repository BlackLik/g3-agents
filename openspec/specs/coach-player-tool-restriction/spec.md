# coach-player-tool-restriction

## Purpose

Tool-layer enforcement of the coach and player role invariants in both ports: the coach allowlists grant review-only
access (no mutation, shell, or direct exploration tools), and the player allowlist grants MCP access only through the
`mcp__*` pattern — never through a bare `*` wildcard.

## Requirements

### Requirement: Claude-port coach allowlist is review-only at the tool layer

The `tools:` frontmatter of `.claude/agents/coach.md` SHALL be exactly `Read, Agent(Explore, coach), mcp__*`. It SHALL
NOT contain a bare `*` wildcard, and SHALL NOT contain `Edit`, `Write`, `NotebookEdit`, `Bash`, `Glob`, `Grep`,
`WebFetch`, `WebSearch`, or `Skill`. The prompt body SHALL remain unchanged.

#### Scenario: coach.md frontmatter contains only the review-only allowlist

- **WHEN** the `tools:` frontmatter of `.claude/agents/coach.md` is inspected
- **THEN** it SHALL be exactly `Read, Agent(Explore, coach), mcp__*`
- **THEN** no bare `*` wildcard SHALL be present

#### Scenario: coach attempts to modify a file or run a shell command

- **WHEN** a coach session attempts to invoke Edit, Write, NotebookEdit, or Bash
- **THEN** the tool SHALL be unavailable to the subagent
- **THEN** coach SHALL return findings and a verdict without applying fixes, per its role invariants

#### Scenario: coach needs codebase or web content beyond the provided diff

- **WHEN** coach needs file history, additional file contents, or web content during a review
- **THEN** coach SHALL delegate the gathering to the Explore agent via `Agent(subagent_type="explore")`
- **THEN** coach SHALL NOT invoke Bash, Grep, Glob, WebFetch, or WebSearch directly (they are absent from its
  allowlist)

### Requirement: OpenCode coach permission map enforces the same restriction

The `permission` frontmatter of `.opencode/agents/coach.md` SHALL deny `bash`, `edit`, `grep`, `glob`, `list`, `lsp`,
`question`, `websearch`, `webfetch`, `skill`, and `todowrite`; SHALL deny `read` except for `*/reference/*.md`; and
SHALL restrict `task` to the `explore` and `coach` targets.

#### Scenario: coach.md permission map denies mutation and exploration tools

- **WHEN** the frontmatter of `.opencode/agents/coach.md` is inspected
- **THEN** `bash`, `edit`, `grep`, `glob`, `websearch`, `webfetch`, and `skill` SHALL be denied
- **THEN** `read` SHALL be denied except for `*/reference/*.md`
- **THEN** `task` SHALL be allowed for the `explore` and `coach` targets only

### Requirement: Claude-port player allowlist has no bare wildcard

The `tools:` frontmatter of `.claude/agents/player.md` SHALL be exactly `Read, Edit, Write, Bash, Glob, Grep,
WebFetch, WebSearch, Skill, Agent(Explore, player), mcp__*`. MCP access SHALL be granted only through the `mcp__*`
pattern, never through a bare `*` wildcard. The prompt body SHALL remain unchanged.

#### Scenario: player.md frontmatter grants MCP via mcp__* only

- **WHEN** the `tools:` frontmatter of `.claude/agents/player.md` is inspected
- **THEN** it SHALL end with `mcp__*` and SHALL NOT contain a bare `*` wildcard
- **THEN** `Read`, `Edit`, `Write`, `Bash`, `Glob`, `Grep`, and `Agent(Explore, player)` SHALL be present
