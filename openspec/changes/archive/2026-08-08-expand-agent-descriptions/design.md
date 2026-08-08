# Design: expand-agent-descriptions

## Context

The four agents in `.opencode/agents/` (`flow`, `subflow`, `player`, `coach`) are the reference implementation of this multi-agent system. When the system is consumed through MCP or a subagent/task surface, the frontmatter `description` is the only text a calling LLM sees about each agent — it drives the model's routing decision of *which* agent to call and *why*.

Current descriptions are slogans, not routing contracts:

- `flow` / `subflow`: "Orchestrator flow/subflow — agent delegation pattern with @player executor and @coach reviewer." — mentions peer agents by `@`-syntax a foreign model cannot resolve, and never states what the orchestrator returns or when to pick it.
- `player`: "Lazy programmer — minimal code, no explanations…" — persona, not purpose.
- `coach`: "Maximally picky code reviewer…" — closest to usable, but still misses input expectations (a git diff) and return shape (verdict + findings).

Constraint: only the `description` frontmatter line changes; bodies, modes, temperatures, permissions are untouched. Port rule: `.opencode/` is the source of truth; `.claude/` lists frontmatter `description` as a deliberate port-owned divergence, so the Claude port may adapt wording (its descriptions live in a different frontmatter format consumed by Claude Code's Agent tool).

## Goals / Non-Goals

**Goals:**

- Every description answers, for a foreign LLM with zero system context: what the role does, when to delegate to it, what input it expects, what it returns.
- Descriptions stay short enough to serve as tool metadata (target ~40–80 words each) while being self-contained.
- Keep `@`-mentions and port-specific jargon out of descriptions, or define them inline, so the text survives MCP transport.

**Non-Goals:**

- No changes to agent bodies, orchestration logic, temperatures, or permissions.
- No renaming of agents.
- No new agents, no removal of the `subflow`/`flow` split.
- No forced sync of `.claude` descriptions — alignment is best-effort and recorded in `.claude/AGENTS.md`.

## Decisions

1. **Structured one-paragraph format per description**: `<role summary>. Use when <trigger conditions>. Expects <input>. Returns <output>.` — Rationale: mirrors how tool descriptions are written for function calling, which is exactly the consumption mode (MCP). Alternative considered: multi-sentence marketing-style prose — rejected, wastes the small attention budget a routing model gives tool metadata.

2. **Describe peers by capability, not by name**: e.g. flow "delegates implementation to an executor subagent and review to a reviewer subagent" instead of "with @player executor and @coach reviewer". — Rationale: `@player`/`@coach` are unresolvable for external models; capability wording conveys the pattern. Alternative: keep `@`-names for precision — rejected, broken references are worse than slightly generic ones.

3. **Preserve persona flavor in one clause**: keep the distinctive trait ("lazy programmer", "zero-tolerance reviewer") as a qualifier inside the contract sentence, not as the whole description. — Rationale: persona influences how the caller phrases prompts; the slogans are part of this project's identity, but they must not crowd out routing information.

4. **Keep flow vs subflow distinction explicit**: both descriptions state the same orchestration contract; `subflow` additionally states it is the subagent-invocable variant used when a primary orchestrator already exists. — Rationale: the only difference between the two files is frontmatter (per `orchestrator-tool-restriction` spec), so the description must carry the selection criterion for flow-vs-subflow.

## Risks / Trade-offs

- [Longer descriptions may push MCP/tool-metadata size up] → Target 40–80 words per description; measured, still far below typical tool-description limits.
- [Generic peer wording loses precision for in-repo callers] → Bodies still reference `@player`/`@coach` explicitly; only the externally-visible description is generalized.
- [`.claude` port wording drift] → Any residual divergence is explicitly recorded in `.claude/AGENTS.md` "Deliberate divergences" per the port sync rule.

## Migration Plan

Edit four frontmatter lines in `.opencode/agents/`, optionally mirror in `.claude/agents/`, update `.claude/AGENTS.md` divergence note if wording is aligned, run `npx markdownlint-cli2` (must pass with 0 errors). Rollback: revert the single commit.
