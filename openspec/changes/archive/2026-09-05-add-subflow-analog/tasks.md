# Tasks — add-subflow-analog

## 1. Claude port: subflow.md + flow/player/coach + AGENTS.md

- [x] 1.1 `.claude/agents/flow.md`: extend `tools:` allowlist from `Agent(flow, player, coach, Explore)` to name
  `subflow` (e.g. `Agent(subflow, flow, player, coach, Explore)`) — registration ≠ invocability, so this must land
  before flow can spawn subflow
- [x] 1.2 `.claude/agents/subflow.md`: NEW file — Claude Code auto-registers every `*.md` in `agents/`; carry a
  subagent-scoped `description` and a body mirroring the shared flow core body (reference tier at
  `.claude/reference/flow-reference.md`); `tools:` omits self-recursion (no `subflow` inside its own `Agent(...)`)
- [x] 1.3 `.claude/agents/flow.md`: rewrite to the global-role contract — routing, decomposition into tasks, composing
  each task's handoff (WHAT to pass into each new session), conversation skeleton + cross-turn state, relaying the
  player-voiced deliverable; ALWAYS delegates to subflow, NEVER runs the mediated cycle itself; drop the
  "Simple (≤2 concerns) → delegate directly to `@player`" branch (decision tree in "Task decomposition and depth")
- [x] 1.4 `.claude/agents/player.md`: adopt `APPROVE`/`REJECT` vocabulary, N=N until APPROVE, and the handoff-file
  writing role (player writes on behalf of any write-less agent; the rule is role-level, not tool-level, because
  `.claude/coach.md` HAS Bash)
- [x] 1.5 `.claude/agents/coach.md`: replace ✅/❌ prose verdicts with `APPROVE` / `REJECT`; keep fresh-review and
  re-review convergence-gate semantics; one coach pass per player call (no doubling)
