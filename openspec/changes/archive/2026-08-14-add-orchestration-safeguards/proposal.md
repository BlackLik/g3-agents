# Why

Two chronic failure modes are observed when running the flow/subflow orchestration in practice:

1. **Loops.** Flow gets stuck in unbounded player → coach rejection cycles. The causes are structural, not
   model-specific: the `cycle-priority` spec mandates "repeat until coach accepts" with no retry bound and forbids
   telling the user about rejections until the cycle completes; coach's from-scratch re-review surfaces brand-new
   findings every round (whack-a-mole); each revision starts a fresh player session with no memory of prior rounds
   (oscillation); and keyword-based review routing creates a player ↔ coach ping-pong trap for ordinary
   implementation prompts that mention "verify" or "check".
2. **Excessive questions.** The `question` tool is available to flow/subflow with no policy governing when to ask
   vs. proceed on stated assumptions, and player's "ask before running" rule is ambiguous about whom a subagent
   should ask — so clarification requests leak to the user from every layer.

Additionally, implementation has drifted from the specs: `orchestrator-tool-restriction` and
`flow-subflow-tool-restriction` require an explicit tool allowlist without `'*': allow`, but the current
`.opencode/agents/flow.md` / `subflow.md` frontmatter still uses `'*': allow` with deny entries.

## What Changes

- **Bounded rejection cycles** — revision rounds are capped (3 per task per recursion level). On budget exhaustion
  flow escalates to the user *through the mediated cycle* (player drafts the escalation summary from coach's open
  findings, coach reviews it, flow delivers it) and stops, awaiting a user decision: accept as-is, re-approach, or
  abort. The rule "never tell the user about a rejection until the cycle completes" is scoped to non-exhausted
  budgets.
- **Re-review convergence gate** — on re-review after a rejection, coach SHALL first re-check its own prior
  findings; NEW blocking findings are limited to CRITICAL/HIGH severity. New MEDIUM/LOW findings are advisory —
  listed, but non-blocking. First reviews remain zero-tolerance; the fresh full-submission review stance is kept.
- **Keyword routing narrowed** — "review/check/verify/audit/validate" route a task to coach only when the task's
  primary deliverable is a review verdict (findings/approval). Implementation tasks that merely mention
  verification steps ("run the tests to verify") stay with player, and player SHALL NOT reject them.
- **Clarification policy (new capability)** — flow proceeds on explicitly stated assumptions by default and asks
  the user at most one question round per top-level request, only when genuinely blocked (ambiguous success
  criteria, destructive/irreversible choice, missing access). Player's "ask before running" becomes "stop and
  return upward with a warning" — only the orchestrator talks to the user, and only via mediated deliveries.
- **Tool allowlist completion** — `question` and `todowrite` are removed from the flow/subflow allowlist
  (completing the in-flight `drop_ask_and_todo` branch direction), and the frontmatter switches from
  `'*': allow` + deny entries to the explicit allowlist the specs already require — fixing the spec drift.
- **Revision continuity** — when the runtime's delegation tool supports resuming a subagent session, flow SHALL
  resume the same player session for revision rounds; otherwise the revision prompt SHALL embed coach's full
  prior findings verbatim, so feedback accumulates instead of resetting.

## Capabilities

### New Capabilities

- `clarification-policy`: Rules governing user interaction for orchestrators and executors — assumptions-first
  behavior, a one-round question budget per top-level request, blocked-only escalation through the mediated cycle,
  and player returning risk warnings upward instead of asking anyone directly.

### Modified Capabilities

- `cycle-priority`: "Cycle repeat on rejection" gains a retry budget and a mediated escalation path; the
  prohibition on telling the user about rejections is scoped to non-exhausted budgets.
- `coach-fresh-review`: from-scratch re-review gains a convergence gate — prior findings re-checked first, new
  blocking findings limited to CRITICAL/HIGH on re-review rounds.
- `review-routing`: keyword routing narrowed to tasks whose primary deliverable is a verdict; player's rejection
  rule narrowed likewise.
- `orchestrator-tool-restriction`: allowed tools list drops `question` and `todowrite`.
- `flow-subflow-tool-restriction`: allowlist scenario updated to the same tool set (`task`, `list`, `skill`,
  `webfetch`).

## Impact

- `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` — prompt body: bounded cycle + escalation, narrowed
  keyword routing, clarification policy, revision continuity (bodies stay byte-identical to each other);
  frontmatter: explicit allowlist `task`, `list`, `skill`, `webfetch` replacing `'*': allow` + denies
- `.opencode/agents/player.md` — narrowed review-task rejection (0.6); "ask before running" → return upward
- `.opencode/agents/coach.md` — re-review convergence gate in the fresh-review section and output contract
- `.opencode/reference/flow-reference.md` — worked example of budget-exhaustion escalation; revision-continuity
  guidance
- `.opencode/reference/coach-reference.md` — re-review gating details and verdict matrix alignment
- `.claude/agents/flow.md`, `.claude/agents/player.md`, `.claude/agents/coach.md`, `.claude/reference/` — port
  synchronization per the root AGENTS.md Port Synchronization contract (same behavior, Claude-format frontmatter)
- `.opencode/AGENTS.md` — tool-restriction section updated (allowlist contents, stale read/grep/glob text removed)
- `.claude/AGENTS.md` — deliberate-divergences list updated if the port differs on escalation mechanics
- Branch `featues/drop_ask_and_todo` WIP (uncommitted `edit: deny` for coach) is aligned/subsumed — coach keeps
  `edit: deny`; the question/todowrite removal lands here
- `openspec/specs/` main specs synced from this change's delta specs
- Verification: `npx markdownlint-cli2` (0 errors), `openspec validate`, flow ↔ subflow byte-identity check
