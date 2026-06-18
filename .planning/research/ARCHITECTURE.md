# Architecture Research: Main-Agent + Specialists Framework

**Project:** BC AL Agentic Development Kit
**Research Date:** 2026-06-18
**Dimension:** Architecture — Human-in-the-Loop Orchestration
**Confidence:** HIGH (analysis of existing codebase + known agent framework patterns)

---

## System Overview

### Current State vs. Target State

| Dimension | Current (al-auto-dev) | Target (Main-Agent) |
|-----------|----------------------|---------------------|
| Entry point | `al-auto-dev` — fire-and-forget pipeline | `main-agent` — conversational partner |
| User interaction | Input once, get PR | Checkpoint after every delegation |
| Specialist count | 6 (planner, analyst, implementer, tester, reviewer, documenter) | 7 core + 3 customer docs + 2 helpers = 12 |
| Session memory | `manage_todo_list` (ephemeral) | `.planning/session/CURRENT.md` (persistent) |
| Customer docs | Generic (al-documenter) | Customer-specific (Betzold, Hermes, Tröber) |
| Helper agents | None | WebSearch, Code-Research |
| Model strategy | Single model | Guidance: Opus for analysis, Sonnet for execution |

### Fundamental Design Shift

The current `al-auto-dev` is designed around this instruction: *"Arbeite vollautomatisch, indem du die Sub-Agents sequenziell aufrufst."* — This is the root of the fire-and-forget problem. `al-planner` even enforces it with *"Keine Rückfragen stellen."*

The new Main-Agent inverts this: **the orchestrator's primary responsibility is to present, explain, and wait — not to run automatically.** Specialists keep returning structured output; the Main-Agent controls the flow between them by inserting checkpoints.

**Key insight:** Specialists do NOT need to be changed to implement Human-in-the-Loop. The checkpoint logic lives entirely in the Main-Agent's orchestration instructions. Specialists remain unaware of the protocol — they just return clean structured output.

---

## Component Design

### Component Map

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           USER  (single conversation)                            │
│            → talks only to Main-Agent, never to specialists directly             │
└────────────────────────────────┬────────────────────────────────────────────────┘
                                 │
                    ╔════════════▼═════════════╗
                    ║        MAIN-AGENT         ║  ← .github/agents/main-agent.agent.md
                    ║   (Opus for planning,     ║  ← reads: session state, agent-policy
                    ║    Sonnet for execution)  ║  ← writes: .planning/session/CURRENT.md
                    ║                           ║
                    ║  Responsibilities:        ║
                    ║  • Gather requirements    ║
                    ║  • Select specialists     ║
                    ║  • Run checkpoint after   ║
                    ║    each delegation        ║
                    ║  • Present + wait         ║
                    ║  • Resume from state      ║
                    ╚═══════════╤═══════════════╝
                                │
           ┌────────────────────┼───────────────────────────┐
           │           CHECKPOINT GATE                       │
           │     Present result → Ask approval → Wait        │
           │     [ja] / [anpassen] / [abbrechen]             │
           └────────────────────┼───────────────────────────┘
                                │ (on approval)
     ┌──────────┬───────────────┼───────────┬───────────┬──────────────┐
     ▼          ▼               ▼           ▼           ▼              ▼
