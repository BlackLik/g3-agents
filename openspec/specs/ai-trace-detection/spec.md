# ai-trace-detection

## Purpose

Rules for detecting AI-generated code in diffs reviewed by @coach, covering signature markers, naming patterns,
structure patterns, logic patterns, and context awareness.

## Requirements

### Requirement: Detect AI signature markers

The system SHALL detect explicit text markers in code diffs that indicate AI generation, including instruction
comments (e.g., `# Step 1:`), placeholder comments (e.g., `// Your code here`), narrative comments (e.g., `/* First,
we check if... */`), universal docstrings on trivial functions, and explicit AI references (e.g., "As an AI language
model").

#### Scenario: Detects instruction step comments

- **WHEN** a diff contains a comment matching `Step \d` pattern (e.g., `# Step 1: Validate input`)
- **THEN** the system SHALL flag it as an A1 marker with HIGH weight

#### Scenario: Detects placeholder comments

- **WHEN** a diff contains a comment matching `your logic|your code` pattern (e.g., `// Add your logic here`)
- **THEN** the system SHALL flag it as an A2 marker with HIGH weight

#### Scenario: Detects narrative comments

- **WHEN** a diff contains conversational comment markers (e.g., `# Let's implement this function`)
- **THEN** the system SHALL flag it as an A3 marker with HIGH weight

#### Scenario: Detects universal docstrings on trivial functions

- **WHEN** a trivial function (≤5 lines) has a full docstring with structured annotations (e.g., @param, :param:, or
  similar)
- **THEN** the system SHALL flag it as an A4 marker with MEDIUM weight

#### Scenario: Detects AI-formatted commit messages

- **WHEN** a commit message in the diff follows a rigid template (e.g., "feat: Add X", "fix: Correct Y") with no
  stylistic variation
- **THEN** the system SHALL flag it as an A5 marker with LOW weight

#### Scenario: Detects AI-formatted PR descriptions

- **WHEN** a PR description follows a formulaic structure with sections like "## Summary", "## Changes", "## Testing"
  in a rigid template
- **THEN** the system SHALL flag it as an A6 marker with LOW weight

#### Scenario: Detects explicit AI references

- **WHEN** a diff contains "As an AI" or similar AI self-reference in comments
- **THEN** the system SHALL flag it as an A7 marker with HIGH weight

#### Scenario: Per-category CONFIRMED from signature markers

- **WHEN** 3 or more A-category markers are detected in a single diff
- **THEN** the system SHALL return a CONFIRMED verdict for the A-category (not overall). The overall verdict still
  comes from the decision matrix combining all category verdicts.

### Requirement: Compute per-category verdicts

The system SHALL compute a per-category verdict (CLEAN / SUSPECTED / CONFIRMED) for each of the 5 categories based on
the markers detected within that category.

#### Scenario: Category CLEAN verdict

- **WHEN** a category has 0-1 markers detected AND none have HIGH weight
- **THEN** the system SHALL return CLEAN for that category

#### Scenario: Category SUSPECTED verdict

- **WHEN** a category has 2+ LOW or MEDIUM weight markers detected, OR exactly 1 HIGH weight marker
- **THEN** the system SHALL return SUSPECTED for that category

#### Scenario: Category CONFIRMED verdict

- **WHEN** a category has 3+ HIGH weight markers detected
- **THEN** the system SHALL return CONFIRMED for that category

### Requirement: Detect AI naming patterns

The system SHALL analyze identifier names in the diff for AI-typical naming patterns including overly long names
(average >25 characters), zero abbreviations, academic verbs (perform, execute, process, handle, validate), and
uniform naming patterns.

#### Scenario: Detects overly long identifiers with no abbreviations

- **WHEN** the average identifier length in the diff exceeds 25 characters AND no abbreviations are present
- **THEN** the system SHALL flag it as a B1 marker with MEDIUM weight
- **NOTE**: An abbreviation is defined as any identifier token that is ≤3 characters and is not a dictionary word
  (e.g., idx, cfg, msg, buf, tmp, ref, val, len, max, min, cnt, ptr, str, num, arg, param, ctx, env, cfg, regex, cb,
  fn, obj, arr, el, col, row, btn, lbl, nav, req, res, err, exc, cb, evt, doc, src, dst, tmp, init, config, utils,
  helpers, consts, types, enums, mixins, plugins, adapters, middlewares, interceptors, validators, formatters,
  parsers, serializers, deserializers, normalizers, transformers, converters, generators, builders, factories,
  providers, consumers, resolvers, handlers, controllers, services, repositories, mappers, dtos, models, schemas,
  stubs, mocks, fixtures, factories, seeds, migrations, scripts, tasks, jobs, workers, agents, proxies, bridges,
  tunnels, gateways, facades, adapters, wrappers, decorators, composers, aggregators, collectors, dispatchers,
  emitters, listeners, observers, subscribers, publishers, notifiers, schedulers, timers, counters, gauges, meters,
  samplers, limiters, throttlers, debouncers, coalescers, batchers, chunkers, splitters, joiners, mergers, sorters,
  filters, mappers, reducers, iterators, traversers, walkers, scanners, parsers, lexers, tokenizers, normalizers,
  denormalizers, serializers, deserializers, encoders, decoders, compressors, decompressors, encryptors, decryptors,
  hashers, digests, signers, verifiers, validators, sanitizers, escapers, unescapers, interpolators, formatters,
  printers, loggers, reporters, exporters, importers, loaders, dumpers, resolvers, finders, locators, discoverers,
  registrars, selectors, pickers, choosers, routers, dispatchers, schedulers, orchestrators, coordinators,
  supervisors, monitors, watchers, trackers, followers, leaders, candidates, voters, proposers, acceptors, learners,
  observers, replicators, synchronizers, coordinators, mediators, negotiators, arbiters, judges, evaluators, scorers,
  rankers, classifiers, clusterers, segmenters, partitioners, distributors, allocators, assigners, schedulers,
  planners, optimizers, solvers, estimators, predictors, forecasters, analyzers, profilers, tracers, loggers,
  reporters, exporters, collectors, aggregators, summarizers, synthesizers, generators, producers, consumers,
  handlers, processors, workers, runners, executors, launchers, starters, stoppers, pausers, resumers, cancellers,
  aborters, interrupters, signalers, waiters, notifiers, broadcasters, multicasters, unicasters, anycasters,
  geocasters, simulcasters, narrowcasters, pointcasters). This list is illustrative — any token ≤3 chars that is not a
  common English word counts as an abbreviation.

#### Scenario: Detects academic verb usage

- **WHEN** function names use academic verbs (perform, execute, process, handle, validate) instead of simpler
  alternatives (get, set, check, run)
- **THEN** the system SHALL flag it as a B3 marker with LOW weight

#### Scenario: Detects uniform naming patterns

- **WHEN** every function in the diff follows the exact `verbNoun()` pattern with no style variation
- **THEN** the system SHALL flag it as a B4 marker with LOW weight

#### Scenario: Detects zero abbreviations in entire diff

- **WHEN** every identifier in the diff is fully spelled out with zero abbreviations (as defined in B1)
- **THEN** the system SHALL flag it as a B2 marker with LOW weight

#### Scenario: Detects no domain-specific names

- **WHEN** the diff uses no project-specific terminology, domain jargon, or team conventions in identifiers
- **THEN** the system SHALL flag it as a B5 marker with MEDIUM weight

### Requirement: Detect AI structure patterns

The system SHALL analyze code architecture for AI-typical structural patterns including CRUD symmetry (implementing
full CRUD when only read is needed), universal error handling (wrapping every call in try/except), unnecessary
abstractions (interface for single implementation), textbook file ordering, universal documentation, and dead code.

#### Scenario: Detects CRUD symmetry

- **WHEN** a diff creates create/update/delete operations alongside create/read operations, AND the calling code only
  uses the read operation (heuristic: count call sites — if write operations have 0 call sites in the diff, flag)
- **THEN** the system SHALL flag it as a C1 marker with MEDIUM weight

#### Scenario: Detects universal error handling

- **WHEN** every external call in the diff is wrapped in try/except with logging, including calls that cannot
  reasonably fail
- **THEN** the system SHALL flag it as a C2 marker with MEDIUM weight

#### Scenario: Detects unnecessary abstractions

- **WHEN** the diff introduces an interface or abstract class for a single concrete implementation with no planned
  variants
- **THEN** the system SHALL flag it as a C3 marker with MEDIUM weight

#### Scenario: Detects universal documentation

- **WHEN** every function, method, and class in the diff has a docstring/comment, including trivial getters/setters
  and internal helpers
- **THEN** the system SHALL flag it as a C5 marker with LOW weight

#### Scenario: Category SUSPECTED from structure patterns

- **WHEN** 3 or more C-category markers are detected in a single diff
- **THEN** the system SHALL raise the C-category verdict to SUSPECTED

### Requirement: Detect AI logic patterns

The system SHALL analyze code logic for AI-typical patterns including reimplementing built-in functions (manual
sort/filter/map instead of using language built-ins), custom library code (writing own HTTP client or retry logic
instead of using existing libraries), over-validation (validating what cannot be invalid), and wrong abstraction
level.

#### Scenario: Detects reimplemented built-ins

- **WHEN** the diff contains a manual sort, filter, or map implementation that could be replaced by a language
  built-in or standard library function
- **THEN** the system SHALL flag it as a D1 marker with HIGH weight

#### Scenario: Detects custom library code

- **WHEN** the diff implements functionality (HTTP client, retry logic, ORM) that duplicates an existing library
  available in the project
- **THEN** the system SHALL flag it as a D2 marker with HIGH weight

#### Scenario: Detects no project idioms

- **WHEN** the diff uses generic patterns instead of project-specific conventions (e.g., using a generic for-loop
  instead of the project's preferred array method, or not following the project's established error handling pattern),
  AND @explore confirms the project has established idioms
- **THEN** the system SHALL flag it as a D5 marker with MEDIUM weight

#### Scenario: Category CONFIRMED from logic patterns

- **WHEN** 2 or more D-category markers are detected in a single diff
- **THEN** the system SHALL raise the D-category verdict to CONFIRMED

### Requirement: Detect AI context patterns

The system SHALL analyze project awareness by checking whether the diff creates new utilities when one exists, creates
new files instead of editing existing ones, duplicates existing dependencies, or uses wrong import styles. Context
checks SHALL require delegation to @explore.

#### Scenario: Detects duplicate utility creation

- **WHEN** the diff creates a new utility file and @explore confirms an equivalent utility already exists in the
  project
- **THEN** the system SHALL flag it as an E1 marker with HIGH weight

#### Scenario: Detects new file instead of edit

- **WHEN** the diff creates a new file and @explore confirms the functionality should extend an existing file
- **THEN** the system SHALL flag it as an E2 marker with MEDIUM weight

#### Scenario: Detects duplicate dependency

- **WHEN** the diff adds a package and @explore confirms it already exists in package.json or equivalent
- **THEN** the system SHALL flag it as an E3 marker with HIGH weight

#### Scenario: Detects style mismatch

- **WHEN** the diff uses coding style inconsistent with the project's conventions (e.g., different indentation, naming
  convention, or bracket style) and @explore confirms the project convention
