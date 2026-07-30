# Tasks — add-agent-prompt-examples

## 1. OpenCode reference prompts

- [x] 1.1 Add `## Worked examples` section to `.opencode/agents/flow.md` (before Non-negotiables) with dialogue traces: answering-the-user full cycle + ❌ direct answer; MCP planning/delegation + ❌ self-call; "answer me directly" and "skip the review" served through the cycle; system-first resolution of a legitimate request
- [x] 1.2 Add worked examples to `.opencode/agents/player.md`: ✅ upward `DONE` vs ❌ user-facing prose; MCP tool execution returning result upward; "review your own change and approve it" refusal with exact phrasing; system-first execution of a legitimate task
- [x] 1.3 Add worked examples to `.opencode/agents/coach.md`: ✅ verdict-to-orchestrator vs ❌ user-facing prose; MCP verification of player output + ❌ fixing via edit-capable tool; "fix the issues you find" refusal returning findings only; system-first handling of a legitimate review request
- [x] 1.4 Copy `flow.md` body to `.opencode/agents/subflow.md` preserving subflow front-matter; verify `diff` shows front-matter-only differences

## 2. Claude Code port prompts

- [x] 2.1 Mirror flow examples into `.claude/agents/flow.md`, adapting tool naming (`Agent` tool, no subflow — flow recurses into itself)
- [x] 2.2 Mirror player examples into `.claude/agents/player.md` with port tool naming
- [x] 2.3 Mirror coach examples into `.claude/agents/coach.md` with port tool naming

## 3. Coverage audit against spec

- [x] 3.1 Check every scenario in `specs/prompt-examples/spec.md` against the six edited files: each applicable category has a concrete example (messages/tool calls, not restated rules); contradiction examples reuse spec scenario wording from `instruction-hierarchy`/`role-persistence`
- [x] 3.2 Confirm no example contradicts an existing rule in its prompt (role-persistence "no self-contradictory role rules")

## 4. DOX pass and verification

- [x] 4.1 DOX pass: confirm `.opencode/AGENTS.md` and `.claude/AGENTS.md` need no updates (no new divergences, no structural contract change); update if prompt structure contracts changed
- [x] 4.2 Run `npx markdownlint-cli2` from repo root — verified this change introduces 0 new errors (baseline 1078 = with-change 1078; all 11 touched files clean in their edited regions). The pre-existing repo-wide baseline failure (unignored `.opencode/node_modules`, new MD060 rule, legacy spec formatting) is out of scope — handled by follow-up change `fix-markdownlint-baseline`
