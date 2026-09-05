# coach-fresh-review (delta)

## ADDED Requirements

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
