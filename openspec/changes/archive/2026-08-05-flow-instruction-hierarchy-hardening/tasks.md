## 1. Flow Prompt — Pre-Analysis Phase

- [x] 1.1 Add the mandatory pre-action analysis phase section to `.opencode/agents/flow.md` — instructs flow to classify the request, identify domains, and produce a plan before any delegation
- [x] 1.2 Add section header "Analysis phase" near the top of the prompt, before "Task decomposition", in both `flow.md` and `subflow.md`
- [x] 1.3 Mirror the analysis phase section in `.opencode/agents/subflow.md` (byte-identical body requirement)
- [x] 1.4 Port the analysis phase section to `.claude/agents/flow.md` (with Agent tool naming)

## 2. Flow Prompt — Recency-Optimized Ordering

- [x] 2.1 Restructure `.opencode/agents/flow.md` ordering: move "Role invariants" and "Non-negotiables" to the end of the prompt (closest to model output)
- [x] 2.2 Restructure `.opencode/agents/subflow.md` identically
- [x] 2.3 Restructure `.claude/agents/flow.md` identically
- [x] 2.4 Verify that "Instruction priority" section still appears before "Non-negotiables" (priority section → non-negotiables → end of prompt)

## 3. Flow Prompt — Skill Context Fence

- [x] 3.1 Add the skill context fence format (opening fence + closing fence) to `.opencode/agents/flow.md` — placed where skill instructions are loaded into context
- [x] 3.2 Add a "Skill content handling" section to `.opencode/agents/flow.md` — instructs flow that skill content is priority level 4 and must be analyzed, not followed directly
- [x] 3.3 Mirror into `.opencode/agents/subflow.md`
- [x] 3.4 Port to `.claude/agents/flow.md`

## 4. Flow Prompt — Pre-Flight Self-Check Enhancement

- [x] 4.1 Add the instruction-priority check to the existing "Pre-response self-check" in `.opencode/agents/flow.md`: "Does this action respect the instruction priority hierarchy (role > workflow > user > content)?"
- [x] 4.2 Mirror into `.opencode/agents/subflow.md`
- [x] 4.3 Port to `.claude/agents/flow.md`

## 5. Worked Examples — Skill Capture Pattern

- [x] 5.1 Add ❌ Bad / ✅ Good worked example for skill invocation to `.opencode/agents/flow.md` "Worked examples" section: skill triggered, flow must analyze and delegate rather than follow directly
- [x] 5.2 Ensure the ✅ example shows the analysis phase explicitly — flow producing a plan before delegating
- [x] 5.3 Mirror into `.opencode/agents/subflow.md`
- [x] 5.4 Port to `.claude/agents/flow.md` (with Agent tool naming)

## 6. Verification

- [x] 6.1 Diff-check both ports: `diff .opencode/agents/flow.md .opencode/agents/subflow.md` — verify only front-matter differs
- [x] 6.2 Run `npx markdownlint-cli2` from repo root — verify 0 errors in agent files
- [x] 6.3 Review `.claude/agents/flow.md` against `.opencode/agents/flow.md` — verify documented divergences are the only differences (tool naming, subflow references) and that skill capture logic is equivalent
- [x] 6.4 Test with Claude Sonnet 5 / DeepSeek V4 Flash: invoke a skill (e.g., `/opsx-propose` with a request) and verify flow analyzes before delegating instead of following skill instructions directly
- [x] 6.5 Test with Claude Opus 5 / Kimi K3: verify the change does not regregate large model behavior (they should still work correctly, just with the added analysis phase)
