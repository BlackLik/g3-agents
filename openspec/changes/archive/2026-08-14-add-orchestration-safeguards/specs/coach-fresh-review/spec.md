# coach-fresh-review

## MODIFIED Requirements

### Requirement: Coach reviews from scratch each time

Each coach invocation SHALL re-read the full submission (not just the diff from the previous version) and perform
a complete independent review. Coach SHALL NOT carry forward previous approvals or assume any code is correct
based on prior reviews. On a re-review after a rejection, coach SHALL FIRST verify each of its own prior findings
and report each as fixed or not fixed; NEW findings on a re-review SHALL be blocking only at CRITICAL or HIGH
severity — new MEDIUM or LOW findings SHALL be listed as advisory and SHALL NOT change the verdict. First reviews
are unaffected: findings of any severity block.

#### Scenario: Second review of same code after revision

- **WHEN** player submits a revision after a rejected review
- **THEN** coach SHALL re-read the full submission and review it entirely from scratch, not just the changed
  parts
- **THEN** coach SHALL first verify each prior finding and report each as fixed or not fixed

#### Scenario: Repeated acceptance

- **WHEN** coach accepts a submission
- **THEN** on the next review (even of related code), coach SHALL start fresh with no assumptions about
  correctness

#### Scenario: New low-severity finding on re-review

- **WHEN** coach discovers a new MEDIUM-severity issue during a re-review after a rejection
- **THEN** coach SHALL list it as advisory
- **THEN** the advisory finding SHALL NOT change the verdict by itself

#### Scenario: New critical regression on re-review

- **WHEN** a revision introduces a new CRITICAL-severity issue discovered on re-review
- **THEN** coach SHALL report it as a blocking finding
- **THEN** coach SHALL issue ❌ Rejected
