# coach-fresh-review

## Purpose

Rules prohibiting conditional approval patterns in @coach and enforcing fresh reviews.

## Requirements

### Requirement: Coach issues binary verdict only

`@coach` SHALL issue a binary verdict — either `APPROVE` or `REJECT` — with specific findings. The prose ✅ Accepted /
❌ Rejected vocabulary is replaced by the `APPROVE` / `REJECT` tokens. Coach SHALL NOT use conditional approval
patterns such as "if you fix X, Y, Z you'll get approval" or "approved pending fixes". The inner loop is N=N: one
coach call per player call until coach APPROVEs; each player call is reviewed exactly once (no extra coach pass at
flow exit).

#### Scenario: Conditional approval attempted

- **WHEN** coach is about to say "approved if you fix X"
- **THEN** coach SHALL instead issue `REJECT` with X as a finding

#### Scenario: Multiple issues found

- **WHEN** coach finds multiple issues
- **THEN** coach SHALL issue `REJECT` and list all findings
- **THEN** the per-task orchestrator SHALL create a revision task with all findings

#### Scenario: Review passes

- **WHEN** coach finds no issues in a player call
- **THEN** coach SHALL issue `APPROVE`
- **THEN** the per-task orchestrator SHALL treat that player call as accepted
- **THEN** flow SHALL relay the approved result without re-reviewing the same player call

### Requirement: Coach reviews from scratch each time

Each coach invocation SHALL re-read the full submission (not just the diff from the previous version) and perform a
complete independent review. Coach SHALL NOT carry forward previous approvals or assume any code is correct based on
prior reviews. On a re-review after a rejection, coach SHALL FIRST verify each of its own prior findings and report
each as fixed or not fixed; NEW findings on a re-review SHALL be blocking only at CRITICAL or HIGH severity — new
MEDIUM or LOW findings SHALL be listed as advisory and SHALL NOT change the verdict. First reviews are unaffected:
findings of any severity block.

#### Scenario: Second review of same code after revision

- **WHEN** player submits a revision after a rejected review
- **THEN** coach SHALL re-read the full submission and review it entirely from scratch, not just the changed parts
- **THEN** coach SHALL first verify each prior finding and report each as fixed or not fixed

#### Scenario: New critical regression on re-review

- **WHEN** a revision introduces a new CRITICAL-severity issue discovered on re-review
- **THEN** coach SHALL report it as a blocking finding
- **THEN** coach SHALL issue `REJECT`

### Requirement: Coach does not prescribe fixes

Coach SHALL identify what is wrong and why, but SHALL NOT prescribe specific code fixes. Prescribing fixes is
`@player`'s responsibility.

#### Scenario: Coach finds a bug

- **WHEN** coach finds a security vulnerability
- **THEN** coach SHALL describe the vulnerability and its impact
- **THEN** coach SHALL NOT provide the fix code
- **THEN** flow SHALL delegate the fix to `@player` with coach's findings as context

### Requirement: Coach review input is sourced via explore

Before issuing any verdict, coach SHALL obtain the full picture of the change under review. Because coach has no
`bash`/`read`/`grep`/`glob` tools, the review input (the git diff, diff stat, and recent commit log) SHALL be gathered
by delegating to `@explore`, and coach SHALL refuse to review if the diff cannot be obtained. This sourcing step is a
prerequisite to every review and does not itself constitute a review verdict.

#### Scenario: Coach cannot see the diff

- **WHEN** coach begins a review but the explore delegation fails to return a usable diff
- **THEN** coach SHALL refuse to review and demand the diff
- **THEN** coach SHALL NOT issue a verdict without the diff

#### Scenario: Review begins with an explore-sourced diff

- **WHEN** coach starts Step 0 of a review
- **THEN** coach SHALL have the diff, diff stat, and log from `@explore` before reading any hunk
- **THEN** coach SHALL read the diff text completely before evaluating findings
