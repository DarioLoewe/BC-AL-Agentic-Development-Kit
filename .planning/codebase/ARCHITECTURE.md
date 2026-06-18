<!-- refreshed: 2026-06-18 -->
# Architecture

**Analysis Date:** 2026-06-18

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        USER / AI ASSISTANT                                   │
│  /gsd-* commands   •   al-auto-dev trigger   •   prompt invocations          │
└──────────────┬─────────────────────┬─────────────────────┬───────────────────┘
               │                     │                     │
               ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────────┐  ┌──────────────────────────┐
│    PROMPTS        │  │   GSD SKILLS         │  │   AL WORKFLOW            │
│ .github/prompts/  │  │ .github/skills/gsd-* │  │ .github/agents/          │
│ plan-al-change    │  │ gsd-plan-phase        │  │ al-auto-dev (orchest.)   │
│ review-al-pr      │  │ gsd-execute-phase     │  │ al-planner               │
│ (quick starters)  │  │ gsd-discuss-phase     │  │ al-codebase-analyst      │
└──────────────────┘  │ ... 70+ commands      │  │ al-implementer           │
                       └──────────┬───────────┘  │ al-build-tester          │
                                  │               │ al-reviewer              │
                                  ▼               │ al-documenter            │
               ┌─────────────────────────────┐   └──────────────────────────┘
               │        GSD CORE             │                │
               │  .github/gsd-core/          │                ▼
               │  workflows/  references/    │   ┌──────────────────────────┐
               │  templates/  bin/           │   │   AL SKILLS              │
               └──────────────────────────── ┘   │ .github/skills/al-*      │
                                                  │ al-object-analysis       │
┌──────────────────────────────────────────────── │ al-build-validation      │
│  INSTRUCTIONS  .github/instructions/        ←── │ al-code-review           │
│  (domain rules, applied per file type)          │ al-test-design           │
└──────────────────────────────────────────────── │ al-devops-workitem       │
                                                  └──────────────────────────┘
┌──────────────────────────────────────────────────────────────────────────────┐
│  POLICY  .github/policies/agent-policy.md  (highest precedence)              │
│  Enforces: no main commits • no auto-merge • no prod deploy • no secrets     │
└──────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  PLANNING ARTIFACTS  .planning/                                               │
│  STATE.md  ROADMAP.md  PROJECT.md  codebase/  (runtime GSD state)            │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | Location |
|-----------|----------------|----------|
| `al-auto-dev` | Orchestrator for full AL dev workflow; delegates all steps to sub-agents | `.github/agents/al-auto-dev.agent.md` |
| `al-planner` | Converts requirements into technical plans; uses al-devops-workitem + al-object-analysis skills | `.github/agents/al-planner.agent.md` |
| `al-codebase-analyst` | Locates relevant AL objects, patterns, extension points; read-only | `.github/agents/al-codebase-analyst.agent.md` |
| `al-implementer` | Writes AL code changes based on confirmed plan; uses al-build-validation skill | `.github/agents/al-implementer.agent.md` |
| `al-build-tester` | Runs build, compile, diagnostics; max 3 fix-loops back to al-implementer | `.github/agents/al-build-tester.agent.md` |
| `al-reviewer` | Code review on quality, upgradability, BC conventions; produces PR-ready verdict | `.github/agents/al-reviewer.agent.md` |
| `al-documenter` | Generates PR description, release notes, test hints; read + write docs only | `.github/agents/al-documenter.agent.md` |
| `al-object-analysis` (skill) | Finds relevant AL objects; enforces symbol download first | `.github/skills/al-object-analysis/SKILL.md` |
| `al-build-validation` (skill) | Symbol download, build, diagnostics, fix suggestions | `.github/skills/al-build-validation/SKILL.md` |
| `al-code-review` (skill) | Structured review checklist for AL code changes | `.github/skills/al-code-review/SKILL.md` |
| `al-test-design` (skill) | Derives functional and technical test cases | `.github/skills/al-test-design/SKILL.md` |
| `al-devops-workitem` (skill) | Decomposes Azure DevOps Work Items into structured plans | `.github/skills/al-devops-workitem/SKILL.md` |
| `agent-policy` | Hard constraints for ALL agents; takes precedence over all other files | `.github/policies/agent-policy.md` |
| `copilot-instructions` | Global AI behavioral rules + GSD bootstrap instructions | `.github/copilot-instructions.md` |
| GSD Core | Workflow engine: phase lifecycle, gates, planning templates, CLI tools | `.github/gsd-core/` |
| GSD Skills (gsd-*) | ~70 user-invocable workflow commands (slash commands) | `.github/skills/gsd-*/SKILL.md` |
| GSD Agents (gsd-*) | ~35 specialized utility agents spawned by GSD workflows | `.github/agents/gsd-*.agent.md` |

