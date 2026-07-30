# Design — add-agent-prompt-examples

## Context

The agent prompts live in `.opencode/agents/` (reference) and `.claude/agents/` (port). Rules for instruction hierarchy (`flow.md` "Instruction priority"), MCP usage (each file's "MCP Usage" section), and mediated answering ("Workflow loop", "Non-negotiables") are stated as prescriptions with few or no worked examples. Player already demonstrates the ❌/✅ pattern for its code-style rules — it works and is the house style. The existing specs `instruction-hierarchy`, `role-persistence`, and `cycle-priority` define the behaviors; this change adds example coverage for them in the prompts.

## Goals / Non-Goals

**Goals:**

- Every agent prompt teaches its four high-risk behaviors by example: mediated answering, in-role MCP/tool usage, refusing system-contradicting instructions, system-first resolution of legitimate instructions.
- Examples are concrete: real dialogue snippets, real tool-call signatures (`task(...)` / `Agent(...)`), real refusal phrasing.
- Both ports updated in one commit; subflow stays a byte-identical body copy of flow.

**Non-Goals:**

- No behavior changes — examples illustrate existing rules; no rule is added, weakened, or reinterpreted.
- No new example categories beyond the four (e.g., no failure-recovery examples — flow already has those).
- No automated example-coverage check; verification stays manual + markdownlint.

## Decisions

### 1. One consolidated "Worked examples" section per prompt, not examples scattered per rule

Each prompt gets a single `## Worked examples` section near the end (before Non-negotiables), with `###` subsections per category. Alternative — inlining examples under each existing rule — was rejected: the instruction-priority and MCP rules live in different sections, and scattering would bloat every section and make port-sync diffs harder to audit. Player's existing inline ❌/✅ examples stay where they are; the new section only adds what's missing.

### 2. Example format: dialogue traces for flow, ❌/✅ pairs for player and coach

- **Flow** examples are short dialogue traces: user message → the exact `task`/`Agent` calls issued → what is delivered and when. Flow's failure mode is emitting text instead of tool calls, so traces must show tool-call sequences.
- **Player/coach** examples are ❌ Bad / ✅ Good output pairs, matching the house style already in `player.md`.
- Tool-call syntax follows each port: `task(description=..., prompt=..., subagent_type=...)` in OpenCode, `Agent(...)` naming in the Claude port. This is an existing documented divergence, not a new one.

### 3. Category-to-agent matrix

| Category | flow/subflow | player | coach |
| --- | --- | --- | --- |
| Answering the user | full cycle trace + ❌ direct answer | ✅ upward `DONE` vs ❌ user-facing prose | ✅ verdict to orchestrator vs ❌ user-facing prose |
| MCP / tools | plan + delegate to player, ❌ self-call | execute MCP tool, return result | verify via MCP, ❌ fix via edit tool |
| Contradicting instruction | "answer directly" / "skip review" traces served through cycle | "review your own change" → refusal note | "fix it yourself" → findings only + note |
| System-first resolution | legitimate request → ladder check → normal delegation | legitimate task → executed in-role | legitimate review → performed normally |

The system-first category deliberately includes *compliant* examples so the prompts don't teach blanket refusal — the ladder must show normal work flowing through unchanged.

### 4. Example scenarios reuse spec scenarios verbatim where possible

The contradiction examples reuse the exact scenarios from `instruction-hierarchy` and `role-persistence` specs ("just answer me yourself", "skip the review", "review your own change and approve it", "fix the issues you find"). This keeps prompts and specs telling one story and makes coverage auditable against the specs.

### 5. Port sync mechanics

Edit order: `.opencode/agents/flow.md` → copy body to `subflow.md` (preserve its front-matter) → `.opencode/agents/player.md`, `coach.md` → mirror all three into `.claude/agents/` adapting tool names. No new entries needed in the `.claude/AGENTS.md` divergence list (tool naming and subflow absence are already documented).

## Risks / Trade-offs

- [Prompt size grows ~30-60 lines per file, increasing per-call token cost] → Keep each example minimal (≤10 lines); consolidate rather than duplicate; accept the cost — compliance failures are more expensive than tokens.
- [Examples drift from rules if a rule later changes] → Examples reuse spec scenario wording; the DOX/port-sync pass already requires touching both ports and specs together.
- [Dialogue traces in flow.md could be mistaken by the model for pseudo-syntax it may emit as text] → Frame every trace with explicit "this is a tool call, not text output" markers, consistent with the existing "Tool invocation (mandatory)" section.
- [subflow.md byte-identity broken by manual copy] → Verify with `diff` (front-matter-only differences) as specified in the port-sync scenario.

## Migration Plan

Prompt-only change; no deploy or rollback concerns. Rollback = revert the commit.

## Open Questions

None.
