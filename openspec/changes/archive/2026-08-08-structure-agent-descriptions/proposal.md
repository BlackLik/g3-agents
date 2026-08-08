# Proposal: structure-agent-descriptions

## Why

The frontmatter `description` fields of `flow`, `subflow`, `player`, and `coach` are the routing contracts a calling LLM uses to select an agent. They currently follow an ad-hoc paragraph shape. Research on tool/agent descriptions shows selection accuracy improves when descriptions follow an explicit structure: a context-independent **Purpose** sentence, **Guidelines** ("use when…" / behavior cues), **Parameter explanation** (input semantics and format, not just type — the Yahoo Finance MCP case showed missing format hints, e.g. `YYYY-MM-DD`, cause wasteful calls), **Limitations**, and **Side effects**. Our descriptions cover purpose and usage cues but lack explicit input-format semantics, limitations, and side-effect statements.

## What Changes

- Rewrite the `description` frontmatter field of `.opencode/agents/flow.md`, `.opencode/agents/subflow.md`, `.opencode/agents/player.md`, `.opencode/agents/coach.md` to follow the five-part structure: Purpose → Guidelines → Parameters → Limitations → Side effects.
- Mirror the equivalent descriptions in the Claude Code port (`.claude/agents/flow.md`, `.claude/agents/player.md`, `.claude/agents/coach.md`) per the Port Synchronization contract, keeping its documented divergences (no subflow; Agent-tool wording in `flow`).
- Relax the current 40–80 word single-paragraph budget to a labeled multi-segment budget that fits tool-metadata constraints.
- **BREAKING** (spec-level): the length/paragraph requirement in the `agent-descriptions` spec is replaced by a structured-format requirement.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `agent-descriptions`: descriptions SHALL follow the five-part structure (Purpose, Guidelines, Parameter explanation, Limitations, Side effects); the single-paragraph 40–80 word budget is replaced by a labeled-segment format with a revised size budget; self-containment, no-dangling-references, flow/subflow selection criterion, and frontmatter-only scope remain in force.

## Impact

- **Code**: frontmatter `description` lines only, in `.opencode/agents/*.md` (4 files) and `.claude/agents/*.md` (3 files). Role bodies, `mode`, `temperature`, `permission`/`tools` remain byte-identical.
- **Docs**: `.opencode/AGENTS.md` (frontmatter description convention note) and `.claude/AGENTS.md` (divergence list) updated if the format change alters their statements.
- **Specs**: `openspec/specs/agent-descriptions/spec.md` receives a delta.
- **Consumers**: any LLM routing on these descriptions sees a richer, structured contract; no runtime or API breakage.
