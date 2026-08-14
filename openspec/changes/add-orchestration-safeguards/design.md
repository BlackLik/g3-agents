# Context

The flow/subflow orchestrator runs a mediated player → coach cycle. Today the cycle has no termination condition
other than coach acceptance: `cycle-priority` requires "create revision tasks until ✅ Accepted" and forbids
telling the user about rejections until the cycle completes. Coach reviews every re-submission from scratch with
zero tolerance, so each round can surface brand-new findings. Player is a lazy minimal executor whose stance
("don't add validation beyond the task") is structurally opposed to coach's stance ("assume it's broken"). The
observed result in real sessions: rejection loops that never converge, and — because the `question` tool is
available with no usage policy — frequent clarification questions to the user from multiple layers of the system.

Specs currently mandate the looping behavior (cycle-priority) and drifted from implementation on the tool
allowlist (specs require an explicit allowlist; flow.md/subflow.md still use `'*': allow`). A WIP branch
(`featues/drop_ask_and_todo`) already began removing tool surface (`edit: deny` for coach, uncommitted).

Constraints: flow/subflow prompt bodies must remain byte-identical to each other; both ports (`.opencode/`,
`.claude/`) must land behavior changes together (root AGENTS.md Port Synchronization); every normative rule keeps
its inline `[PRIORITY:n]` marker; `npx markdownlint-cli2` must pass.

## Goals / Non-Goals

**Goals:**

- Every rejection cycle terminates: bounded retries, then a mediated escalation to the user
- Re-reviews converge: coach re-checks its own prior findings first; new blocking findings on re-review are
  CRITICAL/HIGH only
- No routing ping-pong: keyword routing keyed on the task's primary deliverable, not word presence
- One voice for user interaction: assumptions-first, at most one question round per top-level request, only the
  orchestrator addresses the user, player escalates risk by returning upward
- Tool-layer enforcement of the above where possible (allowlist), not prompt text alone
- Fix the `'*': allow` drift while editing the same frontmatter lines

**Non-Goals:**

- Not softening coach's zero-tolerance stance on FIRST reviews — severity gating applies to re-review rounds only
- Not changing the depth limits (recursion terminal at depth 2) or the explore-first ordering
- Not removing `todowrite`/`question` from player or coach — only from flow/subflow
- Not redesigning the mediated cycle itself (player → coach → deliver stays unconditional)
- Not touching the ai-trace detection catalogs or vulnerability review content

## Decisions

### Decision 1: Retry budget = 3 revision rounds per task per recursion level

After coach's 3rd consecutive rejection of the same task at the same depth, flow stops revising and escalates.
The counter resets per task and per depth level (each subflow subtask has its own budget).

**Rationale**: One round is often legitimately needed (zero-tolerance coach vs minimal player); two rounds catch
most convergence; a third rejection almost always signals a structural disagreement (infeasible task,
contradictory requirements, or coach/player stance tension) that no amount of retrying resolves — only a human
decision does. Per-task-per-level scoping keeps deep recursion from multiplying a single global budget into
invisibility.

**Alternatives considered**:

- Unlimited retries (status quo) — the loop this change exists to kill.
- Budget 1 — too tight; rejects the legitimate "coach found real bugs, player fixes them" round.
- User-configurable budget — over-engineering for a prompt-defined system; revisit if practice demands it.

### Decision 2: Escalation goes through the mediated cycle, then stops the turn

