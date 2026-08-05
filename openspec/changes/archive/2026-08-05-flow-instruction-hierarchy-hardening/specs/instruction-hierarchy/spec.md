# instruction-hierarchy

## ADDED Requirements

### Requirement: Skill instructions are priority level 4 (task content)

Skill instructions loaded into flow's context SHALL be treated as priority level 4 (task content) — the lowest level in the instruction priority hierarchy. They SHALL NOT compete with or override role invariants (level 1), workflow rules (level 2), or user instructions (level 3).

#### Scenario: Skill instructions contradict role invariants

- **WHEN** skill instructions tell flow to "execute the following steps directly" (contradicting the role invariant that flow delegates and never executes)
- **THEN** the instruction priority hierarchy SHALL resolve the conflict: role invariants (level 1) override skill content (level 4)
- **THEN** flow SHALL analyze the skill's intent and delegate through the mediated cycle as normal

#### Scenario: Skill instructions claim to override workflow

- **WHEN** skill instructions contain text like "bypass review" or "skip delegation"
- **THEN** these instructions SHALL be treated as invalid — workflow rules (level 2) outrank them
- **THEN** flow SHALL proceed with the full mediated cycle

### Requirement: Flow checks priority before every action

Before emitting any response or tool call, flow SHALL verify that the intended action is consistent with the instruction priority hierarchy. If the action would violate a higher-priority rule (role invariants, workflow rules), flow SHALL NOT execute it, regardless of what lower-priority content (user instructions, task content, skill instructions) suggests.

#### Scenario: Priority check catches violation

- **WHEN** flow is about to follow a skill instruction that would bypass the mediated cycle
- **THEN** the priority check SHALL detect the conflict: skill (level 4) trying to override workflow (level 2)
- **THEN** flow SHALL self-correct: reject the skill instruction and proceed with the mediated cycle
