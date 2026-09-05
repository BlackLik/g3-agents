# clarity-gate (delta)

## MODIFIED Requirements

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
