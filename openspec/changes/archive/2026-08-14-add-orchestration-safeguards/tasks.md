# 1. Runtime Capability Check

- [x] 1.1 Verify whether the target OpenCode runtime's `task` tool supports resuming a subagent session (task/session
  id); check the Claude Code Agent tool likewise. Record the result — it decides which revision-continuity path
  (session resume vs verbatim findings) is documented as primary per port in `.claude/AGENTS.md` divergences

  Result (recorded 2026-08-14): OpenCode `task` tool v1.18.15 SUPPORTS session resume via optional `task_id`
  parameter ("pass a prior task_id and the task will continue the same subagent session as before instead of creating
  a fresh one"). Claude Code Agent tool v2.1.232 does NOT — `AgentInput` has no resume/session-id field (description,
  prompt, subagent_type, model, run_in_background, name, isolation only). Primary path: OpenCode port = session
  resume via `task_id`; Claude port = verbatim findings embedded in the revision prompt.

## 2. OpenCode Port — Orchestrator Bodies

- [x] 2.1 Update `.opencode/agents/flow.md` body: (a) Mediated cycle section — add the 3-round retry budget per task
  per recursion level and the budget-exhaustion escalation path (player drafts summary → coach reviews → deliver
  with accept / re-approach / abort → stop turn); (b) Review routing paragraph — route by primary deliverable
  (verdict → coach; code → player), not keyword presence; (c) new clarification-policy subsection — assumptions-first,
  one question round per top-level request, blocked-only, escalation via mediated delivery; (d) Delegation mechanics —
  revision continuity (resume session when supported, else embed all prior findings verbatim); (e) Non-negotiables —
  add the bounded-cycle and escalation bullets. Keep inline `[PRIORITY:n]` markers on every rule
- [x] 2.2 Mirror the exact same body into `.opencode/agents/subflow.md` (bodies SHALL remain byte-identical; only
  frontmatter differs)

## 3. OpenCode Port — Player and Coach Bodies

- [x] 3.1 Update `.opencode/agents/player.md`: (a) rule 0.6 — reject only verdict-deliverable tasks; implementation
  tasks mentioning "verify/check" steps are executed, with a worked example ("implement X and verify it works" →
  executed, not rejected); (b) Safety section — replace "ask before running" with "stop and return upward with a ⚠️
  warning — the orchestrator decides"; add the note that player never asks the user or other agents
- [x] 3.2 Update `.opencode/agents/coach.md`: (a) Fresh-review section — add the re-review convergence gate (verify
  each prior finding fixed/not-fixed first; new blocking findings on re-review are CRITICAL/HIGH only; new MEDIUM/LOW
  are advisory); (b) Output contract — add the advisory-findings listing rule for re-reviews

## 4. OpenCode Port — Frontmatter

- [x] 4.1 Replace the `permission` block in `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` with the
  explicit allowlist `task`, `list`, `skill`, `webfetch` plus `edit: deny` and `bash: deny`; remove `'*': allow` and
  all per-tool deny entries made redundant by the allowlist; `question` and `todowrite` SHALL NOT appear
- [x] 4.2 Keep the uncommitted `edit: deny` addition to `.opencode/agents/coach.md` (branch
  `featues/drop_ask_and_todo` WIP) — it is part of this change's tool-layer enforcement

  Note: `edit: deny` in coach.md was already committed on this branch (4672ac5 "deny coach edit tool") — kept.

## 5. Reference Tiers (OpenCode)

- [x] 5.1 Update `.opencode/reference/flow-reference.md`: add a worked example of a budget-exhaustion escalation
  trace (3 rejections → player drafts summary → coach reviews → delivered choice → turn stops) and the
  revision-continuity guidance (session resume / verbatim findings fallback)
- [x] 5.2 Update `.opencode/reference/coach-reference.md`: document the re-review convergence gate next to the
  verdict matrix and severity definitions (advisory MEDIUM/LOW on re-review; blocking CRITICAL/HIGH only)

## 6. Claude Port Synchronization

- [x] 6.1 Apply the same body changes as tasks 2.1/3.1/3.2 to `.claude/agents/flow.md`, `.claude/agents/player.md`,
  `.claude/agents/coach.md` (same behavior, Claude Code format)
- [x] 6.2 Update `.claude/agents/flow.md` `tools:` allowlist: remove any interactive user-question tool and any
  todo-list tool; keep `Agent(flow, player, coach, Explore)`, read-only exclusions, and `mcp__*`
- [x] 6.3 Mirror the reference-tier changes into `.claude/reference/flow-reference.md` and
  `.claude/reference/coach-reference.md`
- [x] 6.4 Update `.claude/AGENTS.md` deliberate-divergences list: record the revision-continuity path per port
  (from task 1.1) and any tool-name differences

## 7. Main Spec Synchronization

- [x] 7.1 Apply the five modified delta specs to `openspec/specs/` main specs: `cycle-priority`,
  `coach-fresh-review`, `review-routing`, `orchestrator-tool-restriction`, `flow-subflow-tool-restriction`
- [x] 7.2 Create `openspec/specs/clarification-policy/spec.md` from this change's delta spec (dropping the
  `## ADDED Requirements` header for a plain `## Requirements` section per main-spec format)

## 8. DOX Updates

- [x] 8.1 Update `.opencode/AGENTS.md`: Orchestrator tool restriction section (explicit allowlist contents; remove
  the stale claim that read/grep/glob remain allowed); Critical operational rules (bounded cycle + escalation,
  assumptions-first clarification); Review routing section (primary-deliverable rule); Cycle priority section
  (retry budget); Coach fresh review section (convergence gate)
- [x] 8.2 Update `.claude/AGENTS.md` if any body or allowlist change alters the divergence statements

  Note: done as part of 6.4 — tool-name mapping (`question`/`todowrite` → `AskUserQuestion`/`TodoWrite`) and the
  per-port revision-continuity paths recorded in the divergences list; no other divergence statement was altered.

## 9. Verification

- [x] 9.1 Verify `.opencode/agents/flow.md` and `.opencode/agents/subflow.md` bodies are byte-identical (diff shows
  frontmatter only)
- [x] 9.2 Grep for stale text: no `question`/`todowrite` in flow/subflow allowlists or permission docs; no
  "ask before running" in player.md; no unbounded "until ✅ Accepted" wording without the budget in flow/subflow
- [x] 9.3 Run `npx markdownlint-cli2` from the repo root — 0 errors
- [x] 9.4 Run `openspec validate add-orchestration-safeguards` — valid
