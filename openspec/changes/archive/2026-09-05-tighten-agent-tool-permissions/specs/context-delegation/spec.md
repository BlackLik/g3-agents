# context-delegation (delta)

## MODIFIED Requirements

### Requirement: Flow delegates context-gathering to explore agent

When the orchestrator flow needs information of any kind — project context (file contents, codebase structure, search
results, git history) or external/web information (documentation, references, lookups via webfetch/websearch) — it
SHALL delegate directly to the explore agent via `subagent_type="explore"` — never to `@player` and never by invoking
an information tool itself. Flow holds no information-gathering tools.

#### Scenario: Flow needs file contents

- **WHEN** flow needs to read a file to understand context for a task
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with instructions to read the file

#### Scenario: Flow needs codebase search

- **WHEN** flow needs to search the codebase for patterns or definitions
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with search instructions

#### Scenario: Flow needs git history

- **WHEN** flow needs git log, diff, or blame information
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with git instructions

#### Scenario: Flow needs web information

- **WHEN** flow needs external documentation, a web search, or a fetched URL
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with the web query or URL
- **THEN** flow SHALL NOT invoke `webfetch` or `websearch` directly

### Requirement: Player does not handle context-gathering

`@player` SHALL NOT receive tasks whose primary purpose is reading, searching, or investigating the codebase. Player's
sole responsibility is writing/modifying code per task instructions and verifying it through the terminal. Player's
`bash` tool SHALL be available and is the primary execution surface: running code, tests, and commands, and pinpoint
viewing (`cat`, `sed -n`) of files already named by the task prompt or by explore output. Any broad search or
multi-file investigation SHALL go through `@explore`; player SHALL NOT use `read`/`grep`/`glob`/`webfetch`/`websearch`.

#### Scenario: Player runs and verifies its change

- **WHEN** player completes an implementation task
- **THEN** player SHALL run the result via `bash` (tests, the command, the build) and show the output

#### Scenario: Player views an already-named file

- **WHEN** the task prompt or explore output names a specific file/region player must see
- **THEN** player MAY view it via `bash` (`cat`, `sed -n`)
- **THEN** player SHALL NOT perform a broad `grep`/glob sweep across the codebase

#### Scenario: Context task misdirected to player

- **WHEN** flow accidentally delegates a context-gathering task to `@player`
- **THEN** `@player` SHALL reject the task and return upward with a message indicating the task should be routed to
  explore

### Requirement: Coach gathers beyond-diff context via explore

Coach reviews the delivered diff directly — the diff is its input — but SHALL NOT use `bash`, `read`, `grep`, or `glob`
itself (the sole `read` exception is the reference tier, `reference/*.md`). Coach SHALL obtain the review input — the
git diff, diff stat, and recent log — by delegating one task to `@explore` that runs the git commands and returns the
output verbatim. Coach SHALL then run its detection categories over the diff text in its own context. Any context
beyond the diff (project conventions, duplicates, callers of changed code, surrounding code of a hunk, dependency
manifests) SHALL be requested from `@explore` as one aggregated query.

#### Scenario: Coach Step 0 gets the diff

- **WHEN** coach begins a review
- **THEN** coach SHALL delegate to `@explore` to run `git diff HEAD~1 HEAD`, `git diff --stat HEAD~1 HEAD`, and
  `git log --oneline -5` and return the output verbatim
- **THEN** coach SHALL NOT run `bash` or `git` itself

#### Scenario: Coach runs detection over the diff text

- **WHEN** coach has the diff text from explore
- **THEN** coach SHALL scan the diff text directly for the detection categories (A–E) in its own context
- **THEN** coach SHALL NOT invoke `grep`/`read` against the repository for the diff itself

#### Scenario: Coach checks for duplicate utility

- **WHEN** coach suspects the diff reinvents an existing utility (E-category check)
- **THEN** coach SHALL ask `@explore` whether an equivalent utility already exists in the project

#### Scenario: Coach needs surrounding code of a hunk

- **WHEN** coach needs the code around a diff hunk to judge correctness
- **THEN** coach SHALL request the surrounding context from `@explore`, not open the file itself