On budget exhaustion flow does NOT emit a plain-text plea and does NOT keep a backdoor tool. Instead: player
drafts an escalation summary (coach's open findings, what was tried across rounds, current state of the diff),
coach reviews it for accuracy, flow delivers it with an explicit choice — accept as-is / re-approach / abort —
and STOPS. The user's reply arrives as a new top-level request.

**Rationale**: Every invariant survives — structure-first responses, coach-gated delivery, no direct answers —
while the loop gains an exit. The escalation content is coach's own findings summarized, so coach review of the
summary converges in one round in practice; the retry budget applies to it as well, so even a pathological case
terminates.

**Alternatives considered**:

- Keep the `question` tool only for escalations — contradicts the drop_ask_and_todo direction and keeps the
  temptation surface that prompt-only policy already failed to govern.
- Flow emits escalation as plain text without player/coach — violates the structure-first invariant and the
  coach-gated delivery rule.

### Decision 3: Re-review convergence gate — prior findings first, CRITICAL/HIGH-only for new blocking findings

On a re-review after rejection, coach SHALL first verify each of its own prior findings (fixed / not fixed) and
SHALL report NEW findings as blocking only at CRITICAL/HIGH severity. New MEDIUM/LOW findings are listed as
advisory — visible in the review, non-blocking for the verdict. First reviews are unchanged: full zero tolerance.

**Rationale**: Whack-a-mole ends because the verdict gate becomes "prior findings resolved AND no new
critical/high regression", not "no issues exist in the universe". A revision can still be blocked by a genuine
regression it introduced (a new CRITICAL bug), which is exactly the protection fresh review exists for. The
from-scratch re-read is preserved — coach still reviews the full submission, so fixed-one-broken-another is
caught.

**Alternatives considered**:

- Freeze all new findings on re-review — unsafe: a revision introducing a new injection hole would pass.
- Coach carries forward full state between rounds — contradicts the fresh-review stance and invites anchoring.
- Severity gating on ALL reviews — guts the zero-tolerance identity of coach; out of scope (non-goal).

### Decision 4: Routing keyed on primary deliverable, not keyword presence

"Review/check/verify/audit/validate" route to coach only when the task's PRIMARY deliverable is a review verdict
(findings or approval). "Implement X and verify it works" delivers code — it stays with player, and player SHALL
NOT reject it. Player rejects only tasks whose deliverable is a verdict.

**Rationale**: The ping-pong trap (flow routes by word → player must reject by word → flow re-routes → coach
cannot implement) existed because both rules keyed on surface text. Keying both rules on the deliverable type
makes the routing decision coherent at both ends.

**Alternatives considered**:

- Fix only player's rejection rule — half-fix: flow would still route "verify the fix" prompts to coach, and
  coach would receive implementation tasks it cannot execute.
- Expand the keyword list with exceptions — exception lists rot; deliverable-type is one stable test.

### Decision 5: Remove `question` and `todowrite` from the flow/subflow allowlist; enforce policy at the tool layer

Frontmatter moves from `'*': allow` + deny entries to the explicit allowlist `task`, `list`, `skill`, `webfetch`
— which simultaneously (a) drops the two tools, and (b) fixes the standing drift where specs already required an
explicit allowlist but implementation kept `'*': allow`.

**Rationale**: This repo's own history (flow-subflow-use-explore) demonstrated the pattern: a tool that remains
available gets used despite prompt-level prohibition. Policy that must hold goes to the tool layer. `question`
removal forces the assumptions-first + escalation-via-delivery behavior; `todowrite` removal completes the
in-flight branch direction. Prompt text still documents the policy (defense in depth), but the tool layer
enforces it.

**Alternatives considered**:

- Keep tools, prompt-only policy — already the de-facto state; it produces the reported symptom.
- Remove `question` but keep `todowrite` — leaves half the branch work unlanded for no behavioral gain.

### Decision 6: Assumptions-first clarification policy

Flow proceeds on explicitly stated assumptions by default: the assumption is written into the delegation prompt,
and the delivery names it ("assumed X — say the word to redo"). Flow asks the user at most ONE question round per
top-level request, only when genuinely blocked: ambiguous success criteria, a destructive/irreversible choice, or
missing access. Player's "ask before running" becomes "stop and return upward with a ⚠️ warning" — the
orchestrator decides whether the warning warrants escalation; subagents never address the user.

**Rationale**: One voice (orchestrator), one budget (one round), one direction for risk (upward). Asking remains
possible for genuinely blocked cases, but the default flips from ask to assume-and-disclose — which matches how
the system is actually used (iterative, user watching deliveries).

### Decision 7: Revision continuity — resume session when supported, verbatim findings otherwise

When the runtime's delegation tool supports resuming a subagent session (e.g., a task/session id), flow SHALL
resume the same player session for revision rounds. Where unsupported, the revision prompt SHALL embed coach's
full findings from ALL prior rounds verbatim, newest first.

**Rationale**: Fresh-context revisions are the oscillation source (fix round-2 finding, reintroduce round-1
regression). Session resume gives real memory; verbatim embedding is the portable fallback that works in every
runtime. The spec texts both so behavior is correct regardless of runtime capability.

## Risks / Trade-offs

- **[Risk]** Budget 3 still allows 3 full player+coach cycles per task — noticeable latency on hard tasks →
  **Mitigation**: the budget is a ceiling, not a target; convergent tasks finish in round 1–2 as today. The cost
  of a bounded worst case is the point.
- **[Risk]** Advisory MEDIUM/LOW findings accumulate unaddressed → **Mitigation**: they remain listed in the
  review record and in any escalation summary, so the user sees and can act on them; nothing is hidden.
- **[Risk]** A genuinely blocked flow without the `question` tool stalls → **Mitigation**: escalation-via-delivery
  is the spec'd path (Decision 2/6): the blocker is delivered as a reviewed message and the turn ends with a
  question to the user.
- **[Risk]** Coach's convergence gate could rubber-stamp prior findings without real verification →
  **Mitigation**: the gate requires an explicit fixed/not-fixed verdict per prior finding in the review output;
  the from-scratch re-read is unchanged.
- **[Trade-off]** Verbatim-findings fallback grows revision prompts → accepted: it is the portable path; runtimes
  with session resume skip it.
- **[Risk]** Claude port cannot express temperature and has different tool names → **Mitigation**: port lands the
  behavioral body changes and allowlist equivalents; differences are recorded in `.claude/AGENTS.md` divergences
  per the sync contract.

## Open Questions

- Does the OpenCode `task` tool expose session resume (task id) in the target runtime? Implementation task 6.1
  verifies; if absent, only the verbatim-findings path is documented for the OpenCode port and the divergence is
  noted.
- Is a per-task budget sufficient, or do nested subflows need a per-request global ceiling? Decided per-task for
  now; if practice shows multiplicative latency at depth 2, a follow-up change can add a global ceiling without
  altering this change's semantics.
