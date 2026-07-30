# Fix Markdownlint Baseline

## Why

The root AGENTS.md verification contract requires `npx markdownlint-cli2` to pass with 0 errors, but the repo currently produces 1078 errors independent of any recent change: vendored `.opencode/node_modules` markdown is linted, the new MD060 table-style rule (markdownlint v0.41.1) flags existing tables, and legacy `openspec/specs/**` files have blank-line formatting violations. Verification is meaningless until the baseline is green.

## What Changes

- Extend `.markdownlint-cli2.jsonc` `ignores` with vendored and archived content: `.opencode/node_modules/**` and `openspec/changes/archive/**` (archives are historical records and must not be edited to satisfy new lint rules).
- Normalize table pipe spacing (MD060) in live files: `.opencode/agents/coach.md`, `.claude/agents/coach.md`, `openspec/specs/ai-trace-detection/spec.md` — whitespace-only, no behavior change; both coach ports updated in the same commit per Port Synchronization.
- Fix blank-line formatting (MD022/MD032/MD041 and similar) in live `openspec/specs/**` files, preferring `markdownlint-cli2 --fix` for auto-fixable rules.
- Result: `npx markdownlint-cli2` from repo root exits 0.

## Capabilities

### New Capabilities

- `markdownlint-baseline`: The repo-wide markdownlint run passes with 0 errors; lint scope excludes vendored dependencies and archived changes.

### Modified Capabilities

*None — whitespace/formatting only; no agent behavior or spec requirement changes.*

## Impact

- `.markdownlint-cli2.jsonc`
- `.opencode/agents/coach.md`, `.claude/agents/coach.md` (whitespace-only; port sync applies, `subflow.md` unaffected — no tables)
- `openspec/specs/**/*.md` (live specs only; archive excluded via ignores)
- Verification contract in root AGENTS.md becomes enforceable again
