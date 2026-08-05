## Why

When skills or MCP tools are loaded into the flow orchestrator's context, the model follows them directly instead of maintaining its role as orchestrator. This "Skill-Induced Role Capture" breaks the instruction priority hierarchy (role > workflow > user > content): skill instructions, which should be task content (level 4), hijack attention away from role invariants (level 1). The problem scales with model size — smaller models (DeepSeek V4 Flash, Claude Sonnet 5) collapse under concrete affordances and follow skills directly; larger models (Kimi K3 2.8T, Claude Opus 5) correctly maintain the hierarchy.

## What Changes

- Add a **mandatory pre-action request analysis phase** — flow classifies the incoming request (skill invocation, direct task, question, mixed) and decomposes it into domains before any delegation
- **Frame skill instructions explicitly as task content (priority level 4)** — never loaded as if they extend the system prompt; a contextual fence separates "who you are" from "what the user is asking via a skill"
- **Add "skill capture" worked examples** to flow prompts in both ports — concrete ❌/✅ pairs showing the analysis-before-delegation pattern
- **Model-specific prompt adaptations** for smaller models: recency-optimized ordering (role invariants placed at the end of the prompt, closest to output), reinforced pre-flight checks, and additional worked examples targeting the skill-following failure mode
- **Add a pre-action self-check** to the flow's pre-response checklist: before any tool call, verify the action respects the instruction priority hierarchy

## Capabilities

### New Capabilities

- `request-analysis`: Mandatory pre-delegation analysis phase where flow classifies the incoming request (identifying user domain vs skill domain vs other-agent domain) and produces a structured decomposition plan before any tool call or delegation
- `skill-context-framing`: Rules for how skill instructions are loaded into context — framed as priority level 4 (task content), separated from role invariants and workflow rules by an explicit contextual fence, and never allowed to compete with higher-priority instructions

### Modified Capabilities

- `instruction-hierarchy`: Extend to cover skill instructions as a specific lower-priority content type (level 4) that must not override role invariants (level 1) or workflow rules (level 2); add scenarios for skill invocation with analysis-before-delegation requirement
- `role-persistence`: Add coverage for the case where skill context competes with role invariants — skills and MCP tools loaded into flow's session must not change flow's identity or responsibilities
- `prompt-examples`: Add "skill capture" worked example category: a skill is invoked (e.g., `/opsx-propose`), and flow must analyze the request and delegate through the mediated cycle rather than following the skill's instructions directly
- `cycle-priority`: Incorporate the pre-analysis phase as a prerequisite that gates the start of the mediated cycle — flow must analyze before it can delegate

## Impact

- **Flow prompts** (`.opencode/agents/flow.md`, `.claude/agents/flow.md`, and `.opencode/agents/subflow.md`): reordering for recency optimization, new worked examples, pre-flight check addition, skill context framing language
- **Player and coach prompts** (`.opencode/agents/player.md`, `.claude/agents/player.md`, `.opencode/agents/coach.md`, `.claude/agents/coach.md`): minor — if the skill context framing affects delegated prompts
- **Specs**: 2 new capability specs, 4 delta specs
- **OpenCode config**: no changes — all changes are within the agent prompt files and spec documents
- **MCP configuration**: no changes — tools remain available to all agents; the change is in how flow processes them
