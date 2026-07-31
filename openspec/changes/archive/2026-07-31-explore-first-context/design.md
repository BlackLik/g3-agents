# explore-first-context — Design

## Context

The three roles gather context inconsistently today:

- **flow** — already compliant: "PROHIBITED: reading files… delegate ALL investigation directly to @explore" (`.opencode/agents/flow.md`). Nothing to fix except adding the explore-first framing it should propagate into delegated prompts.
- **player** — contradictory guidance. Rule 0 says "use `@explore` for batch reads or graph search", but rule 5 ("Check before you write") instructs raw `grep -r`, and "How You Work" says "**Glob/Grep** for exploring the codebase". Under conflict, players default to cheap-looking direct reads that are actually expensive: every file read lands in player's own context window.
- **coach** — mixed. E-category checks and line 422 ("If need read file then call `@explore`") route through explore, but the review algorithm otherwise assumes direct grep (A-category grep patterns) and gives no ordering rule for beyond-diff context.

`@explore` runs complex queries in its own context and returns only the distilled answer — the caller pays for the summary, not the exploration. One aggregated explore query replaces N raw reads.

## Goals / Non-Goals

**Goals:**

- One consistent ordering rule in all three role prompts: explore FIRST for detailed context; direct read/grep only for narrow refinement of what explore surfaced.
- Remove the contradictory pro-grep guidance in player.md; re-scope, don't delete, the underlying intent (reuse checks still happen — via explore).
- Coach keeps reviewing the diff directly (the diff is its input); only beyond-diff context routes through explore.
- Both ports updated in the same commit; `subflow.md` stays byte-identical to `flow.md`.

**Non-Goals:**

- No tooling/permission enforcement (OpenCode `permission` maps or Claude `tools:` allowlists stay unchanged — read tools remain available for the refinement carve-out).
- No change to the mediated cycle, depth rules, or review routing.
- No change to flow's existing hard ban on self-reading (it stays stricter than player/coach: flow never reads, even for refinement).

## Decisions

### D1: Prompt-level rule, not tool removal

Enforce explore-first via prompt rules rather than stripping Read/Grep from player/coach tool lists. Rationale: the refinement carve-out is legitimate (pinpoint re-check of one line range is cheaper inline than a second explore round-trip), and coach's grep-based A-category signature checks operate on the diff text itself, which must stay direct. Alternative considered — removing read tools entirely — rejected: it would force explore round-trips for trivial confirmations and break coach's diff-grep checks.

### D2: "Narrow refinement" defined by provenance, not size

A direct-tool call is allowed only when scoped to a concrete target explore (or the task prompt) already named — a specific file/symbol/line range. This is testable in review: if the target didn't come from explore output or the delegated prompt, the call violates the rule. Alternative — a byte/file-count budget — rejected as unmeasurable in a prompt contract.

### D3: Per-role placement of the rule

- **player.md**: rule 0 becomes the explore-first rule with the ordering + refinement carve-out; rule 5 rewritten to route reuse checks through explore (keep the ❌ raw-grep example as the Bad case); "How You Work" bullet rewritten ("**Bash** for running things; context via `@explore`, direct Read/Grep only to refine explore results"); "What You Do" step 2 updated accordingly; Non-negotiables gets the explore-first line.
- **coach.md**: extend the existing explore mentions (line ~74 and ~422) into one explicit rule near the review algorithm: diff = direct input; everything beyond the diff = explore first; direct read only to pin-verify an explore finding. A/B/C/D-category diff-text checks unchanged.
- **flow.md / subflow.md**: add one line to "Context gathering via @explore" stating the ordering rationale (complex aggregated queries, token economy) so flow phrases explore queries as aggregated requests and embeds the same expectation when delegating to player/coach.

### D4: SOLID framing in one sentence, not an essay

Each prompt gets at most 1–2 sentences of rationale (token economy + single responsibility: explore investigates, you execute/review). The rule text carries the behavior; long justifications in agent prompts are themselves token waste.

### D5: DOX + spec sync

`/.opencode/AGENTS.md` "Critical operational rules" gains the explore-first contract per role; `/.claude/AGENTS.md` needs no new divergence entry (behavior is identical across ports — divergence list only records port-format differences). Delta spec extends the existing `context-delegation` capability rather than creating a new one, since that spec already owns explore-delegation rules.

## Risks / Trade-offs

- [Over-delegation: agent sends trivial single-symbol lookups to explore, adding round-trip latency] → The refinement carve-out explicitly permits direct reads for concrete targets already named in the task prompt; rule text says "detailed or broad context", not "any context".
- [Coach's grep-based signature checks (A-category) misread as violations] → D1/D3 explicitly exempt diff-text analysis; only beyond-diff context routes through explore.
- [Ports drift during edit] → Single commit touches both ports; `subflow.md` regenerated byte-identical from `flow.md`; markdownlint run as the existing verification gate.
- [Prompt-level rules are advisory, not enforced] → Accepted; consistent with every other contract in this system (role invariants, review routing). Consistency of wording across all three prompts is the mitigation.
