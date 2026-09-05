# session-handoff (delta)

## ADDED Requirements

### Requirement: Inter-session context travels via a handoff file

A text file in a temp dir SHALL carry inter-session context. `player` SHALL write the handoff file on behalf of any
write-less agent (flow/subflow/coach have no general write in either port). The NEXT session's `player` SHALL read
it. The same session SHALL never be resumed to recover context — the file replaces resume.

#### Scenario: Player writes handoff file for a write-less agent

- **WHEN** a session completes a task and needs to pass context to the next session
- **THEN** `player` SHALL write the context to a text handoff file in the temp dir
- **THEN** the completing session SHALL report the handoff file path upward

#### Scenario: Next session's player reads the handoff file

- **WHEN** a new session begins with a handoff-file path in its prompt
- **THEN** the new session's `player` SHALL read the handoff file to recover the context
- **THEN** the new session SHALL NOT resume the prior session to recover the same context

#### Scenario: Role-level rule holds across ports

- **WHEN** the agent in question is a write-less orchestrator (flow/subflow) or reviewer (coach)
- **THEN** the handoff write SHALL be performed by `player` on its behalf, regardless of which write tools the
  reviewer has in its session

### Requirement: Orchestrators pass path and digest only

Orchestrators (flow/subflow) SHALL NOT read handoff-file contents. Flow SHALL pass only the handoff-file PATH plus
its own composed digest in the delegated prompt. Heavy content SHALL NOT enter orchestrator contexts.

#### Scenario: Flow forwards path and digest

- **WHEN** flow delegates a task to the per-task orchestrator or relays a result upward
- **THEN** flow SHALL include the handoff-file path and its own composed digest in the prompt
- **THEN** flow SHALL NOT embed the handoff file's full contents in the prompt

### Requirement: Fresh session per invocation, no resume

Every agent invocation SHALL start a fresh session. Session resume SHALL be abandoned everywhere — including the
`.opencode` `task_id` resume path. Revision continuity SHALL come from verbatim coach-findings embedding plus the
handoff file, never from resuming a prior session.

#### Scenario: Revision rounds use fresh sessions

- **WHEN** a player call is rejected and a revision is created
- **THEN** the revision SHALL run in a new fresh `@player` session
- **THEN** the revision prompt SHALL embed all prior coach findings verbatim, newest first
- **THEN** any inter-session context SHALL travel via the handoff file