┌─────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐
│ DevOps- │ │Architect │ │ Coder    │ │Reviewer │ │ Tester   │ │Validator │
│ Reader  │ │          │ │          │ │         │ │(optional)│ │          │
│(read-   │ │plan+     │ │code+     │ │review   │ │AL tests, │ │require-  │
│only ADO │ │analyse   │ │build     │ │quality  │ │AI tests  │ │ment      │
│& GitHub │ │+ estimate│ │+ branch  │ │verdict  │ │          │ │coverage  │
└─────────┘ └──────┬───┘ └────┬─────┘ └─────────┘ └──────────┘ └──────────┘
                   │           │
            ┌──────▼──┐  ┌────▼──────────┐
            │  Code-  │  │   WebSearch   │
            │Research │  │               │
            │(AL sym- │  │ MS Learn, web │
            │bols, MS │  │ BC docs query │
            │examples)│  │               │
            └─────────┘  └───────────────┘
                    (helper agents — invoked by specialists, not Main-Agent)

     ┌─────────────────────────────────────────────────────────┐
     │                  DOCS-COORDINATOR                        │
     │  coordinates documentation across customer agents        │
     └─────────────────────────┬───────────────────────────────┘
                               │  selects based on session state
              ┌────────────────┼───────────────────┐
              ▼                ▼                   ▼
     ┌───────────────┐ ┌──────────────┐ ┌──────────────────┐
     │ al-docs-      │ │ al-docs-     │ │ al-docs-troeber  │
     │ betzold       │ │ hermes       │ │                  │
     │               │ │              │ │                  │
     │ formal DE,    │ │ Hermes style │ │ Tröber style,    │
     │ Betzold PR    │ │ PR format,   │ │ PR format,       │
     │ format        │ │ README rules │ │ README rules     │
     └───────────────┘ └──────────────┘ └──────────────────┘
              (all share al-docs-base SKILL.md as common base)
```

### Component Responsibilities

| Component | File | Responsibility | Tools |
|-----------|------|----------------|-------|
| `main-agent` | `agents/main-agent.agent.md` | Sole user-facing interface; orchestrates all specialists with HiTL checkpoints; reads/writes session state | `read, write, edit, agent, ado/*, session_store_sql, manage_todo_list` |
| `al-devops-reader` | `agents/al-devops-reader.agent.md` | Read-only access to GitHub Issues, PRs, Azure DevOps Work Items; returns structured WI data | `read, search, ado/*` |
| `al-architect` | `agents/al-architect.agent.md` | Merges current al-planner + al-codebase-analyst; analyses objects, plans changes, estimates effort; may call al-code-research | `read, search, agents: [al-code-research]` |
| `al-coder` | `agents/al-coder.agent.md` | Merges current al-implementer + al-build-tester; writes AL code, manages IDs, runs build, handles fix loops (max 3); may call WebSearch | `read, write, edit, terminal, al/*, agents: [al-websearch]` |
| `al-reviewer` | `agents/al-reviewer.agent.md` | Read-only quality review per BC conventions; produces Freigabe/Änderungen/Blocker verdict | `read, search` |
| `al-tester` | `agents/al-tester.agent.md` | On-demand AL test design + AI test generation; not in standard workflow by default | `read, write, edit, al/*` |
| `al-validator` | `agents/al-validator.agent.md` | Checks requirement coverage against delivered code; triggers correction loop if gaps found | `read, search` |
| `al-docs-coordinator` | `agents/al-docs-coordinator.agent.md` | Coordinates documentation output; selects customer-specific docs agent based on session state | `read, agent, agents: [al-docs-betzold, al-docs-hermes, al-docs-troeber]` |
| `al-docs-betzold` | `agents/al-docs-betzold.agent.md` | Generates PR descriptions, Release Notes, README additions in Betzold style | `read, write, edit` |
| `al-docs-hermes` | `agents/al-docs-hermes.agent.md` | Generates docs in Hermes style | `read, write, edit` |
| `al-docs-troeber` | `agents/al-docs-troeber.agent.md` | Generates docs in Tröber style | `read, write, edit` |
| `al-websearch` | `agents/al-websearch.agent.md` | Microsoft Learn + web search; answers AL syntax/API questions for Architect and Coder | `websearch, read` |
| `al-code-research` | `agents/al-code-research.agent.md` | AL symbol lookup, BC example code, MS reference implementations | `read, search, al/*` |
| `al-docs-base` (skill) | `skills/al-docs-base/SKILL.md` | Shared documentation procedure + output templates used by all customer docs agents | — |

---

## Data Flow

### Primary Flow: Work Item → Draft PR (with HiTL Checkpoints)

```
User input: WI URL or requirement text
     │
     ▼
Main-Agent
  1. Reads .planning/session/CURRENT.md (resume check)
  2. Reads agent-policy.md
  3. Collects customer context if not in session state
     │
     ▼
── delegate ──────────────────────────────────────────
  runSubagent(al-devops-reader)
    → Returns: WI title, description, acceptance criteria, tags, branch name
── CHECKPOINT ──────────────────────────────────────────
  Main-Agent presents WI summary to user
  "WI #1234: [Titel] — hier sind die Akzeptanzkriterien.
   Soll ich jetzt die technische Planung starten? [ja/nein/anpassen]"
  → WAIT for approval
── on approval ──────────────────────────────────────────
  Write session state: step=2 (Architect delegiert)
     │
     ▼
── delegate ──────────────────────────────────────────
  runSubagent(al-architect)
    → [may internally call al-code-research]
    → Returns: technical plan, affected objects, effort estimate
── CHECKPOINT ──────────────────────────────────────────
  Main-Agent presents plan summary
  "Architect schlägt vor: 2 neue Felder in SalesHeader, 1 Flowfield, ~4h.
   Plan freigeben? [ja/nein/anpassen]"
  → WAIT for approval
── on approval ──────────────────────────────────────────
  Write session state: step=3 (Coder delegiert), plan approved
     │
     ▼
── delegate ──────────────────────────────────────────
  runSubagent(al-coder)
    → [may internally call al-websearch for syntax questions]
    → Writes code on feature branch
    → Runs build (max 3 fix iterations internally)
    → Returns: changed files, build status, branch name
── CHECKPOINT ──────────────────────────────────────────
  Main-Agent presents code summary
  "Coder hat 3 Dateien auf Branch feature/wi-1234-... geändert. Build OK.
   Mit Code Review fortfahren? [ja/nein/Review überspringen]"
  → WAIT for approval
── on approval ──────────────────────────────────────────
  Write session state: step=4 (Reviewer delegiert)
     │
     ▼
── delegate ──────────────────────────────────────────
  runSubagent(al-reviewer)
    → Returns: Freigabe / Änderungen notwendig / Blocker verdict
── CHECKPOINT ──────────────────────────────────────────
  [If Blocker]: Main-Agent presents blocker, asks user for direction
  [If Änderungen]: Main-Agent shows list, asks "Coder nochmals beauftragen? [ja/nein]"
  [If Freigabe]: Main-Agent asks "Requirement-Validierung? [ja/überspringen]"
── on approval ──────────────────────────────────────────
     │
     ▼ (optional — on user request)
── delegate ──────────────────────────────────────────
  runSubagent(al-validator)
    → Checks all acceptance criteria against code changes
    → Returns: covered/uncovered criteria list
── CHECKPOINT ──────────────────────────────────────────
  "Alle Akzeptanzkriterien abgedeckt. Dokumentation erstellen? [ja/nein]"
── on approval ──────────────────────────────────────────
     │
     ▼
── delegate ──────────────────────────────────────────
  runSubagent(al-docs-coordinator)
    → Reads session state to determine customer (Betzold/Hermes/Tröber)
    → Delegates to al-docs-{customer}
    → Returns: PR description, Release Notes
── CHECKPOINT ──────────────────────────────────────────
  Main-Agent presents PR description preview
  "Dokumentation bereit. Draft PR erstellen? [ja/nein]"
── on FINAL approval ──────────────────────────────────────────
  Main-Agent creates Draft PR
  Write session state: completed, archive session
  ──────────────────────── STOP (human merges) ────
```

### Helper Agent Invocation Flow (within Specialist)

```
al-architect is running
  → encounters unknown BC table ID
  → runSubagent(al-code-research, "find table 36 Sales Header fields")
  → al-code-research returns: field list, relevant extensions
  → al-architect incorporates into plan
  (Main-Agent does NOT see this sub-delegation — it's internal to the specialist)
```

Helper agents are **transparent to the Main-Agent**. They operate inside specialists. This keeps the Main-Agent's checkpoint view at the right level of abstraction (specialist-level, not sub-task level).

### Session Resumption Flow

```
User opens new session
  │
  ▼
Main-Agent reads .planning/session/CURRENT.md
  → Finds: step=3, WI #1234, branch feature/wi-1234-..., Coder completed
  → Presents: "Ich erinnere mich: WI #1234 — Coder hat Code bereitgestellt.
               Weiter mit Review? [ja/von vorne/abbrechen]"
  → User: "ja"
  → Proceeds from step 4 (Reviewer)
```

---

## Session State Design

### State File: `.planning/session/CURRENT.md`

**Location:** `.planning/session/CURRENT.md`
**Written by:** Main-Agent after every checkpoint (using `write`/`edit` tool)
**Read by:** Main-Agent at session start
**Committed:** Yes — provides audit trail and enables cross-session resumption
**Archived to:** `.planning/session/archive/wi-{id}-{date}.md` on completion

**Schema:**

```markdown
---
wi_id: "1234"
wi_title: "Lieferantensperre im Verkaufsauftrag anzeigen"
wi_url: "https://dev.azure.com/..."
customer: betzold
project_path: "C:\\Users\\dloewe\\Betzold\\BetzoldExtension\\"
branch: "feature/wi-1234-lieferantensperre"
current_step: 3
last_updated: "2026-06-18T14:28:00"
status: active
---

# Session State — WI #1234

## Schritt-Protokoll

| Schritt | Agent | Status | Zeitpunkt | Freigabe |
|---------|-------|--------|-----------|----------|
| 1 | DevOps-Reader | ✅ Abgeschlossen | 14:05 | ja |
| 2 | Architect | ✅ Abgeschlossen | 14:15 | ja |
| 3 | Coder | ✅ Abgeschlossen | 14:28 | ausstehend |
| 4 | Reviewer | ⏳ Bereit | — | — |
| 5 | Validator | ⏳ Bereit | — | — |
| 6 | Docs (Betzold) | ⏳ Bereit | — | — |

## Letzte Ausgabe des aktuellen Schritts

[Strukturierte Zusammenfassung des zuletzt abgeschlossenen Spezialisten]

## Getroffene Entscheidungen

- [2026-06-18 14:15] Architect: Flowfield statt berechnetes Feld (Performance)
- [2026-06-18 14:20] Coder: Vendor-Block-Prüfung über Vendor-Tabelle direkt (kein Helper)

## Offene Punkte

- Klärung ob Vendor-Sperre auch in Purchase Order sichtbar sein soll (WI-Kommentar)
```

**Why markdown + YAML frontmatter (not session_store_sql):**
- Git-committable — provides audit trail across sessions
- Human-readable — developer can inspect and edit
- No database dependency
- Consistent with the framework's existing planning artifact pattern (STATE.md, PLAN.md)
- `session_store_sql` tool is for ephemeral in-session memory, not cross-session persistence

### What to Persist

| Field | Why | Type |
|-------|-----|------|
| `customer` | Determines which docs agent to call | String: betzold/hermes/troeber |
| `wi_id` + `wi_url` | Resume DevOps context | String |
| `project_path` | Where AL extension lives | Absolute path string |
| `branch` | Which branch to continue on | String |
| `current_step` | Resume point | Integer 1–6 |
| `step_protocol` | Which steps completed + user approved | Array of step records |
| `key_decisions` | Architecture choices from Architect | Bulleted list |
| `last_specialist_output` | Summary of last completed specialist | Markdown |

### What NOT to Persist

- Raw specialist output (too large) — only the Main-Agent's digest of it
- User's chat messages verbatim — only extracted decisions
- AL code content — lives in git (branch)
- Credentials — never in session state (policy)

---

## Human-in-the-Loop Checkpoint Protocol

### Checkpoint Format (in Main-Agent instructions)

The Main-Agent instructions define this exact template to use after every specialist:

```
## Checkpoint: [Schritt-Name] abgeschlossen

**Was wurde gemacht:**
[2-3 Sätze — was der Spezialist getan hat]

**Ergebnis:**
[Strukturierte Zusammenfassung des Outputs — z.B. Planliste, geänderte Dateien, Verdikt]

**Entscheidungspunkte / Offene Fragen:**
- [decision 1 or blocker]
- [optional: decision 2]

**Nächster geplanter Schritt:** [Specialist] — [kurze Beschreibung was er tun wird]

---
→ **Fortfahren?** Antwort mit **[ja]**, **[anpassen: ...]** oder **[abbrechen]**
```

### Checkpoint Responses and Handling

| User Response | Main-Agent Action |
|---------------|-------------------|
| `ja` | Write step approval to session state; delegate to next specialist |
| `anpassen: [instruction]` | Incorporate instruction into next specialist's invocation; note the adaptation in session state |
| `abbrechen` | Write `status: paused` to session state; tell user how to resume |
| No response / disconnect | Session state preserves last completed step; resume protocol on next session open |

### Mandatory vs. Optional Checkpoints

| Checkpoint After | Mandatory | Notes |
|------------------|-----------|-------|
| DevOps-Reader | Yes | User must confirm WI understood correctly |
| Architect | Yes | Plan approval is critical — affects all subsequent steps |
| Coder | Yes | Branch and code created — user should be aware |
| Reviewer | Yes | Verdict may require user decision (blockers) |
| Tester | No (optional) | Only invoked if user explicitly requests testing |
| Validator | No (optional) | Invoked when user wants coverage check |
| Docs-Coordinator | Yes | Preview before PR is created |

---

## Customer Docs Agent Design

### Pattern: Shared Base Skill + Customer Style Overlay

```
.github/skills/al-docs-base/SKILL.md     ← shared documentation procedure
                                              common output template structure
                                              PR format skeleton
                                              Release Notes structure

.github/agents/al-docs-betzold.agent.md  ← references base skill
                                              Betzold-specific style rules
.github/agents/al-docs-hermes.agent.md   ← references base skill
                                              Hermes-specific style rules
.github/agents/al-docs-troeber.agent.md  ← references base skill
                                              Tröber-specific style rules
```

**Why three separate agent files (not one agent + context injection):**
- Each agent is independently auditable — diff the files to see exactly what differs
- Style rules are explicit and version-controlled per customer
- No runtime context injection = no risk of wrong style applied to wrong customer
- AI gets the full customer context upfront, not via runtime parameter

### Base Skill Schema (al-docs-base/SKILL.md)

Defines the procedure and output structure that all three customer agents follow:
1. Read the diff / changed file list
2. Identify WI ID, requirements, acceptance criteria from session state
3. Write PR title in customer format
4. Write PR body sections: Anforderung, Umsetzung, Testhinweise, Bekannte Einschränkungen
5. Write Release Notes entry
6. Write WI comment (if applicable)

### Customer Agent Differentiation

| Dimension | Betzold | Hermes | Tröber |
|-----------|---------|--------|--------|
| Language register | Formelles Deutsch (Sie) | [to be defined] | [to be defined] |
| PR title format | `[WI #ID] Kurzbeschreibung` | [customer format] | [customer format] |
| Sections required | Anforderung, Umsetzung, Testhinweise, Einschränkungen | [customer-specific] | [customer-specific] |
| Release notes style | Kompakt, technisch | [customer-specific] | [customer-specific] |
| README conventions | Tabelle für neue Felder | [customer-specific] | [customer-specific] |

*Note: Hermes and Tröber style details need to be gathered from developer before Phase 3 agent implementation.*

### Docs-Coordinator Agent

The `al-docs-coordinator` is the Main-Agent's delegation target for documentation. It:
1. Reads `customer` from session state
2. Delegates to the appropriate `al-docs-{customer}` agent
3. Returns the documentation package (PR description + Release Notes) to Main-Agent
4. Main-Agent presents via checkpoint before PR creation

This indirection means the Main-Agent's workflow steps are customer-agnostic — it always calls `al-docs-coordinator`, never a customer-specific agent directly.

---

## Agent File Structure

### Main-Agent Frontmatter Pattern

```yaml
---
name: main-agent
description: Einziger Gesprächspartner für AL-Entwicklung. Orchestriert alle Spezialisten mit Human-in-the-Loop-Checkpoints.
tools:
  [
    "read",
    "write",
    "edit",
    "search",
    "agent",
    "ado/*",
    "session_store_sql",
    "manage_todo_list"
  ]
agents:
  - al-devops-reader
  - al-architect
  - al-coder
  - al-reviewer
  - al-tester
  - al-validator
  - al-docs-coordinator
---
```

*Note: Customer docs agents (al-docs-betzold, etc.) are NOT listed in main-agent's `agents:` — they are called by al-docs-coordinator, not Main-Agent directly. This keeps the main-agent's delegation surface clean.*

### Specialist Frontmatter Pattern (example: al-architect)

```yaml
---
name: al-architect
description: Analysiert relevante AL-Objekte und erstellt technische Umsetzungspläne mit Aufwandsschätzung.
tools: ["read", "search"]
agents:
  - al-code-research
---
```

### Helper Agent Frontmatter Pattern

```yaml
---
name: al-websearch
description: Sucht in Microsoft Learn, BC-Dokumentation und dem Web nach AL/BC-technischen Fragen.
tools: ["websearch", "read"]
agents: []
---
```

Helper agents declare no `agents:` — they are leaf nodes in the delegation tree.

### Relationship to Existing Agents

| Existing Agent | Target Mapping | Action |
|---------------|----------------|--------|
| `al-auto-dev` | → `main-agent` | Replace (or rename + rewrite) |
| `al-planner` | → `al-architect` (partial) | Merge into al-architect |
| `al-codebase-analyst` | → `al-architect` (partial) | Merge into al-architect |
| `al-implementer` | → `al-coder` (partial) | Merge into al-coder |
| `al-build-tester` | → `al-coder` (partial) | Merge into al-coder |
| `al-reviewer` | → `al-reviewer` | Keep, minor updates |
| `al-documenter` | → `al-docs-coordinator` | Replace |

Keeping `al-planner`, `al-codebase-analyst`, `al-implementer`, `al-build-tester` as-is is also viable for Phase 1 — the Main-Agent can delegate to the existing agents while checkpoints are added. Merging into `al-architect`/`al-coder` is a Phase 2 refinement that reduces context overhead.

---

## Model Switching Design

The agent framework (GitHub Copilot, Claude Code) does not natively support per-agent model specification in `.agent.md` frontmatter as of the current framework version. Model switching is implemented as:

**Approach 1 — Operator guidance (recommended for Phase 1):**
- Main-Agent's instructions include explicit guidance: *"Für Analyse- und Planungsschritte (DevOps-Reader, Architect) ist ein reasoning-starkes Modell ideal. Weise den User hin, falls das aktuelle Modell für komplexe Planung nicht ausreicht."*
- Practical: User selects model manually when prompted by Main-Agent at session start

**Approach 2 — Session state model hint (Phase 2 enhancement):**
- Session state includes `model_tier: opus | sonnet`
- Main-Agent surfaces this at checkpoint transitions: *"Wechsel zu Sonnet empfohlen für Coding-Schritte"*

**Anti-pattern to avoid:** Implementing model switching as a hard rule the agent enforces — the AI cannot actually switch its own model mid-conversation. Keep this as guidance/hint, not a hard constraint.

---

## Architecture Layers (Updated)

The existing 6-layer architecture is preserved and extended:

```
Policy Layer           agent-policy.md                    (unchanged, highest authority)
    │
Instruction Layer      .github/instructions/              (unchanged, applyTo file-scoped)
    │
Skill Layer            .github/skills/                    (NEW: al-docs-base added)
    │
Agent Layer            .github/agents/                    (EXPANDED: +7 new agent files)
    │       ┌──────────────────────────────────────────────────────────┐
    │       │  main-agent (new entry point)                             │
    │       │  al-devops-reader (new)  al-architect (new/merged)        │
    │       │  al-coder (new/merged)   al-validator (new)               │
    │       │  al-docs-coordinator (new)  al-docs-{3 customers} (new)   │
    │       │  al-websearch (new)  al-code-research (new)               │
    │       │  al-reviewer (updated)  al-tester (new)                   │
    │       │  [existing al-planner, al-implementer etc. retained]      │
    │       └──────────────────────────────────────────────────────────┘
    │
Session State Layer    .planning/session/                 (NEW layer)
    │       ┌──────────────────────────────────────────────────────────┐
    │       │  CURRENT.md (active session)                              │
    │       │  archive/wi-{id}-{date}.md (completed sessions)          │
    │       └──────────────────────────────────────────────────────────┘
    │
GSD Core Layer         .github/gsd-core/                  (unchanged)
    │
Planning Artifacts     .planning/                         (unchanged, GSD runtime state)
```

---

## Build Order

### Rationale for Ordering

Build order is determined by three principles:
1. **Fastest path to conversational value** — Main-Agent with checkpoints works even with existing specialists
2. **Dependency order** — helpers enable specialists; docs-base enables customer agents
3. **Risk-front-loading** — unclear Hermes/Tröber style rules are a risk; gather data before building

### Recommended Phase Structure

**Phase 1: Main-Agent + Session State (Highest Value, No Dependencies)**

Deliverables:
- `main-agent.agent.md` — rewrite of al-auto-dev with HiTL checkpoint protocol
- `.planning/session/CURRENT.md` schema + write/read logic in Main-Agent instructions
- `al-devops-reader.agent.md` — new read-only DevOps specialist
- Main-Agent can call existing `al-planner`, `al-codebase-analyst`, `al-implementer` etc. while Phase 2 refactors them

*Value delivered:* The user immediately has a conversational partner with checkpoints instead of fire-and-forget. All existing specialists continue working.

**Phase 2: Core Specialist Refactoring (Workflow Completion)**

Deliverables:
- `al-architect.agent.md` — merge al-planner + al-codebase-analyst into single richer agent
- `al-coder.agent.md` — merge al-implementer + al-build-tester into single agent with internal build loop
- `al-validator.agent.md` — new requirement coverage checker
- Update `al-reviewer.agent.md` — remove "Orchestrator-Nutzung: warte nicht auf Bestätigung" instruction (now Main-Agent handles this)
- `al-tester.agent.md` — AL test + AI test generation

*Value delivered:* Reduced context overhead (fewer agents per workflow), cleaner output structure for Main-Agent checkpoints.

**Phase 3: Customer Docs Agents (Customer-Specific Output)**

Deliverables:
- `al-docs-base/SKILL.md` — shared documentation procedure + templates
- `al-docs-coordinator.agent.md` — docs workflow coordinator
- `al-docs-betzold.agent.md` — Betzold style rules + PR format
- `al-docs-hermes.agent.md` — Hermes style rules + PR format
- `al-docs-troeber.agent.md` — Tröber style rules + PR format

*Prerequisite:* Gather Hermes and Tröber style requirements from developer before Phase 3 planning.

**Phase 4: Helper Agents (Depth Enhancement)**

Deliverables:
- `al-websearch.agent.md` — MS Learn / web search wrapper
- `al-code-research.agent.md` — AL symbol + BC examples research
- Update `al-architect.agent.md` to declare `agents: [al-code-research]`
- Update `al-coder.agent.md` to declare `agents: [al-websearch]`

*Value delivered:* Specialists can resolve own questions without Main-Agent intervention or user queries. Reduces blocker rate.

### Build Order Summary Table

| Phase | Agents Created | Agents Modified | Prerequisites |
|-------|---------------|-----------------|---------------|
| 1 | main-agent, al-devops-reader | — | None |
| 2 | al-architect, al-coder, al-validator, al-tester | al-reviewer | Phase 1 |
| 3 | al-docs-base (skill), al-docs-coordinator, al-docs-betzold, al-docs-hermes, al-docs-troeber | — | Phase 2 + customer style requirements gathered |
| 4 | al-websearch, al-code-research | al-architect, al-coder | Phase 2 |

---

## Architectural Constraints (Updated)

All constraints from the existing architecture remain in force. Additional constraints:

- **Single entry point rule:** All AL development conversations start via `main-agent`. Direct invocation of specialists by the user is allowed but defeats the HiTL model — document this in `main-agent` instructions as a warning.
- **Session state is required before first delegation:** Main-Agent MUST write session state (WI ID, customer, project path) before calling any specialist. No specialist should run without session state being initialized.
- **Customer context is mandatory for docs:** `al-docs-coordinator` MUST read `customer` from session state before delegating. If session state has no customer, it asks Main-Agent to clarify before proceeding.
- **Helper agents never call Main-Agent back:** Helper agents are leaf nodes. They cannot trigger checkpoints or session state updates. Only Main-Agent writes session state.
- **al-auto-dev retained for backward compatibility:** The existing fire-and-forget workflow remains available for users who want it. Main-Agent is additive, not a replacement that breaks existing functionality.

---

## Anti-Patterns

### Anti-Pattern 1: Main-Agent Performing Specialist Work
**What:** Main-Agent reads AL files directly, analyses code, or runs builds instead of delegating
**Why bad:** Bypasses per-specialist policy checks; mixes orchestration context with implementation context; breaks the clear checkpoint boundary
**Instead:** Strict delegation — Main-Agent only reads session state and agent-policy; everything else is a specialist's job

### Anti-Pattern 2: Checkpoint Inside Specialist
**What:** Specialist presents results and asks user for approval directly
**Why bad:** Breaks the single-conversation-partner principle; user has to interact with multiple agents
**Instead:** Specialist returns structured output; Main-Agent handles all user interaction including checkpoints

### Anti-Pattern 3: Helpers Triggered by Main-Agent
**What:** Main-Agent directly calls `al-websearch` when a specialist needs a lookup
**Why bad:** Main-Agent doesn't know what internal question the specialist is trying to answer; wrong level of abstraction
**Instead:** Specialists call helpers themselves; Main-Agent only sees the specialist's final output

### Anti-Pattern 4: Customer Context Injection at Runtime
**What:** Main-Agent passes customer name as a parameter to a single docs agent
**Why bad:** Single agent must reason about multiple customer styles; style rules are mixed in one file; hard to audit per customer
**Instead:** Three separate customer docs agent files; customer selection happens via `al-docs-coordinator` reading session state

### Anti-Pattern 5: Session State Only in manage_todo_list
**What:** Using `manage_todo_list` as the only session persistence mechanism
**Why bad:** `manage_todo_list` is ephemeral within a session; lost on context reset or session close
**Instead:** Write session state to `.planning/session/CURRENT.md` after every checkpoint; `manage_todo_list` can be used for intra-session step tracking only

---

## Pitfalls for Phase Planning

| Phase | Likely Pitfall | Mitigation |
|-------|---------------|------------|
| Phase 1 (Main-Agent) | Checkpoint loop becomes chatty — user gets too many prompts | Pre-define which checkpoints are mandatory vs. skippable; allow `[ja, alle]` for expert users |
| Phase 1 (Main-Agent) | Main-Agent forgets to write session state → resumption broken | Add session state write as the first and last action in every checkpoint instruction block |
| Phase 2 (Specialists) | Merging planner+analyst into architect loses context separation | Define clear internal sections in `al-architect` output (Analyse section vs. Plan section) |
| Phase 3 (Docs Agents) | Hermes/Tröber style unknown → agents built on wrong assumptions | Require explicit style documentation from developer before Phase 3 starts |
| Phase 4 (Helpers) | Specialist builds infinite helper query loop | Define max 1 helper call per specialist invocation in policy or agent instructions |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Checkpoint Protocol Design | HIGH | Directly derived from existing agent pattern analysis + known HiTL principles |
| Session State Schema | HIGH | Consistent with existing GSD planning artifact patterns |
| Customer Docs Agent Structure | HIGH (Betzold) / MEDIUM (Hermes, Tröber) | Betzold style defined; other two require customer discovery |
| Helper Agent Integration | HIGH | Standard sub-agent delegation pattern; low technical risk |
| Build Order | HIGH | Phase 1 has zero dependencies; confirmed by existing agent compatibility |
| Model Switching | MEDIUM | Platform support varies; guidance-only approach is safe fallback |

---

*Architecture research: 2026-06-18 — Downstream consumer: ROADMAP.md phase structure*
