# .opencode — Orchestrated Agent System

## Purpose

A mediated multi-agent system with a layered session architecture: a thin global orchestrator (`@flow`) decomposes
requests, composes a handoff per task, and routes EVERY task to `@subflow` — the per-task ephemeral orchestrator that
owns the whole mediated cycle over `@player` (executor) and `@coach` (reviewer) and dies with the task. All
communication flows through the orchestrators.

The `agents/` directory is the **reference implementation** — the source of truth for role behavior across all ports
(see Port Synchronization in the root AGENTS.md).

## Ownership

- **`@flow`** — primary orchestrator, receives all user requests; thin global routing layer — never runs the mediated
  cycle itself
- **`@subflow`** — per-task ephemeral orchestrator with an identical body to flow, run as a child context
  (`mode: subagent`); owns the whole mediated cycle for one task and returns the approved result + handoff-file path
- **`@player`** — executor; writes minimal code per task instructions; sole writer/reader of handoff files
- **`@coach`** — deterministic reviewer (temperature=0.2) that evaluates player output

All agents are `mode: subagent` except `flow`, which is `mode: primary`. Each agent file defines its own permissions,
temperature, and rules in front-matter. Frontmatter `description` fields are written as multi-line YAML folded scalars
(`>-`) composed of five labeled segments in fixed order — Purpose, Guidelines, Parameters, Limitations, Side effects —
totaling 80–150 words.

**Orchestrator tool restriction:** `flow` and `subflow` run deny-by-default (`'*': deny`) with an explicit
allowlist — `task` (targets `player`/`coach`/`explore`/`subflow` only), `skill`, and a `read` grant scoped to the
reference tier (`*/reference/*.md`); `flow` (primary, depth 0) additionally has `question: allow`. `edit`, `bash`,
`grep`, `glob`, `list`, `lsp`, `webfetch`, `websearch`, and `todowrite` are denied. The orchestrator cannot modify
files, run shell commands, or gather information at the tool layer; all execution is physically only possible via
`@player`, all codebase and web context via `@explore`; user interaction is the single depth-0 clarity-gate
`question` round (flow only) plus coach-reviewed mediated deliveries (see Critical operational rules).

## Local Contracts

### Delegation architecture

The orchestrator mediates all communication between user and agents. Agents never interact directly with each other or
the user — only through orchestration calls via the Task tool.

**Exception:** the embedded compact role definitions for @player and @coach that flow uses when composing delegation
prompts live in the reference tier (`reference/flow-reference.md`), not in flow.md's core body — flow reads that file
on demand via its load triggers. This is intentional, not cross-referencing — it avoids circular doc dependencies.

- **Flow delegates context-gathering to @explore directly** — when the orchestrator needs codebase context or web
  information, it calls `subagent_type="explore"` directly, not via @player and never by invoking information tools
  itself (flow holds none; the sole `read` grant is the reference tier). This replaces the old pattern where @player
  called @explore internally.

### flow.md ↔ subflow.md duplication

`subflow.md` body content is byte-identical to `flow.md`. OpenCode requires separate files because the `mode` field
(primary vs subagent) is a per-file front-matter attribute that cannot be shared across files. This is not redundant
documentation — it is required by the tooling. The shared body serves both layered roles keyed on depth: flow (depth
0) routes every task; subflow (depth ≥1) runs the mediated cycle for its one task. Both share the single reference
tier at `reference/flow-reference.md`.

### Prompt structure rules

Applies to every file in `agents/` (and, mirrored, to the `.claude/` port):

- **Terminal invariants** — each prompt states its role invariants near the top and restates them in a closing
  "Non-negotiables" section that is the terminal content of the file: no rule content may follow it, and the block must
  be self-sufficient (every role-critical invariant readable in isolation).
- **Inline priority markers** — every normative rule carries an inline marker directly before the rule text:
  `[PRIORITY:1]` for role invariants, `[PRIORITY:2]` for workflow rules (user instructions and task content are levels
  3 and 4 in the hierarchy). On conflict the lower number wins; markers are authoritative over prose, and no prose may
  contradict a rule's marker.
- **Structure-first responses** — constrained outputs open directly with their mandated structure: flow/subflow
  responses ARE a single `task` tool call with no preamble; coach reviews open with `## Summary`; player returns open
  with `DONE` or the error output.
