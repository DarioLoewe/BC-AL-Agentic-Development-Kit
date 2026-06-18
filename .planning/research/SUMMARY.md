# Project Research Summary

**Project:** BC AL Agentic Development Kit — Milestone 2 (Main-Agent Architecture)
**Domain:** Agentic coding framework for Business Central AL development
**Researched:** 2026-06-18
**Confidence:** HIGH (all four research files grounded in codebase audit, not generic AI advice)

---

## Executive Summary

The BC AL Agentic Development Kit exists to transition the current fire-and-forget `al-auto-dev` orchestrator into a **conversational, Human-in-the-Loop (HiTL) architecture**. The developer speaks only to a single `main-agent`, which orchestrates a team of specialists behind the scenes, surfaces a structured checkpoint after every delegation step, and waits for explicit developer approval before continuing. The entire framework stays markdown-native — no Python runtimes, no new databases, no external orchestration frameworks. The GSD workflow engine + `.agent.md` files + `## CHECKPOINT` output blocks are sufficient to implement the full HiTL protocol.

All four research files independently converge on the same four-phase build order: **(1) Main-Agent + Session State first** (enables the conversational interface immediately, all existing specialists continue working), **(2) Core Specialist refactoring** (Architect, Coder, Validator — reduce context overhead and formalize output contracts), **(3) Customer Docs Agents** (Betzold, Hermes, Tröber — customer-specific PR output), **(4) Helper Agents** (WebSearch, Code-Research — depth enhancement). No phase depends on a later phase, and Phase 1 delivers standalone value from day one.

The highest-risk execution decision is the **`ado/*` wildcard** present in `al-auto-dev.agent.md`. This wildcard grants every Azure DevOps write operation to all agents — including the DevOps-Reader that is architecturally supposed to be read-only. Research is unanimous: this wildcard **must be replaced with an explicit read-only allowlist before any new agent work begins**, making it a mandatory pre-phase cleanup item. A second pre-condition is resolving the three open questions identified across multiple research files (Hermes/Tröber documentation style, VS Code Copilot `model:` frontmatter support, and `session_store_sql` durability semantics) — two of these require information from the developer that has no technical substitute.

---

## Key Findings

### Cross-Cutting Findings (appear in 2+ research files)

