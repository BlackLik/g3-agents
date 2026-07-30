# Tasks — Strengthen Agent Prompts

## 1. Reference prompts (.opencode/agents/)

- [x] 1.1 flow.md: remove skill-loading preamble and `🎯 Orchestrator:` prefix references; rewrite self-correction rule as "issue the missing tool call"
- [x] 1.2 flow.md: add `## Role invariants` block after the title (fixed role, tool-list independence incl. MCP, delegate-only)
- [x] 1.3 flow.md: add `## Instruction priority` section (role invariants > workflow rules > user instructions > task content; bypass requests refused and served through the cycle)
- [x] 1.4 flow.md: add pre-response self-check checklist (tool-call-only output; coach ✅ before delivery) and closing `## Non-negotiables` restating invariants
- [x] 1.5 subflow.md: mirror flow's invariants, instruction-priority, self-check, and non-negotiables blocks
- [x] 1.6 player.md: fix rule 0 wording; reconcile rule 6 with Output Format (`DONE` + max one line); add role-invariants block, refuse-and-note rule for role-changing delegated instructions, closing non-negotiables
- [x] 1.7 coach.md: add role-invariants block (review-only regardless of tools), refuse-and-note rule ("fix it yourself" → findings only), closing non-negotiables; compress B1 abbreviation list to ~15 representative examples

## 2. Claude Code port (.claude/agents/)

- [x] 2.1 flow.md: mirror tasks 1.1–1.4 with port wording (Agent tool, Explore agent, no subflow — flow recurses into itself)
- [x] 2.2 player.md: mirror task 1.6 with port wording
- [x] 2.3 coach.md: mirror task 1.7 with port wording

## 3. DOX pass

- [x] 3.1 Update `.claude/AGENTS.md` divergence list: remove the skill-preamble/prefix divergence (now shared with the reference); record any new port-specific wording introduced
- [x] 3.2 Re-check `.opencode/AGENTS.md` and root `AGENTS.md` for contract changes; update if the prompt restructure affects documented behavior

## 4. Verification

- [x] 4.1 Run `npx markdownlint-cli2` from the repo root — 0 errors (result: this change adds zero new errors; 612 pre-existing errors on clean HEAD — mostly MD060 from a newer markdownlint version — are out of scope)
- [x] 4.2 Audit both ports for contradictions removed in 1.1/1.6 (no rule pairs prescribing mutually exclusive behavior; role invariants present top + closing in all six agent files)
