# instruction-hierarchy (delta)

## ADDED Requirements

### Requirement: Priority levels carry explicit inline markers

Each normative rule in an agent prompt that participates in the priority hierarchy SHALL carry an explicit inline
priority marker immediately before its formulation (e.g. `[PRIORITY:1] Never write or edit code.`). Role invariants
SHALL be marked level 1, workflow rules level 2, user instructions level 3, and task content level 4. Prose-only
declarations of the hierarchy (an explanatory paragraph without per-rule markers) SHALL NOT be the sole expression of
priority. This applies to every agent prompt (`flow.md`, `subflow.md`, `player.md`, `coach.md`) in both ports.

#### Scenario: Marker presence audit

- **WHEN** any agent prompt file (`flow.md`, `subflow.md`, `player.md`, `coach.md`) in either port is inspected
- **THEN** every role invariant SHALL carry a `[PRIORITY:1]` marker directly before the rule text
- **THEN** every workflow rule SHALL carry a `[PRIORITY:2]` marker directly before the rule text

#### Scenario: Markers beat prose on conflict

- **WHEN** a prose passage and an inline marker would imply different priorities for the same rule
- **THEN** the inline marker SHALL be authoritative
- **THEN** the prompt SHALL NOT contain prose that contradicts any rule's marker
