# post-recursion-review (delta)

## MODIFIED Requirements

### Requirement: Coach review after each recursion level

Coach review SHALL happen INSIDE the per-task orchestrator (currently `@subflow`) for each player call of its task:
the orchestrator SHALL invoke `@coach` after each player delegation and SHALL repeat until `APPROVE` (N=N). Flow
SHALL perform NO extra coach pass at its exit — `@subflow`'s APPROVE is sufficient; there SHALL be exactly one coach
pass per player call, no doubling. Flow's only role SHALL be relaying the approved result and the handoff-file path.

#### Scenario: Single task with 3 player calls

- **WHEN** the per-task orchestrator decomposes a task into 3 player delegations
- **THEN** after each player delegation completes, the orchestrator SHALL call `@coach` with that player call's
  result
- **THEN** the orchestrator SHALL proceed to the next player delegation only after `APPROVE`

#### Scenario: Flow does not re-review at exit

- **WHEN** a task's cycle completes inside `@subflow` with an `APPROVE` verdict
- **THEN** flow SHALL relay the approved result to the user
- **THEN** flow SHALL NOT invoke `@coach` again on the same player call (no extra coach pass at flow exit)

### Requirement: Coach review scope per level

Each coach review in the per-task orchestrator SHALL be scoped to the player call it accompanies. The review SHALL
NOT re-review work from other player calls or from flow's routing.

#### Scenario: Review scoped to one player call

- **WHEN** the orchestrator calls coach after a player delegation completes
- **THEN** coach SHALL review only that player call's output, not the entire task or prior player calls

### Requirement: Review gate blocks progression

If coach rejects the result of a player call, the per-task orchestrator SHALL NOT proceed to the next delegation or
return to flow. The orchestrator SHALL create a fresh revision `@player` session (with all prior findings embedded
verbatim) and repeat until coach approves, bounded by the retry budget.

#### Scenario: Rejected player call blocks progression

- **WHEN** coach rejects the result of a player call
- **THEN** the orchestrator SHALL create a fresh revision task for `@player` with the findings embedded verbatim
- **THEN** the orchestrator SHALL NOT proceed or return to flow until coach approves
