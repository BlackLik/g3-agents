## Context

The project is a multi-agent orchestration system with four roles: flow (orchestrator), subflow (recursive orchestrator), player (executor), and coach (reviewer). It has two ports: OpenCode (`.opencode/agents/`) and Claude Code (`.claude/agents/`).

Currently, no MCP servers are configured and no agent has MCP tool access. Agents can only use built-in tools (bash, read, edit, grep, task, etc.) and skills. As the project grows, agents need access to external tools — Langflow, databases, APIs, etc. — through MCP. Without MCP support, every new integration requires custom code or manual steps.

The permission model today:
- **flow/subflow**: `*: deny` — only `task` tool and `skill` are explicitly allowed
- **player**: `*: allow` — has bash, read, webfetch, websearch, lsp, edit, skill, task
- **coach**: `*: allow` — has bash, read, grep, skill, lsp, websearch, webfetch, task (no edit)

No `opencode.json` exists at the repo root. Agent prompts are `.md` files with YAML frontmatter (mode, temperature, permissions) and markdown body text.

## Goals / Non-Goals

**Goals:**
- Make MCP tools available to all agents with role-appropriate access
- Add `opencode.json` at the repo root with MCP server definitions
- Update agent prompts with role-specific MCP usage guidance
- Keep the existing permission model intact — MCP tools inherit from the `*: allow`/`*: deny` stance
- Sync changes across both OpenCode and Claude Code ports

**Non-Goals:**
- Per-agent MCP tool allowlisting (MCP tools are native tools, controlled by the existing permission system — the Claude port's existing `tools:` mechanism is a general permission system, not MCP-specific allowlisting)
- Changing the permission model for flow/subflow to `*: allow` — they stay `*: deny` and rely on prompting to avoid direct MCP use
- Adding MCP server implementations or writing custom MCP server code
- Migrating existing integrations (Langflow, etc.) to MCP in this change — this change enables them
- Changing agent frontmatter structure or introducing a new permission key for MCP

## Decisions

1. **opencode.json at repo root**: The standard location. All agents discover MCP servers from this single file. No per-environment or per-agent config files.

2. **MCP tools as native tools**: MCP servers configured in `opencode.json` expose their tools as native tools to all agents automatically. No separate MCP tool registration or allowlisting step is needed — the permission system controls access.

3. **Permission model**:
   - **flow/subflow** (`*: deny`): MCP tools are blocked by default. Prompting instructs them to delegate MCP work to player rather than calling MCP tools directly. If specific MCP tools are needed for planning/verification in the future, individual tool patterns can be allowlisted.
   - **player** (`*: allow`): MCP tools are available automatically. Player is the primary executor.
   - **coach** (`*: allow`): MCP tools are available automatically. Coach uses them for verification.
   - **Claude port** (`tools:` allowlist): Claude port requires `tools:` allowlist updates to grant MCP tool access to the player agent. These updates constitute permission changes and are documented in the permissions spec.

4. **Prompt strategy — body text, not frontmatter**: MCP usage guidance goes into the markdown body of each agent prompt file. Frontmatter stays focused on mode, temperature, and permissions. This keeps MCP guidance as instructional text that can evolve independently of the agent runtime config.

5. **Two-port sync**: Both `.opencode/agents/` and `.claude/agents/` get identical MCP usage sections. The `.claude/AGENTS.md` divergences list is updated to reflect any sync-relevant changes.

## Risks / Trade-offs

- **flow/subflow cannot use MCP tools even when appropriate**: Keeping `*: deny` means flow/subflow cannot directly call MCP tools even if a future use case warrants it (e.g., querying an MCP-connected knowledge base during planning). Mitigation: individual tool patterns can be allowlisted as needs arise; the design does not preclude targeted exceptions.
- **Prompt-only guardrails for flow/subflow**: Preventing flow/subflow from using MCP tools relies on prompt instructions rather than enforcement. A misconfigured or overridden agent could attempt direct MCP calls. Mitigation: the `*: deny` permission blocks these calls regardless of prompting — the prompt is a usability guide, not the access control mechanism.
- **No MCP server implementations yet**: This change enables MCP but does not deliver any working MCP-connected tool until servers are configured. The value is realized in follow-up work that adds specific server definitions.
- **Two-port maintenance**: Every MCP prompt update must land in both `.opencode/` and `.claude/` ports. The divergence tracking in `.claude/AGENTS.md` adds a manual step that can be missed.
