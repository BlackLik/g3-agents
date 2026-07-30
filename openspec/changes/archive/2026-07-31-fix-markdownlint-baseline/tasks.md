# Tasks — fix-markdownlint-baseline

## 1. Lint scope

- [x] 1.1 Add `**/node_modules/**` and `openspec/changes/archive/**` to `ignores` in `.markdownlint-cli2.jsonc`; re-run lint and confirm no findings from those trees

## 2. Table normalization (MD060)

- [x] 2.1 Normalize table pipe spacing in `.opencode/agents/coach.md` and apply the identical whitespace fix to `.claude/agents/coach.md` (same commit; verify rendered tables unchanged)
- [x] 2.2 Normalize table pipe spacing in `openspec/specs/ai-trace-detection/spec.md` and any other live file still reporting MD060

## 3. Spec formatting (MD022/MD032/MD041)

- [x] 3.1 Run `npx markdownlint-cli2 --fix "openspec/specs/**/*.md"` for auto-fixable blank-line rules; review diff is whitespace-only
- [x] 3.2 Hand-fix remaining errors (add missing `# <capability>` H1 titles per existing convention; any non-auto-fixable leftovers)

## 4. Verification and DOX

- [x] 4.1 Run `npx markdownlint-cli2` from repo root — 0 errors, exit 0
- [x] 4.2 DOX pass: confirm AGENTS.md docs need no updates (verification contract wording unchanged); report docs intentionally left unchanged
