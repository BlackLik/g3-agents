# recursive-splitting

## Purpose

Rules for how recursive calls must split requests into smaller independent subtasks.

## Requirements

### Requirement: Recursive calls split requests into subtasks

When flow delegates to `@subflow` (OpenCode) or self-recurses (Claude), it SHALL decompose the request into N
independent subtasks and delegate each separately. The prompt SHALL NOT contain the full unsplit request.

#### Scenario: Complex task with 3 independent parts

- **WHEN** flow receives a task with 3 independent concerns (e.g., model, endpoint, tests)
- **THEN** flow SHALL create 3 separate subtask delegations, each with only its portion of the request

#### Scenario: Sequential dependent subtasks

- **WHEN** subtask B depends on subtask A's output
- **THEN** flow SHALL delegate A first, wait for completion, then delegate B with A's result as context

### Requirement: Subtask boundary clarity

Each subtask delegation SHALL have a clearly defined scope, success criteria, and output format. Subtasks SHALL NOT
overlap in responsibilities.

#### Scenario: Non-overlapping subtask definitions

- **WHEN** flow defines subtasks
- **THEN** each subtask SHALL specify exactly which files it touches and what output it produces

#### Scenario: Subtask output format

- **WHEN** a subtask completes
- **THEN** it SHALL return its output in a format that flow can merge with other subtask outputs

### Requirement: No full-request passthrough

Flow SHALL NOT delegate a task to `@subflow` or self-recursion where the prompt is the full original request unchanged.

#### Scenario: Full request passthrough detected

- **WHEN** flow is about to delegate to subflow
- **THEN** it SHALL verify the prompt is not identical to the original request
- **IF** it is identical
- **THEN** flow SHALL split it before delegating
