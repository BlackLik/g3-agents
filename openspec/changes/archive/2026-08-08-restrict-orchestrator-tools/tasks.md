# Tasks

## 1. OpenCode Orchestrator Permissions

- [x] 1.1 Edit `.opencode/agents/flow.md` frontmatter: change `permission` from `'*': allow` to `'*': allow` + `edit: deny` + `bash: deny` (deny rules listed after the wildcard)
- [x] 1.2 Apply the identical `permission` block to `.opencode/agents/subflow.md` frontmatter
- [x] 1.3 Verify flow/subflow bodies remain byte-identical: `diff <(sed '1,/^---$/d' .opencode/agents/flow.md) <(sed '1,/^---$/d' .opencode/agents/subflow.md)` — no output expected

## 2. Claude Port Tools Allowlist

- [x] 2.1 Edit `.claude/agents/flow.md` frontmatter: replace `tools: Agent(flow, player, coach, Explore), *` with the explicit allowlist `Agent(flow, player, coach, Explore), Read, Glob, Grep, WebFetch, WebSearch, Skill, TodoWrite, mcp__*` (no bare `*`; `mcp__*` MCP passthrough kept; no Edit/Write/NotebookEdit/Bash)
- [x] 2.2 Verify `.claude/agents/flow.md` body is unchanged — frontmatter-only edit

## 3. DOX Updates

- [x] 3.1 Update `.opencode/AGENTS.md` Ownership section: document that flow/subflow run with `edit: deny` + `bash: deny` (delegation and read-only tools remain) — the orchestrator cannot modify files or run shell commands at the tool layer
- [x] 3.2 Update `.claude/AGENTS.md` divergence list: extend the "`permission` maps → `tools:` allowlists" entry to record that flow's allowlist now excludes Edit/Write/NotebookEdit/Bash
- [x] 3.3 Check root `AGENTS.md` Child DOX Index entries for `.opencode/` and `.claude/` — update only if the permission change alters their one-line scope descriptions

## 4. Verification

- [x] 4.1 Run `npx markdownlint-cli2` from repo root — verify 0 errors
- [x] 4.2 Run `openspec validate restrict-orchestrator-tools` — verify the change validates
- [x] 4.3 Verify permission blocks: both `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` contain `edit: deny` and `bash: deny`; `.claude/agents/flow.md` tools line contains no bare `*` wildcard (only the `mcp__*` passthrough), `Edit`, `Write`, `NotebookEdit`, or `Bash`
- [x] 4.4 Manual smoke test: run a session as `flow` and attempt a direct file edit and a bash command — both must fail with permission denial; a Task delegation to `@player` must succeed
