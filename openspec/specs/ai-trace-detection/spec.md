# ai-trace-detection

## Purpose

Rules for detecting AI-generated code in diffs reviewed by @coach, covering signature markers, naming patterns, structure patterns, logic patterns, and context awareness.

## Requirements

### Requirement: Detect AI signature markers

The system SHALL detect explicit text markers in code diffs that indicate AI generation, including instruction comments (e.g., `# Step 1:`), placeholder comments (e.g., `// Your code here`), narrative comments (e.g., `/* First, we check if... */`), universal docstrings on trivial functions, and explicit AI references (e.g., "As an AI language model").

#### Scenario: Detects instruction step comments

- **WHEN** diff contains `Step \d` pattern
- **THEN** flag A1 with HIGH weight

#### Scenario: Detects placeholder comments

- **WHEN** diff contains `your logic|your code` pattern
- **THEN** flag A2 with HIGH weight

#### Scenario: Detects narrative comments

- **WHEN** diff contains conversational comment markers
- **THEN** flag A3 with HIGH weight

#### Scenario: Detects universal docstrings on trivial functions

- **WHEN** trivial function (≤5 lines) has structured docstring
- **THEN** flag A4 with MEDIUM weight

#### Scenario: Detects AI-formatted commit messages

- **WHEN** commit message follows rigid template
- **THEN** flag A5 with LOW weight

#### Scenario: Detects AI-formatted PR descriptions

- **WHEN** PR description follows formulaic structure
- **THEN** flag A6 with LOW weight

#### Scenario: Detects explicit AI references

- **WHEN** diff contains "As an AI"
- **THEN** flag A7 with HIGH weight

#### Scenario: Per-category CONFIRMED from signature markers

- **WHEN** 3+ A-category markers detected
- **THEN** CONFIRMED for A-category

### Requirement: Compute per-category verdicts

The system SHALL compute a per-category verdict (CLEAN / SUSPECTED / CONFIRMED) for each of the 5 categories based on the markers detected within that category.

#### Scenario: Category CLEAN verdict

- **WHEN** 0-1 markers AND none HIGH
- **THEN** CLEAN

#### Scenario: Category SUSPECTED verdict

- **WHEN** 2+ LOW/MED markers OR exactly 1 HIGH
- **THEN** SUSPECTED

#### Scenario: Category CONFIRMED verdict

- **WHEN** 3+ HIGH markers
- **THEN** CONFIRMED

### Requirement: Detect AI naming patterns

The system SHALL analyze identifier names in the diff for AI-typical naming patterns including overly long names (average >25 characters), zero abbreviations, academic verbs (perform, execute, process, handle, validate), and uniform naming patterns.

#### Scenario: Detects overly long identifiers with no abbreviations

- **WHEN** avg length >25 AND no abbreviations
- **THEN** flag B1 with MEDIUM weight

#### Scenario: Detects academic verb usage

- **WHEN** function names use academic verbs
- **THEN** flag B3 with LOW weight

#### Scenario: Detects uniform naming patterns

- **WHEN** every function follows `verbNoun()` pattern
- **THEN** flag B4 with LOW weight

#### Scenario: Detects zero abbreviations in entire diff

- **WHEN** every identifier fully spelled out
- **THEN** flag B2 with LOW weight

#### Scenario: Detects no domain-specific names

- **WHEN** no project-specific terminology used
- **THEN** flag B5 with MEDIUM weight

### Requirement: Detect AI structure patterns

The system SHALL analyze code architecture for AI-typical structural patterns including CRUD symmetry, universal error handling, unnecessary abstractions, and universal documentation.

#### Scenario: Detects CRUD symmetry

- **WHEN** full CRUD but only read used
- **THEN** flag C1 with MEDIUM weight

#### Scenario: Detects universal error handling

- **WHEN** every external call wrapped in try/except
- **THEN** flag C2 with MEDIUM weight

#### Scenario: Detects unnecessary abstractions

- **WHEN** interface/abstract class for single implementation
- **THEN** flag C3 with MEDIUM weight

#### Scenario: Detects universal documentation

- **WHEN** every function has docstring
- **THEN** flag C5 with LOW weight

#### Scenario: Category SUSPECTED from structure patterns

- **WHEN** 3+ C-category markers
- **THEN** SUSPECTED for C-category

### Requirement: Detect AI logic patterns

The system SHALL analyze code logic for AI-typical patterns including reimplementing built-in functions, custom library code, and no project idioms.

#### Scenario: Detects reimplemented built-ins

- **WHEN** manual sort/filter/map replacing built-in
- **THEN** flag D1 with HIGH weight

#### Scenario: Detects custom library code

- **WHEN** duplicates existing library (requires @explore)
- **THEN** flag D2 with HIGH weight

#### Scenario: Detects no project idioms

- **WHEN** generic patterns instead of project conventions (requires @explore)
- **THEN** flag D5 with MEDIUM weight

#### Scenario: Category CONFIRMED from logic patterns

- **WHEN** 2+ D-category markers
- **THEN** CONFIRMED for D-category

### Requirement: Detect AI context patterns

The system SHALL analyze project awareness by checking whether the diff creates new utilities when one exists, creates new files instead of editing existing ones, duplicates existing dependencies, or uses wrong import styles. Context checks SHALL require delegation to @explore.

#### Scenario: Detects duplicate utility creation

- **WHEN** new utility file and @explore confirms equivalent exists
- **THEN** flag E1 with HIGH weight

#### Scenario: Detects new file instead of edit

- **WHEN** new file and @explore confirms should extend existing
- **THEN** flag E2 with MEDIUM weight

#### Scenario: Detects duplicate dependency

- **WHEN** adds package and @explore confirms exists
- **THEN** flag E3 with HIGH weight

#### Scenario: Detects style mismatch

- **WHEN** style inconsistent with project conventions (requires @explore)
- **THEN** flag E4 with MEDIUM weight

#### Scenario: Detects wrong import style

- **WHEN** import style inconsistent with project conventions (requires @explore)
- **THEN** flag E5 with MEDIUM weight

#### Scenario: Context checks only when suspected

- **WHEN** no other category SUSPECTED or CONFIRMED
- **THEN** skip E-category

### Requirement: Apply decision matrix for overall verdict

The system SHALL combine per-category verdicts using the decision matrix: CLEAN (≤1 SUSPECTED, 0 CONFIRMED), SUSPECTED (2-3 SUSPECTED or 1 CONFIRMED), CONFIRMED (≥4 SUSPECTED or ≥2 CONFIRMED).

#### Scenario: Clean verdict

- **WHEN** 0-1 SUSPECTED and 0 CONFIRMED
- **THEN** CLEAN, normal review

#### Scenario: Suspected verdict

- **WHEN** 2-3 SUSPECTED or 1 CONFIRMED
- **THEN** SUSPECTED, flag with explanation request

#### Scenario: Confirmed verdict

- **WHEN** ≥4 SUSPECTED or ≥2 CONFIRMED
- **THEN** CONFIRMED, elevate scrutiny

### Requirement: Report AI detection findings

The system SHALL include a structured `## AI Detection` section in the coach review output containing the verdict, evidence list with marker IDs and locations, and an action request when verdict is SUSPECTED or CONFIRMED.

#### Scenario: Reports detection results in review

- **WHEN** SUSPECTED or CONFIRMED
- **THEN** append AI Detection section with verdict, evidence, action request

#### Scenario: Clean verdict omits detection section

- **WHEN** CLEAN
- **THEN** do NOT include AI Detection section
