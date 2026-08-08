# Design: structure-agent-descriptions

## Context

Agent frontmatter `description` fields are the only signal a calling LLM has when selecting a subagent via the `task`/`Agent` tool — they function as tool descriptions. The current descriptions (in `.opencode/agents/`, mirrored in `.claude/agents/`) are single flowing paragraphs that cover purpose and "use when" cues but omit explicit input-format semantics, limitations, and side-effect statements. Empirical tool-description practice (e.g. the Yahoo Finance MCP case, where a missing `YYYY-MM-DD` format hint caused agents to fetch excessive data) shows that unstructured descriptions degrade selection and call quality.

Constraints:

- Port Synchronization contract: role-behavior changes must land in `.opencode/` and `.claude/` together; each port documents deliberate divergences.
- Existing spec `agent-descriptions` requires self-containment, no dangling `@`-references, a flow/subflow selection criterion, and frontmatter-only edits.
- `.claude/` has no `subflow.md`; `flow`'s description there already diverges deliberately (Agent-tool delegation + self-recursion).
- Descriptions remain YAML folded scalars (`>-`) per `.opencode/AGENTS.md` convention.

## Goals / Non-Goals

**Goals:**

- Every agent description follows the five-part structure: Purpose → Guidelines → Parameters → Limitations → Side effects.
- Parameters state input semantics and format explicitly (scoped task, success criteria, output format, `(depth: N)` marker).
- Side effects state explicitly what the agent can mutate (player: writes files/runs commands; coach: read-only verdict; flow/subflow: no file/shell mutation, only delegated task calls).
- Both ports updated in the same change; divergence lists in `.claude/AGENTS.md` stay accurate.
- Total size stays within a tool-metadata budget (80–150 words per description).

**Non-Goals:**

- No changes to role bodies, `mode`, `temperature`, or `permission`/`tools` fields.
- No new agents, no routing-logic changes, no workflow changes.
- No changes to embedded example prompts or dialogue traces inside bodies.

## Decisions

### D1: Five labeled segments inside the folded scalar

Keep `description: >-` and write the five segments as labeled lines (`Purpose: …`, `Guidelines: …`, `Parameters: …`, `Limitations: …`, `Side effects: …`). Labels make the structure machine-checkable (spec scenario) and scannable for a routing model.

*Alternative considered:* unlabeled prose covering the same five concerns — rejected: not verifiable, drifts back to ad-hoc shape.

### D2: Budget raised from 40–80 to 80–150 words

Five segments cannot fit 80 words without losing the parameter-format and side-effect content that motivates the change. 80–150 words stays well within MCP/tool-metadata norms.

*Alternative considered:* keep 40–80 words and drop segments — rejected: defeats the purpose of the change.

### D3: Per-agent segment content

- **flow** (both ports): Purpose — primary orchestrator of a mediated multi-agent workflow. Guidelines — use when a user task needs decomposition and quality-gated delivery; delegates implementation to an executor and review to a reviewer, repeating until accepted. Parameters — a user task; recursive delegations carry `(depth: N)`, terminal at depth 2. Limitations — never writes code, runs shell, or answers directly; every output is a delegation or review decision. Side effects — none directly (file/shell mutation denied); all effects occur via delegated subagents.
- **subflow** (OpenCode only): same contract as flow, plus the selection criterion — invocable as a subagent when a primary orchestrator already drives the session; top-level entry uses the primary orchestrator.
- **player**: Parameters — one concrete scoped task with success criteria and expected output format. Limitations — refuses review tasks and out-of-scope fixes; escalates broken unrelated linters/tests upward. Side effects — writes/edits files and runs commands within task scope.
- **coach**: Parameters — a git diff or change set, with `(depth: N)` when split. Limitations — binary verdict only, no fixes, no conditional approval; max review depth 2. Side effects — none; read-only, returns findings.

### D4: Claude port wording

`player` and `coach` descriptions stay verbatim-identical to the reference (existing divergence policy). `flow` diverges only as already documented: Agent-tool delegation and self-recursion instead of the flow/subflow selection criterion. The five-segment structure itself is identical across ports.

### D5: Spec delta

Modify `agent-descriptions`: ADD the five-part-structure requirement; MODIFY the budget requirement (40–80 words → 80–150 words, folded scalar with labeled segments). Self-containment, no-dangling-references, selection-criterion, and frontmatter-only requirements remain untouched.

## Risks / Trade-offs

- [Longer descriptions consume more tool-metadata context] → Capped at ~150 words; folded scalar keeps formatting compact.
- [Structure drifts when descriptions are edited later] → Spec scenarios make the five-segment order and labels checkable; DOX convention note updated in the same change.
- [Port divergence if one port is updated without the other] → Both ports edited in the same commit per Port Synchronization; tasks.md enforces pairwise edits.
- [Router models overfitting to labels instead of semantics] → Labels are short prefixes; segment text remains natural prose with the behavioral cues ("Use when…").
