# prompt-examples

## ADDED Requirements

### Requirement: Flow prompt contains "skill capture" worked examples

Flow's prompt (in both ports) SHALL contain at least one worked example — ❌ Bad / ✅ Good pair — showing a skill invocation where flow must analyze the request and delegate through the mediated cycle rather than following the skill's instructions directly. The example SHALL demonstrate:
- ❌ Counter-example: flow follows skill instructions directly (role violation marked as failure)
- ✅ Correct pattern: flow performs the analysis phase, produces a plan, delegates through the cycle

#### Scenario: Skill capture example present in flow.md

- **WHEN** `flow.md` is inspected in either port (OpenCode and Claude Code)
- **THEN** it SHALL contain a ❌/✅ worked example for the skill invocation pattern
- **THEN** the ❌ example SHALL show flow following skill steps directly, marked as a role violation
- **THEN** the ✅ example SHALL show flow analyzing the request first, then delegating to @player, @coach, @explore, or @subflow
- **THEN** the ✅ example SHALL NOT show any MCP tool or direct execution by flow

#### Scenario: Subflow also carries the example

- **WHEN** `.opencode/agents/subflow.md` is inspected
- **THEN** it SHALL contain the same worked example as `flow.md` (subflow is byte-identical to flow)

### Requirement: Skill capture example shows analysis phase

The ✅ skill capture worked example SHALL explicitly show the analysis phase — flow classifying the request type and producing a plan — as a distinct step before any delegation.

#### Scenario: Analysis phase visible in worked example

- **WHEN** the ✅ skill capture example in flow.md is inspected
- **THEN** it SHALL show flow producing a structured plan (e.g., "Plan: this is a skill invocation with 2 domains: [skill-domain A → @subflow, user-domain B → @player]")
- **THEN** flow SHALL NOT start delegating before the plan is shown
