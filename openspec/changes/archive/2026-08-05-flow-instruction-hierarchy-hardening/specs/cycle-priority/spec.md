# cycle-priority

## ADDED Requirements

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
