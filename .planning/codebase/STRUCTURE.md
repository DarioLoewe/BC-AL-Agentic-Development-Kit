# Codebase Structure

**Analysis Date:** 2026-06-18

## Directory Layout

```
BC-AL-Agentic-Development-Kit\          ← Framework root (NO AL extension code here)
├── .alpackages\                         ← AL symbol package cache (downloaded by al_downloadsymbols)
├── .altestrunner\                       ← AL test runner config (VS Code extension state)
│   └── config.json                      ← Test runner settings (server, company, suite)
├── .git\                                ← Git repository
├── .github\                             ← ALL framework definitions live here
│   ├── .gsd-profile                     ← GSD install profile ("full")
│   ├── copilot-instructions.md          ← Master AI instructions (loaded every session)
│   ├── gsd-file-manifest.json           ← GSD v1.5.0 install registry + SHA-256 checksums
│   ├── gsd-install-state.json           ← Applied migration history
│   ├── agents\                          ← Custom agent definition files
│   │   ├── al-auto-dev.agent.md         ← Main AL orchestrator (entry point)
│   │   ├── al-planner.agent.md          ← Requirement analysis + plan creation
│   │   ├── al-codebase-analyst.agent.md ← AL object + dependency discovery
│   │   ├── al-implementer.agent.md      ← AL code writing
│   │   ├── al-build-tester.agent.md     ← Build, compile, diagnostics
│   │   ├── al-reviewer.agent.md         ← Code review
│   │   ├── al-documenter.agent.md       ← PR + documentation generation
│   │   └── gsd-*.agent.md               ← ~35 GSD utility agents (planner, executor, verifier, etc.)
│   ├── gsd-core\                        ← GSD framework engine (installed by gsd-update)
│   │   ├── VERSION                      ← GSD version (currently 1.5.0)
│   │   ├── bin\                         ← CLI tools (Node.js CJS modules)
│   │   │   ├── gsd_run                  ← Shell entry point script
│   │   │   ├── gsd-tools.cjs            ← CLI dispatcher
│   │   │   ├── check-latest-version.cjs ← Version check utility
│   │   │   └── lib\                     ← ~80 library modules (phase, config, audit, etc.)
│   │   ├── contexts\                    ← Shared context overlays for agents
│   │   │   ├── dev.md                   ← Development context
│   │   │   ├── research.md              ← Research context
│   │   │   └── review.md                ← Review context
│   │   ├── references\                  ← Reference docs loaded by workflows via @-imports
│   │   │   ├── agent-contracts.md       ← Completion marker registry for all agents
│   │   │   ├── gates.md                 ← Gate taxonomy (pre-flight, revision, escalation, abort)
│   │   │   ├── context-budget.md        ← Context window management rules
│   │   │   ├── planner-guidance.md      ← Plan quality guidelines
│   │   │   ├── verification-patterns.md ← Verification checklist patterns
│   │   │   └── ...                      ← ~65 reference files
│   │   ├── templates\                   ← Planning artifact templates
│   │   │   ├── codebase\                ← Codebase doc templates (arch, stack, etc.)
│   │   │   ├── state.md                 ← STATE.md template
│   │   │   ├── project.md               ← PROJECT.md template
│   │   │   ├── roadmap.md               ← ROADMAP.md template
│   │   │   ├── milestone.md             ← Milestone template
│   │   │   └── ...                      ← ~30 artifact templates
│   │   └── workflows\                   ← Workflow instruction files (~90 files)
│   │       ├── execute-phase.md         ← Wave-based parallel execution workflow
│   │       ├── plan-phase.md            ← Plan creation with research + verification loop
│   │       ├── discuss-phase.md         ← Decision extraction + CONTEXT.md creation
│   │       ├── discuss-phase\           ← Subdirectory with discuss-phase modes
│   │       ├── execute-phase\           ← Subdirectory with execute-phase hooks
│   │       └── ...                      ← All other gsd-* command workflows
│   ├── gsd-migration-journal\           ← Timestamped migration records
│   ├── hooks\                           ← GSD runtime session state
│   │   └── gsd-session.json             ← Active session tracking
│   ├── instructions\                    ← Domain instruction files (auto-applied by AI)
│   │   ├── al-coding-standards.instructions.md   ← applyTo: **/*.al
│   │   ├── al-testing.instructions.md            ← applyTo: **/*.al
│   │   ├── al-review.instructions.md             ← applyTo: **/*.al
│   │   └── azure-devops.instructions.md          ← applyTo: **/*
│   ├── policies\                        ← Hard constraints (highest precedence)
│   │   └── agent-policy.md              ← THE policy file (all agents must load this)
│   ├── prompts\                         ← VS Code chat prompt templates
│   │   ├── plan-al-change.prompt.md     ← Plan AL change from requirement
│   │   └── review-al-pr.prompt.md       ← Review an AL PR
│   ├── scripts\                         ← Utility scripts
│   │   ├── changeset\                   ← Changeset management scripts
│   │   ├── fix-slash-commands.cjs       ← Slash command repair utility
│   │   └── lib\                         ← Script library modules
│   └── skills\                          ← Skill modules (each is a directory with SKILL.md)
│       ├── al-build-validation\         ← Build, compile, diagnostics skill
│       ├── al-code-review\              ← Structured AL code review skill
│       ├── al-devops-workitem\          ← Azure DevOps WI decomposition skill
│       ├── al-object-analysis\          ← AL object + pattern discovery skill
│       ├── al-test-design\              ← Test case design skill
│       └── gsd-*/                       ← ~70 GSD workflow skill directories
├── .planning\                           ← GSD runtime planning artifacts (generated)
│   └── codebase\                        ← Codebase analysis documents (this directory)
├── .snapshots\                          ← GSD snapshot files
├── AGENTS.md                            ← Root-level AI agent instructions
├── README.md                            ← Project documentation (German)
└── LICENSE                              ← License file
```

