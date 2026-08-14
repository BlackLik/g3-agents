# cycle-priority

## MODIFIED Requirements

### Requirement: Cycle repeat on rejection

When coach rejects a result, flow SHALL create a revision task for `@player` incorporating coach's findings, then
repeat the cycle. Flow SHALL NOT bypass the cycle by applying coach's feedback directly. Revision rounds SHALL be
bounded: at most 3 revision rounds per task per recursion level. After the 3rd consecutive rejection of the same
task at the same depth, flow SHALL stop revising and escalate per the escalation requirement. While the budget
remains, flow SHALL NOT tell the user about the rejection; once the budget is exhausted, escalation to the user
is mandatory.

#### Scenario: Coach rejects with findings

- **WHEN** coach rejects player output with 3 findings and the retry budget is not exhausted
- **THEN** flow SHALL create a new task for `@player` with the 3 findings as revision requirements
- **THEN** flow SHALL NOT edit the code itself
- **THEN** flow SHALL NOT tell the user about the rejection while the budget remains

#### Scenario: Retry budget exhausted

- **WHEN** coach rejects the 3rd consecutive revision of the same task at the same recursion level
- **THEN** flow SHALL NOT create another revision task
- **THEN** flow SHALL escalate to the user per the escalation requirement

## ADDED Requirements

### Requirement: Escalation on retry budget exhaustion

When the retry budget is exhausted, flow SHALL escalate through the mediated cycle: `@player` drafts an
escalation summary containing coach's open findings, what changed across revision rounds, and the current state;
`@coach` reviews the summary for accuracy; flow delivers the reviewed summary to the user with an explicit
choice — accept as-is, re-approach, or abort — and SHALL stop the turn. The user's reply SHALL be treated as a
new top-level request. The retry budget SHALL apply to the escalation-summary review as well.

#### Scenario: Escalation summary is mediated

- **WHEN** the retry budget for a task is exhausted
- **THEN** flow SHALL delegate drafting of the escalation summary to `@player`
- **THEN** flow SHALL pass the draft to `@coach` for accuracy review
- **THEN** flow SHALL deliver the reviewed summary with the accept / re-approach / abort choice and stop

#### Scenario: User replies to an escalation

- **WHEN** the user responds to a delivered escalation (e.g., "accept as-is" or "re-approach with Y")
- **THEN** flow SHALL treat the reply as a new top-level request with a fresh analysis phase and fresh retry
  budgets

### Requirement: Revision continuity across rounds

Revision delegations SHALL preserve memory of prior rounds. When the runtime's delegation tool supports resuming
a subagent session, flow SHALL resume the same `@player` session for each revision round; otherwise each revision
prompt SHALL embed coach's findings from ALL prior rounds verbatim, newest round first.

#### Scenario: Runtime supports session resume

- **WHEN** flow creates a revision task in a runtime whose delegation tool exposes session resume
- **THEN** flow SHALL resume the same player session rather than starting a fresh one

#### Scenario: Runtime without session resume

- **WHEN** the runtime's delegation tool has no session resume capability
- **THEN** the revision prompt SHALL contain coach's findings from every prior round verbatim, newest first
