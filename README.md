# g3-agents — Multi-Agent Orchestration for OpenCode and Claude Code

A set of agent configs (agents) for OpenCode with mediation, layered task decomposition, and zero-tolerance review. No
dependency installation required. A Claude Code port of the same system ships in `.claude/agents/`.

## 📋 Purpose

The system implements mediated multi-agent orchestration: four roles interact through a strict contract via an
orchestrator (`@flow`), which decides on task decomposition, delegation, and reviewer verdicts. Agents **never
communicate directly** — all inter-agent communication goes through `@flow`.

## 🚀 Getting Started

This project requires no dependency installation — once the `.opencode/agents/` directory is in place, OpenCode
automatically discovers agents via YAML front-matter in compatible runtimes (e.g. Claude Code, OpenCode Skills).

Send tasks to `@flow` — the orchestrator handles decomposition and coordination. A realistic flow with revision cycles:

```text
@flow → decomposition → @subflow (per task) → @player (first version) → @coach → REJECT
→ fresh @player session (findings embedded) → @coach → APPROVE
→ @subflow returns the approved result + handoff-file path → @flow relays → done
```

## 📥 Installation

Use `scripts/install.sh` (macOS/Linux) or `scripts/install.ps1` (Windows). Interface:

```text
scripts/install.sh <opencode|claude|all> [--global|--local]   # default: --global
```

| Tool | global | local |
| --- | --- | --- |
| opencode | `~/.config/opencode/agents/` | `./.opencode/agents/` |
| claude | `~/.claude/agents/` | `./.claude/agents/` |

From a clone of this repository:

```bash
scripts/install.sh opencode   # OpenCode, global
scripts/install.sh claude     # Claude Code, global
```

Without keeping a clone (temporary directory):

```bash
tmpdir=$(mktemp -d) && \
git clone https://github.com/BlackLik/g3-agents.git "$tmpdir" && \
"$tmpdir/scripts/install.sh" all && \
rm -rf "$tmpdir"
```

**Windows (PowerShell):**

```powershell
scripts/install.ps1 opencode
scripts/install.ps1 claude
```

> **Note:** Installation only copies/overwrites files from the repository —
> your existing agents are never deleted.

In this repository the Claude Code port (`.claude/agents/`: flow, subflow,
player, coach) is discovered automatically.
Start with `claude --agent flow` to run the orchestrator as the main session.

## 🗑 Uninstall

Same interface, removes only this project's files by explicit list:

```bash
scripts/uninstall.sh opencode   # OpenCode, global
scripts/uninstall.sh claude     # Claude Code, global
```

**Windows (PowerShell):**

```powershell
scripts/uninstall.ps1 opencode
scripts/uninstall.ps1 claude
```

## 🏗 Architecture

```text
User → @flow (global orchestrator) → @subflow (per-task orchestrator) → @player (executor) → @coach (reviewer)
         ↑                             ↑                                                        │
         └── relays approved result    └──── @subflow evaluates coach verdict: APPROVE→return    ↓
                                                REJECT → fresh @player session──────────────────┘
```

`@coach` **never sends** revisions directly to `@player`. All verdicts go through `@subflow`, which decides whether to
continue the cycle or return upward; `@flow` only composes handoffs and relays approved results.

## ⚙️ How It Works

The global orchestrator decomposes the request and routes every task to `@subflow`; each task's cycle runs entirely
inside `@subflow` with exactly one coach review per player call — no extra coach pass at flow exit.

## 📐 Layered Sessions

A depth marker separates the two orchestrator layers:

| Depth | Role | Behavior |
| --- | --- | --- |
| **0** | `@flow` — thin global orchestrator | Decomposes the request, composes a handoff per task, routes EVERY task to `@subflow` |
| **≥1** | `@subflow` — per-task ephemeral orchestrator | Owns the whole mediated cycle (player → coach, N=N until APPROVE), dies with the task |

## 📏 Task Routing Rules