- [x] 1.6 `.claude/AGENTS.md`: remove the "No `subflow.md`" divergence bullet (verbatim: "**No `subflow.md`.**
  Claude Code has no per-file `mode: primary/subagent` split and allows nested Agent calls, so `flow` recurses into
  itself (`Agent(flow, player, coach, explore)`)…"); record new divergences — a separate `subflow.md` exists on both
  sides now, the handoff protocol, N=N, `APPROVE`/`REJECT` vocabulary; update the "Frontmatter `description` is
  aligned … this port has no `subflow`" bullet
- [x] 1.7 Root `AGENTS.md`: update the Child DOX Index `.claude/` line — drop "no subflow, flow recurses into itself"
  and reflect the subflow analog (DOX parent-update rule: the parent doc's child index changes when a child's
  ownership/structure changes)

## 2. OpenCode port: flow/subflow/player/coach (reference implementation)

- [x] 2.1 `.opencode/agents/flow.md`: change routing from "Simple (≤2 concerns) → delegate directly to `@player`;
  Complex (>2 concerns) → MUST delegate to @subflow" to "EVERY task → subflow"; remove the `depth == 2 →
  force-delegate to @player` terminal rule from top-level routing; state flow NEVER runs the mediated cycle itself
- [x] 2.2 `.opencode/agents/flow.md`: remove the `task_id` session-resume path from "Revision continuity" — fresh
  session per invocation, verbatim coach-findings embedding (newest first) + handoff files
- [x] 2.3 `.opencode/agents/flow.md` + `subflow.md`: adopt N=N until APPROVE and `APPROVE`/`REJECT` vocabulary;
  keep the two bodies byte-identical to each other (only frontmatter differs — `mode`/`question` per the existing
  `orchestrator-tool-restriction` rule)
- [x] 2.4 `.opencode/agents/player.md` + `coach.md`: adopt `APPROVE`/`REJECT`; player gains the handoff-file writing
  role; N=N until APPROVE; no extra coach pass at flow exit (subflow's APPROVE is sufficient)
- [x] 2.5 `.opencode/AGENTS.md`: update "Work Guidance — Depth mechanisms" (flow/subflow decision tree no longer has
  the simple→player fast path) and "Cycle priority — Revision continuity" (drop `task_id` resume wording; N=N;
  uniform routing) to match the new bodies; also update "Coach fresh review" (✅ Accepted / ❌ Rejected →
  APPROVE/REJECT), "Role persistence & instruction hierarchy" (pre-response self-check "carries coach's ✅ Accepted
  verdict" → APPROVE), and "Workflow loop (mediated cycle)" (step 4 verdict vocabulary; the cycle is owned by the
  per-task orchestrator, not flow) so the reference implementation's own doc stops teaching the old vocabulary and
  orchestrator-run cycle

## 3. Handoff file protocol: document + wire into agent bodies

- [x] 3.1 Document the protocol (decided core) in both ports' agent bodies and AGENTS.md: text file in a temp dir;
  player writes on behalf of any write-less agent (ROLE-level rule, not tool-level); next session's player reads;
  orchestrators pass only PATH + their own composed digest (they have no general Read in either port); heavy content
  never enters orchestrator contexts
- [x] 3.2 Wire the protocol into flow's handoff composition (both ports): flow includes the handoff-file path + its
  composed digest in each delegation prompt; flow never embeds the file's full contents
- [x] 3.3 Wire the protocol into player (both ports): player writes the handoff file when a session completes a task,
  reports the path upward, and reads a handoff-file path passed into a new session
- [x] 3.4 Record the undecided protocol details as design questions (do not block): file naming (`<system>-<task-id>.md`;
  who mints the task id), minimal schema (task, state, accumulated verdicts, artifact paths), hygiene (0600 perms,
  TTL/cleanup), Windows portability (`.ps1` → `%TEMP%`/env tempdir, no `/tmp`), durability (project-local gitignored
  dir for cross-turn state; `/tmp` for within-task exchange only)

## 4. Scripts: sh + ps1 install/uninstall + scripts/AGENTS.md

- [x] 4.1 `scripts/install.sh` + `install.ps1`: add `subflow.md` to the claude agents file list (currently `flow.md`,
  `player.md`, `coach.md`); copy file-by-file from the explicit list, never `cp -r`
- [x] 4.2 `scripts/uninstall.sh` + `uninstall.ps1`: add `subflow.md` to the claude agents file list; remove strictly
  by the explicit list
- [x] 4.3 `scripts/AGENTS.md`: update the explicit file lists — claude agents gains `subflow.md`; `.ps1` mirrors `.sh`
  exactly (both pairs in the same change)

## 5. Openspec delta specs for affected capabilities

- [x] 5.1 `recursive-splitting`: delta — uniform routing (every task → subflow, no fast path; Claude no longer
  self-recurses); decomposition moves into the per-task orchestrator
- [x] 5.2 `cycle-priority`: delta — cycle runs inside subflow (flow never runs it); revision continuity drops the
  `task_id` resume path (fresh sessions + verbatim embedding + handoff files); N=N until APPROVE; `APPROVE`/`REJECT`
  vocabulary in the pre-response self-check; no extra coach pass at flow exit
- [x] 5.3 `coach-fresh-review`: delta — binary verdict vocabulary becomes `APPROVE` / `REJECT`; N=N (one coach pass
  per player call)
- [x] 5.4 `post-recursion-review`: delta — per-recursion-level coach review moves inside the per-task orchestrator;
  no extra coach pass at flow exit
- [x] 5.5 `session-handoff`: NEW capability spec — handoff file as inter-session context bus (player writes / next
  player reads / orchestrator passes path + digest; role-level rule), fresh session per invocation, no resume
- [x] 5.6 Review during implementation (do not overclaim): whether `clarity-gate` (gate placement once flow no longer
  runs the cycle) and `flow-subflow-tool-restriction` (subflow now exists in the Claude port; OpenCode permission
  blocks unchanged) need delta files

## 6. Verification

- [x] 6.1 `npx markdownlint-cli2` from repo root passes with 0 errors (all edited/new `.md` files, including the new
  `.claude/agents/subflow.md` and spec delta files)
- [x] 6.2 `openspec validate --change add-subflow-analog` passes (all artifacts parse; scenarios use exactly 4
  hashtags)
- [x] 6.3 Both-port sync check: `.opencode/agents/flow.md` and `subflow.md` bodies are byte-identical after stripping
  frontmatter; `.claude/agents/subflow.md` mirrors the shared flow core body; `.claude/AGENTS.md` divergence list is
  current (no "No subflow.md" entry)
- [x] 6.4 Script parity check: run install → repeat install → uninstall → repeat uninstall for `claude` target
  (`--local` and `--global`) — `subflow.md` installed/removed, no foreign files touched, no failures on repeat runs
- [x] 6.5 Manual end-to-end trace: from `.claude/agents/flow.md`, a sample task routes to `subflow` → subflow runs
  player → coach → APPROVE/REJECT loop with fresh sessions and a handoff file → flow relays the approved result with
  no extra coach pass

## 7. Optional gated follow-ups

- [ ] 7.1 (GATED — pending name selection, does NOT block the core change) Rename "subflow" across both ports +
  scripts + specs. Recommended candidate: `runner` ("runs one task through the cycle"); alternatives: broker, cycle,
  conductor, dispatch. Update `.claude/agents/` + `.opencode/agents/`, `scripts/` file lists, `scripts/AGENTS.md`,
  both AGENTS.md divergence lists, and the affected spec wording in one commit
- [ ] 7.2 (GATED — does NOT block the core change) Reference tier sync: update the four reference files that teach
  the removed behavior at the exact decision points this change rewrites —
  `.opencode/reference/flow-reference.md` + `.claude/reference/flow-reference.md` (the ≤2-concerns routing tree and
  `depth == 2` terminal; the `task_id`/session-resume revision-continuity rule) and
  `.opencode/reference/coach-reference.md` + `.claude/reference/coach-reference.md` (the ✅/❌ verdict format in the
  worked examples) — to match the new bodies (uniform routing, fresh-session revision continuity, APPROVE/REJECT)