## Directory Purposes

**`.github/agents/`:**
- Purpose: Custom agent definition files consumed by AI coding assistants (GitHub Copilot, Claude Code)
- Contains: `*.agent.md` files with YAML frontmatter (`name`, `description`, `tools`, `agents`) + markdown role instructions
- Key files: `al-auto-dev.agent.md` (AL orchestrator), `gsd-executor.agent.md`, `gsd-planner.agent.md`

**`.github/skills/`:**
- Purpose: Reusable skill modules — each a subdirectory with `SKILL.md` as the entry point
- Contains: AL-specific skills (`al-*`) and GSD workflow skills (`gsd-*`)
- Key files: `al-object-analysis/SKILL.md`, `al-build-validation/SKILL.md`, `gsd-execute-phase/SKILL.md`

**`.github/instructions/`:**
- Purpose: Domain rules loaded contextually by AI when working on matching file types
- Contains: `.instructions.md` files with `applyTo` frontmatter that scopes them to file patterns
- Key files: `al-coding-standards.instructions.md` (applies to all `**/*.al` files)

**`.github/policies/`:**
- Purpose: Non-negotiable safety constraints that override all other guidance
- Contains: `agent-policy.md` — the single source of truth for what agents can and cannot do
- Key files: `agent-policy.md`

**`.github/prompts/`:**
- Purpose: Template-driven quick-start prompts for VS Code Chat
- Contains: `.prompt.md` files with `description` frontmatter and `${input:...}` variable substitution
- Key files: `plan-al-change.prompt.md`, `review-al-pr.prompt.md`

**`.github/gsd-core/workflows/`:**
- Purpose: Step-by-step workflow instructions for each `/gsd-*` command
- Contains: `.md` files with `<!-- gsd-loop-host -->` metadata headers defining step, gates, agent roles, and I/O artifacts
- Key files: `execute-phase.md`, `plan-phase.md`, `discuss-phase.md`

**`.github/gsd-core/references/`:**
- Purpose: Reference documents loaded by workflows via `@.github/gsd-core/references/` imports in `<required_reading>` blocks
- Contains: Guidance documents for agents (planner-guidance, gates, agent-contracts, verification-patterns, etc.)
- Key files: `agent-contracts.md` (completion marker registry), `gates.md` (gate taxonomy)

