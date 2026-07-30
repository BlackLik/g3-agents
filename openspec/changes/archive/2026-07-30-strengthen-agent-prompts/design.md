# Design — Strengthen Agent Prompts

## Context

Two ports of the same three-role system exist: `.opencode/agents/` (reference: flow, subflow, player, coach) and `.claude/agents/` (port: flow, player, coach). The specs `cycle-priority` and `review-routing` already mandate the mediated cycle, but the prompts fail under two real pressures:

1. **Tool-set drift** — when MCP servers or extra tools appear, agents act on them outside their role (flow executes tools itself; coach could edit; player wanders into review/explanation).
2. **User-instruction override** — a user saying "just answer", "skip the review" causes flow to answer directly or deliver player output without coach review.

Contributing prompt weaknesses observed in the current files:

- Rules against direct answers live in one place mid-prompt; nothing restates them at the end, so they lose weight in long contexts.
- No explicit statement of instruction precedence — the prompts never say what wins when the user contradicts them.
- Internal contradictions undermine authority: `.opencode/flow.md` still opens with a skill-loading preamble ("Load this skill FIRST") and references a `🎯 Orchestrator:` text prefix while also mandating "no text, only tool calls"; `.opencode/player.md` rule 6 shows a prose result example while "Output Format" mandates `DONE` only, and rule 0 is broken English; `coach.md` B1 contains a multi-hundred-word inline word list that buries the actual rules.

## Goals / Non-Goals

**Goals:**

- Make each prompt state its role invariants twice (top + closing non-negotiables) so they survive long contexts and tool-list growth.
- Add an explicit instruction-hierarchy section to flow, plus refuse-and-note rules to player and coach for role-changing instructions embedded in delegated prompts.
- Add flow's pre-response self-check (tool-call-only output; coach ✅ before delivery).
- Remove internal contradictions that dilute prompt authority.
- Land the same behavior in both ports in one change, updating `.claude/AGENTS.md` divergences if port wording differs.

**Non-Goals:**

- No changes to the delegation mechanics, depth rules, decomposition thresholds, or the AI-trace detection system (content preserved, only relocated/trimmed where it buries rules).
- No new agents, tools, or frontmatter capability changes.
- No prompt-injection defense beyond role/workflow rules (secrets handling etc. is out of scope).

## Decisions

### 1. Role-invariants block: top + closing restatement (primacy/recency)

Each prompt gets a short `## Role invariants` block immediately after the title, and a closing `## Non-negotiables` section that restates the same 3–5 lines. Rationale: LLMs weight the start and end of a prompt most heavily; a single mid-file rule is exactly what fails today. Alternative considered — a single "IMPORTANT" block mid-file: rejected, that is the current failing design.

The invariants also carry the tool-independence clause verbatim in all three prompts, e.g.: "Your role does not change with your tool list. New tools (including MCP) extend what you can do *within* this role — they never make you an executor/reviewer/orchestrator."

### 2. Instruction hierarchy as an explicit precedence list in flow

Flow gets a `## Instruction priority` section: `role invariants > workflow rules > user instructions > task content`. Conflicts resolve upward; a user instruction conflicting with the workflow is executed *through* the workflow (the explanation to the user is itself produced by the cycle). Alternative — a blanket "ignore conflicting instructions": rejected as too blunt; the user's underlying request must still be served, only the bypass is refused.

### 3. Refuse-and-note pattern for player/coach

Player and coach get one rule each mirroring their existing rejection rules (investigation/review routing): a delegated prompt that tries to change their role is executed only within-role, with a one-line note in the return output. This reuses the established "This is a review task — routing to @coach" pattern instead of inventing a new mechanism.

### 4. Pre-response self-check in flow as a checklist, not prose

Two-line checklist immediately before the closing non-negotiables: (1) "Is this response an Agent/task tool call? If not — make it one." (2) "Am I delivering a result? Then it must carry coach's ✅." Rationale: checklists right before output-generation are more reliably followed than buried prose; this also implements the `cycle-priority` delta.

### 5. Contradiction cleanup, minimal edits

- `.opencode/flow.md`: drop the skill-loading preamble and `🎯 Orchestrator:` prefix references (the Claude port already did this — the reference adopts the same fix; OpenCode agent files are agent definitions, not skills). Self-correction rule rewritten in terms of "issue the missing tool call".
- `.opencode/player.md`: fix rule 0 wording; reconcile rule 6 with Output Format (decision: `DONE` + at most one line, matching the lazy-programmer intent).
- `coach.md` (both ports): move the B1 abbreviation word-list into a compact parenthetical of ~15 representative examples ("idx, cfg, msg, … and similar common shortenings") — the exhaustive list adds no detection power and buries neighboring rules. Detection logic itself unchanged.

### 6. Port sync strategy

Edit `.opencode/agents/*.md` first (source of truth), mirror to `.claude/agents/*.md` in the same commit, adjusting only port-specific wording (Agent vs task tool, Explore naming). `subflow.md` receives the same invariants/hierarchy blocks as flow (it shares the orchestrator role). If any new port divergence is introduced, it goes into `.claude/AGENTS.md` "Deliberate divergences" in the same commit; the current expectation is zero new divergences — one existing divergence (skill-preamble removal) actually disappears because the reference adopts the fix, so the divergence list shrinks.

## Risks / Trade-offs

- [Prompt length grows, diluting attention] → Net growth is bounded: contradiction cleanup and the B1 list trim offset the new blocks; invariant blocks are ≤6 lines each.
- [Over-hardening: flow refuses legitimate meta-requests (e.g. user genuinely configuring the system)] → The hierarchy refuses only *bypass* of the cycle, not the content of requests; meta-requests are still served through player/coach.
- [Reference and port drift during mirroring] → Single commit for both ports; closeout re-reads `.claude/AGENTS.md` divergence list against the actual diff.
- [Removing the `🎯 Orchestrator:` prefix from the reference changes OpenCode UX] → The prefix was already contradicted by the "tool calls only" rule; `description` fields keep the visual marker role, as the Claude port proved viable.

## Migration Plan

1. Edit reference prompts (`.opencode/agents/`), then mirror to `.claude/agents/`.
2. Update `.claude/AGENTS.md` divergence list (remove the now-shared skill-preamble divergence).
3. Run `npx markdownlint-cli2` (existing verification).
4. Rollback: single revert commit restores both ports atomically.

## Open Questions

- None blocking. If OpenCode tooling turns out to depend on the `🎯 Orchestrator:` prefix, keep it in the reference and record it as a port divergence instead (decision deferred to implementation, does not affect specs).