Uniform — no fast path: every task, simple or complex, goes `@flow` → `@subflow` → (`@player` ⇄ `@coach`). Every
invocation is a fresh session; inter-session context travels via handoff files (`@player` writes and reads them,
orchestrators pass only the path plus their own digest).

## 📂 File Structure

```text
AGENTS.md              — Root DOX contract (repo-wide rules, Child DOX Index)
LICENSE
README.md
.markdownlint-cli2.jsonc — Markdown lint config

.opencode/             — OpenCode (reference implementation)
├── AGENTS.md    — DOX contract for the agents (rules, contracts, Child DOX Index)
└── agents/
    ├── flow.md      — Orchestrator (primary agent)
    ├── player.md    — Executor (subagent, minimalist executor)
    ├── coach.md     — Reviewer (subagent, zero-tolerance reviewer)
    └── subflow.md   — Per-task orchestrator (subagent, identical to flow.md except for front-matter)

.claude/               — Claude Code port
├── AGENTS.md    — DOX contract for the port (divergences, sync rules)
└── agents/
    ├── flow.md      — Orchestrator (routes every task to subflow)
    ├── subflow.md   — Per-task orchestrator (same body as flow.md)
    ├── player.md    — Executor
    └── coach.md     — Reviewer (review-only tools enforced)

scripts/               — Install/uninstall scripts for both ports
├── AGENTS.md    — DOX contract (interface, path mapping, guarantees)
├── install.sh   — install.sh <opencode|claude|all> [--global|--local]
├── uninstall.sh — same interface, removes by explicit file list
├── install.ps1  — Windows equivalent
└── uninstall.ps1
```

## 🎯 Roles: Details

### `@flow` — Orchestrator (primary, temperature 0.1)

- The only top-level interface with the user
- Receives requests, decomposes them into tasks, and composes a handoff per task
- Delegates work exclusively via the `task()` tool — EVERY task goes to `@subflow`
- Relays approved results; never runs the mediated cycle itself
- Never answers the user directly — only through the mediation loop

### `@player` — Executor (subagent, temperature 0.6)

- Minimalist executor: minimal code, no explanations
- Does not refactor others' code, does not add validation by default
- Works strictly within the scope of the assigned task
- On linter/test errors — returns the error upward, does not fix

### `@coach` — Reviewer (subagent, temperature 0.2)

- Zero-tolerance checks: security, correctness, anti-patterns, performance
- Checks for AI-generated patterns and security issues
- Returns a binary APPROVE / REJECT verdict with specific feedback
- Does not make code changes — review only

### `@subflow` — Per-Task Orchestrator (subagent, temperature 0.1)

- Identical body to `@flow`, but runs as a subagent — one fresh session per task
- Receives EVERY task from `@flow` and owns the whole mediated cycle internally
- Returns upward only the approved result plus the handoff-file path, then dies with the task

## 📊 Example Task Flow

```text
User: "@flow: implement a REST API for user CRUD"
       │
       ▼
@flow (depth=0, split → one handoff per task)
       ├── Task 1: "create User model and validation schema" → @subflow(depth=1)
       │                    │
       │                    ▼
       │              @player → code → @coach → APPROVE
       │
       └── Task 2: "create endpoints GET/POST/PUT/DELETE /users" → @subflow(depth=1)
                            │
                            ▼
                      @player → code → @coach → REJECT (security issue)
                            │
                            ▼
                      fresh @player session (prior findings embedded verbatim) → revised code → @coach → APPROVE

@flow relays each approved result — no extra coach pass at exit (one coach review per player call)
```

## ⚠️ Important Rules

- **`@flow` never answers directly** — only through the mediation loop
- **`@player` does not explain itself** — code speaks for itself
- **`@coach` is uncompromising** — security and correctness over speed
- **No fast path** — every task routes through `@subflow`; sessions are never resumed (handoff files carry context)

---

## 📖 Related Documents

- [`.opencode/AGENTS.md`](.opencode/AGENTS.md) — DOX contract: rules, contracts, Child DOX Index