**`.github/gsd-core/templates/`:**
- Purpose: Templates for planning artifacts generated by GSD workflows
- Contains: Markdown templates that define the structure of `STATE.md`, `PLAN.md`, `SUMMARY.md`, `CONTEXT.md`, etc.
- Key files: `state.md`, `roadmap.md`, `project.md`, `codebase/` (codebase doc templates)

**`.github/gsd-core/bin/`:**
- Purpose: Node.js CLI tools for GSD framework maintenance (install, update, version check)
- Contains: CommonJS (`.cjs`) modules; NOT invoked during normal AL development workflows
- Key files: `gsd_run` (shell entry), `gsd-tools.cjs` (CLI dispatcher), `lib/` (~80 modules)

**`.planning/`:**
- Purpose: GSD runtime state — all planning artifacts generated during active project work
- Contains: `STATE.md`, `ROADMAP.md`, `PROJECT.md`, phase directories, `codebase/` docs
- Key files: `codebase/ARCHITECTURE.md` (this file), `codebase/STACK.md`, etc.

**`.alpackages/`:**
- Purpose: Cache directory for Business Central AL symbol packages (populated by `al_downloadsymbols`)
- Contains: `.app` symbol files from Base Application and System Application
- Key note: Must be non-empty before any `al-object-analysis` or `al-build-validation` skill runs

## Key File Locations

**Entry Points:**
- `.github/copilot-instructions.md`: Global AI session instructions; bootstraps GSD command routing
- `.github/agents/al-auto-dev.agent.md`: AL development workflow orchestrator
- `.github/policies/agent-policy.md`: Policy file — load first, precedence over everything

**Skill Indexes:**
- `.github/skills/al-object-analysis/SKILL.md`: AL object discovery procedure
- `.github/skills/al-build-validation/SKILL.md`: Build + diagnostics procedure
- `.github/skills/al-code-review/SKILL.md`: Code review checklist
- `.github/skills/al-test-design/SKILL.md`: Test case design procedure
- `.github/skills/al-devops-workitem/SKILL.md`: Work item decomposition

**Domain Standards:**
- `.github/instructions/al-coding-standards.instructions.md`: AL naming, patterns, object rules
- `.github/instructions/al-testing.instructions.md`: Test structure, GIVEN/WHEN/THEN, docs
- `.github/instructions/al-review.instructions.md`: Review criteria and verdict format
- `.github/instructions/azure-devops.instructions.md`: WI tags, branch names, commit format, PR structure

**GSD Workflow Definitions:**
- `.github/gsd-core/workflows/plan-phase.md`: Phase planning workflow
- `.github/gsd-core/workflows/execute-phase.md`: Phase execution workflow
- `.github/gsd-core/workflows/discuss-phase.md`: Decision extraction workflow

**Agent Contracts:**
- `.github/gsd-core/references/agent-contracts.md`: Completion markers for all GSD agents
- `.github/gsd-core/references/gates.md`: Gate types and behavior

**Install State:**
- `.github/gsd-file-manifest.json`: SHA-256 checksums of all installed GSD files
- `.github/gsd-install-state.json`: Migration history with timestamps
- `.github/gsd-core/VERSION`: GSD framework version (1.5.0)

## Naming Conventions

**Agent Files:**
- Pattern: `{agent-name}.agent.md`
- AL agents: `al-{role}.agent.md` (e.g., `al-planner.agent.md`, `al-implementer.agent.md`)
- GSD agents: `gsd-{role}.agent.md` (e.g., `gsd-executor.agent.md`, `gsd-planner.agent.md`)

**Skill Directories:**
- Pattern: `{skill-name}/SKILL.md` — directory named after skill, entry file always `SKILL.md`
- AL skills: `al-{function}/` (e.g., `al-object-analysis/`, `al-build-validation/`)
- GSD skills: `gsd-{command}/` (e.g., `gsd-execute-phase/`, `gsd-plan-phase/`)

