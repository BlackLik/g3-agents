# Proposal — add-subflow-analog

## Why

The two ports of the agent system are asymmetric and both carry a session model that the next generation of the
system is moving away from:

- The Claude Code port (`.claude/`) has **no `subflow` analog**. Its `.claude/AGENTS.md` "Deliberate divergences"
  list records "No `subflow.md` — Claude Code has no per-file `mode: primary/subagent` split … flow recurses into
  itself (`Agent(flow, player, coach, explore)`)", and `flow.md`'s decomposition tree says "Complex (>2 concerns) →
  MUST delegate recursively to @flow". The divergence list must be updated the moment a `subflow.md` exists on both
  sides.
- Both ports still run the mediated cycle *in the orchestrator*: `flow` decomposes → delegates to `@player` →
  reviews with `@coach` → repeats, and `flow` holds the per-task session. The `.opencode` port resumes the same
  `@player` session across revision rounds via `task_id`; the Claude port has no resume (verified v2.1.232) and
  embeds prior findings verbatim instead. This splits the decision (resume vs verbatim) across ports and couples
  session state to the orchestrator.

The target is a **layered session architecture**: a single thin, long-lived global `flow` that routes and composes
handoffs, and a per-task ephemeral orchestrator (currently "subflow") that owns the whole mediated cycle internally
and dies with the task. This removes the simple-vs-complex routing fast path, abandons session resume everywhere
(including the `.opencode` `task_id` path), and standardizes revision continuity on verbatim findings embedding plus
handoff files.

## What Changes

- **New `.claude/agents/subflow.md`** — the Claude Code analog of `.opencode/agents/subflow.md`. Claude Code
  auto-registers every `*.md` in `agents/` as an agent, so the file must carry a subagent-scoped `description` and a
  body mirroring the shared flow core (reference tier at `.claude/reference/flow-reference.md`). Prerequisite:
  `.claude/agents/flow.md`'s `tools: Agent(flow, player, coach, Explore)` allowlist must name `subflow` before flow
  can spawn it (registration ≠ invocability).
- **Layered session architecture (both ports)** — `flow` becomes a thin global role: routing, decomposition,
  composing each task's handoff, holding the conversation skeleton + cross-turn state, and relaying the
  player-voiced deliverable. `flow` NEVER runs the mediated cycle itself. The per-task ephemeral orchestrator
  (currently "subflow") runs the whole mediated cycle internally and returns upward only the APPROVED result plus
  the path to the handoff file.
- **Uniformity — no fast path (both ports)** — routing changes from "Simple (≤2 concerns) → delegate directly to
  `@player`; Complex (>2 concerns) → MUST delegate to @subflow" to "EVERY task → subflow". Even trivial turns run
  the full pipeline; the system is explicitly designed for medium/large features.
- **Fresh session per invocation (both ports)** — session resume abandoned everywhere. The `.opencode` `task_id`
  resume path is removed from the protocol. Revision continuity = verbatim coach-findings embedding + handoff files.
- **Coach verdict vocabulary (both ports)** — `APPROVE` / `REJECT` replaces the ✅/❌ prose. Inner loop is N=N: "N
  player calls = N coach calls until coach APPROVE"; REJECT → new fresh player session with all prior coach findings
  embedded. No extra coach pass at `flow` exit — subflow's APPROVE is sufficient (single coach pass per player call,
  no doubling).
- **Handoff file protocol (both ports, new)** — a text file in a temp dir carries inter-session context; the same
  session is never resumed. The rule is ROLE-level, not tool-level (`.claude/coach.md` has Bash; orchestrators have
  no general Read in either port) — player writes on behalf of any write-less agent; the NEXT session's player reads;
  orchestrators pass only PATH + their own composed digest in the prompt. Heavy content never enters orchestrator
  contexts.
- **`.claude/AGENTS.md`** — remove the "No `subflow.md`" divergence; record new divergences (subflow exists on both
  sides now; handoff protocol; N=N; APPROVE/REJECT vocabulary).
- **`.opencode/agents/flow.md` + `subflow.md`** — routing becomes uniform (every task → subflow); the `task_id`
  resume protocol is dropped; N=N + APPROVE/REJECT vocabulary. Bodies stay byte-identical to each other.
- **`.claude/agents/flow.md` / `player.md` / `coach.md`** — flow rewritten to the global-role contract (always
  delegates to subflow); player/coach gain APPROVE/REJECT, N=N until APPROVE, and player's handoff-file writing role.