## Pattern Overview

**Overall:** Layered orchestrator-with-delegation, policy-enforced multi-agent framework

**Key Characteristics:**
- **Strict separation of concerns**: Each agent has a single role; orchestrator delegates 100%, never acts directly
- **Policy supremacy**: `agent-policy.md` overrides all other guidance; loaded by every agent and the orchestrator
- **Confidence-based gating**: Agents self-score implementation confidence (0.00–1.00) before acting
- **Max-bounded fix loops**: Build errors get at most 3 correction iterations before escalation
- **Draft-PR boundary**: Automation stops at Draft PR — humans always approve, merge, and release
- **No AL code in framework**: Extension projects live outside this repository as sibling directories

## Layers

**Policy Layer:**
- Purpose: Non-negotiable safety and compliance boundaries for all agents
- Location: `.github/policies/agent-policy.md`
- Contains: Allowed/forbidden actions, thin-requirement rules, confidence table, build rules, stop rules
- Depends on: Nothing (highest authority)
- Used by: Every agent and skill

**Instruction Layer:**
- Purpose: Domain-specific technical standards loaded by AI per file type (`applyTo` frontmatter)
- Location: `.github/instructions/`
- Contains: AL coding standards, testing rules, review criteria, Azure DevOps workflow rules
- Depends on: Policy layer
- Used by: Copilot/agents when working with `**/*.al` files or `**/*` files

**Skill Layer:**
- Purpose: Reusable, callable capability modules — invoked within agents, not standalone
- Location: `.github/skills/{skill-name}/SKILL.md`
- Contains: Structured step-by-step procedures with standardized output formats
- Depends on: Policy + Instruction layers
- Used by: Agents declare skills they use; skills provide callable procedures

**Agent Layer:**
- Purpose: Specialized roles that orchestrate skills to perform a defined job
- Location: `.github/agents/*.agent.md`
- Contains: YAML frontmatter (name, tools, sub-agent refs) + markdown instructions
- Depends on: Skills, Policy, Instructions
- Used by: Orchestrators or directly by the user

**GSD Core Layer:**
- Purpose: Generic project management framework — phase planning, execution, verification
- Location: `.github/gsd-core/`
- Contains: Workflow `.md` files, reference documents, planning artifact templates, CLI bin
- Depends on: Agent layer (spawns gsd-* agents)
- Used by: GSD skill commands (`gsd-plan-phase`, `gsd-execute-phase`, etc.)

**Planning Artifacts Layer:**
- Purpose: Runtime state generated by GSD workflows during a project
- Location: `.planning/`
- Contains: STATE.md, ROADMAP.md, PROJECT.md, phase plans (PLAN.md), codebase docs
- Depends on: GSD Core (templates define structure)
- Used by: All GSD workflows read/write artifacts here

## Data Flow

### Primary Flow: AL Development (Work Item → Draft PR)

1. **Input arrives** — Work Item URL or customer requirement text given to `al-auto-dev`
2. **Policy check** — `al-auto-dev` loads `.github/policies/agent-policy.md`, assesses confidence
3. **Planning** — `runSubagent(al-planner)` → uses `al-devops-workitem` + `al-object-analysis` skills → returns structured plan with assumptions, acceptance criteria, affected objects
4. **Codebase analysis** — `runSubagent(al-codebase-analyst)` → uses `al-object-analysis` skill (downloads symbols via `al_downloadsymbols` first) → returns file paths, extension points, existing patterns
5. **Implementation** — `runSubagent(al-implementer)` → receives plan + analysis context → uses `al-build-validation` skill → writes AL code on feature branch
6. **Build loop** — `runSubagent(al-build-tester)` → runs `al_build` + `al_getdiagnostics` → if errors, returns fix list to `al-implementer` → max 3 iterations → if still failing, escalates to user
7. **Review** — `runSubagent(al-reviewer)` → uses `al-code-review` + `al-test-design` skills → produces Freigabe / Änderungen / Blocker verdict
8. **Documentation** — `runSubagent(al-documenter)` → uses `al-code-review` + `al-test-design` skills → writes PR description, release notes, test hints
9. **Output** — Draft Pull Request ready for human review and merge

