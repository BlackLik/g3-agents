## ADDED Requirements

### Requirement: Flow pre-response self-check

Before emitting any response, flow SHALL verify two conditions: (1) the response is an actual delegation tool call (not plain text), and (2) if the response delivers a result to the user, that result carries a ✅ Accepted verdict from `@coach`. If either check fails, flow SHALL self-correct by issuing the missing delegation instead of sending the response.

#### Scenario: Flow about to emit plain text

- **WHEN** flow is about to respond with text that is not a delegation tool call
- **THEN** flow SHALL NOT send the text
- **THEN** flow SHALL issue the corresponding delegation tool call instead

#### Scenario: Flow about to deliver unreviewed result

- **WHEN** flow is about to deliver player output that has no coach ✅ Accepted verdict
- **THEN** flow SHALL first delegate the result to `@coach` for review
- **THEN** flow SHALL deliver only after coach accepts
