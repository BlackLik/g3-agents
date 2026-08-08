# Tasks: expand-agent-descriptions

## 1. Rewrite reference descriptions (`.opencode/agents/`)

- [x] 1.1 Rewrite `description` in `.opencode/agents/flow.md`: primary orchestrator role, when to delegate to it, input (user task), output (reviewed result), delegation to executor/reviewer subagents described by capability
- [x] 1.2 Rewrite `description` in `.opencode/agents/subflow.md`: same orchestration contract as flow plus the explicit selection criterion that it is the subagent-invocable variant used when a primary orchestrator already drives the session
- [x] 1.3 Rewrite `description` in `.opencode/agents/player.md`: lazy-programmer executor role, when to delegate implementation, input (single concrete task), output (code changes, escalates broken linters/tests instead of fixing)
- [x] 1.4 Rewrite `description` in `.opencode/agents/coach.md`: zero-tolerance reviewer role, when to delegate review, input (git diff / change set), output (verdict with findings)
- [x] 1.5 Verify each description is one paragraph of 40–80 words and contains no unresolved `@`-mentions
- [x] 1.6 Verify `git diff` on `.opencode/agents/` touches only `description:` frontmatter lines (bodies, mode, temperature, permission unchanged)

## 2. Align `.claude` port

- [x] 2.1 Adapt the expanded descriptions into `.claude/agents/flow.md`, `.claude/agents/player.md`, `.claude/agents/coach.md` in the Claude Code frontmatter format
- [x] 2.2 Update the "Deliberate divergences" list in `.claude/AGENTS.md`: adjust the "Frontmatter `description` is port-owned" note to reflect what actually diverges after alignment

## 3. Verification

- [x] 3.1 Run `npx markdownlint-cli2` from repo root — must pass with 0 errors
- [x] 3.2 Run `openspec validate expand-agent-descriptions` and fix any issues
