# clarity-gate Specification

## Purpose

A single bounded pre-implementation clarification round: when the orchestrator is materially blocked, it asks the user
once — interactive `question` tool on the OpenCode port at depth 0, mediated fallback elsewhere — before any
implementation delegation.

## Requirements

### Requirement: Pre-implementation clarity gate

A single bounded pre-implementation clarification round: when the orchestrator is materially blocked, it asks the user
once via the interactive `question` tool (OpenCode port, depth 0 only) before any implementation delegation, instead of
burning tokens on wrong assumptions. When no interactive question tool exists, the round falls back to the mediated
cycle.

After the analysis phase (and any `@explore` context pass) and before composing the first task handoff (the first
`@subflow` delegation), `flow` SHALL assess whether it is materially blocked. If so, `flow` SHALL ask the user at most
ONE round of questions via the `question` tool before delegating any task. Materially blocked means: ambiguous success
criteria, a destructive or irreversible choice, or missing access. If not materially blocked, `flow` SHALL proceed on
stated assumptions without asking.

#### Scenario: Materially blocked task triggers one question round

- **WHEN** a top-level request has ambiguous success criteria, a destructive choice, or missing access
- **THEN** flow SHALL invoke the `question` tool exactly once with all open questions batched
- **THEN** flow SHALL incorporate the answers into the task handoffs
- **THEN** flow SHALL NOT ask further question rounds for that top-level request

#### Scenario: Clear task proceeds on assumptions

- **WHEN** a top-level request has a reasonable interpretation and no destructive choice
- **THEN** flow SHALL NOT invoke the `question` tool
- **THEN** flow SHALL proceed on stated assumptions per the clarification policy

#### Scenario: Question round is the only non-task response

- **WHEN** flow emits a response that is not a `task` tool call
- **THEN** that response SHALL be exactly one `question` tool call under this gate
- **THEN** all other user-facing output SHALL remain a coach-reviewed mediated delivery

### Requirement: Question tool restricted to depth 0

The `question` permission SHALL be granted to `flow` (primary, depth 0) only. `subflow` — which always runs at depth ≥1
— SHALL NOT have the `question` tool available, and nested orchestrators SHALL NOT ask the user questions.

#### Scenario: flow.md grants question, subflow.md does not

- **WHEN** the frontmatter of `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` are compared
- **THEN** `flow.md` SHALL contain `question: allow`
- **THEN** `subflow.md` SHALL NOT contain `question: allow`

#### Scenario: Subflow hit by a blocking ambiguity

- **WHEN** a subflow at depth ≥1 encounters a materially blocking ambiguity
- **THEN** it SHALL proceed on a stated assumption or escalate the finding upward through the mediated cycle
- **THEN** it SHALL NOT ask the user a question directly

### Requirement: Mediated fallback when no interactive question tool exists

In environments without an interactive question tool (the Claude port), the single question round SHALL still happen,
but SHALL be delivered through the mediated cycle: `@player` drafts the questions, `@coach` reviews them, and `flow`
delivers them as a turn-ending message. The bounded one-round limit still applies.

#### Scenario: Claude port needs clarification

- **WHEN** the Claude-port flow is materially blocked
- **THEN** it SHALL produce the question round via player-draft → coach-review → delivery, not via an interactive tool
- **THEN** the round SHALL still be limited to one per top-level request
