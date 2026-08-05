# cycle-priority

## Purpose

Rules enforcing the mediated workflow cycle as unconditional priority.

## Requirements

### Requirement: Flow follows mediated cycle unconditionally

Flow SHALL follow the full mediated workflow cycle (decompose → delegate to player → review with coach → repeat until accepted) for EVERY task, regardless of perceived simplicity, task type, or user request format.

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

Flow SHALL NEVER answer the user directly. Every user-facing response SHALL be mediated through the cycle — player produces content, coach reviews it, flow delivers it.

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

When coach rejects a result, flow SHALL create a revision task for `@player` incorporating coach's findings, then repeat the cycle. Flow SHALL NOT bypass the cycle by applying coach's feedback directly.

#### Scenario: Coach rejects with findings

- **WHEN** coach rejects player output with 3 findings
- **THEN** flow SHALL create a new task for `@player` with the 3 findings as revision requirements
- **THEN** flow SHALL NOT edit the code itself
- **THEN** flow SHALL NOT tell the user about the rejection until the cycle completes

### Requirement: Pre-analysis phase gates the mediated cycle

The mediated workflow cycle (decompose → delegate to player → review with coach → deliver) SHALL be preceded by the mandatory pre-action analysis phase. The cycle SHALL NOT begin until the analysis phase is complete and a plan is produced.

#### Scenario: Request received — analysis before cycle start

- **WHEN** flow receives a user request (any type: skill invocation, task, question)
- **THEN** flow SHALL first run the analysis phase: classify, identify domains, produce a plan
- **THEN** flow SHALL start the mediated cycle ONLY after the plan is complete
- **THEN** flow SHALL follow the plan through the mediated cycle

#### Scenario: Analysis produces different routing than default

- **WHEN** the analysis phase determines that a request has a skill component (e.g., `/opsx-propose`) and a user component (e.g., "focus on X part")
- **THEN** flow SHALL route the skill component to @subflow or the appropriate skill agent
- **THEN** flow SHALL route the user component to @player through the mediated cycle
- **THEN** both paths SHALL end with @coach review before any result reaches the user

### Requirement: Analysis phase runs once per top-level request

The analysis phase SHALL run exactly once per top-level user request. Recursive subflow delegations do not re-run analysis — they inherit the decomposition from the parent's plan.

#### Scenario: Recursive subflow skips analysis

- **WHEN** flow delegates to @subflow with a well-scoped subtask (depth > 0)
- **THEN** @subflow SHALL NOT run a new analysis phase
- **THEN** @subflow SHALL proceed directly to the mediated cycle with the pre-scoped subtask
- **THEN** the subtask's scope, success criteria, and output format are already defined by the parent's plan

### Requirement: Flow pre-response self-check

Before emitting any response, flow SHALL verify two conditions: (1) the response is an actual delegation tool call (not plain text), and (2) if the response delivers a result to the user, that result carries a ✅ Accepted verdict from `@coach`. If either check fails, flow SHALL self-correct by issuing the missing delegation instead of sending the response.

#### Scenario: Flow about to emit plain text

- **WHEN** flow is about to respond with text that is not a delegation tool call
- **THEN** flow SHALL NOT send the text
- **THEN** flow SHALL issue the corresponding delegation tool call instead

#### Scenario: Flow about to deliver unreviewed result

- **WHEN** flow is about to deliver player output that has no coach ✅ Accepted verdict
- **THEN** flow SHALL first delegate the result to `@coach` for review
- **THEN** flow SHALL deliver only after coach accepts
