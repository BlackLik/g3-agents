# Design: harden-player-coach-prompts

## Context

The mediated system (`@flow`/`@subflow` → `@player` → `@coach`) runs on models that measurably degrade on
instruction-following when (a) critical rules sit far from the generation point, (b) many normative rules compete in one
prompt, and (c) free-form reasoning precedes constrained output. Current state: `coach.md` (518 lines) and `flow.md`
(519 lines, ~30 sections) both carry 20+ normative rules with invariants placed mid-document; `player.md` is 347 lines;
priority is declared in prose ("Level 1 > Level 2 > ...") without per-rule markers. The scope covers all four agent
prompts — the orchestrator is attacked at least as often as the specialists (users ask flow to "just answer directly"
or "skip review"), and flow.md is as oversized as coach.md.
Constraints: both ports (`.opencode/`, `.claude/`) must stay in sync per the root Port Synchronization rule;
`subflow.md` must stay byte-identical to `flow.md`; all content in English; `npx markdownlint-cli2` must pass.

## Goals / Non-Goals

**Goals:**

- Raise role-adherence of flow, subflow, player, and coach under adversarial prompting; the user self-checks the result
  after implementation.
- Restructure all four prompts around the evidence-backed levers: recency placement, rule-count reduction, explicit
  priority markers, plus structure-first output.

**Non-Goals:**

- No changes to the delegation architecture, mediated cycle, tool permissions, or agent roster.
- No model fine-tuning, logit processors, or serving-level interventions — prompt-level and process-level only.
- No adversarial benchmark suite, violation detector, or automated measurement harness — verification is the user's
  manual self-check, not an automated gate.
- No attempt to reach 0% violations via privilege-markup schemes alone (published results show even marked hierarchies
  degrade); the levers are evidence-backed improvements, not guarantees.

## Decisions

### D1: Terminal placement of role invariants

Move the closing non-negotiables block to be literally the last content in all four prompts (`flow.md`, `subflow.md`,
`player.md`, `coach.md`, both ports), self-sufficient per role (flow/subflow: delegate-only + task-call-only responses;
player: implement-only + return-upward; coach: review-only + binary verdict + never edit). Rationale: positional-bias
findings (SIFo, IFScale) show monotonic follow-rate decay with distance from the generation point; the terminal block is
the cheapest possible intervention. Alternative: repeat invariants after every major section — rejected, it inflates
rule count (works against D2).

### D2: Core/reference split for oversized prompts (coach AND flow)

Split `coach.md` and `flow.md` — both 500+ lines — each into a core tier (always in the system prompt, capped at ~10
discrete rules, plus explicit triggers saying when to consult reference) and a reference tier in a separate file read on
demand. Coach's reference: AI-trace detection categories, vulnerability catalog, anti-pattern catalog, worked examples.
Flow's reference: worked examples, failure-recovery examples, and the embedded player/coach role definitions (which
exist to help flow compose delegation prompts — on-demand reading preserves that purpose). `subflow.md` inherits flow's
core body byte-identically; the reference file is shared. Reference tiers live at `<port>/reference/<agent>-reference.md`
(outside `agents/` — Claude Code parses every `*.md` there as an agent definition). Install/uninstall scripts (both
`.sh`/`.ps1` pairs) copy and remove the reference dir beside `agents/` (global: `~/.config/opencode/reference/`,
`~/.claude/reference/`); core load triggers name the repo-relative path with the installed global path as fallback, and
`opencode.jsonc` registers an `agent-reference` alias so OpenCode advertises the resolved path into agent context.
Rationale: Instruction Stacking Collapse measured follow-rate
falling from ~96% (1 rule) to 20–60% (20 rules), driven by pairwise rule conflicts — and both oversized prompts are in
that zone. Alternatives: (a) keep everything and accept degradation — rejected; (b) split only coach — rejected, flow.md
is the same size and the orchestrator is the most-attacked role; (c) more than two tiers — rejected, two tiers is the
simplest split that removes the bulk of stacking. Risk that an agent skips loading its reference is mitigated by
explicit load triggers in the core tier and the user's self-check of reference-dependent behavior.