```text
Work Item → al-auto-dev → al-planner → al-codebase-analyst → al-implementer
                                                                      ↑ (max 3×)
                                                               al-build-tester
                                                                      ↓
                                                               al-reviewer
                                                                      ↓
                                                               al-documenter
                                                                      ↓
                                                              Draft PR (STOP)
```

### Secondary Flow: GSD Phase Lifecycle

1. **User invokes `/gsd-discuss-phase`** → loads `.github/skills/gsd-discuss-phase/SKILL.md` → workflow loads `.github/gsd-core/workflows/discuss-phase.md`
2. **Discussion** → `gsd-discuss-phase` produces `CONTEXT.md` in `.planning/{phase}/`
3. **User invokes `/gsd-plan-phase`** → spawns `gsd-phase-researcher`, then `gsd-planner`, then `gsd-plan-checker` agents → revision loop (max 3) → produces `PLAN.md`
4. **User invokes `/gsd-execute-phase`** → reads `PLAN.md` → spawns `gsd-executor` agents in dependency-ordered waves → each produces `SUMMARY.md` → `gsd-verifier` validates gates
5. **Completion markers** — each GSD agent signals completion via standardized H2 markers (e.g. `## PLANNING COMPLETE`, `## PLAN COMPLETE`, `## Verification Complete`)

### Confidence Decision Gate

Every agent evaluates confidence before acting:

| Score | Action |
|------:|--------|
| 0.80–1.00 | Implement fully |
| 0.60–0.79 | Implement cautiously, document all assumptions |
| 0.40–0.59 | Technical spike/preparation only, no production logic |
| 0.00–0.39 | Block, document blocker, mark Work Item as `ai:blocked` |

**State Management:**
- GSD state lives in `.planning/STATE.md` (YAML frontmatter + markdown)
- AL workflow state tracked via `manage_todo_list` tool in `al-auto-dev`
- GSD session state in `.github/hooks/gsd-session.json`

## Key Abstractions

**Agent Definition File:**
- Purpose: Defines an agent's identity, tools, and behavioral instructions
- Examples: `.github/agents/al-auto-dev.agent.md`, `.github/agents/gsd-executor.agent.md`
- Pattern: YAML frontmatter (`name`, `description`, `tools: []`, `agents: []`) + markdown role instructions + output format specification

**Skill Module:**
- Purpose: A reusable procedure an agent can invoke by name
- Examples: `.github/skills/al-object-analysis/SKILL.md`, `.github/skills/gsd-plan-phase/SKILL.md`
- Pattern: `name` + `description` in frontmatter, step-by-step `## Vorgehen` section, standardized `## Output` markdown template

**GSD Workflow File:**
- Purpose: The actual step-by-step instruction set for a `/gsd-*` command
- Examples: `.github/gsd-core/workflows/execute-phase.md`, `.github/gsd-core/workflows/plan-phase.md`
- Pattern: HTML comment `gsd-loop-host` header (step, points, agent-roles, produces, consumes) → `<purpose>` → `<required_reading>` → `<available_agent_types>` → `<process>` steps

**Instruction File:**
- Purpose: Domain rules loaded contextually by AI when working on matching file types
- Examples: `.github/instructions/al-coding-standards.instructions.md` (applies to `**/*.al`)
- Pattern: YAML frontmatter `applyTo` → markdown rules with AL code examples

**Planning Artifact:**
- Purpose: Runtime documents written by GSD workflows to track project progress
- Examples: `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/codebase/ARCHITECTURE.md`
- Pattern: Defined by templates in `.github/gsd-core/templates/`

## Entry Points

**AL Development Workflow:**
- Location: `.github/agents/al-auto-dev.agent.md`
- Triggers: User provides Work Item ID/URL or customer requirement text
- Responsibilities: Orchestrates entire AL dev pipeline via sequential `runSubagent` calls; does NOT read/write AL code itself

**GSD Workflow Commands:**
- Location: `.github/skills/gsd-{command}/SKILL.md` → delegates to `.github/gsd-core/workflows/{command}.md`
- Triggers: User types `/gsd-plan-phase`, `/gsd-execute-phase`, etc.
- Responsibilities: Load the appropriate workflow file and follow its instructions

**VS Code Prompts:**
- Location: `.github/prompts/plan-al-change.prompt.md`, `.github/prompts/review-al-pr.prompt.md`
- Triggers: User invokes via VS Code Chat prompt picker
- Responsibilities: Template-driven single-shot queries for common tasks; uses `${input:...}` variable substitution

**Master Instructions:**
- Location: `.github/copilot-instructions.md`
- Triggers: Loaded automatically by GitHub Copilot for every session
- Responsibilities: Sets global rules, bootstraps GSD command routing, references policy file

