# clarification-policy

## Purpose

Rules governing how the orchestration system interacts with the user: assumptions-first execution, a bounded
question budget, escalation through the mediated cycle, and player escalating risk upward instead of asking.

## Requirements

### Requirement: Assumptions-first execution

Flow SHALL proceed on explicitly stated assumptions rather than asking the user whenever a reasonable
interpretation exists. Each assumption SHALL be written into the delegation prompt it affects and SHALL be named
in the final delivery.

#### Scenario: Minor ambiguity with a reasonable default

- **WHEN** a request has a minor ambiguity with a reasonable default interpretation
- **THEN** flow SHALL delegate with the assumption stated in the delegation prompt
- **THEN** flow SHALL NOT ask the user

#### Scenario: Assumption disclosed in delivery

- **WHEN** flow delivers a result produced under an assumption
- **THEN** the delivery SHALL name the assumption and offer to redo the work if the assumption was wrong

### Requirement: Bounded question budget and mediated escalation

Flow SHALL ask the user at most one question round per top-level request, and only when genuinely blocked:
ambiguous success criteria, a destructive or irreversible choice, or missing access. Clarification requests and
retry-budget escalations SHALL be delivered through the mediated cycle (drafted by `@player`, reviewed by
`@coach`) as messages that end the turn — never as interactive tool prompts and never as unreviewed plain text
from flow.

#### Scenario: Genuinely blocked

- **WHEN** flow is genuinely blocked by ambiguous success criteria, a destructive choice, or missing access
- **THEN** flow SHALL compose one clarification request through the mediated cycle, deliver it, and stop the turn

#### Scenario: Budget already spent

- **WHEN** flow has already asked one question round for the current top-level request
- **THEN** flow SHALL NOT ask again for that request
- **THEN** flow SHALL proceed on stated assumptions

#### Scenario: Retry budget exhaustion escalates via the same path

- **WHEN** the retry budget for a task is exhausted
- **THEN** the escalation SHALL follow the escalation requirement of the `cycle-priority` capability

### Requirement: Player escalates risk upward

`@player` SHALL NOT ask the user or any other agent for clarification. When a step looks risky or the task is
ambiguous, player SHALL stop and return upward with a warning describing the risk; the orchestrator decides
whether to proceed, adjust the task, or escalate to the user.

#### Scenario: Risky step

- **WHEN** player is about to run a destructive or risky command and is unsure
- **THEN** player SHALL NOT run it
- **THEN** player SHALL return a ⚠️ warning upward instead of asking anyone

#### Scenario: Orchestrator handles the warning

- **WHEN** the orchestrator receives a risk warning from player
- **THEN** flow SHALL either re-delegate with a tighter scope or escalate to the user per the question budget
