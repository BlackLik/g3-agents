# Design — add-subflow-analog

## Context

The system ships two ports of the same role set:

- **OpenCode** (`.opencode/agents/*.md`) — the reference implementation. `flow.md` (primary, depth 0) and
  `subflow.md` (subagent) share **byte-identical bodies**; the `.opencode/AGENTS.md` rationale: "`subflow.md` body
  content is byte-identical to `flow.md`. OpenCode requires separate files because the `mode` field (primary vs
  subagent) is a per-file front-matter attribute that cannot be shared across files." Orchestrator tool surface is
  deny-by-default (`'*': deny`) with `task` restricted to `player`/`coach`/`explore`/`subflow`, `skill`, a
  reference-scoped `read`, and `question` on flow only.
- **Claude Code** (`.claude/agents/*.md`) — the mirrored port. **No `subflow.md`** — its divergence list says: "No
  `subflow.md`. Claude Code has no per-file `mode: primary/subagent` split and allows nested Agent calls, so `flow`
  recurses into itself (`Agent(flow, player, coach, explore)`). Depth rules (terminal at `depth: 2`) are unchanged
  and tracked via `(depth: N)` in prompts. Consequently this port has no byte-identity constraint; the single flow
  core body shares the reference tier at `.claude/reference/flow-reference.md`." Claude Code auto-registers every
  `*.md` in `agents/` as an agent; `flow.md`'s `tools:` line is `Agent(flow, player, coach, Explore), WebFetch,
  WebSearch, Skill, mcp__*`.

Current session model (both ports): `flow` runs the mediated cycle itself — decompose → delegate to `@player` →
review with `@coach` → repeat, bounded to 3 revision rounds per task per recursion level, then a mediated
escalation. Routing has a fast path: "Simple (≤2 concerns) → delegate directly to `@player`; Complex (>2 concerns)
→ **MUST delegate to @subflow**". Revision continuity differs per port: the `.opencode` `task` tool supports session
resume (`task_id`, verified v1.18.15) and its primary path resumes the same `@player` session; Claude Code's Agent
tool has no resume parameter (verified v2.1.232 `AgentInput`), so that port embeds prior coach findings verbatim in
each revision prompt. This asymmetry is the seed of the change: session state is coupled to the orchestrator, and
the two ports behave differently on the same rule.

## Goals / Non-Goals

**Goals:**

- Give the Claude port a real `subflow` analog (`.claude/agents/subflow.md`) and make flow delegable to it via the
  `Agent(...)` allowlist.
- Introduce the layered session architecture in both ports: thin global `flow` (routing, decomposition, handoff
  composition, conversation skeleton, delivery) + per-task ephemeral orchestrator (currently "subflow") that owns
  the entire mediated cycle internally and dies with the task.
- Uniform routing — no fast path. EVERY task goes through subflow. No "simple → player directly" branch.
- Fresh session on every invocation; abandon session resume everywhere, including removing the `.opencode` `task_id`
  resume path from the protocol. Revision continuity = verbatim coach-findings embedding + handoff files.
- Coach verdict vocabulary `APPROVE` / `REJECT`; inner loop N=N ("N player calls = N coach calls until coach
  APPROVE"); REJECT → new fresh player session with all prior findings embedded; no extra coach pass at flow exit
  (subflow's APPROVE is sufficient — single coach pass per player call).
- Handoff file protocol as the inter-session context bus (player writes / next player reads; orchestrators pass
  path + digest only).
- Update both ports' AGENTS.md (divergence lists), `scripts/` install/uninstall file lists, and the affected openspec
  specs.

**Non-Goals:**

- Implementing the change itself — this is the PROPOSE plan.
- Renaming "subflow" — an OPEN decision (see Open Questions); the rename is an optional gated follow-up, not part of
  the core change.
- Building the question judge («судья вопроса») mechanism — out of scope; if it turns out to be a separate
  capability, it is a follow-up.
- Any change to unrelated tool permissions, the 14 archived changes, or runtime code outside the agent/script/spec
  surface listed in the proposal's Impact section.

## Decisions

### D1 — Layered session architecture (both ports)

**Choice:** Single entry point: every user message lands in `flow` first. `flow` = long-lived, thin, GLOBAL role:
routing, decomposition into tasks, composing each task's handoff (deciding WHAT to pass into each new session),
holding the conversation skeleton + cross-turn state, and relaying the player-voiced deliverable to the user. `flow`
never runs the mediated cycle itself. The per-task ephemeral orchestrator (currently "subflow") — one fresh session
per task — owns the whole mediated cycle internally (decompose → explore → player → coach → revisions until
APPROVE), dies with the task, and returns upward ONLY the APPROVED result + the path to the handoff file.

**Why:** Session state today is coupled to the orchestrator: flow both decomposes and runs every step of the cycle,
so every revision keeps the orchestrator context hot and grows it. Moving the cycle into a per-task session isolates
each task's context, lets the task session die on completion (freeing context), and lets flow stay thin — its only
per-task work is composing WHAT to pass into the next session. This also equalizes the two ports: today the Claude
port has no subflow, so flow recurses into itself; the layered model gives both ports the same shape.

**Alternatives considered:** keep the current single-orchestrator loop (flow runs the cycle) — rejected: couples
session state to the global orchestrator and is exactly the architecture this change replaces. Give flow a reduced
cycle ("fast path for simple tasks") — rejected: the change explicitly forbids a fast path; the system is designed
for medium/large features and uniformity keeps behavior predictable.

### D2 — Uniformity: no fast path, every task → subflow

**Choice:** Replace the routing rule "Simple (≤2 concerns) → delegate directly to `@player`; Complex (>2 concerns) →
**MUST delegate to @subflow**" (in the OpenCode flow/subflow bodies and the Claude flow body) with: **EVERY task →
subflow**. `flow` composes the handoff and delegates to `subflow` for every task; `subflow` internally decomposes
into player/coach/explore calls. The depth-based terminal rule ("`depth == 2` → force-delegate to `@player`") is
removed from the top-level routing; subflow's internal decomposition keeps its own bounded structure.

**Why:** The simple/complex branch is where the "simple → player directly" fast path lives; it is the rule this
change deletes. Uniformity makes the pipeline identical for every request — one path to reason about, no
trivial-task shortcut that bypasses the full pipeline. The system is explicitly designed for medium/large features,
so there is no upside to a fast path.

**Alternatives considered:** keep the fast path but make it route through a cheaper subflow — rejected: that is a
fast path by another name; the decision is uniformity. Keep simple→player directly and only add the Claude subflow —
rejected: that preserves the two-branch model and the fast path this change removes.

### D3 — Fresh session per invocation; drop `task_id` resume everywhere

**Choice:** Fresh session on EVERY invocation in both ports. Session resume is abandoned everywhere — including
removing the `.opencode` `task_id` resume path from the protocol (the current rule: "when the delegation tool
supports resuming a subagent session (a task/session id), resume the same `@player` session for each revision
round; otherwise the revision prompt SHALL embed coach's findings from ALL prior rounds verbatim, newest round
first"). Claude Code has no resume at all (verified v2.1.232), so the unified rule is the verbatim-embedding branch
in both ports. Revision continuity = verbatim coach-findings embedding + handoff files. The higher agent composes
what goes into each new session (the handoff contract).

**Why:** Two behaviors for one rule is a port-divergence liability. The `task_id` resume path is the OpenCode-only
branch; since the Claude port cannot resume, the system standardizes on the branch that works everywhere. Fresh
sessions also bound context growth per invocation — each player call starts clean with only the composed digest and
findings it needs.

**Alternatives considered:** keep `task_id` resume in the OpenCode port — rejected: preserves the asymmetry and the
"same session forever" context growth the layered model is meant to remove. Keep both branches — rejected: the whole
point of the layered model is one uniform session discipline.

### D4 — Handoff file protocol (context bus between sessions)

**Choice:** A text file in a temp dir carries inter-session context; never resume the same session. Details:

- **Writer:** `player` writes the handoff file on behalf of any write-less agent (`flow`/`subflow`/`coach` have no
  general write in either port). The rule is **role-level, not tool-level** — `.claude/coach.md` HAS Bash, so a
  tool-level rule would not hold across ports; the ROLE "player writes, on behalf of others" does.
- **Reader:** the NEXT session's `player` reads it.
- **Orchestrators:** in BOTH ports orchestrators have no general Read (`.opencode` `read` is scoped to
  `*/reference/*.md`; `.claude` flow has no Read tool) → orchestrators physically cannot read the handoff files; the
  bus is strictly worker-level. Orchestrators pass only the PATH + their own composed digest in the prompt. Heavy
  content never enters orchestrator contexts.

**Why:** Inter-session context must survive fresh sessions without resuming them; a file is the only channel both
ports support without a session-id tool. Because orchestrators cannot read, the protocol is self-enforcing: flow
cannot accidentally pull heavy content into its context; it only forwards the path and its digest.

**Open protocol details (documented as design questions, NOT decided):** file naming (`<system>-<task-id>.md`; who
mints the task id — the higher agent at composition time?); minimal schema (task, state, accumulated verdicts,
artifact paths); hygiene (0600 perms, TTL/cleanup vs OS temp purging); Windows portability (scripts ship `.ps1` →
no `/tmp`; use `%TEMP%`/env tempdir); durability (`/tmp` wiped on reboot → for multi-day features cross-turn state
may need a project-local gitignored dir; `/tmp` only for within-task exchange).

**Alternatives considered:** pass all context through prompts only (no file) — rejected: heavy content (diffs,
findings, artifact paths) would bloat orchestrator and next-session contexts; the file keeps orchestrator contexts
thin. Session resume — rejected per D3.

### D5 — Coach verdict vocabulary: APPROVE / REJECT; N=N until APPROVE

**Choice:** Coach verdict vocabulary becomes `APPROVE` / `REJECT`, replacing the ✅/❌ prose ("✅ Accepted" / "❌
Rejected"). The inner loop is N=N: "N player calls = N coach calls until coach APPROVE". REJECT → new fresh player
session with all prior coach findings embedded. No extra coach pass at flow exit — subflow's APPROVE is sufficient;
single coach pass per player call, no doubling.

**Why:** The emoji verdicts are prose in the middle of formatted reviews; `APPROVE`/`REJECT` are unambiguous
machine-checkable tokens. N=N is the discipline that makes the count explicit and prevents doubling (flow exiting
with its own second coach pass would double reviews of the same player call). Subflow's APPROVE is the gate; flow
relays it.

**Alternatives considered:** keep ✅/❌ — rejected: prose verdicts are not token-clean and the vocabulary change is
explicitly requested. Keep an extra flow-level coach pass at exit — rejected: doubles the coach calls per player
call; subflow's internal APPROVE already gates.

### D6 — Claude port: new `subflow.md` + flow allowlist extension

**Choice:** Create `.claude/agents/subflow.md`. Claude Code parses every `*.md` in `agents/` as an agent
(auto-registration), so the file needs a subagent-scoped `description` and a body mirroring the shared flow core
body (single reference tier at `.claude/reference/flow-reference.md`). Prerequisite: extend `.claude/agents/flow.md`'s
`tools:` allowlist from `Agent(flow, player, coach, Explore)` to name `subflow` (e.g. `Agent(subflow, flow, player,
coach, Explore)`) before flow can spawn it — registration ≠ invocability. The `subflow.md` `tools:` line omits
self-recursion (`subflow` inside its own `Agent(...)` list) since it owns one task's cycle and delegates to
player/coach/Explore only.

**Why:** Parity requires the Claude port to have the same orchestrator set as OpenCode. Because Claude Code
auto-registers agents, the file must exist before flow's allowlist can reference it; the allowlist extension is the
invocability gate.

**Alternatives considered:** keep flow self-recursion and only add a naming wrapper — rejected: self-recursion is
the divergence this change removes; the layered model wants a distinct per-task orchestrator role.

### D7 — Player's handoff-writing role; player/coach N=N + APPROVE/REJECT

**Choice:** `.claude/agents/player.md` and `coach.md` (and their `.opencode` mirrors) adopt: verdict vocabulary
`APPROVE`/`REJECT`; N=N until APPROVE; player writes the handoff file (per D4). `coach.md`'s Bash tool exists but
the handoff-write stays a player role — the rule is role-level.

**Why:** Player is the only agent with general write in both ports, so it is the natural handoff writer. N=N and the
vocabulary are port-wide role contracts; both files must carry them for the inner loop to work identically in both
ports.

### D8 — `.claude/AGENTS.md` divergence-list update

**Choice:** Remove the "No `subflow.md`" divergence bullet (verbatim: "**No `subflow.md`.** Claude Code has no
per-file `mode: primary/subagent` split and allows nested Agent calls, so `flow` recurses into itself
(`Agent(flow, player, coach, explore)`). Depth rules (terminal at `depth: 2`) are unchanged and tracked via
`(depth: N)` in prompts. Consequently this port has no byte-identity constraint; the single flow core body shares the
reference tier at `.claude/reference/flow-reference.md`."). Record new divergences: a separate `subflow.md` exists
on both sides now; the handoff protocol; N=N; APPROVE/REJECT vocabulary. Update the "Frontmatter `description` is
aligned with the reference … Only `flow`'s wording diverges: this port has no `subflow`" bullet to reflect the new
state.

**Why:** The divergence list is the port-sync contract; the moment both ports have subflow, the "no subflow" entry is
stale and must be replaced by the new divergences.

### D9 — `.opencode` flow/subflow bodies: uniform routing + drop `task_id` resume + N=N + APPROVE/REJECT

**Choice:** `.opencode/agents/flow.md` and `subflow.md` (bodies remain byte-identical to each other, per the existing
rule in `orchestrator-tool-restriction`): change routing to "EVERY task → subflow"; remove the `task_id` resume path
from "Revision continuity"; adopt N=N and APPROVE/REJECT. `.opencode/AGENTS.md` wording that describes the old
simple→player fast path and the `task_id` resume (Work Guidance — Depth mechanisms; Cycle priority — Revision
continuity) is updated.

**Why:** The OpenCode port is the reference implementation; the body rules drive both ports. Byte-identity is
preserved per the existing constraint. Doc wording must stop describing the removed fast path and resume protocol.

### D10 — Scripts and scripts/AGENTS.md

**Choice:** `scripts/install.sh`, `install.ps1`, `uninstall.sh`, `uninstall.ps1` gain `subflow.md` in the Claude
agent file lists; `/scripts/AGENTS.md`'s explicit file list ("claude agents: `flow.md`, `player.md`, `coach.md`")
gains `subflow.md`. Scripts copy file-by-file from the explicit list (never `cp -r`); `.ps1` mirrors `.sh` exactly.

**Why:** The Claude install surface must ship the new agent file or installs break parity; the script contract is the
explicit file list, so the list and the scripts change together.

### D11 — Spec deltas

**Choice:** Delta specs under `openspec/changes/add-subflow-analog/specs/` for the four modified capabilities
(`recursive-splitting`, `cycle-priority`, `coach-fresh-review`, `post-recursion-review`) and a new `session-handoff`
capability. Specs affected by the removed "simple → player directly" routing: `recursive-splitting` (the routing /
subtask-delegation contract). Specs affected by the removed `task_id` resume / revision-continuity change:
`cycle-priority` (its "Revision continuity across rounds" requirement). Verdict vocabulary: `coach-fresh-review`.
Post-recursion review scope: `post-recursion-review`.

**Candidate deltas (review during implementation, do not overclaim):** `clarity-gate` (where the depth-0 question
round fires once flow no longer runs the cycle — flow composes the handoff, but the gate's mediated fallback lives
in subflow's cycle) and `flow-subflow-tool-restriction` (subflow now exists in the Claude port; the OpenCode
permission blocks themselves are unchanged).

**Why:** Only the specs whose REQUIREMENTS change get delta files; naming them accurately keeps the proposal↔spec
contract honest.

## Risks / Trade-offs

- **Removing the fast path adds latency to trivial turns** → Mitigation: explicit design decision — uniformity
  over speed; the system targets medium/large features.
- **Handoff file protocol has undecided details (naming, schema, TTL, Windows, durability)** → Mitigation: the
  decided core (player writes / next player reads / orchestrator passes path+digest / role-level rule) is
  specified; the open details are recorded as design questions and must not block the core change.
- **`.claude` port gains rules without tool enforcement** → Mitigation: documented as a deliberate divergence, as
  today; prompt-level rules carry role behavior.
- **Renaming "subflow" later touches both ports + scripts + specs** → Mitigation: the rename is an OPEN, gated
  follow-up (task group 7), explicitly not blocking the core change.
- **Flow no longer runs the cycle could drift into "flow does nothing but relay"** → Mitigation: flow's contract is
  explicit (routing, decomposition, handoff composition, skeleton + cross-turn state, delivery); the design lists
  these responsibilities.
- **N=N doubling risk if a second coach pass sneaks back in at flow exit** → Mitigation: the "no extra coach pass at
  flow exit" rule is explicit in the cycle-priority delta and the agent bodies.

## Migration Plan

No runtime/data migration — this changes agent prompt bodies, one new agent file, AGENTS.md divergence lists,
script file lists, and spec documents. Steps (deployment order):

1. Extend `.claude/agents/flow.md` `tools:` allowlist and add `.claude/agents/subflow.md` (registration before
   invocability).
2. Rewrite the orchestrator/executor/reviewer bodies in both ports for the layered model, N=N, APPROVE/REJECT, and
   the handoff-writing role.
3. Update `.claude/AGENTS.md` divergence list and `.opencode/AGENTS.md` wording.
4. Update `scripts/` sh+ps1 install/uninstall file lists and `scripts/AGENTS.md`.
5. Land the openspec delta specs and the new `session-handoff` spec.

Rollback = revert the commit; the new `subflow.md` file and the scripts list changes revert together. Existing
installed copies update on the next `scripts/install.sh` / `install.ps1` run.

## Open Questions

- **Rename of "subflow"** — user asked to consider a rename reflecting its meaning. Candidates evaluated: **runner**
  (Recommended — "runs one task through the cycle"), broker (mediator between player and coach), cycle (one
  mediated-cycle run), conductor (conductor of ephemeral sessions), dispatch (routing — but that is flow's job). A
  rename touches both ports + scripts + specs; it is an OPTIONAL/gated follow-up task, pending name selection, and
  does NOT block the core change.
- **Handoff protocol details** (per D4): file naming (`<system>-<task-id>.md`; who mints the task id — the higher
  agent at composition time?); minimal schema (task, state, accumulated verdicts, artifact paths); hygiene (0600
  perms, TTL/cleanup vs OS temp purging); Windows portability (`.ps1` → no `/tmp`; use `%TEMP%`/env tempdir);
  durability (`/tmp` wiped on reboot → cross-turn state may need a project-local gitignored dir for multi-day
  features; `/tmp` only for within-task exchange).
- **N=N edge cases**: (a) are utility player calls (e.g. writing a state file) judged by coach too, or is N=N scoped
  to deliverable-producing calls? (b) strict equality vs coach-first — may coach judge the task prompt/question
  BEFORE the first player call (making coach ≥ player)? (c) what concretely is the question judge («судья
  вопроса») — routing/validity pre-check, safety/injection screen, or post-hoc fit-to-request check — and who
  performs it (tentatively treated as a separate follow-up capability).
- **Flow utility-write channel** — may flow call player directly for file writes, or does EVERYTHING route through
  subflow to keep "flow never talks to player for tasks" pure?
- **Clarity-gate placement** — with flow no longer running the cycle, whether the depth-0 gate fires in flow (before
  composing the first handoff) or inside subflow's cycle is a candidate delta to resolve during implementation.
