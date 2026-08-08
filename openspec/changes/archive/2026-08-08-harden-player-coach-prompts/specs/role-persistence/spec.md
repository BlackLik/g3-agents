# role-persistence (delta)

## MODIFIED Requirements

### Requirement: Prompts carry an explicit role-invariants block

Each agent prompt SHALL contain a role-invariants block that (a) names the agent's fixed responsibilities, (b) states
that tool availability never changes them, and (c) is restated as the terminal content of the prompt — the closing
non-negotiables section SHALL be the last block before the generation point, with no other rule content after it.

#### Scenario: Prompt structure check

- **WHEN** an agent prompt file (`flow.md`, `subflow.md`, `player.md`, `coach.md` in either port) is inspected
- **THEN** it SHALL contain a role-invariants block near the top
- **THEN** it SHALL restate the invariants in a closing section at the end of the prompt
- **THEN** no normative rule content SHALL appear after that closing section

#### Scenario: Closing block is self-sufficient

- **WHEN** the closing non-negotiables section of any agent prompt is read in isolation
- **THEN** it SHALL contain every role-critical invariant on its own (flow/subflow: delegate only, never answer the user
  directly, every response is a `task` tool call; player: implement only, return upward, never answer the user; coach:
  review only, binary verdict, never edit files)
- **THEN** it SHALL NOT depend on mid-document rules to be complete

## ADDED Requirements

### Requirement: Oversized prompts are split into core and reference tiers

Any agent prompt whose normative rule count exceeds the instruction-stacking budget SHALL be split into a core tier that
is always present in the system prompt and a reference tier that is loaded on demand (via tool call or a separate file)
instead of being held in context permanently. This applies at minimum to `coach.md` and `flow.md` (both 500+ lines);
`subflow.md` SHALL inherit flow's split mechanically to preserve byte-identity. The core tier SHALL contain only the
role-critical rules (flow: delegate-only, `task`-call-only responses; coach: review-only stance, binary verdict, never
edit code) plus explicit triggers stating when to consult the reference tier. The number of simultaneously active
normative rules in a core tier SHALL stay small enough to avoid instruction-stacking collapse (target: at most 10
discrete rules).

#### Scenario: Core tier content audit

- **WHEN** the core tier of `coach.md` or `flow.md` is audited
- **THEN** it SHALL contain that agent's role-critical rules and structure-first response rule
- **THEN** it SHALL NOT inline bulk catalogs (coach: AI-trace categories, vulnerability catalog, anti-pattern catalog;
  flow: worked examples, failure-recovery examples) — those SHALL live in the reference tier

#### Scenario: Reference tier is reachable on demand

- **WHEN** an agent needs reference material during work (coach needs a detection checklist; flow composes a delegation
  prompt needing embedded role definitions)
- **THEN** the material SHALL be retrievable from the reference tier (file read or equivalent mechanism)
- **THEN** both ports SHALL expose the same core/reference split
- **THEN** when agents are installed via the install scripts (global or local), the reference tier SHALL be installed
  beside `agents/`, and the core tier's load triggers SHALL name both the repo-relative path and the installed
  fallback path

#### Scenario: Subflow byte-identity preserved

- **WHEN** `flow.md` is restructured into core and reference tiers
- **THEN** `subflow.md` SHALL receive the byte-identical body
- **THEN** the split SHALL NOT break the tooling requirement that the two files share body content

### Requirement: Constrained responses are structure-first

For responses governed by a mandated output structure (flow's delegation response, coach's review format, player's
return block), the response SHALL begin directly with that structure. Free-form reasoning SHALL NOT precede the
structure; any reasoning lives inside the structure's designated sections.

#### Scenario: Flow response is a tool call

- **WHEN** flow or subflow emits any response
- **THEN** the response SHALL be an actual `task` tool call with no plain-text preamble before it
- **THEN** any reasoning SHALL live inside the delegated prompt or not be emitted at all

#### Scenario: Coach review starts with structure

- **WHEN** coach emits a review
- **THEN** the first content of the response SHALL be the review format's opening heading (`## Summary`)
- **THEN** no preamble, thinking-aloud, or restatement of the task SHALL appear before it

#### Scenario: Player return starts with structure

- **WHEN** player returns a result upward
- **THEN** the response SHALL begin with its mandated return structure
- **THEN** any rationale SHALL appear inside the structure, not before it