### D3: Inline `[PRIORITY:n]` markers in every prompt

Attach a `[PRIORITY:1]`..`[PRIORITY:4]` marker directly before each normative rule in all four prompts, both ports (1 =
role invariants, 2 = workflow rules, 3 = user instructions, 4 = task content), replacing prose-only hierarchy
declarations; markers are authoritative on conflict. Rationale: Control Illusion showed explicit marking measurably
improves priority adherence over unmarked text. Alternative: ordinal/scalar privilege interfaces (ManyIH-style) —
rejected, even top models score under 50% there; simple numeric tags capture the measured gain without a bespoke format.

### D4: Structure-first responses instead of CoT control

We cannot reliably disable a reasoning model's internal thinking from a prompt file, so the rule targets observable
output, per role: flow/subflow responses MUST be an actual `task` tool call with no plain-text preamble; coach reviews
and player returns MUST open with the mandated structure (`## Summary` first content), with any reasoning inside the
structure's sections. Rationale: CoT was shown to degrade simple structural-constraint adherence (13 of 14 models on
IFEval, small models worst); constraining the output head is the prompt-level lever available to us. Alternative:
API-level reasoning toggles per agent — out of scope (serving-level), noted as a future lever if ports gain that
control.

## Risks / Trade-offs

- [An agent skips loading its reference tier, weakening checklist-dependent behavior (coach detection quality, flow
  delegation-prompt composition)] → Core tier carries explicit load triggers; the `agent-reference` alias advertises
  the tier's resolved path and usage description into agent context; the user's self-check after
  implementation covers reference-dependent behavior (checklist-driven reviews, delegation prompts needing embedded
  role definitions).
- [Moving flow's embedded player/coach role definitions to reference breaks the spawn-context convenience] → The
  definitions exist to help flow compose delegation prompts; flow reads the reference tier when composing. If
  delegation quality regresses on self-check, keep a compressed version of the role definitions in flow's core tier
  within the rule budget.
- [Markers are ignored by small models anyway (Control Illusion showed partial rollback to internal priors)] → Accepted
  — markers are an improvement, not a guarantee.
- [Core/reference split diverges between ports, or flow/subflow byte-identity breaks] → Existing same-commit Port
  Synchronization rule applies; every flow edit is mechanically mirrored to subflow in the same commit; divergence
  list updated if any port differs.
- [Rule-count cap forces deletion of genuinely useful guidance] → Move, don't delete: guidance lives in the reference
  tier; cap applies only to simultaneously active core rules.
- [Without an automated gate, a lever could regress adherence unnoticed] → Accepted — the user self-checks after
  implementation; every lever is a separate commit over prompt text only, so a regression is reverted by reverting one
  commit.

## Migration Plan

1. Apply prompt edits lever by lever, each in both ports in the same commit: D1 (terminal placement) → D3 (priority
   markers) → D4 (structure-first) → D2 (core/reference split for coach and flow, largest diff last). Every `flow.md`
   edit is mirrored to `subflow.md` byte-identically in the same commit.
2. Update distribution and DOX: install/uninstall scripts copy and remove the reference tier beside `agents/` in both
   script pairs; `opencode.jsonc` registers the `agent-reference` alias; `.opencode/AGENTS.md` prompt-structure rules,
   `scripts/AGENTS.md` file lists and path mapping, `.claude/AGENTS.md` divergence list; run
   `npx markdownlint-cli2`.
3. Hand off to the user for manual self-check of role adherence.
4. Rollback: every lever is a separate commit over prompt text only — revert the lever's commit to restore the prior
   prompt.

## Open Questions

- Whether the reference tiers live as one file per agent or per-category files — default to one file per agent unless
  size forces a split.