## Architectural Constraints

- **No AL code in framework repo**: Extension projects are ALWAYS sibling directories outside this repository. Never create `app.json`, `.al` files, or `src/` inside `BC-AL-Agentic-Development-Kit\`. See `.github/policies/agent-policy.md`.
- **Delegation-only orchestrator**: `al-auto-dev` MUST use `runSubagent` for every task; it cannot directly read, write, or analyse AL files. Violation breaks the separation of concerns that allows policy enforcement at each step.
- **Symbol download prerequisite**: `al-object-analysis` and `al-build-validation` skills MUST call `al_downloadsymbols` before analysis or build. No symbol download = analysis is incomplete.
- **Feature branch requirement**: AL code changes happen only on feature branches (`feature/wi-{id}-*`, `bugfix/wi-{id}-*`, `ai/wi-{id}-*`). No direct commits to `main`, `master`, `release/*`, `production/*`.
- **3-iteration fix cap**: `al-build-tester` runs at most 3 correction loops before escalating to user.
- **No inline plan execution in Copilot**: GSD `execute-phase.md` defaults to sequential inline execution on Copilot runtime (no reliable subagent completion signals). Parallel execution only on Claude Code.
- **German language**: Documentation, PR descriptions, WI comments, and error messages are written in German. AL code identifiers follow English naming per BC conventions.

## Anti-Patterns

### Orchestrator performing sub-agent work

**What happens:** `al-auto-dev` directly reads AL files or runs build commands instead of delegating
**Why it's wrong:** Bypasses the per-agent policy check; mixes analysis context with implementation context; breaks the max-3 fix loop boundary
**Do this instead:** Every step MUST use `runSubagent(agentName)`. The orchestrator only reads Work Items and tracks the overall todo list.

### Creating AL objects in the framework repo

**What happens:** An agent creates `.al` files, `app.json`, or a `src/` directory inside `BC-AL-Agentic-Development-Kit\`
**Why it's wrong:** This repository is the tooling framework; all AL Extension projects must live as sibling directories (see policy)
**Do this instead:** Create the project at `C:\Users\dloewe\{Kunde}\{ExtensionName}\` — always ask user for the correct sibling path if unclear

### Skipping symbol download

**What happens:** `al-object-analysis` or `al-build-validation` skills run analysis/build without first calling `al_downloadsymbols`
**Why it's wrong:** Without Base Application symbols in `.alpackages/`, object analysis is incomplete and build may miss BC standard objects
**Do this instead:** Always run `al_downloadsymbols` as step 0; verify `.alpackages/` is non-empty before proceeding

### Hardcoded credentials in launch.json

**What happens:** `al-build-validation` skill writes username/password into `.vscode/launch.json`
**Why it's wrong:** Credentials committed to git = security incident
**Do this instead:** Write only `server`, `serverInstance`, `authentication` fields; tell user to enter credentials manually via VS Code's login dialog

### Blocking on thin requirements instead of documenting assumptions

**What happens:** Agent refuses to act because requirement is ambiguous, asks endless clarifying questions
**Why it's wrong:** Defeats the confidence-based approach; for thin requirements, implement the smallest safe change with assumptions documented
**Do this instead:** Apply the confidence table — if ≥ 0.60, implement with assumptions; if < 0.40, block with documented reason and `ai:blocked` tag

## Error Handling

**Strategy:** Fail-forward with documented assumptions at every decision point

**Patterns:**
- Build errors → up to 3 fix iterations in `al-build-tester` → escalate to user if unresolved
- Thin requirements → smallest safe implementation + documented assumptions in PR
- Confidence < 0.40 → document blocker, add `ai:blocked` WI tag, stop without implementing
- Ambiguous requirement → `al-planner` documents the ambiguity as a WI comment, does NOT invent interpretation
- Missing `launch.json` → `al-build-tester` asks user for server details, never guesses or writes credentials

## Cross-Cutting Concerns

**Language:** German for all documentation, comments, PR descriptions, and user-facing output; English for AL code identifiers and BC-native names
**Policy Enforcement:** `agent-policy.md` is referenced by `copilot-instructions.md` and every `al-*.agent.md`; all agents read it at startup
**Skill Discovery:** Agents declare which skills they use under `## Nutze diese Skills`; skills provide standardized `## Output` blocks for consistent handoff
**Completion Protocol:** GSD agents signal completion via H2 markers (`## PLANNING COMPLETE` etc.) parsed by orchestrating workflows

---

*Architecture analysis: 2026-06-18*
