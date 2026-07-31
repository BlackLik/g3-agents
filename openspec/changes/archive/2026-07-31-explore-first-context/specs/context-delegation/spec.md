# context-delegation (delta)

## ADDED Requirements

### Requirement: Explore-first ordering for detailed context

Every agent (flow, player, coach) SHALL delegate to `@explore` FIRST whenever it needs detailed or broad project context — multi-file contents, codebase structure, pattern or semantic search, callers/usages of a symbol, project conventions, or "how does X work" questions. The explore query SHALL be phrased as one complex, session-scoped request (what is needed and why), not as a series of single-file read requests. Direct read/grep/glob tools SHALL NOT be the first step of context gathering.

#### Scenario: Player needs to understand a module before implementing

- **WHEN** player receives a task that requires understanding code it has not seen (e.g., "add a timeout param to `fetch_data`" and player does not know `fetch_data`'s signature or callers)
- **THEN** player SHALL delegate one aggregated query to `@explore` (e.g., "show `fetch_data` definition, its callers, and existing timeout patterns in this repo")
- **THEN** player SHALL NOT open the files itself as the first step

#### Scenario: Agent starts with a direct grep sweep

- **WHEN** an agent begins context gathering with direct `grep`/`glob`/`read` calls across the codebase before any `@explore` delegation
- **THEN** this SHALL be treated as a workflow violation of the explore-first rule

### Requirement: Direct tools permitted only for narrow refinement

After an `@explore` pass, an agent MAY use direct read/grep tools only to refine a specific item that explore already surfaced — e.g., re-reading one named file range, confirming one exact symbol or line. A direct-tool call SHALL be scoped to a concrete target (specific file path, symbol, or line range) obtained from explore output or from the task prompt itself.

#### Scenario: Pinpoint follow-up after explore

- **WHEN** explore output names `api.py` lines 40–60 as the relevant region and the agent needs to confirm one detail there
- **THEN** the agent MAY read that specific range directly without a second explore delegation

#### Scenario: Refinement drifts into re-exploration

- **WHEN** a "refinement" requires opening files or searching patterns explore did not surface
- **THEN** the agent SHALL delegate a new query to `@explore` instead of continuing with direct tools

### Requirement: Player reuse checks route through explore

Player's pre-write existence/reuse check (verifying whether a function, utility, or dependency already exists before writing new code) SHALL be delegated to `@explore` as a single query, not performed via direct `grep` sweeps.

#### Scenario: Player checks for an existing helper

- **WHEN** player is about to write a new helper (e.g., an email sender) and must check whether one exists
- **THEN** player SHALL ask `@explore` (e.g., "does this repo already have email-sending code or a library for it?")
- **THEN** player SHALL reuse or extend what explore finds, writing from scratch only as a last resort

### Requirement: Coach gathers beyond-diff context via explore

Coach reviews the delivered diff directly — the diff is its input. Any context beyond the diff (project conventions, existing utilities or duplicates, callers of changed code, surrounding code of a hunk, dependency manifests) SHALL be requested from `@explore` first. Coach MAY use direct reads only to pin-verify a specific finding explore already surfaced.

#### Scenario: Coach checks for duplicate utility

- **WHEN** coach suspects the diff reinvents an existing utility (E-category check)
- **THEN** coach SHALL ask `@explore` whether an equivalent utility already exists in the project

#### Scenario: Coach needs surrounding code of a hunk

- **WHEN** coach needs the code around a diff hunk to judge correctness
- **THEN** coach SHALL request the surrounding context from `@explore`, not open the file as the first step
