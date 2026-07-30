# markdownlint-baseline

## Purpose

Keep the repo-wide markdownlint baseline green so the root AGENTS.md verification contract (`npx markdownlint-cli2` passes with 0 errors) stays enforceable, with vendored and archived markdown excluded from lint scope and lint-driven edits limited to formatting.

## Requirements

### Requirement: Repo-wide markdownlint run passes clean

Running `npx markdownlint-cli2` from the repository root SHALL exit with 0 errors.

#### Scenario: Clean verification run

- **WHEN** `npx markdownlint-cli2` is executed from the repo root
- **THEN** it SHALL report 0 issues and exit with status 0

### Requirement: Lint scope excludes vendored and archived markdown

The markdownlint configuration SHALL exclude vendored dependencies (`.opencode/node_modules/**`) and archived changes (`openspec/changes/archive/**`) from linting. Archived change documents SHALL NOT be edited to satisfy lint rules.

#### Scenario: Vendored and archived files ignored

- **WHEN** the lint run executes
- **THEN** no findings SHALL be reported from `.opencode/node_modules/**` or `openspec/changes/archive/**`
- **THEN** files under `openspec/changes/archive/**` SHALL remain byte-identical to their archived state

### Requirement: Lint fixes are formatting-only

Lint-driven edits to agent prompts and live specs SHALL be limited to whitespace and formatting (table pipe spacing, blank lines around headings/lists). Coach prompt table fixes SHALL land in both ports in the same commit.

#### Scenario: Coach table normalization

- **WHEN** MD060 table fixes are applied to `.opencode/agents/coach.md`
- **THEN** the equivalent whitespace fix SHALL be applied to `.claude/agents/coach.md` in the same commit
- **THEN** the rendered table content (cells, rows, semantics) SHALL be unchanged
