# review-routing

## Purpose

Rules ensuring all review work is routed to @coach, never to @player.

## Requirements

### Requirement: All review tasks go to coach

Flow SHALL route ALL review, verification, audit, and validation tasks to `@coach` via `subagent_type="coach"`. Flow
SHALL NEVER route such tasks to `@player`.

#### Scenario: Review after player execution

- **WHEN** `@player` completes a task and returns a result
- **THEN** flow SHALL call `task(..., subagent_type="coach")` with the player's output for review

#### Scenario: Review of existing code

- **WHEN** flow needs existing code reviewed (without player having just written it)
- **THEN** flow SHALL call `task(..., subagent_type="coach")` with the code to review

### Requirement: Keyword-based routing enforcement

Flow SHALL treat any task whose description or prompt contains any of the following keywords as review-only and route to
`@coach`: "review", "check", "verify", "audit", "validate".

#### Scenario: Task with review keyword

- **WHEN** a task prompt contains the word "review"
- **THEN** flow SHALL use `subagent_type="coach"` regardless of other content

#### Scenario: Task with validate keyword

- **WHEN** a task prompt contains the word "validate"
- **THEN** flow SHALL use `subagent_type="coach"` regardless of other content

### Requirement: Player rejects review tasks

If `@player` receives a task whose primary purpose is review, it SHALL reject it and return upward indicating the task
should be routed to `@coach`.

#### Scenario: Review task misdirected to player

- **WHEN** flow accidentally delegates a review task to `@player`
- **THEN** `@player` SHALL respond with "This is a review task — routing to @coach" and not execute it