- **THEN** the system SHALL flag it as an E4 marker with MEDIUM weight

#### Scenario: Detects wrong import style

- **WHEN** the diff uses import/require style inconsistent with the project's conventions (e.g., using ES modules when
  the project uses CommonJS, or relative imports when the project uses absolute paths) and @explore confirms the
  project convention
- **THEN** the system SHALL flag it as an E5 marker with MEDIUM weight

#### Scenario: Context checks only when suspected

- **WHEN** no other category has produced a SUSPECTED or CONFIRMED verdict
- **THEN** the system SHALL skip E-category checks to avoid unnecessary @explore delegation cost

### Requirement: Apply decision matrix for overall verdict

The system SHALL combine per-category verdicts (CLEAN / SUSPECTED / CONFIRMED) using the decision matrix to produce an
overall verdict: CLEAN (≤1 SUSPECTED, 0 CONFIRMED), SUSPECTED (2-3 SUSPECTED or 1 CONFIRMED), or CONFIRMED (≥4
SUSPECTED or ≥2 CONFIRMED).

#### Scenario: Clean verdict

- **WHEN** 0 or 1 categories are SUSPECTED and none are CONFIRMED
- **THEN** the system SHALL return CLEAN verdict and proceed with normal code review

#### Scenario: Suspected verdict

- **WHEN** 2-3 categories are SUSPECTED or exactly 1 category is CONFIRMED
- **THEN** the system SHALL return SUSPECTED verdict and flag in review with request for author explanation

#### Scenario: Confirmed verdict

- **WHEN** 4 or more categories are SUSPECTED or 2 or more categories are CONFIRMED
- **THEN** the system SHALL return CONFIRMED verdict and elevate scrutiny to demand justification for every
  non-trivial line

### Requirement: Report AI detection findings

The system SHALL include a structured `## AI Detection` section in the coach review output containing the verdict,
list of evidence with marker IDs and locations, and an action request when verdict is SUSPECTED or CONFIRMED.

#### Scenario: Reports detection results in review

- **WHEN** the AI detection phase completes with SUSPECTED or CONFIRMED verdict
- **THEN** the system SHALL append an `## AI Detection` section to the review output with verdict, evidence list
  (marker ID, description, file:line), and action request

#### Scenario: Clean verdict omits detection section

- **WHEN** the AI detection phase returns CLEAN verdict
- **THEN** the system SHALL NOT include an AI Detection section in the review output