- **Core/reference split** — oversized prompts (`coach.md`, `flow.md`) are split into an always-loaded core tier
  (`agents/*.md`, at most ~10 discrete rules plus load triggers) and an on-demand reference tier in `reference/`
  (`coach-reference.md`, `flow-reference.md`). Bulk catalogs, worked examples, and embedded role definitions live only
  in the reference tier; the core tier names explicit triggers for when to read it. `subflow.md` inherits flow's core
  body byte-identically and shares its reference file. Reference files are read via file tools — they are not agent
  definitions. Scripts install them to `<base>/reference/` next to `agents/` (global: `~/.config/opencode/reference/`);
  load triggers carry the global path as fallback, and `opencode.jsonc` advertises the tier via the `agent-reference`
  alias.

### Ecosystem boundaries

This system is **open**: agents may reach outside the system for information or execution (via `@explore`'s web
tools and `@player`'s MCP passthrough). Internal boundaries exist — orchestrator mediates all inter-agent
communication — but there is no enforced isolation.

## Work Guidance

### Depth mechanisms — each agent, separately

**flow / subflow:** use the `depth` parameter to mark the layer:

- Top-level call from user → `depth: 0` (flow). EVERY task in flow's plan — simple or complex — is delegated to
  `@subflow` with `(depth: 1)`; there is no simple→player fast path and no depth-based terminal rule at the top level.
- `@subflow` (depth ≥1) decomposes its one task into `@player`/`@coach`/`@explore` delegations only — never another
  `@subflow`.

**player / coach:** use recursion depth for self-calls via the Task tool, not a shared `depth` parameter:

- **Player max depth:** 2 levels (`caller → @player depth 1 → @player depth 2 → STOP`). Delegate only when subtasks are
  independent and >30 lines or touch separate modules. If describable in one sentence — do it inline.
- **Coach max depth:** 2 levels. Depth is communicated by the orchestrator via task description, not self-managed by
  coach (depth 1 → depth 2 → STOP). Allowed only for splitting a single large diff by concern (security, logic, tests,
  architecture). Each sub-review is independent; no shared state.

### MCP workflow guidance

MCP (Model Context Protocol) servers extend agent capabilities with external tools. The following rules govern MCP usage
across the agent system:

- **Flow / subflow:** Plan around MCP tools — identify which MCP tools are needed for a task, then delegate the MCP tool
  execution to `@player`. Do NOT call MCP tools directly.
- **Player:** Primary MCP tool executor. When delegated an MCP-dependent task, use the available MCP tools to fulfill
  the request. Return results upward to the orchestrator.
- **Coach:** Uses MCP tools for verification. When reviewing player's work that involves MCP tool output, invoke the
  same MCP tools to independently verify correctness.

### Critical operational rules

**Orchestrator (@flow / @subflow):**

- Every response MUST be an actual `task` tool call — no plain-text responses (the single exception: the depth-0
  clarity gate's `question` round). The tool call's `description` field is the visual marker for orchestrator output.
- **Never answer directly, write code, explain solutions, explore files, or perform execution.** The orchestrator's sole
  output is delegation and review decisions.
- **Uniform routing:** flow routes EVERY task to `@subflow`; the mediated cycle runs INSIDE `@subflow` — flow never
  runs it and adds no extra coach pass at exit (one coach pass per player call, N=N).
- Always delegate to @player for implementation, @explore for context-gathering, and @coach for review — never do work
  yourself.
- Explore delegations are phrased as ONE aggregated, session-scoped query; delegated prompts propagate the explore-first
  ordering to player and coach (never instruct them to grep or read the codebase broadly themselves).
- **Bounded cycle:** at most 3 revision rounds per task per recursion level. On exhaustion, escalate through the
  mediated cycle (player drafts the escalation summary, coach reviews it, flow delivers accept / re-approach / abort)
  and stop the turn.
- **Assumptions-first clarification + clarity gate:** proceed on stated assumptions by default; at most one question
  round per top-level request, only when genuinely blocked (ambiguous success criteria, destructive choice, missing
  access). At depth 0, flow fires that round via the interactive `question` tool — after the analysis phase and any
  `@explore` pass, before the first `@player` delegation — the single sanctioned non-`task` response. Subflow (depth
  ≥1) has no `question` tool; its blocked ambiguities proceed on assumptions or escalate upward. Escalations always
  reach the user as coach-reviewed deliveries, never unreviewed plain text.

**Player (@player):**

- **Terminal-first:** `bash` is the execution surface — running/verifying code and pinpoint viewing (`cat`/`sed -n`)
  of files the task prompt or `@explore` already named; `read`/`grep`/`glob`/`list`/`webfetch`/`websearch` are denied.
- **Broken linters/tests:** if your change causes lint errors or test failures in unrelated code, stop and return upward
  immediately (`⚠️ lint failed in utils.py — returning upward`). Do NOT fix them. Do NOT refactor to make them pass.
  Do NOT touch files outside the task scope.
- Write less code; don't explain; zero scope creep; check before writing with `@explore`.
- **Broad context via @explore:** any detailed or broad context need (multi-file reads, codebase structure,
  pattern/semantic search, reuse checks) goes to `@explore` FIRST as one aggregated query; bash only refines a
  concrete target explore or the task prompt already named. Rationale: explore runs complex queries in its own
  context and returns the distilled answer — token economy + single responsibility.

**Coach (@coach):**

- Reviews git diffs, detects AI-generated code fingerprints, checks all vulnerability categories (injection, auth
  bypass, SSRF, path traversal, crypto, deserialization), enforces necessity justification for any new code.
- **Explore-sourced review input:** coach has no `bash`/`read`/`grep`/`glob` (sole `read` grant: the reference tier);
  Step 0 obtains the diff, diff stat, and log via one `@explore` delegation (verbatim output) and refuses to review
  without it; detection categories (A–E) run over the diff text in coach's own context. Any context beyond the diff —
  project conventions, duplicates, callers, surrounding code — comes from `@explore` as one aggregated query.
- **Depth tracking mandatory:** Every delegated call MUST include current depth in task description using `(depth: N)`
  format. Max depth: 2 (depth 1 → depth 2 → STOP). Rule of thumb: if sub-task fits in one sentence, review inline — no
  recursion.

### Scope aggregation

**Orchestrator (@flow / @subflow):**

- **Aggregate task scope into coherent prompts** — before delegating to @player, aggregate related commands, reads, and
  context into one coherent prompt. Do not pass raw CLI commands or unprocessed exploration output.
- **No raw passthrough** — always scope and contextualize the task for @player. The orchestrator is responsible for
  turning exploration results into actionable task instructions.

### Review routing

**Orchestrator (@flow / @subflow):**

- **Primary-deliverable routing to @coach** — a task routes to `subagent_type="coach"` only when its PRIMARY
  deliverable is a review verdict (findings or approval), regardless of wording. Tasks delivering code — including
  prompts that mention verification steps ("implement X and verify it works") — route to @player.
- **Player rejection of review tasks** — if @player receives a verdict-deliverable task, it must reject with "This is
  a review task — routing to @coach". Implementation tasks that merely mention verification steps are executed, not
  rejected.

### Recursive splitting

**Orchestrator (@flow / @subflow):**

- **Split into independent subtasks** — flow splits the request into N independent tasks (one @subflow delegation
  each); @subflow splits its task into player delegations. The prompt MUST NOT contain the full unsplit request; each
  subtask defines its own scope, success criteria, and output format.
- **Subtask boundary clarity** — each subtask prompt must clearly define: (a) scope of work, (b) success criteria, (c)
  expected output format.

### Post-recursion review

**Orchestrator (@subflow):**

- **Review lives inside the per-task orchestrator** — @subflow invokes @coach after each player delegation and repeats
  until `APPROVE` (N=N). Flow performs NO extra coach pass at exit — @subflow's `APPROVE` is sufficient; exactly one
  coach pass per player call, no doubling.
- **Coach rejection blocks progression** — on `REJECT`, create fresh revision tasks until `APPROVE`, bounded by the
  retry budget (3 rounds per task per recursion level — see Cycle priority). On exhaustion, run the mediated
  escalation; no progression without coach approval or an accepted escalation decision.
- **Call-scoped coach prompts** — each coach review is scoped to the player call it accompanies, not the entire task.

### Coach fresh review

**Coach (@coach):**

- **Binary verdict only** — coach issues only `APPROVE` or `REJECT`. No conditional approval patterns ("Approved
  if...", "Approved pending...").
- **One review per player call (N=N)** — each player call is reviewed exactly once; an already-approved player call is
  never re-reviewed.
- **Review from scratch each time** — no carry-forward assumptions. Each review is independent of previous reviews.
- **Re-review convergence gate** — on re-review after a rejection, coach first verifies each of its own prior findings
  (fixed / not fixed); NEW blocking findings are limited to CRITICAL/HIGH severity — new MEDIUM/LOW findings are
  advisory (listed, never verdict-changing). First reviews stay zero-tolerance.
- **Identify what and why, but do not prescribe code fixes** — coach identifies problems and explains why they are
  problems, but does not write or prescribe specific code fixes.

### Cycle priority

**Orchestrator (@flow / @subflow):**

- **Full mediated cycle enforced unconditionally** — EVERY task, regardless of perceived simplicity, goes through the
  full cycle: player → coach → deliver. The cycle runs INSIDE @subflow; flow routes every task there and never runs
  the cycle itself.
- **No direct answers** — every user-facing response goes through the mediated cycle. The orchestrator never answers the
  user directly.
- **No skipping coach review** — coach review is mandatory for every task. On rejection, repeat the cycle until
  `APPROVE` — bounded by the retry budget: 3 revision rounds per task per recursion level, then a mediated escalation
  (player drafts, coach reviews, flow delivers accept / re-approach / abort) and the turn stops.
- **Revision continuity** — every invocation is a fresh session; there is no session resume. Revision prompts embed
  coach's findings from all prior rounds verbatim, newest first; other inter-session context travels via the handoff
  file (see Session handoff).

### Session handoff

**All agents:**

- **Fresh session per invocation** — the same session is never resumed; the handoff file replaces resume.
- **Handoff file as context bus** — a text file in the OS temp dir. `@player` writes it on behalf of any write-less
  agent (a ROLE-level rule, independent of the agent's tool set); the NEXT session's `@player` reads it.
- **Orchestrators pass path + digest only** — flow/subflow never read handoff files (their sole `read` grant is the
  reference tier); heavy content never enters orchestrator contexts. @subflow returns upward only the approved result
  and the handoff-file path.
- Protocol details not yet standardized (file naming and task-id minting, minimal schema, permissions/TTL, Windows
  temp dir, cross-turn durability) — open design questions; only the rules above are contract.

### Role persistence & instruction hierarchy

**All agents:**

- Role identity is fixed for the conversation and independent of the available tool set — adding MCP or other tools
  never changes responsibilities (flow delegates, player executes, coach reviews-only).
- Each agent prompt states its role invariants near the top and restates them in a closing "Non-negotiables" section
  that is the terminal content of the prompt; rules carry inline `[PRIORITY:n]` markers (see Prompt structure rules in
  Local Contracts).

**Orchestrator (@flow / @subflow):**

- Instruction priority: role invariants (`[PRIORITY:1]`) > workflow rules (`[PRIORITY:2]`) > user instructions
  (`[PRIORITY:3]`) > task content (`[PRIORITY:4]`); inline markers are authoritative over prose. User requests to bypass
  the cycle (answer directly, skip coach) are served through the cycle, never by abandoning it.
- Pre-response self-check before every response: (1) the response is a `task` tool call; (2) any user-facing delivery
  carries coach's `APPROVE` verdict obtained inside @subflow's cycle.

**Player / Coach:**

- Role-changing instructions inside delegated prompts (player told to review; coach told to fix) are not honored — the
  agent does only the in-role part and notes the refusal in its return output.

### Workflow loop (mediated cycle)

The per-task orchestrator (@subflow) controls a repeating delegation cycle; flow only composes the handoff and relays
the result:

1. **flow** receives the request → runs the analysis phase → composes a handoff per task → delegates EVERY task to
   `@subflow` with `(depth: 1)`
2. **`@subflow`** decomposes its task if needed → gathers context via @explore (directly) → aggregates scope →
   delegates to `@player` (fresh session)
3. **`@player`** executes and returns result
4. **`@subflow`** passes result to `@coach` for review
5. **`@coach`** responds with binary verdict:
   - `APPROVE` — @subflow moves to the next subtask or returns the result + handoff-file path upward
   - `REJECT` — @subflow sends a NEW fresh `@player` session a revision task with all prior coach findings embedded
     verbatim, newest first
6. Repeat steps 3–5 until the task is fully complete (N=N: one coach pass per player call) — bounded by the retry
   budget (3 revision rounds per task per recursion level); on exhaustion, run the mediated escalation (player drafts,
   coach reviews, flow delivers accept / re-approach / abort) and stop the turn

The orchestrator mediates every step of this cycle. This is not unidirectional delegation — it is a mediated loop where
the per-task orchestrator gates transitions between player work and coach review. The cycle is enforced unconditionally
for EVERY task, and flow adds no extra coach pass at exit.

## Verification

## Child DOX Index