**Instruction Files:**
- Pattern: `{domain}.instructions.md`
- Examples: `al-coding-standards.instructions.md`, `azure-devops.instructions.md`

**Prompt Files:**
- Pattern: `{action}.prompt.md`
- Examples: `plan-al-change.prompt.md`, `review-al-pr.prompt.md`

**GSD Workflow Files:**
- Pattern: `{command}.md` (matching the `/gsd-{command}` invocation)
- Examples: `execute-phase.md`, `plan-phase.md`, `discuss-phase.md`

**Planning Artifacts (generated by GSD):**
- `STATE.md` — project state (YAML frontmatter + status tracking)
- `ROADMAP.md` — phase list with statuses
- `PROJECT.md` — project definition
- `CONTEXT.md` — per-phase discussion output
- `PLAN.md` — per-phase implementation plan (YAML frontmatter + tasks)
- `SUMMARY.md` — per-plan execution summary

**AL Extension Projects (outside this repo):**
- Location: `C:\Users\dloewe\{Kunde}\{ExtensionName}\`
- Branch naming: `feature/wi-{id}-{short-title}`, `bugfix/wi-{id}-{short-title}`, `ai/wi-{id}-{short-title}`
- Commit format: `WI #{id}: short description`

## Where to Add New Code

**New AL-specific Agent:**
- File: `.github/agents/al-{new-role}.agent.md`
- Frontmatter: `name`, `description`, `tools: ["read", "search"]`, `agents: []`
- Register in `al-auto-dev.agent.md` frontmatter `agents:` list if it becomes a sub-agent

**New AL Skill:**
- Directory: `.github/skills/al-{function}/`
- File: `.github/skills/al-{function}/SKILL.md`
- Frontmatter: `name: al-{function}`, `description: ...`
- Include: `## Vorgehen` (steps) + `## Output` (standardized markdown output format)
- Reference in relevant agent `## Nutze diese Skills` section

**New Instruction Rule:**
- Add to existing file in `.github/instructions/` if it fits an existing domain
- Or create `.github/instructions/{domain}.instructions.md` with `applyTo: "**/*.al"` (or matching glob)

**New GSD Workflow:**
- Skill: `.github/skills/gsd-{command}/SKILL.md`
- Workflow: `.github/gsd-core/workflows/{command}.md`
- Agent (if needed): `.github/agents/gsd-{role}.agent.md`
- Note: GSD files are managed by the GSD installer — use `/gsd-update` to sync

**Policy Additions:**
- Edit: `.github/policies/agent-policy.md` directly
- No new policy files — single policy file is intentional

**New Planning Artifact Template:**
- File: `.github/gsd-core/templates/{artifact-name}.md`
- Follows the same structure as existing templates

## Special Directories

**`.alpackages/`:**
- Purpose: BC symbol package cache for AL LSP and build tools
- Generated: Yes, by `al_downloadsymbols` tool
- Committed: No (should be in `.gitignore`; regenerated per dev environment)

**`.altestrunner/`:**
- Purpose: AL Test Runner VS Code extension state
- Generated: Yes, by the AL Test Runner VS Code extension
- Committed: Partially — `config.json` skeleton committed; credentials and run state excluded

**`.planning/`:**
- Purpose: GSD runtime planning artifacts (project state, roadmaps, phase plans, codebase docs)
- Generated: Yes, by GSD workflow commands
- Committed: Yes — planning artifacts are committed as project memory

**`.snapshots/`:**
- Purpose: GSD framework snapshot files used for diff/rollback
- Generated: Yes, by GSD installer/updater
- Committed: Yes — tracks install state

**`.github/gsd-core/`:**
- Purpose: GSD framework engine — managed by GSD installer, not edited manually
- Generated: Yes, installed/updated by `/gsd-update`
- Committed: Yes — framework files are versioned with the project

**`.github/gsd-migration-journal/`:**
- Purpose: Timestamped JSON records of GSD installer migrations applied
- Generated: Yes, by GSD installer
- Committed: Yes — audit trail for framework upgrades

---

*Structure analysis: 2026-06-18*
