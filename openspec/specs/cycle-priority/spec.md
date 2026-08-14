# cycle-priority

## Purpose

Rules enforcing the mediated workflow cycle as unconditional priority.

## Requirements

### Requirement: Flow follows mediated cycle unconditionally

Flow SHALL follow the full mediated workflow cycle (decompose → delegate to player → review with coach → repeat until
accepted) for EVERY task, regardless of perceived simplicity, task type, or user request format.

#### Scenario: Simple one-line change

- **WHEN** user requests a one-line code change
- **THEN** flow SHALL delegate to `@player` for the change
- **THEN** flow SHALL pass the result to `@coach` for review
- **THEN** flow SHALL repeat until coach accepts

#### Scenario: User asks a question

- **WHEN** user asks a question instead of requesting a change
- **THEN** flow SHALL NOT answer directly
- **THEN** flow SHALL delegate to `@player` to formulate the answer
- **THEN** flow SHALL pass the answer to `@coach` for review

### Requirement: No direct answers

Flow SHALL NEVER answer the user directly. Every user-facing response SHALL be mediated through the cycle — player
produces content, coach reviews it, flow delivers it.

#### Scenario: User asks "what is X?"

- **WHEN** user asks a factual question
- **THEN** flow SHALL delegate research to `@player` (or `@explore` for codebase questions)
- **THEN** flow SHALL pass the result to `@coach` for accuracy review
- **THEN** flow SHALL deliver the reviewed answer to the user

### Requirement: No skipping coach review

Flow SHALL NEVER skip the coach review step, even for tasks that appear trivial or low-risk.

#### Scenario: Trivial typo fix

- **WHEN** user reports a typo in documentation
- **THEN** flow SHALL delegate the fix to `@player`
- **THEN** flow SHALL pass the diff to `@coach` for review
- **THEN** flow SHALL NOT deliver the fix without coach acceptance

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

### Requirement: Pre-analysis phase gates the mediated cycle

The mediated workflow cycle (decompose → delegate to player → review with coach → deliver) SHALL be preceded by the
mandatory pre-action analysis phase. The cycle SHALL NOT begin until the analysis phase is complete and a plan is
produced.

#### Scenario: Request received — analysis before cycle start

- **WHEN** flow receives a user request (any type: skill invocation, task, question)
- **THEN** flow SHALL first run the analysis phase: classify, identify domains, produce a plan
- **THEN** flow SHALL start the mediated cycle ONLY after the plan is complete
- **THEN** flow SHALL follow the plan through the mediated cycle

#### Scenario: Analysis produces different routing than default

- **WHEN** the analysis phase determines that a request has a skill component (e.g., `/opsx-propose`) and a user
  component (e.g., "focus on X part")
- **THEN** flow SHALL route the skill component to @subflow or the appropriate skill agent
- **THEN** flow SHALL route the user component to @player through the mediated cycle
- **THEN** both paths SHALL end with @coach review before any result reaches the user

### Requirement: Analysis phase runs once per top-level request

The analysis phase SHALL run exactly once per top-level user request. Recursive subflow delegations do not re-run
analysis — they inherit the decomposition from the parent's plan.

#### Scenario: Recursive subflow skips analysis

- **WHEN** flow delegates to @subflow with a well-scoped subtask (depth > 0)
- **THEN** @subflow SHALL NOT run a new analysis phase
- **THEN** @subflow SHALL proceed directly to the mediated cycle with the pre-scoped subtask
- **THEN** the subtask's scope, success criteria, and output format are already defined by the parent's plan

### Requirement: Flow pre-response self-check

Before emitting any response, flow SHALL verify two conditions: (1) the response is an actual delegation tool call (not
plain text), and (2) if the response delivers a result to the user, that result carries a ✅ Accepted verdict from
`@coach`. If either check fails, flow SHALL self-correct by issuing the missing delegation instead of sending the
response.

#### Scenario: Flow about to emit plain text

- **WHEN** flow is about to respond with text that is not a delegation tool call
- **THEN** flow SHALL NOT send the text
- **THEN** flow SHALL issue the corresponding delegation tool call instead

#### Scenario: Flow about to deliver unreviewed result

- **WHEN** flow is about to deliver player output that has no coach ✅ Accepted verdict
- **THEN** flow SHALL first delegate the result to `@coach` for review
- **THEN** flow SHALL deliver only after coach accepts
