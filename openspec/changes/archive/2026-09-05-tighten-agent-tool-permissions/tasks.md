# Tasks — tighten-agent-tool-permissions

## 1. OpenCode frontmatter permissions

- [x] 1.1 `.opencode/agents/flow.md`: replace `'*': allow` block with `'*': deny`; allow `task` (targets
  `player`/`coach`/`explore`/`subflow` only), `skill`, `question`; scoped `read` (`*/reference/*.md` allow, `*` deny);
  explicit denies for `edit`/`bash`/`grep`/`glob`/`list`/`lsp`/`webfetch`/`websearch`/`todowrite`
- [x] 1.2 `.opencode/agents/subflow.md`: same block as flow but WITHOUT `question: allow`; keep `lsp: deny` (already
  present), add the rest
- [x] 1.3 `.opencode/agents/player.md`: add `bash: allow`; restrict `task` to `explore`/`player` only; add denies for
  `list`/`question` (others already denied); keep `'*': allow` (MCP passthrough) and `edit` allowed
- [x] 1.4 `.opencode/agents/coach.md`: restrict `task` to `explore`/`coach` only; add denies for `list`/`question`
  (others already denied); scoped `read` (`*/reference/*.md` allow, `*` deny); keep `'*': allow` (MCP verification) and
  `edit: deny`, `bash: deny`

## 2. Prompt bodies — OpenCode port (reference implementation)

- [x] 2.1 `flow.md` body: add "Pre-implementation clarity gate" section (one bounded `question` round at depth 0 when
  materially blocked; sole exception to "every response is a task call"); remove the "You have no interactive question
  tool" line; keep escalations mediated
- [x] 2.2 `flow.md` body: extend context-gathering — web information (webfetch/websearch) also delegates to `@explore`;
  state flow holds no information tools; update the clarification-policy and Non-negotiables sections to reference the
  gate
- [x] 2.3 Copy `flow.md` body verbatim to `subflow.md` (byte-identical bodies; only frontmatter differs)
- [x] 2.4 `player.md` body: terminal-first rule — bash for running/verifying and pinpoint viewing (`cat`/`sed -n`) of
  files named by the task or explore; broad search only via `@explore`; reframe rule 0 accordingly
- [x] 2.5 `coach.md` body: rewrite Step 0 — obtain `git diff`/`git diff --stat`/`git log` via one `@explore` task
  (verbatim output); run A–E detection over the diff text in coach's context; refuse review if no diff; keep
  beyond-diff context via one aggregated `@explore` query

## 3. Reference tiers — OpenCode port

- [x] 3.1 `.opencode/reference/coach-reference.md`: replace "Grep for …" detection wording with "scan the diff text
  for …" (categories A–E run over the diff text in coach's context)
- [x] 3.2 `.opencode/reference/flow-reference.md`: add a worked example of the clarity gate (one `question` round at
  depth 0, then delegation) alongside existing worked examples

## 4. Claude port — mirrored bodies

- [x] 4.1 `.claude/agents/flow.md` body: same clarity-gate and explore-routed-info changes, phrased for the Agent tool;
  question round uses the mediated fallback (no interactive tool); frontmatter `tools:` unchanged
- [x] 4.2 `.claude/agents/player.md` body: same terminal-first change; frontmatter unchanged
- [x] 4.3 `.claude/agents/coach.md` body: same Step 0 rewrite; frontmatter unchanged
- [x] 4.4 `.claude/reference/coach-reference.md` and `flow-reference.md`: mirror 3.1 and 3.2

## 5. DOX pass

- [x] 5.1 `.opencode/AGENTS.md`: rewrite "Orchestrator tool restriction" to the new deny-by-default allowlist +
  question gate; remove stale "player has webfetch: allow" (Ecosystem boundaries + Player rules); update coach Step 0
  and flow context-gathering descriptions; add clarity-gate to operational rules
- [x] 5.2 `.claude/AGENTS.md`: add divergences — tool enforcement only in the OpenCode port (tools: lists unchanged);
  interactive question tool only in OpenCode port (Claude port uses mediated fallback)

## 6. Verification

- [x] 6.1 `npx markdownlint-cli2` from repo root passes with 0 errors (all edited/new .md files)
- [x] 6.2 All four opencode frontmatters parse as valid YAML and match the spec'd permission sets
- [x] 6.3 `flow.md`/`subflow.md` bodies are byte-identical after stripping frontmatter