- **`scripts/install.sh`, `install.ps1`, `uninstall.sh`, `uninstall.ps1`** — add `subflow.md` to the Claude file
  lists; update `/scripts/AGENTS.md` explicit file lists ("claude agents: `flow.md`, `player.md`, `coach.md`" →
  add `subflow.md`).
- **openspec delta specs** — for the affected capabilities identified below (routing change, revision-continuity /
  resume change, verdict vocabulary, post-recursion review scope). **BREAKING** for the old routing/resume contract.

## Capabilities

### New Capabilities

- `session-handoff`: The inter-session context bus — a text handoff file in a temp dir, written by `player` on
  behalf of any write-less agent (role-level rule, not tool-level), read by the NEXT session's `player`;
  orchestrators pass only the path plus their own composed digest. Includes the fresh-session-per-invocation
  discipline (no resume, no `task_id` path).

### Modified Capabilities

- `recursive-splitting`: routing changes from "simple → player directly, complex → subflow" to "EVERY task →
  subflow" (uniformity); the orchestrator's per-task decomposition moves into the per-task ephemeral orchestrator;
  subtask boundary clarity still applies to flow→subflow handoff composition and subflow→player decomposition.
- `cycle-priority`: the mediated cycle is enforced unconditionally but now runs INSIDE the per-task orchestrator —
  flow never runs the cycle itself; revision continuity drops session resume (the `task_id` path is removed) in favor
  of fresh sessions + verbatim findings embedding + handoff files; coach verdicts use APPROVE/REJECT; N=N until
  APPROVE with no extra coach pass at flow exit.
- `coach-fresh-review`: binary verdict vocabulary changes from ✅ Accepted / ❌ Rejected prose to `APPROVE` / `REJECT`;
  fresh-review and re-review convergence-gate semantics are retained under the new vocabulary.
- `post-recursion-review`: per-recursion-level coach review moves inside the per-task orchestrator (subflow); `flow`
  performs no extra coach pass at exit — subflow's APPROVE is sufficient, single coach pass per player call.

## Impact

- `.claude/agents/subflow.md` — **new** file (auto-registered by Claude Code).
- `.claude/agents/flow.md`, `player.md`, `coach.md` — body rewrites (global-role flow, APPROVE/REJECT, handoff
  writing role for player); `flow.md` `tools:` allowlist gains `subflow`.
- `.opencode/agents/flow.md` + `subflow.md` — body edits (uniform routing, drop `task_id` resume, N=N +
  APPROVE/REJECT); bodies remain byte-identical to each other.
- `.claude/AGENTS.md` — divergence-list update (remove "No subflow.md"; add subflow-both-sides, handoff protocol,
  N=N).
- `.opencode/AGENTS.md` — wording updates where the old behavior is described: "Work Guidance — Depth mechanisms"
  (simple→player fast path), "Cycle priority — Revision continuity" (drop `task_id` resume; N=N; uniform routing),
  "Coach fresh review" (✅ Accepted / ❌ Rejected → APPROVE/REJECT), "Role persistence & instruction hierarchy"
  (pre-response self-check "carries coach's ✅ Accepted verdict" → APPROVE), and "Workflow loop (mediated cycle)"
  (step 4 verdict vocabulary; the cycle is owned by the per-task orchestrator, not flow).
- `scripts/install.sh`, `install.ps1`, `uninstall.sh`, `uninstall.ps1` + `scripts/AGENTS.md` — Claude agent file
  lists gain `subflow.md`.
- `openspec/specs/` — delta specs for the four modified capabilities above plus the new `session-handoff` capability.
- Root `AGENTS.md` — the Child DOX Index `.claude/` line ("flow/player/coach as Claude Code subagents; no subflow,
  flow recurses into itself") becomes false after this change; update it to drop "no subflow, flow recurses into
  itself" and reflect the subflow analog.
- Reference tier (`.opencode/reference/flow-reference.md`, `coach-reference.md` + `.claude/reference/flow-reference.md`,
  `coach-reference.md`) — currently teaches the removed behavior at the exact decision points this change rewrites
  (the ≤2-concerns routing tree and `depth == 2` terminal in `flow-reference.md`; the `task_id`/session-resume
  revision-continuity rule in `flow-reference.md`; the ✅/❌ verdict format in `coach-reference.md` worked examples).
  Scoped as an explicit gated follow-up (task 7.2), not part of the core change — it must not be silently omitted.
