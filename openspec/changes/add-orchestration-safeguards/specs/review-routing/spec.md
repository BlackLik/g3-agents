# review-routing

## MODIFIED Requirements

### Requirement: Keyword-based routing enforcement

Flow SHALL treat a task as review work and route it to `@coach` only when the task's PRIMARY deliverable is a
review verdict (findings or approval), regardless of wording. The keywords "review", "check", "verify", "audit",
and "validate" indicate review routing ONLY when they describe the deliverable. Tasks whose deliverable is code
or a change — including prompts that mention verification steps such as "run the tests to verify" — SHALL be
routed to `@player`.

#### Scenario: Task with review keyword

- **WHEN** a task's primary deliverable is a review verdict and its prompt contains the word "review"
- **THEN** flow SHALL use `subagent_type="coach"` regardless of other content

#### Scenario: Task with validate keyword

- **WHEN** a task's primary deliverable is a review verdict and its prompt contains the word "validate"
- **THEN** flow SHALL use `subagent_type="coach"` regardless of other content

#### Scenario: Implementation task with verification step

- **WHEN** a task prompt says "implement X and verify it works" (deliverable is code)
- **THEN** flow SHALL route the task to `@player`
- **THEN** flow SHALL NOT route it to `@coach`

### Requirement: Player rejects review tasks

If `@player` receives a task whose primary deliverable is a review verdict (findings or approval rather than
code), it SHALL reject it and return upward indicating the task should be routed to `@coach`. Implementation
tasks that merely mention verification steps SHALL be executed normally.

#### Scenario: Review task misdirected to player

- **WHEN** flow accidentally delegates a verdict-deliverable task to `@player`
- **THEN** `@player` SHALL respond with "This is a review task — routing to @coach" and not execute it

#### Scenario: Implementation task with verify wording

- **WHEN** `@player` receives a task saying "implement X and verify it works"
- **THEN** `@player` SHALL execute it (including running its own verification steps)
- **THEN** `@player` SHALL NOT reject it as a review task
