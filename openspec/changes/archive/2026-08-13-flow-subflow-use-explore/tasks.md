# 1. OpenCode Port — Frontmatter Changes

- [x] 1.1 Update `.opencode/agents/flow.md` frontmatter: replace `'*': allow` with explicit allowlist
  `[task, list, skill, todowrite, question, webfetch]`; keep `edit: deny` and `bash: deny`
- [x] 1.2 Update `.opencode/agents/subflow.md` frontmatter: identical change to flow.md

## 2. Claude Port — Tools Allowlist Changes

- [x] 2.1 Update `.claude/agents/flow.md` tools allowlist: remove `Read`, `Grep`, `Glob` from the explicit allowlist

## 3. Spec Update

- [x] 3.1 Update `openspec/specs/orchestrator-tool-restriction/spec.md`: modify "Delegation and read-only tools
  remain available" requirement to remove read/grep/glob from allowed tools; add requirement for explicit
  allowlist
- [x] 3.2 Create `openspec/specs/flow-subflow-tool-restriction/spec.md` from the change's delta spec

## 4. Verification

- [x] 4.1 Verify `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` frontmatter match the new allowlist
  spec
- [x] 4.2 Verify `.claude/agents/flow.md` tools allowlist matches
- [x] 4.3 Verify prompt bodies remain byte-identical between flow and subflow in both ports
- [x] 4.4 Run `npx markdownlint-cli2` from repo root — must pass with 0 errors
