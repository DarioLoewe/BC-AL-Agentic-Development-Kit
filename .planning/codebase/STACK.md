# Technology Stack

**Analysis Date:** 2026-06-18

## Overview

This is a **framework-only repository** — no AL extension source code lives here.
The stack consists of two distinct layers:

1. **GSD workflow tooling** — the runtime that powers planning, agent orchestration, and skill execution (Node.js / CJS)
2. **AL development target** — Business Central AL extensions that agents will generate *outside* this repo, as sibling directories

---

## Languages

**Primary:**
- **Markdown** — All agents, skills, instructions, policies, and prompts are authored in `.md` files. This is the dominant "language" of the framework.
- **JavaScript (CJS/Node.js)** — GSD-core CLI tools (`gsd-tools.cjs`, `check-latest-version.cjs`, changeset scripts), all under `.github/gsd-core/bin/` and `.github/scripts/`
- **Shell (bash/sh)** — Launcher script `gsd_run` at `.github/gsd-core/bin/gsd_run`; session hook commands in `.github/hooks/gsd-session.json`

**Target Language (for generated extensions — NOT present in this repo):**
- **AL (Application Language)** — Microsoft Dynamics 365 Business Central extension language. Instructions apply to `**/*.al` in sibling AL project directories.

---

## Runtime

**Environment:**
- **Node.js** — Required runtime for all GSD-core CLI tools. Scripts use `#!/usr/bin/env node` shebang and CommonJS (`require`/`module.exports`).
- **Shell** — `gsd_run` launcher uses POSIX sh for symlink-safe path resolution.
- **PowerShell** — Used in session hooks (`.github/hooks/gsd-session.json`) and AL test runner workflows; expected on Windows developer machines.

**Package Manager:**
- No `package.json` is present in this repository root. The GSD-core scripts are distributed as pre-built CJS bundles.
- Lockfile: Not present (bundles ship pre-compiled)

---

## Frameworks

**Core Framework:**
- **GSD (Get Stuff Done)** v1.5.0 — AI-agent orchestration framework installed into `.github/`. Version tracked at `.github/gsd-core/VERSION`. Install state tracked in `.github/gsd-install-state.json`. File integrity tracked in `.github/gsd-file-manifest.json`.

**AL Language Tooling (invoked by agents, not bundled here):**
- **AL Language Server / LSP** — VS Code AL extension tools invoked via agent tool calls:
  - `al_downloadsymbols` — downloads Base Application and System Application symbols into `.alpackages/`
  - `al_build` — compiles the AL project
  - `al_getdiagnostics` — retrieves compiler diagnostics
  - `vscode_listCodeUsages` — LSP code usage lookup
- **AL Test Runner** — Container/VM-based test runner configured in `.altestrunner/config.json`

**Changeset / Release Tooling:**
- Custom Node.js changeset CLI at `.github/scripts/changeset/cli.cjs` — handles `render`, `github-release-notes`, and `extract` subcommands for CHANGELOG generation and GitHub release notes.
- Slash-command normalizer at `.github/scripts/fix-slash-commands.cjs` — bidirectional `/gsd-<cmd>` ↔ `gsd-<cmd>` normalization for skill installation.

---

## Key Dependencies

**Critical:**
- `node` (runtime) — Required for all GSD-core CLI operations. No version pin detected; scripts use standard Node.js built-ins (`node:fs`, `node:path`).
- VS Code AL Extension — Provides `al_downloadsymbols`, `al_build`, `al_getdiagnostics` tool capabilities used by `al-build-tester` and `al-implementer` agents.
- Git — Required for branching, commits, and PR workflows referenced throughout instructions and GSD workflow scripts.

**Infrastructure:**
- `.alpackages/` directory — Populated by `al_downloadsymbols` at runtime; stores `.app` symbol files for Base Application and System Application. Currently empty (no AL project in this repo).
- `.altestrunner/config.json` — AL Test Runner configuration stub; references Docker containers, remote VMs, and PowerShell sessions for automated test execution.
- `.planning/` directory — GSD planning state directory; contains `STATE.md`, `ROADMAP.md`, and codebase analysis artifacts.

