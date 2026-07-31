# explore-first-context

## Why

`flow`, `player`, and `coach` frequently gather context by reading files directly (`Read`, `Grep`, `cat`, `Glob`), burning tokens in their own context windows just to figure out what is going on. The prompts already mention `@explore`, but only for narrow cases (player: "batch reads", coach: E-category checks), while other sections actively push direct tools (player's "Check before you write: grep for it", "Glob/Grep for exploring the codebase"). The result is inconsistent behavior: agents default to self-reading instead of delegating.

`@explore` handles complex, session-scoped queries in its own context and returns only the distilled result — cheaper in tokens and higher-quality answers. It also matches SOLID single-responsibility: explore investigates, player executes, coach reviews, flow orchestrates.

## What Changes

- **Explore-first ordering rule for all three roles**: when an agent needs detailed context (multi-file reads, codebase structure, pattern/semantic search, "how does X work"), it SHALL delegate to `@explore` FIRST. Direct `Read`/`Grep`/`Glob` are permitted only AFTER an explore pass, for narrow point-refinement of something explore already surfaced (e.g., re-checking one specific line range or one exact symbol).
- **flow**: no behavior change (already forbidden from reading files; delegates to explore) — but its prompt gets the explicit explore-first framing so delegated prompts propagate the rule.
- **player**: rewrite the contradictory guidance — rule 5 ("Check before you write" via raw `grep`) and "How You Work" ("Glob/Grep for exploring the codebase") are re-scoped: existence/reuse checks and any exploration go through `@explore` first; direct grep/read only for pinpoint follow-up on explore results.
- **coach**: reviews the diff itself (that is its input), but any context beyond the diff — project conventions, existing utilities, callers, surrounding code — goes through `@explore` first; direct reads only for pinpoint verification of a specific explore finding.
- Both ports updated in the same change (`.opencode/agents/*.md` reference + `.claude/agents/*.md` port; `subflow.md` stays byte-identical to `flow.md`).
- DOX docs (`/.opencode/AGENTS.md`, `/.claude/AGENTS.md`) updated to record the explore-first contract.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `context-delegation`: extended from "flow delegates context-gathering to @explore" to an explore-first ordering contract covering all three roles — player and coach SHALL use `@explore` first for any detailed/broad context need, and MAY use direct read/grep tools only for narrow refinement of explore results.

## Impact

- `.opencode/agents/flow.md`, `.opencode/agents/subflow.md` (byte-identical), `.opencode/agents/player.md`, `.opencode/agents/coach.md`
- `.claude/agents/flow.md`, `.claude/agents/player.md`, `.claude/agents/coach.md`
- `/.opencode/AGENTS.md`, `/.claude/AGENTS.md` (DOX pass)
- `openspec/specs/context-delegation/spec.md` (via delta spec)
- Verification: `npx markdownlint-cli2` must stay at 0 errors
