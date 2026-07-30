# Design — fix-markdownlint-baseline

## Context

markdownlint-cli2 v0.23.2 (markdownlint v0.41.1) reports 1078 errors from the repo root. Breakdown: ~460 in `.opencode/node_modules/**` (vendored READMEs/CHANGELOGs), ~250 in `openspec/changes/archive/**` (historical records), ~100 MD060 table-style errors in live coach prompts and `ai-trace-detection` spec, and ~150 blank-line violations (MD022/MD032/MD041) in live `openspec/specs/**`. The config already disables MD013 and ignores `CLAUDE.md`.

## Goals / Non-Goals

**Goals:**

- `npx markdownlint-cli2` exits 0 from the repo root, making the AGENTS.md verification contract enforceable.
- No semantic changes anywhere — whitespace/formatting only in live files; archives untouched.

**Non-Goals:**

- No pinning of the markdownlint-cli2 version (acceptable drift; revisit only if new-rule churn repeats).
- No re-styling of prose, no MD013 revival, no lint of vendored deps.

## Decisions

### 1. Ignore, don't edit, vendored and archived markdown

Add `.opencode/node_modules/**` and `openspec/changes/archive/**` to `ignores`. Editing vendored files is churn lost on every reinstall; editing archives falsifies historical records. Alternative — `**/node_modules/**` glob — adopted for robustness against future install locations.

### 2. Fix MD060 by normalizing pipes, not disabling the rule

MD060 flags compact separator rows (`|---|---|`) mixed with spaced data rows. Normalize to spaced style (`| --- | --- |`, spaces around every pipe) in the three live files. Alternative — `"MD060": false` — rejected: the rule enforces a real consistency issue and the fix is cheap and one-time. Coach tables are prompt-body content → apply identically in both ports in the same commit (Port Synchronization); `flow.md`/`subflow.md`/`player.md` contain no tables, so no other sync impact.

### 3. Auto-fix blank-line violations, then verify manually

Run `npx markdownlint-cli2 --fix` scoped to `openspec/specs/**` for MD022/MD032 (auto-fixable), then hand-fix the remainder (MD041 first-line-heading in `role-persistence`/`scope-aggregation` specs — add `# <capability>` title lines). Reject hand-editing everything: ~150 mechanical errors.

### 4. MD041 title insertions are formatting, not content

Adding a `# <capability-name>` H1 to spec files that start at `## Purpose` changes no requirement text. Newer specs (e.g. `prompt-examples`) already carry H1 titles — this aligns older files with the existing convention.

## Risks / Trade-offs

- [`--fix` touches many spec files at once, risking accidental content edits] → Review the diff file-by-file; assert the diff is whitespace/heading-only before committing.
- [Future markdownlint upgrades introduce new rules and break the baseline again] → Accepted; if it recurs, pin the version in a follow-up.
- [Ignoring archives hides genuinely broken markdown there] → Acceptable: archives are read-only records, not maintained docs.

## Migration Plan

Single commit; rollback = revert. No runtime surface.

## Open Questions

None.
