# explore-first-context — Tasks

## 1. OpenCode reference (`.opencode/agents/`)

- [x] 1.1 `player.md`: rewrite rule 0 as the explore-first rule — explore FIRST for any detailed/broad context (multi-file, structure, search, "how does X work"); direct Read/Grep only to refine a concrete target explore or the task prompt already named; add 1–2-sentence rationale (token economy in own context window + single responsibility)
- [x] 1.2 `player.md`: rewrite rule 5 "Check before you write" — reuse/existence checks go through one aggregated `@explore` query; keep raw `grep -r` as the ❌ Bad example, explore query as ✅ Good
- [x] 1.3 `player.md`: update "What You Do" step 2 and "How You Work" bullet (drop "Glob/Grep for exploring the codebase"; context via `@explore`, direct tools only for refinement); add explore-first line to Non-negotiables
- [x] 1.4 `coach.md`: add explicit beyond-diff rule near the review algorithm — the diff itself is direct input (A–D diff-text checks unchanged, incl. grep on diff text); any context beyond the diff (conventions, duplicates, callers, surrounding code) goes to `@explore` first; direct read only to pin-verify a specific explore finding; align line ~74 and ~422 wording with this rule
- [x] 1.5 `flow.md`: extend "Context gathering via @explore" with the explore-first framing — phrase explore queries as one aggregated session-scoped request; propagate the explore-first expectation in prompts delegated to player/coach
- [x] 1.6 `subflow.md`: regenerate body byte-identical to `flow.md` (frontmatter `mode: subagent` preserved)

## 2. Claude Code port (`.claude/agents/`)

- [x] 2.1 `player.md`: mirror tasks 1.1–1.3 (Explore built-in agent via the Agent tool instead of `@explore`/`task`)
- [x] 2.2 `coach.md`: mirror task 1.4
- [x] 2.3 `flow.md`: mirror task 1.5

## 3. DOX pass

- [x] 3.1 `/.opencode/AGENTS.md`: record the explore-first contract in "Critical operational rules" (per-role: player context + reuse checks via explore; coach beyond-diff context via explore; direct tools only for named-target refinement)
- [x] 3.2 `/.claude/AGENTS.md`: confirm no new divergence entry needed (behavior identical across ports); update wording only if existing entries now read stale

## 4. Verification

- [x] 4.1 `diff .opencode/agents/flow.md .opencode/agents/subflow.md` — body identical, frontmatter-only differences
- [x] 4.2 `npx markdownlint-cli2` from repo root — 0 errors
- [x] 4.3 Cross-port consistency check: explore-first rule present in all six role files (3 reference + 3 port) with equivalent wording
