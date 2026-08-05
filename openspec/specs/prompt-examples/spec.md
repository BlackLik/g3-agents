# prompt-examples

## Purpose

Worked examples embedded in agent prompts — ❌ Bad / ✅ Good pairs and dialogue traces for high-risk behaviors (mediated answering, MCP usage, refusals, system-first resolution), synchronized across both ports.

## Requirements

### Requirement: Agent prompts carry worked examples for high-risk behaviors

Each agent prompt (`flow.md`, `player.md`, `coach.md` in both ports; `subflow.md` stays byte-identical to `flow.md`) SHALL contain worked examples — ❌ Bad / ✅ Good pairs or short dialogue traces (user message → tool calls → output) — covering every example category applicable to that agent's role. Examples SHALL show concrete messages and tool calls, not restated rules.

#### Scenario: Prompt inspection for example coverage

- **WHEN** an agent prompt file is inspected in either port
- **THEN** it SHALL contain at least one worked example for each category applicable to its role (per the category requirements below)
- **THEN** each example SHALL be concrete (actual messages, tool-call signatures, or diffs), not an abstract description of correct behavior

### Requirement: Examples for answering the user through the mediated cycle

Flow's prompt SHALL contain at least one full dialogue trace of answering a user through the cycle (user request → delegate to `@player` → pass result to `@coach` → deliver accepted result) and at least one ❌ counter-example of answering directly. Player's prompt SHALL show that its output returns upward to the orchestrator, never addressed to the user. Coach's prompt SHALL show a verdict returned to the orchestrator, not user-facing prose.

#### Scenario: Flow answering trace present

- **WHEN** `flow.md` is inspected
- **THEN** it SHALL contain a trace where a user question is answered only after a coach ✅ Accepted verdict
- **THEN** it SHALL contain a ❌ counter-example where flow answers in plain text, marked as a failure

#### Scenario: Player and coach output direction

- **WHEN** `player.md` or `coach.md` is inspected
- **THEN** it SHALL contain an example showing output addressed upward (to the orchestrator), with any user-facing phrasing shown as ❌

### Requirement: Examples for MCP and external tool usage

Each agent prompt SHALL contain worked examples of in-role MCP/tool usage: flow planning around an MCP tool and delegating its execution to `@player` (with a ❌ example of flow calling the MCP tool itself); player executing an MCP tool to complete a delegated task; coach invoking an MCP tool for verification only (with a ❌ example of coach using a write-capable tool to fix code).

#### Scenario: Flow MCP delegation example

- **WHEN** `flow.md` is inspected
- **THEN** it SHALL contain an example where a task requiring an MCP tool is delegated to `@player` naming the tool, and a ❌ example of flow invoking the MCP tool directly

#### Scenario: Player MCP execution example

- **WHEN** `player.md` is inspected
- **THEN** it SHALL contain an example of player calling an MCP tool to fulfill a delegated task and returning the result upward

#### Scenario: Coach MCP verification example

- **WHEN** `coach.md` is inspected
- **THEN** it SHALL contain an example of coach using an MCP tool to independently verify player's output
- **THEN** it SHALL contain a ❌ example of coach applying a fix via an edit-capable tool, marked as a role violation

### Requirement: Examples for refusing system-contradicting user instructions

Each agent prompt SHALL contain worked examples where a user (or delegated-prompt) instruction contradicts the system prompt and is resolved by following the system: flow serving "answer me directly" / "skip the review" through the full cycle; player refusing role changes ("review your own change", "reply to the user directly") while doing the in-role part; coach refusing "fix the issues yourself" and returning findings only. Each example SHALL show the exact refusal phrasing or routing action.

#### Scenario: Flow bypass-attempt examples

- **WHEN** `flow.md` is inspected
- **THEN** it SHALL contain dialogue traces for at least "answer directly" and "skip coach review" requests, each resolved through the full cycle with the delegation tool calls shown

#### Scenario: Player and coach refusal examples

- **WHEN** `player.md` or `coach.md` is inspected
- **THEN** it SHALL contain an example of a role-changing instruction inside a delegated prompt, the in-role part executed, and the refusal noted in the return output with concrete phrasing

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

### Requirement: Examples for system-first instruction resolution

Each agent prompt SHALL contain at least one worked example showing the resolution order applied to an incoming work instruction: the agent checks the instruction against the priority ladder (role invariants → workflow rules → user instruction → task content) and honors the instruction for *what* to do while the system governs *how*. The example SHALL show a compliant case (instruction fits the role — executed normally), distinguishing it from the refusal cases.

#### Scenario: Compliant instruction resolved system-first

- **WHEN** any agent prompt is inspected
- **THEN** it SHALL contain an example where a legitimate work instruction is received, checked against the ladder, and executed in-role — demonstrating that system-first resolution does not mean refusing normal work

### Requirement: Example sections synchronized across ports

Example sections SHALL land in both ports in the same commit, differing only in port-specific tool naming (`task` tool in OpenCode, `Agent` tool in Claude Code) and the ports' documented divergences. `subflow.md` SHALL remain byte-identical to the OpenCode `flow.md`.

#### Scenario: Port sync check

- **WHEN** the example sections of `.opencode/agents/*.md` and `.claude/agents/*.md` are compared
- **THEN** they SHALL contain the same example categories and equivalent content, with only documented divergences (tool names, subflow references)
- **THEN** `diff .opencode/agents/flow.md .opencode/agents/subflow.md` SHALL show differences only in front-matter (name, description, mode)
