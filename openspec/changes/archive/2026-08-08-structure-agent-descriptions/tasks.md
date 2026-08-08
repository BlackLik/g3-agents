# Tasks: structure-agent-descriptions

## 1. Reference port (.opencode)

- [x] 1.1 Rewrite the `description` frontmatter of `.opencode/agents/flow.md` into the five labeled segments (Purpose, Guidelines, Parameters, Limitations, Side effects), 80–150 words, per design D3; keep `>-` folded scalar and all other frontmatter/body byte-identical
- [x] 1.2 Rewrite the `description` frontmatter of `.opencode/agents/subflow.md` identically to flow plus the selection criterion (subagent-invocable variant; top-level entry uses the primary orchestrator)
- [x] 1.3 Rewrite the `description` frontmatter of `.opencode/agents/player.md` (scoped-task input with success criteria/output format; refuses reviews and out-of-scope fixes; side effect: writes files and runs commands within task scope)
- [x] 1.4 Rewrite the `description` frontmatter of `.opencode/agents/coach.md` (git-diff input with `(depth: N)` when split; binary verdict, no fixes, max depth 2; side effect: none, read-only)

## 2. Claude port (.claude)

- [x] 2.1 Apply the new `flow` description to `.claude/agents/flow.md` with the documented divergence (Agent-tool delegation, self-recursion, no subflow mention)
- [x] 2.2 Apply the new `player` description to `.claude/agents/player.md` verbatim-identical to the reference
- [x] 2.3 Apply the new `coach` description to `.claude/agents/coach.md` verbatim-identical to the reference

## 3. Verification and docs

- [x] 3.1 Verify diffs touch only `description:` frontmatter lines in all seven agent files (bodies, `mode`, `temperature`, `permission`/`tools` unchanged)
- [x] 3.2 Verify each description has all five labeled segments in order and totals 80–150 words; verify no `@`-mentions resolve to dangling references
- [x] 3.3 Update `.opencode/AGENTS.md` frontmatter-convention note (five labeled segments, 80–150 words) and refresh `.claude/AGENTS.md` divergence list if wording changed
- [x] 3.4 Run `npx markdownlint-cli2` from the repo root; must pass with 0 errors