| Finding | Appears In | Priority |
|---------|-----------|----------|
| **4-phase build order** is consistent and dependency-driven | STACK, ARCHITECTURE, FEATURES | CRITICAL |
| **`ado/*` wildcard must be replaced before Main-Agent goes live** | PITFALLS (C-3), STACK (§4a) | CRITICAL — do first |
| **SESSION.md as durable state store** (`.planning/session/CURRENT.md`) | STACK (§3), ARCHITECTURE (§Session State) | HIGH |
| **Checkpoint protocol lives in Main-Agent only** — specialists return structured output, Main-Agent controls flow | FEATURES (TS-2), ARCHITECTURE (Anti-Pattern 2) | HIGH |
| **Hermes and Tröber documentation style is undefined** — Phase 3 cannot start without this | STACK (Open Q #5), ARCHITECTURE (§Customer Docs), FEATURES (D-1) | HIGH — blocks Phase 3 |
| **VS Code Copilot `model:` frontmatter support unconfirmed** | STACK (Open Q #1, confidence MEDIUM) | MEDIUM — fallback exists |
| **`session_store_sql` is conversation-scoped only**, not cross-session durable | STACK (Open Q #2), PITFALLS (M-4) | HIGH — SESSION.md is the durable layer |

---

## Stack Recommendations

> Full detail: `.planning/research/STACK.md`

The framework is **markdown-native and must stay that way**. The recommended stack introduces no new runtimes. All orchestration, session state, and checkpoint logic is expressed in `.md` files. The existing `runSubagent` / GSD workflow engine handles delegation.

**Core technology decisions:**

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Orchestration** | `## CHECKPOINT` output blocks + `runSubagent` | Direct extension of proven GSD H2-marker pattern (`## PLAN COMPLETE`, etc.) — zero new dependencies |
| **Session state (durable)** | `.planning/session/CURRENT.md` (YAML frontmatter + markdown body) | Survives VS Code restarts, git-trackable, human-readable — identical pattern to GSD's `STATE.md` |
| **Session state (hot)** | `session_store_sql` (intra-session only) | Already declared in `al-auto-dev`; useful for fast in-turn state queries; NOT cross-session durable |
| **ADO integration** | ADO REST API v7.1 via explicit read-only `ado/` tools | Stable, already used — replace `ado/*` wildcard with explicit allowlist: `ado/work-items/get`, `ado/work-items/list`, `ado/repos/get-pull-request`, `ado/repos/list-pull-requests` |
| **GitHub integration** | `gh` CLI (`gh issue view`, `gh pr view`) | Standard, authenticated via `gh auth`; no new tooling |
| **Code research** | `vscode_listCodeUsages` + `al_downloadsymbols` + MS Learn API | All tools already in the framework; MS Learn API is free, no auth required |
| **Model — reasoning agents** | `claude-opus-4` | Main-Agent, al-architect, al-validator — deep reasoning, multi-object dependency analysis |
| **Model — execution agents** | `claude-sonnet-4-5` | al-coder, al-reviewer, al-docs-*, DevOps-Reader, helpers — pattern-heavy, structured output, ~60% cost reduction |

**What NOT to use:**

- **LangGraph / AutoGen / Semantic Kernel / CrewAI** — Python runtimes incompatible with VS Code Copilot agent context; conceptually duplicated by checkpoint protocol
- **SQLite / Redis / PostgreSQL** — server/file overhead unjustified for single-developer local tool; SESSION.md is sufficient
- **Pinecone / ChromaDB** — massive overhead; BC symbol context is already handled by `.alpackages/` + `vscode_listCodeUsages`
- **GitHub Actions for orchestration** — async, event-driven, no conversational turn-taking

---

## Feature Landscape

> Full detail: `.planning/research/FEATURES.md`

### Table Stakes (cannot ship without these)

| ID | Feature | Complexity | Why Non-Negotiable |
|----|---------|-----------|-------------------|
| TS-1 | **Main-Agent single conversational interface** | Medium | Without this, the milestone goal collapses — existing `al-auto-dev` provides no conversation |
| TS-2 | **Human-in-the-Loop checkpoint protocol** | Medium | PROJECT.md hard constraint: "Kein Schritt ohne explizite Nutzer-Zustimmung" |
| TS-3 | **Checkpoint summary format** (standardized specialist output) | Low | Main-Agent cannot extract key facts without consistent `## Ergebnis / ## Entscheidungen / ## Risiken / ## Nächster Schritt` sections |
| TS-4 | **Session state persistence** | Medium | Without state, every message requires full context re-explanation |
| TS-5 | **DevOps-Reader** (read-only ADO/GitHub) | Low–Medium | Developer entry point is a work item; Main-Agent needs ticket context before any specialist runs |
| TS-6 | **Architect-Agent** (BC object planning + effort estimation) | High | Plans objects, fields, ID ranges, events — blocks Coder-Agent |
| TS-7 | **Validator-Agent** (requirement coverage check) | High | Closes the loop: verifies every AC from the plan was actually implemented |
| TS-8 | **Coder-Agent** (HiTL-aware implementer) | Low | Existing al-implementer needs delta: accept structured correction tasks, report build result in checkpoint-ready format |
| TS-9 | **Policy enforcement at every agent layer** | Low | Every specialist must read `agent-policy.md` — Main-Agent cannot be the single enforcement point |

### Differentiators (high value, add in later phases)

| ID | Feature | Phase | Value |
|----|---------|-------|-------|
| D-1 | Customer Doku-Agents (Betzold, Hermes, Tröber) | 3 | Per-customer PR style, terminology, README conventions |
| D-3 | Model switching (Opus/Sonnet routing hints) | 3 | ~60% cost reduction while preserving quality |
| D-5 | Thin requirement risk stratification | 3 | BC domain-specific auto-block for booking/pricing/permissions |
| D-2 | Code-Research helper | 4 | Reduces Architect/Coder hallucination via symbol lookup |
| D-7 | WebSearch helper (MS Learn) | 4 | Real-time BC documentation prevents stale API usage |
| D-6 | Tester-Agent (on-demand) | 4 | AL + AI test generation, only when developer requests it |
| D-4 | ADO Tag Integration (`ai:done`, `ai:blocked`) | 4 | Two-way team-visible workflow state |

### Anti-Features (never build)

- **AF-1:** Autonomous end-to-end execution without checkpoints — explicitly Out of Scope
- **AF-2:** Parallel specialist execution without sequential checkpoints — Coder depends on Architect; policy prohibits parallel runs
- **AF-3:** Auto-merge / auto-publish — production deployments always require human sign-off
- **AF-4:** Writing to ADO/GitHub without explicit approval — DevOps-Reader is architecturally read-only
- **AF-7:** Cross-customer context in Doku-Agents — three separate stateless agents, no shared context

---

## Architecture Guidance

> Full detail: `.planning/research/ARCHITECTURE.md`

### Design Principle

The `al-auto-dev` fire-and-forget model is inverted: **the orchestrator's primary responsibility is to present, explain, and wait — not to run automatically.** Specialists remain structurally unchanged; checkpoint logic lives entirely in the Main-Agent's instructions. This means all 6 existing specialists continue working in Phase 1 — the Main-Agent wraps them, not replaces them.

### Component Map (13 agents + 1 skill)

| Layer | Components | Count |
|-------|-----------|-------|
| **Entry point** | `main-agent` (sole user interface) | 1 |
| **Core specialists** | `al-devops-reader`, `al-architect`, `al-coder`, `al-reviewer`, `al-validator`, `al-tester` | 6 |
| **Docs layer** | `al-docs-coordinator`, `al-docs-betzold`, `al-docs-hermes`, `al-docs-troeber`, `al-docs-base` (skill) | 4 agents + 1 skill |
| **Helper agents** | `al-websearch`, `al-code-research` | 2 |

### Session State Schema (`.planning/session/CURRENT.md`)

```yaml
---
wi_id: "1234"
customer: betzold              # betzold | hermes | troeber
project_path: "C:\\Users\\dloewe\\Betzold\\BetzoldExtension\\"
branch: "feature/wi-1234-..."
current_step: 3                # 1=DevOps-Reader, 2=Architect, 3=Coder, 4=Reviewer, 5=Validator, 6=Docs
status: active                 # active | paused | done
last_updated: "2026-06-18T14:28:00"
---
```

State is written by Main-Agent **before** delegating and updated **after** every checkpoint. `session_store_sql` handles fast intra-session queries; SESSION.md is the durable layer that survives VS Code restarts.

### Checkpoint Protocol (lives in Main-Agent only)

```
## Checkpoint: [Schritt-Name] abgeschlossen

**Was wurde gemacht:** [2-3 Sätze]
**Ergebnis:** [structured summary]
**Entscheidungspunkte / Offene Fragen:** [list]
**Nächster geplanter Schritt:** [Specialist] — [description]

→ Fortfahren? [ja] / [anpassen: ...] / [abbrechen]
```

**Hard rule:** Specialists NEVER present checkpoints to the user directly. Specialists return structured output; Main-Agent handles all user interaction. This is Anti-Pattern 2 if violated.

### Existing Agent Mapping

| Existing Agent | Target | Action |
|---------------|--------|--------|
| `al-auto-dev` | `main-agent` | Rewrite — add HiTL, remove fire-and-forget instructions |
| `al-planner` + `al-codebase-analyst` | `al-architect` | Merge in Phase 2 (Phase 1: Main-Agent delegates to existing agents) |
| `al-implementer` + `al-build-tester` | `al-coder` | Merge in Phase 2 |
| `al-reviewer` | `al-reviewer` | Update in Phase 2 — remove "don't wait for confirmation" instruction |
| `al-documenter` | `al-docs-coordinator` | Replace in Phase 3 |

### Architecture Layers

```
Policy Layer        agent-policy.md                 (unchanged, highest authority)
Instruction Layer   .github/instructions/           (unchanged)
Skill Layer         .github/skills/                 (NEW: al-docs-base)
Agent Layer         .github/agents/                 (EXPANDED: +7 new agents)
Session State Layer .planning/session/              (NEW layer)
GSD Core Layer      .github/gsd-core/               (unchanged)
Planning Artifacts  .planning/                      (unchanged)
```

---

## Critical Pitfalls

> Full detail: `.planning/research/PITFALLS.md`

### Pitfall C-1 — Main-Agent Silent Bypass of Checkpoints (CRITICAL)

**What:** LLM agents optimize for task completion. Without an explicit "stop and surface to user" instruction between each delegation, Main-Agent will run all specialists in a single turn — reproducing the `al-auto-dev` fire-and-forget problem exactly.

**Prevention:** Every transition in `main-agent.agent.md` must contain a named checkpoint block (not prose guidance). Add a policy rule: "Main-Agent darf niemals zwei Spezialisten in derselben Turn-Sequenz starten." Acceptance test: run full pipeline on a trivial task and verify ≥7 distinct checkpoint moments.

---

### Pitfall C-3 — `ado/*` Wildcard Causing Unintended ADO Mutations (CRITICAL)

**What:** `al-auto-dev.agent.md` uses `"ado/*"` — a wildcard that includes every Azure DevOps write operation. An agent reading a work item can trivially invoke `ado/work-items/update` and change state, title, or story points without developer awareness.

**Prevention:** **Replace `ado/*` before any new agent work.** Explicit allowlist only:
```yaml
tools: [ado/work-items/get, ado/work-items/list, ado/repos/get-pull-request, ado/repos/list-pull-requests]
```
Add to `agent-policy.md`: "ADO write operations require explicit user instruction and Main-Agent confirmation checkpoint."

---

### Pitfall C-2 — `runSubagent` Unavailability Causes Silent Pipeline Collapse (CRITICAL)

**What:** The entire orchestration chain depends on `runSubagent`. In GitHub Copilot Chat (not coding agent mode), this capability is absent. The orchestrator fails silently — Architect-Agent is never spawned, Coder-Agent operates without a plan.

**Prevention:** Add a pre-flight check: "Prüfe zuerst: Ist das Tool `runSubagent`/`agent` verfügbar? Wenn NEIN: Gib dem Nutzer die manuelle Ausführungsreihenfolge aus und stoppe." Document a "Manueller Modus" numbered list.

---

### Pitfall C-4 — AL Symbol Download Failure Before Code Generation (HIGH)

**What:** If `al_downloadsymbols` fails (BC server unreachable, stale credentials), the agent generates code against an empty or wrong symbol set. Code may reference non-existent procedures or wrong field signatures that compile locally but fail in the customer environment.

**Prevention:** Add a hard stop to `al-build-validation` SKILL.md: if `al_downloadsymbols` exits non-zero, stop immediately. No code generation without confirmed symbol download. Include `{ bcVersion, alRuntime }` in session state.

---

### Pitfall C-5 — BC Runtime Version Mismatch in Generated Code (HIGH)

**What:** Betzold, Hermes, and Tröber may run different BC versions. The Coder-Agent generates code based on training-data patterns — which may be a different runtime than the actual `app.json`. EnumExtension syntax, `Rec.SystemId`, `IsNullOrEmpty`, and event signatures all vary by runtime.

**Prevention:** Make reading `app.json` mandatory as the first step in any Architect-Agent or Coder-Agent session. Extract `{ runtime, application, platform, target }` and persist in session state. Add BC-specific version guards to `al-coding-standards.instructions.md`.

---

### Pre-Phase Cleanup Pitfalls (HIGH — must complete before Main-Agent build)

| ID | Issue | Fix |
|----|-------|-----|
| m-1 | Missing entry-point prompts (`analyze-work-item.prompt.md`, `explain-build-error.prompt.md`) | Create both prompts with YAML front-matter |
| m-2 | `AGENTS.md` has GSD boilerplate only — no BC project context | Add project context block: purpose, key agents, `agent-policy.md` link, directory policy |
| m-3 | Duplicate policy rules across agent files — policy drift on evolution | Single-source to `agent-policy.md`; add `Lies: agent-policy.md` to every specialist |
| M-2 | No BC-specific confidence calibration rubric | Add rubric to `agent-policy.md`: posting logic base = 0.35, data migration = 0.25, permissions = 0.30 |

---

## Implications for Roadmap

### Recommended Pre-Phase: Foundations Cleanup (no new agents)

**Rationale:** Three pitfalls (m-1, m-2, m-3, `ado/*`) are blocking issues that must be fixed before Main-Agent goes live. Bundling them into a quick foundations phase avoids inheriting technical debt into the new architecture.

**Delivers:**
- `ado/*` replaced with explicit read-only allowlist in `al-auto-dev.agent.md`
- `AGENTS.md` updated with BC project context
- Duplicate policy rules single-sourced to `agent-policy.md`
- Missing entry-point prompts created
- BC-specific confidence rubric added to `agent-policy.md`
- AL label/caption language policy added to `al-coding-standards.instructions.md`

**Avoids:** C-3 (ADO wildcard), m-1/m-2/m-3 (onboarding breakage), M-2 (confidence miscalibration)
**Research flag:** Standard patterns — no additional research needed.

---

### Phase 1: Main-Agent + Session State + DevOps-Reader

**Rationale:** Highest value, no dependencies. The Main-Agent wraps existing specialists — all 6 current agents continue working unchanged. Developer immediately has a conversational partner with checkpoints.

**Delivers:**
- `main-agent.agent.md` — sole user-facing interface, HiTL checkpoint protocol, session state read/write
- `.planning/session/CURRENT.md` — state schema + lifecycle (active → paused → done → archive)
- `al-devops-reader.agent.md` — read-only ADO + GitHub, explicit tool allowlist only
- Session hook extension in `.github/hooks/gsd-session.json` — surface active session on open

**Features addressed:** TS-1, TS-2, TS-3, TS-4, TS-5, TS-9
**Avoids:** C-1 (checkpoint bypass), C-2 (runSubagent fallback), M-4 (stale session state), C-6 (wrong directory for AL files)
**Research flag:** Well-documented patterns — standard GSD agent creation. No additional research phase needed.

---

### Phase 2: Core Specialist Refactoring

**Rationale:** Phase 1 delegates to existing agents. Phase 2 formalizes specialist output contracts and merges redundant agents to reduce context overhead. Must come before Phase 3 (Docs-Coordinator depends on Coder + Reviewer output format).

**Delivers:**
- `al-architect.agent.md` — merges al-planner + al-codebase-analyst; BC object planning, ID management, effort estimation, JSON plan handoff contract
- `al-coder.agent.md` — merges al-implementer + al-build-tester; accepts Validator correction tasks; BLOCKER-REPORT.md after fix-loop exhaustion
- `al-validator.agent.md` — AC-to-object mapping, diff-based coverage check, max 2 correction loops
- `al-tester.agent.md` — on-demand AL test + AI test generation
- `al-reviewer.agent.md` updated — remove "Keine Rückfragen" fire-and-forget instruction; add BC confidence rubric adherence

**Features addressed:** TS-6, TS-7, TS-8, D-6
**Avoids:** C-4 (symbol download gate in al-coder), C-5 (app.json first step), M-1 (JSON plan handoff contract), M-3 (BLOCKER-REPORT.md after fix-loop exhaustion)
**Research flag:** Architect-Agent (TS-6) has high complexity — BC symbol access, ID range management, effort estimation model. Consider a targeted research spike during planning.

---

### Phase 3: Customer Docs Agents

**Rationale:** Depends on Phase 2 output format (Coder + Reviewer produce checkpoint-ready output). Blocked by missing Hermes and Tröber style documentation — gather from developer **before Phase 3 planning starts**.

**Delivers:**
- `al-docs-base/SKILL.md` — shared documentation procedure, PR format skeleton, Release Notes structure
- `al-docs-coordinator.agent.md` — reads `customer` from session state, delegates to correct agent
- `al-docs-betzold.agent.md` — formal German, `[WI #ID] Kurzbeschreibung` PR format, Anforderung/Umsetzung/Testhinweise sections
- `al-docs-hermes.agent.md` — Hermes style (to be defined)
- `al-docs-troeber.agent.md` — Tröber style (to be defined)
- Model switching guidance in Main-Agent (D-3: Opus for planning steps, Sonnet for execution steps)
- Thin requirement risk stratification in Architect-Agent (D-5: auto-block for booking/pricing/permissions)

**Features addressed:** D-1, D-3, D-5
**Avoids:** M-5 (customer style drift — path-derived customer identity, hard-coded path guard per agent)
**Research flag:** **Hermes and Tröber style MUST be gathered from developer before this phase begins.** This is an explicit open question in STACK.md, ARCHITECTURE.md, and FEATURES.md. Phase 3 cannot produce correct output without it.

---

### Phase 4: Helper Agents

**Rationale:** Pure depth enhancement. Specialists call helpers themselves (transparent to Main-Agent). No blocking dependency. Reduces blocker rate and hallucination frequency.

**Delivers:**
- `al-websearch.agent.md` — MS Learn API + web search, BC-specific query templates, fallback to `web_search` on 429
- `al-code-research.agent.md` — `vscode_listCodeUsages` + `al_downloadsymbols` + symbol package analysis
- `al-architect.agent.md` updated — declare `agents: [al-code-research]`
- `al-coder.agent.md` updated — declare `agents: [al-websearch]`
- ADO Tag Integration at final checkpoint (D-4: propose `ai:done` / `ai:blocked`, never auto-write)

**Features addressed:** D-2, D-4, D-7
**Research flag:** MS Learn API rate limits not formally documented — implement caching in `.planning/research/ms-learn-cache/` as safeguard. Otherwise standard patterns.

---

### Phase Ordering Rationale

- **Pre-phase first** because `ado/*` wildcard is an active security risk (live ADO instance) and AGENTS.md gaps break all onboarding. These are minutes of work with high risk reduction.
- **Phase 1 before Phase 2** because Main-Agent + checkpoints deliver standalone value immediately; specialists can be the existing agents.
- **Phase 2 before Phase 3** because Docs-Coordinator reads structured output from Coder + Reviewer — the output contract must be formalized first.
- **Phase 3 before Phase 4** because helpers depend on specialists having clean delegation contracts. Phase 4 is fully additive.
- **Customer style gathering is a hard gate before Phase 3 planning** — building Hermes and Tröber agents on guessed styles would require full rewrites.

### Research Flags Summary

| Phase | Research Needed? | Reason |
|-------|-----------------|--------|
| Pre-phase | No | Straightforward text/config changes |
| Phase 1 | No | Standard GSD agent creation, proven patterns |
| Phase 2 | **Yes (Architect-Agent)** | BC symbol access, ID range management, effort estimation model — complex integration |
| Phase 3 | **Yes (customer style)** | Hermes + Tröber style docs must be gathered from developer — not a technical question |
| Phase 4 | Minimal | MS Learn API rate limit behavior — test in spike, low risk |

---

## Open Questions

Consolidated from all four research files — sorted by blocking priority:

### Blocking (must resolve before affected phase)

1. **Hermes documentation style** — PR format, language register (formal/informal), section structure, README conventions. Blocks Phase 3 planning. *No technical substitute — must ask developer.*

2. **Tröber documentation style** — same as above. Blocks Phase 3 planning. *No technical substitute — must ask developer.*

3. **`ado/read` vs `ado/*` scoping in VS Code Copilot** — whether the platform allows namespace-scoped tool access (`ado/work-items/get` vs full `ado/*`). If not supported, DevOps-Reader read-only constraint must be enforced via agent instructions rather than tool-level restriction. *Test in Phase 1 planning.*

### Non-Blocking (workaround available)

4. **VS Code Copilot `model:` frontmatter support** — STACK.md confidence MEDIUM. If `model:` field is not supported by the current Copilot agent spec, the fallback is text-based model hints in the Main-Agent's checkpoint output ("💡 Tipp: Für diesen Schritt empfehle ich Opus 4"). Fully functional, just less elegant. *Verify during Phase 1 implementation.*

5. **`session_store_sql` exact durability semantics** — not publicly documented. Research consensus: treat as conversation-scoped only. SESSION.md is the durable layer regardless. *Non-blocking: SESSION.md design is correct either way.*

6. **MS Learn API rate limits** — no formal documentation. Implement a caching fallback in `.planning/research/ms-learn-cache/` for the WebSearch agent. *Non-blocking: implement as standard defensive pattern in Phase 4.*

7. **Per-customer AL extension project scaffold** — `app.json` templates with correct `publisher`, `runtime`, `dependencies` for Betzold, Hermes, Tröber are missing. Agents may generate incorrect initial project structures. *Bundle with Coder-Agent phase or create as quick pre-Phase 2 task.*

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | All recommendations are direct extensions of existing, proven framework patterns. No new runtimes. |
| **Features** | HIGH | Derived from PROJECT.md requirements + existing agent audit. Table stakes are objectively non-negotiable for HiTL. |
| **Architecture** | HIGH | Checkpoint protocol, session state schema, component map all grounded in codebase analysis and known agent framework patterns. |
| **Pitfalls** | HIGH | C-1 through C-6 grounded in observed codebase issues (CONCERNS.md audit), not generic AI advice. |
| **Model frontmatter** | MEDIUM | VS Code Copilot `model:` support varies by version — fallback is documented and functional. |
| **Customer docs (Hermes/Tröber)** | LOW | Style rules do not exist yet. Phase 3 confidence is LOW until developer provides them. |

**Overall confidence:** HIGH for Phases 1 and 2, MEDIUM for Phases 3 and 4.

### Gaps to Address During Planning

- **Phase 2 planning:** Architect-Agent's BC symbol access, ID range collision detection, and effort estimation model are complex. A targeted research spike during Phase 2 planning is recommended.
- **Phase 3 planning:** Explicitly schedule a style-gathering session with developer before writing the PLAN.md for Phase 3. Output: `customer-hermes.instructions.md` and `customer-troeber.instructions.md` drafts.
- **Pre-phase:** Verify `ado/` tool namespace scoping in the current platform before declaring DevOps-Reader's tool list final.

---

## Sources

| File | Scope | Confidence |
|------|-------|------------|
| `.planning/research/STACK.md` | Technology decisions, orchestration patterns, model assignment, session state design, integrations, helper agents | HIGH |
| `.planning/research/FEATURES.md` | Table stakes, differentiators, anti-features, feature dependencies, MVP phasing | HIGH |
| `.planning/research/ARCHITECTURE.md` | Component map, data flow, session state schema, checkpoint protocol, customer docs design, build order | HIGH |
| `.planning/research/PITFALLS.md` | 6 critical pitfalls, 5 moderate pitfalls, 5 minor pitfalls, phase-specific warning table | HIGH |

**Secondary sources (referenced within research files):**
- `.planning/PROJECT.md` — requirements, constraints, out-of-scope list
- `.planning/codebase/CONCERNS.md` — codebase audit (foundation for PITFALLS.md)
- `.github/policies/agent-policy.md` — confidence rules, stop rules, blocker behavior
- `.planning/codebase/ARCHITECTURE.md` + `.planning/codebase/STACK.md` — existing system maps

---

*Research completed: 2026-06-18*
*Ready for roadmap: yes — pending resolution of Hermes/Tröber style open questions before Phase 3 planning*