---

## Configuration

**Framework Configuration:**
- `.github/gsd-install-state.json` — Tracks applied GSD migrations with checksums; schema version 1, currently at migration `2026-05-11-first-time-baseline-scan`
- `.github/gsd-file-manifest.json` — File integrity manifest for all GSD-core files; version 1.5.0, timestamp-stamped
- `.github/.gsd-profile` — Single-line profile flag (`full`) that controls which skill clusters are active
- `.github/hooks/gsd-session.json` — Session lifecycle hooks; on `sessionStart`, checks for `.planning/STATE.md` and injects context message to the AI agent

**AL Project Configuration (in sibling repos, not here):**
- `.vscode/launch.json` — Required by `al-build-validation` skill; must contain `server`, `serverInstance`, `authentication` fields. Template provided in `.github/skills/al-build-validation/SKILL.md`.
- `app.json` — AL project manifest (standard BC extension file); must exist in sibling AL project directories.

**Session Hook Behavior:**
- If `.planning/STATE.md` exists → agent receives: `"GSD: .planning/STATE.md present - review the current phase and any blockers before acting."`
- If not → agent receives: `"GSD: no .planning/ workflow found - run /gsd-new-project to start a tracked workflow."`

---

## AL Test Runner Configuration

Config stub at `.altestrunner/config.json`:

```json
{
  "containerResultPath": "",
  "launchConfigName": "",
  "testRunnerServiceUrl": "",
  "dockerHost": "",
  "codeCoveragePath": ".altestrunner\\codecoverage.json",
  "culture": "en-US"
}
```

Supports:
- Docker container-based test execution (`dockerHost`, `remoteContainerName`)
- Remote VM execution (`vmUserName`, `vmSecurePassword`, `newPSSessionOptions`)
- External test runner service (`testRunnerServiceUrl`)
- Code coverage output (`codeCoveragePath`)

---

## Platform Requirements

**Development:**
- Windows developer machine (paths use `C:\Users\dloewe\` convention; PowerShell required)
- VS Code with AL Extension installed (provides LSP tools)
- Node.js (for GSD-core CLI)
- Git
- Access to a Business Central server (OnPrem or SaaS) for symbol downloads and builds

**AL Extension Projects (sibling repos):**
- BC server reachable at configured `server` + `serverInstance`
- Authentication: `UserPassword` or Windows auth (never stored in `launch.json` — entered via VS Code dialog)

---

## GSD Skill Inventory

**AL-Domain Skills (`.github/skills/`):**
| Skill | Purpose |
|-------|---------|
| `al-build-validation` | Symbol download, build, diagnostics |
| `al-object-analysis` | Find relevant tables, pages, codeunits, events |
| `al-code-review` | Quality, upgradeability, BC best-practices review |
| `al-test-design` | Functional and technical AL test case design |
| `al-devops-workitem` | Azure DevOps work item decomposition into AL plans |

**GSD Workflow Skills (`.github/skills/gsd-*/`):** 80+ workflow skills covering planning, execution, review, debug, workspace management, and more.

**AL-Domain Agents (`.github/agents/`):**
| Agent | Role | Tools |
|-------|------|-------|
| `al-auto-dev` | Orchestrator — full automated pipeline | `read`, `search`, `edit`, `terminal`, `agent`, `ado/*`, `al/*`, `session_store_sql`, `manage_todo_list` |
| `al-planner` | Requirements analysis, technical planning | `read`, `search` |
| `al-codebase-analyst` | AL object and pattern analysis | `read`, `search` |
| `al-implementer` | AL code changes | `read`, `search`, `edit` |
| `al-build-tester` | Build, compile, diagnostics | `read`, `search`, `terminal` |
| `al-reviewer` | Code review | `read`, `search` |
| `al-documenter` | PR descriptions, release notes | `read`, `search`, `edit` |

---

*Stack analysis: 2026-06-18*
