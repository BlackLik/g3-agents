# context-delegation

## Purpose

Rules for when and how the orchestrator flow delegates context-gathering to @explore directly instead of @player.

## Requirements

### Requirement: Flow delegates context-gathering to explore agent

When the orchestrator flow needs project context (file contents, codebase structure, search results, git history), it SHALL delegate directly to the explore agent via `subagent_type="explore"` — never to `@player`.

#### Scenario: Flow needs file contents

- **WHEN** flow needs to read a file to understand context for a task
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with instructions to read the file

#### Scenario: Flow needs codebase search

- **WHEN** flow needs to search the codebase for patterns or definitions
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with search instructions

#### Scenario: Flow needs git history

- **WHEN** flow needs git log, diff, or blame information
- **THEN** flow SHALL call `task(..., subagent_type="explore")` with git instructions

### Requirement: Player does not handle context-gathering

`@player` SHALL NOT receive tasks whose primary purpose is reading, searching, or investigating the codebase. Player's sole responsibility is writing/modifying code per task instructions.

#### Scenario: Context task misdirected to player

- **WHEN** flow accidentally delegates a context-gathering task to `@player`
- **THEN** `@player` SHALL reject the task and return upward with a message indicating the task should be routed to explore

### Requirement: Explore result format

The explore agent SHALL return results as markdown with the file path as an H3 header followed by a code block containing the contents. Flow SHALL pass explore's returned output verbatim to @player as context, prefixed with the file path.

#### Scenario: Explore returns file contents

- **WHEN** explore reads a file
- **THEN** it SHALL return: ``### path/to/file\n```\n<file contents>\n``` ``

#### Scenario: Explore returns search results

- **WHEN** explore searches the codebase
- **THEN** it SHALL return matching lines with file paths and line numbers in format: `### path/to/file\n- Line N: <matched line>`

#### Scenario: Flow passes explore output to player

- **WHEN** flow receives explore output
- **THEN** flow SHALL include the explore output verbatim in the player task prompt as context
