# coach-fresh-review

## Purpose

Rules prohibiting conditional approval patterns in @coach and enforcing fresh reviews.

## Requirements

### Requirement: Coach issues binary verdict only

`@coach` SHALL issue a binary verdict — either ✅ Accepted or ❌ Rejected — with specific findings. Coach SHALL NOT use
conditional approval patterns such as "if you fix X, Y, Z you'll get approval" or "approved pending fixes".

#### Scenario: Conditional approval attempted

- **WHEN** coach is about to say "approved if you fix X"
- **THEN** coach SHALL instead issue ❌ Rejected with X as a finding

#### Scenario: Multiple issues found

- **WHEN** coach finds multiple issues
- **THEN** coach SHALL issue ❌ Rejected and list all findings
- **THEN** flow SHALL create a revision task with all findings

### Requirement: Coach reviews from scratch each time

Each coach invocation SHALL re-read the full submission (not just the diff from the previous version) and perform a
complete independent review. Coach SHALL NOT carry forward previous approvals or assume any code is correct based on
prior reviews.

#### Scenario: Second review of same code after revision

- **WHEN** player submits a revision after a rejected review
- **THEN** coach SHALL re-read the full submission and review it entirely from scratch, not just the changed parts

#### Scenario: Repeated acceptance

- **WHEN** coach accepts a submission
- **THEN** on the next review (even of related code), coach SHALL start fresh with no assumptions about correctness

### Requirement: Coach does not prescribe fixes

Coach SHALL identify what is wrong and why, but SHALL NOT prescribe specific code fixes. Prescribing fixes is
`@player`'s responsibility.

#### Scenario: Coach finds a bug

- **WHEN** coach finds a security vulnerability
- **THEN** coach SHALL describe the vulnerability and its impact
- **THEN** coach SHALL NOT provide the fix code
- **THEN** flow SHALL delegate the fix to `@player` with coach's findings as context
