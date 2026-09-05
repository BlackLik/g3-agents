# recursive-splitting (delta)

## MODIFIED Requirements

### Requirement: Recursive calls split requests into subtasks

When flow routes a task to the per-task orchestrator (currently `@subflow`), the orchestrator SHALL decompose the
task into N independent subtasks and delegate each separately. Flow composes the task handoff — scope, success
criteria, and output format — but the decomposition into subtasks happens inside the per-task orchestrator's mediated
cycle. The prompt SHALL NOT contain the full unsplit request.

#### Scenario: Complex task with 3 independent parts

- **WHEN** flow receives a task with 3 independent concerns (e.g., model, endpoint, tests)
- **THEN** flow SHALL compose the handoff for the per-task orchestrator with the task's scope, success criteria, and
  output format
- **THEN** the per-task orchestrator SHALL create 3 separate subtask delegations, each with only its portion of the
  request

#### Scenario: Sequential dependent subtasks

- **WHEN** subtask B depends on subtask A's output
- **THEN** the per-task orchestrator SHALL delegate A first, wait for completion, then delegate B with A's result as
  context

### Requirement: No full-request passthrough

Flow SHALL NOT delegate a task to the per-task orchestrator where the prompt is the full original request unchanged;
the orchestrator SHALL NOT delegate a subtask where the prompt is the full unsplit task.

#### Scenario: Full request passthrough detected

- **WHEN** flow is about to delegate to the per-task orchestrator
- **THEN** it SHALL verify the prompt is not identical to the original request
- **IF** it is identical
- **THEN** flow SHALL compose a scoped handoff before delegating

## ADDED Requirements

### Requirement: Every task routes through the per-task orchestrator (uniformity)

Flow SHALL route EVERY task to the per-task orchestrator (currently `@subflow`) regardless of perceived simplicity.
There SHALL be NO fast path: flow SHALL NOT delegate any task directly to `@player` for the mediated cycle, and the
Claude port SHALL NOT self-recurse for it. Simple and complex tasks run the same pipeline.

#### Scenario: Simple one-line task routes to subflow

- **WHEN** a user requests a one-line change that a previous model classified as simple (≤2 concerns)
- **THEN** flow SHALL compose the handoff and delegate to `@subflow`
- **THEN** flow SHALL NOT delegate directly to `@player`

#### Scenario: Claude port does not self-recurse

- **WHEN** the Claude-port flow receives a complex task
- **THEN** it SHALL delegate to its `subflow` agent (which exists after this change)
- **THEN** it SHALL NOT delegate recursively to `@flow`

#### Scenario: Subtask decomposition inside the orchestrator

- **WHEN** the per-task orchestrator receives a task
- **THEN** it SHALL decompose into independent subtasks and delegate each to `@player` (with `@coach` review per the
  cycle-priority capability)
- **THEN** it SHALL NOT re-route the whole task back to flow
