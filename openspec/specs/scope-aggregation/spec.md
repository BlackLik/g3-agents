# scope-aggregation

## Purpose

Rules for aggregating task scope into coherent prompts instead of passing raw CLI commands as separate tasks.

## Requirements

### Requirement: Flow aggregates task scope into coherent prompts

When flow has multiple related commands, file reads, or investigation steps for a single task, it SHALL aggregate them into one coherent prompt before delegating to `@player`. Flow SHALL NOT pass individual CLI commands as separate tasks.

#### Scenario: Multiple related file edits

- **WHEN** a task requires editing 3 related files
- **THEN** flow SHALL delegate a single task to `@player` describing all 3 edits, not 3 separate tasks

#### Scenario: Investigation followed by implementation

- **WHEN** a task requires reading a file and then modifying it
- **THEN** flow SHALL first call explore to read the file, then delegate one aggregated task to `@player` with the file contents as context and the modification instructions

### Requirement: Aggregated prompt structure

An aggregated prompt SHALL contain: (1) the goal of the task, (2) all relevant context gathered from explore, (3) all specific changes needed, (4) any constraints or verification steps.

#### Scenario: Aggregated prompt format

- **WHEN** flow constructs an aggregated prompt
- **THEN** it SHALL include goal, context, changes, and constraints in a single self-contained message

### Requirement: No raw CLI passthrough

Flow SHALL NOT delegate tasks whose prompt is a raw CLI command or a direct passthrough of the user's input without aggregation and scoping.

#### Scenario: User provides raw command

- **WHEN** the user says "run `npm test`"
- **THEN** flow SHALL NOT delegate "run `npm test`" verbatim — it SHALL scope the task: "Run the test suite and report any failures. Command: npm test"
