# cycle-priority (delta)

## MODIFIED Requirements

### Requirement: Flow follows mediated cycle unconditionally

The full mediated workflow cycle (decompose → delegate to player → review with coach → repeat until accepted) SHALL
be followed for EVERY task, regardless of perceived simplicity, task type, or user request format. The cycle runs
INSIDE the per-task orchestrator (currently `@subflow`): flow routes every task to `@subflow`, and `@subflow` owns
the whole cycle internally — decompose → explore → player → coach → revisions until APPROVE — then returns upward
ONLY the APPROVED result plus the path to the handoff file. Flow NEVER runs the mediated cycle itself.

#### Scenario: Simple one-line change

- **WHEN** user requests a one-line code change
- **THEN** flow SHALL delegate the task to `@subflow`
- **THEN** `@subflow` SHALL delegate to `@player` for the change
- **THEN** `@subflow` SHALL pass the result to `@coach` for review
- **THEN** the cycle SHALL repeat until coach approves

#### Scenario: User asks a question

- **WHEN** user asks a question instead of requesting a change
- **THEN** flow SHALL delegate the task to `@subflow`
- **THEN** `@subflow` SHALL delegate to `@player` to formulate the answer
- **THEN** `@subflow` SHALL pass the answer to `@coach` for review
- **THEN** flow SHALL relay the approved answer to the user

#### Scenario: Flow returns only the approved result

- **WHEN** a task's cycle completes inside `@subflow`
- **THEN** `@subflow` SHALL return upward the APPROVED result and the path to the handoff file
- **THEN** flow SHALL relay the result to the user
- **THEN** flow SHALL NOT re-run any coach review of the same player call (no extra coach pass at flow exit)

### Requirement: Cycle repeat on rejection

When coach rejects a result, the per-task orchestrator SHALL create a revision task for `@player` incorporating
coach's findings, then repeat the cycle. The inner loop is N=N: N player calls = N coach calls until coach APPROVE.
Each revision SHALL run in a FRESH `@player` session with ALL prior coach findings embedded verbatim, newest round
first. The orchestrator SHALL NOT bypass the cycle by applying coach's feedback directly. Revision rounds SHALL be
bounded: at most 3 revision rounds per task per recursion level. After the 3rd consecutive rejection of the same task
at the same depth, the orchestrator SHALL stop revising and escalate per the escalation requirement. While the budget
remains, the user SHALL NOT be told about the rejection; once the budget is exhausted, escalation to the user is
mandatory.

#### Scenario: Coach rejects with findings

- **WHEN** coach rejects player output with 3 findings and the retry budget is not exhausted
- **THEN** the per-task orchestrator SHALL create a new FRESH task for `@player` with the 3 findings as revision
  requirements
- **THEN** the revision prompt SHALL embed all prior coach findings verbatim, newest first
- **THEN** the orchestrator SHALL NOT edit the code itself
- **THEN** flow SHALL NOT tell the user about the rejection while the budget remains

#### Scenario: Retry budget exhausted

- **WHEN** coach rejects the 3rd consecutive revision of the same task at the same recursion level
- **THEN** the per-task orchestrator SHALL NOT create another revision task
- **THEN** it SHALL escalate per the escalation requirement, and flow SHALL deliver the escalation to the user

### Requirement: Flow pre-response self-check

Before emitting any response, flow SHALL verify two conditions: (1) the response is an actual delegation tool call
(not plain text), and (2) if the response delivers a result to the user, that result carries an `APPROVE` verdict
from `@coach` obtained inside `@subflow`'s cycle. If either check fails, flow SHALL self-correct by issuing the
missing delegation instead of sending the response.

#### Scenario: Flow about to emit plain text

- **WHEN** flow is about to respond with text that is not a delegation tool call
- **THEN** flow SHALL NOT send the text
- **THEN** flow SHALL issue the corresponding delegation tool call instead

#### Scenario: Flow about to deliver unreviewed result

- **WHEN** flow is about to deliver player output that has no coach `APPROVE` verdict
- **THEN** flow SHALL route the result through the per-task orchestrator's cycle so `@coach` reviews it
- **THEN** flow SHALL deliver only after coach approves

### Requirement: Pre-analysis phase gates the mediated cycle

The mediated workflow cycle SHALL be preceded by the mandatory pre-action analysis phase. Flow runs the analysis once
per top-level user request — classify, identify domains, produce the decomposition plan — and composes the task
handoff. The cycle SHALL NOT begin until the analysis phase is complete and a plan is produced. The per-task
orchestrator then runs the mediated cycle for its task.

#### Scenario: Request received — analysis before cycle start

- **WHEN** flow receives a user request (any type: skill invocation, task, question)
- **THEN** flow SHALL first run the analysis phase: classify, identify domains, produce a plan
- **THEN** flow SHALL compose the task handoff from the plan
- **THEN** flow SHALL delegate the task to `@subflow` ONLY after the plan is complete
- **THEN** `@subflow` SHALL run the mediated cycle for the task

### Requirement: Analysis phase runs once per top-level request

The analysis phase SHALL run exactly once per top-level user request, in flow. The per-task orchestrator does not
re-run flow's top-level analysis; it runs its own internal decomposition of the handed-off task as part of its
mediated cycle.

#### Scenario: Per-task orchestrator decomposes its task

- **WHEN** flow delegates a well-scoped task to `@subflow`
- **THEN** `@subflow` SHALL NOT re-run flow's top-level analysis
- **THEN** `@subflow` SHALL decompose the task internally into player/coach/explore delegations per its scope,
  success criteria, and output format

### Requirement: Escalation on retry budget exhaustion

When the retry budget is exhausted inside the per-task orchestrator, it SHALL escalate through the mediated cycle:
`@player` drafts an escalation summary containing coach's open findings, what changed across revision rounds, and the
current state; `@coach` reviews the summary for accuracy; the orchestrator passes the reviewed summary upward to flow,
which delivers it to the user with an explicit choice — accept as-is, re-approach, or abort — and SHALL stop the turn.
The user's reply SHALL be treated as a new top-level request. The retry budget SHALL apply to the escalation-summary
review as well.

#### Scenario: Escalation summary is mediated

- **WHEN** the retry budget for a task is exhausted
- **THEN** the per-task orchestrator SHALL delegate drafting of the escalation summary to `@player`
- **THEN** the orchestrator SHALL pass the draft to `@coach` for accuracy review
- **THEN** the reviewed summary SHALL be returned upward to flow
- **THEN** flow SHALL deliver the reviewed summary with the accept / re-approach / abort choice and stop

### Requirement: Revision continuity across rounds

Revision delegations SHALL preserve memory of prior rounds WITHOUT resuming any session. Every invocation SHALL be a
fresh session. Each revision prompt SHALL embed coach's findings from ALL prior rounds verbatim, newest round first.
Inter-session context SHALL travel through the handoff file protocol (see the session-handoff capability); the
`task_id` session-resume path is REMOVED from the protocol in both ports.

#### Scenario: Every revision is a fresh session

- **WHEN** flow or the per-task orchestrator creates a revision task
- **THEN** it SHALL start a fresh `@player` session rather than resuming a prior one
- **THEN** it SHALL NOT pass a task/session id for resume

#### Scenario: Runtime without session resume

- **WHEN** the runtime's delegation tool has no session resume capability
- **THEN** the revision prompt SHALL contain coach's findings from every prior round verbatim, newest first
- **THEN** the handoff file SHALL carry any inter-session context
