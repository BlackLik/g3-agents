# request-analysis

## Purpose

Rules requiring flow to analyze and classify the incoming request before any delegation or tool call, separating user domain from skill domain from other-agent domain.

## Requirements

### Requirement: Flow analyzes request before delegating

Flow SHALL perform a mandatory pre-action analysis phase at the start of every top-level request. Before any delegation, tool call, or response, flow SHALL:
1. Classify the request type — skill invocation, direct task, question, or mixed
2. Identify which domains are involved — user domain, skill domain, other-agent domain
3. Determine what belongs to flow's orchestration responsibility vs what should be routed to other agents
4. Produce a structured decomposition plan

Flow SHALL NOT skip, abbreviate, or inline the analysis phase into a delegation, even for seemingly trivial requests.

#### Scenario: Skill invocation arrives

- **WHEN** the user invokes a skill (e.g. `/opsx-propose`) that loads instructions into flow's context
- **THEN** flow SHALL first analyze: what is the skill asking? What parts are skill-specific vs user-specific? What should flow handle vs delegate?
- **THEN** flow SHALL produce a decomposition plan
- **THEN** flow SHALL delegate per the plan — never follow skill instructions directly

#### Scenario: Direct task request

- **WHEN** the user gives a direct task instruction (e.g. "fix this bug")
- **THEN** flow SHALL analyze: what type of task is this? What tools/agents are needed?
- **THEN** flow SHALL produce a decomposition plan
- **THEN** flow SHALL delegate to @player per the plan

#### Scenario: Question from user

- **WHEN** the user asks a question (e.g. "how does X work?")
- **THEN** flow SHALL analyze: is this a codebase question, conceptual question, or both?
- **THEN** flow SHALL produce a query plan
- **THEN** flow SHALL delegate to @explore and/or @player per the plan

### Requirement: Analysis output is a structured plan

The analysis phase SHALL produce an explicit, structured plan that flow then executes. The plan SHALL be the single source of truth for the delegation sequence — flow SHALL NOT deviate from it based on tool affordances encountered during execution.

#### Scenario: Plan produced and followed

- **WHEN** flow completes the analysis phase and produces a plan (e.g., "decompose into 2 subtasks: [A → @player, B → @explore → @player]")
- **THEN** flow SHALL execute the plan step by step
- **THEN** flow SHALL NOT add steps, skip steps, or reorder steps based on tool availability

### Requirement: Analysis phase has no MCP tool access

During the analysis phase, flow SHALL operate with only the delegation tool (task/Agent) available. Flow SHALL NOT call MCP tools, read files, or execute commands during analysis. MCP and execution tools become available only after the plan is produced.

#### Scenario: Tool attempted during analysis

- **WHEN** flow begins the analysis phase but a direct MCP tool call is attempted (e.g., mcp_db_query)
- **THEN** the analysis phase SHALL be restarted without the tool call
- **THEN** the MCP tool SHALL be recorded in the plan for player to execute later
