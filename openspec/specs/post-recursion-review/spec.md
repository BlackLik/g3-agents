# post-recursion-review

## Purpose

Rules requiring @coach review after each recursion level completes.

## Requirements

### Requirement: Coach review after each recursion level

After all subtasks at a given recursion level complete and their results are merged, flow SHALL invoke `@coach` to
review the merged result before proceeding to the next level or returning to the caller.

#### Scenario: Single recursion level with 3 subtasks

- **WHEN** flow splits a task into 3 subtasks and delegates to subflow
- **THEN** after all 3 subtasks complete and results are merged
- **THEN** flow SHALL call `task(..., subagent_type="coach")` with the merged result

#### Scenario: Nested recursion (depth 0 → depth 1 → depth 2)

- **WHEN** depth-1 subflow splits into depth-2 subtasks
- **THEN** after depth-2 subtasks complete and merge
- **THEN** depth-1 subflow SHALL call coach on the merged result before returning to depth-0 flow

### Requirement: Coach review scope per level

Each recursion level's coach review SHALL be scoped to the subtasks at that level only. The review SHALL NOT re-review
work from parent levels.

#### Scenario: Level-scoped review

- **WHEN** depth-1 subflow calls coach after depth-2 completes
- **THEN** coach SHALL review only the depth-2 subtask outputs, not the entire merged result from depth-1

#### Scenario: Level communicated in coach prompt

- **WHEN** flow calls coach for a recursion-level review
- **THEN** flow SHALL include the depth level in the coach prompt: "Review the following depth-N subtask outputs: [list
  of outputs]"
- **THEN** coach SHALL review only the listed outputs

### Requirement: Review gate blocks progression

If coach rejects the merged result at any recursion level, flow SHALL NOT proceed to the next level or return to the
caller. Flow SHALL create revision tasks and repeat until coach accepts.

#### Scenario: Rejected merge at depth 1

- **WHEN** coach rejects the merged result at depth 1
- **THEN** flow SHALL create revision tasks for the rejected subtasks
- **THEN** flow SHALL NOT return to depth 0 until coach accepts
