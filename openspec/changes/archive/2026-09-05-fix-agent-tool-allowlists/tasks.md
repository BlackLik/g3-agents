# Tasks — fix-agent-tool-allowlists

## 1. Frontmatter fixes (Claude port)

- [x] 1.1 In `.claude/agents/coach.md`, replace the `tools:` line with
      `tools: Read, Agent(Explore, coach), mcp__*` (body untouched)
- [x] 1.2 In `.claude/agents/player.md`, replace the trailing `, *` with `, mcp__*` in the `tools:` line
      (body untouched)

## 2. Documentation sync

- [x] 2.1 In `.claude/AGENTS.md`, rewrite the "`permission` maps → `tools:` allowlists" divergence bullet: coach's
      allowlist is `Read, Agent(Explore, coach), mcp__*` (review-only at the tool layer, mirroring the reference's
      denies); note the unscoped `Read` divergence (Claude `tools:` cannot scope to `*/reference/*.md`); player uses
      `mcp__*` instead of a bare `*`
- [x] 2.2 In `.claude/AGENTS.md`, fix the session-handoff parenthetical claiming "`coach.md` here has Bash" — coach no
      longer has Bash, so the player-writes-handoffs rule is tool-enforced for coach

## 3. Verification

- [x] 3.1 Confirm no bare `*` remains in any `.claude/agents/*.md` `tools:` line
      (`grep -n 'tools:.*\*$' .claude/agents/*.md` matches only `mcp__*` endings) and that coach/player bodies are
      unchanged (`git diff` shows only frontmatter lines)
- [x] 3.2 Run `npx markdownlint-cli2` from the repo root — 0 errors
