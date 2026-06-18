# Technology Stack — Main-Agent Architecture

**Project:** BC AL Agentic Development Kit — Milestone 2 (Main-Agent Architecture)
**Researched:** 2026-06-18
**Scope:** Stack dimension — orchestration, model switching, session persistence, DevOps/GitHub integration, code-research helpers
**Overall Confidence:** HIGH (all recommendations are grounded in the existing framework's proven patterns)

---

## Overview

The existing framework is a **markdown-driven, VS Code Copilot-native agent system**. The recommended
stack for this milestone **extends this foundation — it introduces no new runtimes, no Python
orchestration frameworks, and no databases.** The entire architecture stays prompt-native:
everything is expressed in `.md` files, session state lives in `.planning/`, and orchestration
runs through the existing `runSubagent` / GSD workflow engine.

### Core Principle

> The BC AL framework runs inside VS Code Copilot and Claude Code. The right orchestration
> pattern is **markdown-defined state machines + GSD workflow primitives** — not LangGraph,
> AutoGen, Semantic Kernel, or CrewAI. Adding a Python runtime would break the single-runtime
> guarantee and create operational complexity for a one-developer setup.

### What Must NOT Change

- The markdown-first authoring model (`.agent.md` + `SKILL.md` files)
- The `agent-policy.md` policy supremacy layer
- The GSD phase lifecycle in `.planning/`
- The `runSubagent` delegation contract (orchestrator never does sub-agent work directly)

---

## 1. Orchestration Patterns

### Recommended: Checkpoint Protocol — Markdown-Native HiTL Gates

**Pattern:** Each specialist agent produces a standardized `## CHECKPOINT` output block.
The Main-Agent reads this block, formats it for the user, and waits for explicit approval
before invoking the next specialist. No external state machine framework required.

**How it works:**

```
User → Main-Agent (Orchestrator)
         │
         ├─► runSubagent(al-planner) → produces ## CHECKPOINT block
         │         Main-Agent presents checkpoint to user: "Plan erstellt. Fortfahren?"
         │         User: "ja" / "nein" / "anpassen: [Hinweis]"
         │
         ├─► runSubagent(al-codebase-analyst) → produces ## CHECKPOINT block
         │         Main-Agent: "Analyse abgeschlossen. Fortfahren?"
         │
         ├─► runSubagent(Architect-Agent) → ## CHECKPOINT
         │         Main-Agent: "Objektstruktur definiert. Code starten?"
         │
         ├─► runSubagent(Coder-Agent) → ## CHECKPOINT
         │         "Implementierung fertig. Build-Test starten?"
         │
         └─► ... (Reviewer, Validator, Docs, DevOps-Writer)
```

**Standardized `## CHECKPOINT` output block** (every specialist ends with this):

```markdown
## CHECKPOINT: [agent-name]

**Status:** AWAITING_APPROVAL
**Schritt:** [N] / [Total]
**Agent:** [Displayname]

### Was wurde getan

- [Bullet 1 — konkret, 1 Satz]
- [Bullet 2]
- [Bullet 3]

### Ergebnis

[1–3 Sätze Kernaussage des Schritts]

### Annahmen / Risiken

- [Falls zutreffend: Assumption oder Risk]

### Nächster Schritt bei Zustimmung

→ [Was der nächste Agent tun wird]

---
*Sitzung: {ticket_id} | Checkpoint-Nummer: {n}*
```

**Main-Agent presentation logic** (in `main-agent.agent.md`):

```markdown
Nach jedem Subagent-Aufruf:
1. Lese den ## CHECKPOINT Block aus dem Subagent-Output
2. Präsentiere dem Nutzer: "✅ **[Schritt N/6 — Agent-Name] abgeschlossen.**
   [Summary aus CHECKPOINT]. **Fortfahren?** (ja / nein / anpassen: [Hinweis])"
3. Warte auf Nutzerantwort — KEINE automatische Fortsetzung
4. Bei "ja": nächster runSubagent-Aufruf, SESSION.md aktualisieren
5. Bei "nein": Workflow anhalten, Status in SESSION.md setzen: paused
6. Bei "anpassen [Hinweis]": denselben Subagent mit Feedback neu aufrufen
```

**Why this and not LangGraph / AutoGen / Semantic Kernel:**

| Framework | Why NOT |
|-----------|---------|
| **LangGraph** | Python runtime — VS Code Copilot agents run in the AI model's execution context, not in a Python process. LangGraph's "interrupt" mechanism maps exactly to this checkpoint pattern conceptually, but we get it for free in markdown. |
| **AutoGen** | Requires a local Python agent server (`uvicorn`). Two runtimes (Python + VS Code Copilot) = two failure surfaces, two auth models, two debug paths. |
| **Semantic Kernel** | .NET / Python SDK — adds a compilation or pip dependency chain to a markdown-native framework. |
| **CrewAI** | Python, opinionated crew-role definitions that duplicate the existing `.agent.md` + `SKILL.md` structure. |
| **GitHub Actions** | Async, event-driven, no conversational turn-taking — structurally incompatible with HiTL. |

**Confidence: HIGH** — The GSD framework already uses H2 completion markers for workflow signaling
(`## PLANNING COMPLETE`, `## PLAN COMPLETE`). The checkpoint protocol is an incremental
extension of this existing, proven pattern. Zero new runtime dependencies.

---

## 2. Model Strategy

### Recommended: Frontmatter `model:` Declaration + Main-Agent Routing Hints

**In VS Code Copilot (current primary runtime):**
Model selection is per-conversation. The Main-Agent cannot programmatically switch models
mid-conversation. The practical implementation: Main-Agent includes a model recommendation
in its checkpoint presentation, prompting the user to switch before the next delegation step.

**In Claude Code (parallel / future runtime):**
True per-subagent model selection is possible. Subagents can be spawned with explicit
`--model` flags. `gsd-tools.cjs` already has a `resolve-model` command — hook into this.

### Model Assignment Matrix

| Agent | Recommended Model | Rationale |
|-------|-------------------|-----------|
| **Main-Agent** | `claude-opus-4` | Routing decisions, customer context understanding, ambiguity resolution — needs deep reasoning |
| **al-planner / Architect-Agent** | `claude-opus-4` | Architecture design, acceptance criteria derivation, multi-object dependency analysis |
| **Validator-Agent** | `claude-opus-4` | Requirement coverage analysis needs semantic depth — Sonnet misses edge cases |
| **al-codebase-analyst** | `claude-sonnet-4-5` | Symbol and pattern lookup — structured task, fast on Sonnet, Opus overhead unjustified |
| **al-implementer / Coder-Agent** | `claude-sonnet-4-5` | Routine AL code generation — fast, cost-effective, Sonnet is adequate for templated code |
| **al-build-tester** | `claude-sonnet-4-5` | Diagnostics parsing — rule-based, structured output, no deep reasoning needed |
| **al-reviewer / Reviewer-Agent** | `claude-sonnet-4-5` | Checklist-driven review — structured, Sonnet follows checklists reliably |
| **al-documenter / Docs-Agent** | `claude-sonnet-4-5` | Template-based text generation — standard task |
| **Kunden-Doku-Agents (3×)** | `claude-sonnet-4-5` | Style transformation — low complexity, high volume |
| **DevOps-Reader** | `claude-sonnet-4-5` | Data extraction / structured parsing — no reasoning required |
| **WebSearch-Hilfsagent** | `claude-sonnet-4-5` | Search result summarization — structured, repeatable |
| **Code-Research-Hilfsagent** | `claude-sonnet-4-5` | Symbol lookup + pattern matching — structured, tool-driven |

**Cost impact:** Opus is ~5× more expensive than Sonnet. Using Sonnet for the 8 execution/helper
agents and Opus only for the 3 reasoning agents (Main, Planner, Validator) reduces per-feature
cost by ~60% while preserving quality where it matters.

### Frontmatter Pattern for Agent Files

```yaml
---
name: al-planner
model: claude-opus-4
description: Plant AL-Änderungen aus fachlichen Anforderungen.
tools: ["read", "search"]
---
```

```yaml
---
name: al-implementer
model: claude-sonnet-4-5
description: Schreibt AL-Code gemäß bestätigtem Plan.
tools: ["read", "search", "edit"]
---
```

### Main-Agent Model Hint Presentation (VS Code Copilot)

In `main-agent.agent.md`, include routing hints for the user:

```markdown
Wenn du einen Analyse- oder Planungsschritt startest:
→ "💡 Tipp: Für diesen Schritt empfehle ich Opus 4 — bitte im Chat-Header wechseln."

Wenn du einen Ausführungsschritt delegierst:
→ "⚡ Sonnet 4.5 ist ausreichend für diesen Schritt — spart Tokens."
```

### gsd-tools resolve-model Integration (Claude Code)

```bash
# Call from Main-Agent when routing:
gsd_run resolve-model --task-type analysis    # → claude-opus-4
gsd_run resolve-model --task-type codegen     # → claude-sonnet-4-5
gsd_run resolve-model --task-type review      # → claude-sonnet-4-5
```

**Confidence: HIGH** — Model capability differences between Opus and Sonnet are well-established.
The assignment matrix follows a consistent complexity/cost principle. The frontmatter `model:`
declaration is a VS Code Copilot supported pattern.

---

## 3. Session State Persistence

### Recommended: Markdown SESSION.md + session_store_sql for Hot State

**Primary persistence (cross-session, durable):**

File: `.planning/al-workflow/SESSION.md`

```yaml
---
ticket_id: "WI-1234"
ticket_title: "Lieferantensperre im Verkaufsauftrag anzeigen"
ticket_source: "azure_devops"  # azure_devops | github
customer: "Betzold"
extension_path: "C:\\Users\\dloewe\\Betzold\\BetzoldCore\\"
branch: "ai/wi-1234-lieferantensperre"
current_step: "planning_approved"
current_agent: "al-codebase-analyst"
awaiting_checkpoint: false
paused: false
approved_steps:
  - planning
rejected_steps: []
build_fix_loop_count: 0
doku_agent: "al-doku-betzold"
started_at: "2026-06-18T09:00:00+02:00"
last_updated: "2026-06-18T09:15:00+02:00"
---

## Plan Summary
<!-- Filled in by al-planner checkpoint -->

## Analysis Notes
<!-- Filled in by al-codebase-analyst checkpoint -->

## Architect Decisions
<!-- Filled in by Architect-Agent checkpoint -->

## Implementation Notes
<!-- Filled in by Coder-Agent checkpoint -->

## Review Verdict
<!-- Filled in by Reviewer-Agent checkpoint -->

## Validation Result
<!-- Filled in by Validator-Agent checkpoint -->
```

**Workflow State Lifecycle:**

```
SESSION.md not exists → Main-Agent creates it with ticket data
current_step: "intake"
      ↓ al-planner approved
current_step: "planning_approved"
      ↓ al-codebase-analyst approved
current_step: "analysis_approved"
      ↓ Architect-Agent approved
current_step: "architecture_approved"
      ↓ Coder-Agent + Build complete
current_step: "implementation_approved"
      ↓ Reviewer-Agent approved
current_step: "review_approved"
      ↓ Validator-Agent approved
current_step: "validated"
      ↓ Docs-Agent + Kunden-Doku-Agent complete
current_step: "done"  → rename SESSION.md to SESSION-WI-{id}-done.md, start new
```

**Secondary persistence (hot, in-conversation):**

`session_store_sql` — already declared in `al-auto-dev.agent.md`. Keep this for fast
in-session state lookups (e.g., "which step are we on?"). Use SESSION.md for durability
across VS Code restarts and conversation resets.

**Session Hook extension** — extend `.github/hooks/gsd-session.json`:

```json
{
  "sessionStart": [
    {
      "condition": "fileExists:.planning/al-workflow/SESSION.md AND yaml.awaiting_checkpoint==false AND yaml.current_step!=done",
      "message": "⚠️ AL Workflow aktiv: Ticket {yaml.ticket_id} ({yaml.ticket_title}), Schritt: {yaml.current_step}. Fortführen mit: 'weiter'"
    },
    {
      "condition": "fileExists:.planning/al-workflow/SESSION.md AND yaml.paused==true",
      "message": "⏸️ AL Workflow pausiert: Ticket {yaml.ticket_id}. Fortführen mit: 'weiter'"
    }
  ]
}
```

**Why NOT a database:**

| Option | Why Not |
|--------|---------|
| **SQLite** | Requires a Node.js script outside VS Code context; files are not human-readable; debugging requires `sqlite3` CLI |
| **Redis** | Server process required; unjustified for single-developer tool; VS Code restarts kill the connection |
| **session_store_sql alone** | VS Code Copilot's `session_store_sql` is conversation-scoped — does NOT persist across VS Code restarts or new conversation windows |
| **GSD STATE.md** | GSD STATE.md tracks roadmap phase lifecycle; AL workflow state (active ticket, build loop count, checkpoint status) is operationally distinct. Mixing them couples the planning framework with AL runtime state. |

**Why Markdown SESSION.md:**
- Survives VS Code restarts, conversation resets, and machine reboots
- Human-readable: developer can see exactly where the workflow stands
- Git-trackable: workflow history is auditable
- Zero new dependencies
- Compatible with the session hook injection pattern GSD already uses

**Confidence: HIGH** — The `.planning/` directory as durable state store is proven across all
GSD workflows. SESSION.md follows the exact pattern of GSD's STATE.md. No new dependencies.

---

## 4. Integrations

### 4a. Azure DevOps Integration — DevOps-Reader Agent

**Agent:** `.github/agents/al-devops-reader.agent.md`
**Tool declaration:** `tools: ["ado/read", "terminal"]` *(read-only subset of `ado/*`)*

**Azure DevOps REST API calls** (via `ado/*` tool, API version 7.1):

```
# Work Item detail with all fields
GET /_apis/wit/workitems/{id}?$expand=all&api-version=7.1

# Linked Work Items (parent/child/related)
GET /_apis/wit/workitems/{id}/relations?api-version=7.1

# Sprint/Iteration backlog
GET /_apis/wit/queries/{queryId}?$expand=all&api-version=7.1

# PR linked to Work Item
GET /_apis/git/pullrequests?searchCriteria.workItemRefs={id}&api-version=7.1
```

**Structured output** from DevOps-Reader (fed to Main-Agent):

```markdown
## Ticket Context: WI-{id}

**Titel:** Lieferantensperre im Verkaufsauftrag anzeigen
**Typ:** User Story | **Priorität:** 2 | **Kunde:** Betzold
**Status:** Active | **Iteration:** Sprint 2026-06

### Beschreibung
[Parsed plain text — no HTML tags]

### Akzeptanzkriterien
- [ ] Kriterium 1
- [ ] Kriterium 2

### Verknüpfte Work Items
- WI-1230 (Parent Epic): Lieferstopps im Verkaufsprozess
- WI-1235 (Child Task): UI-Test für Lieferantensperre

### Branch / PR
- Vorhandener Branch: Keiner
- Vorhandener PR: Keiner

### ADO Tags
ai:implement, bc-al, Betzold
```

**GitHub Issues/PRs** (via `terminal` tool using `gh` CLI):

```bash
# Read GitHub issue
gh issue view {number} --json title,body,labels,assignees,state

# Read GitHub PR
gh pr view {number} --json title,body,state,files,reviews

# List issues tagged for AI
gh issue list --label "ai:implement" --json number,title,body
```

**Policy enforcement** in DevOps-Reader:

```markdown
## Verbote
- Kein Schreiben in ADO Work Items (kein POST/PATCH auf /_apis/wit/*)
- Kein Erstellen von PRs
- Keine Statusänderungen in ADO
- Keine Branches erstellen
```

**Confidence: HIGH** — Azure DevOps REST API v7.1 and GitHub CLI (`gh`) are stable,
well-documented, and already partially used in the framework (`ado/*` in al-auto-dev).
The read-only constraint is enforceable via tool declaration.

### 4b. GitHub Integration

The existing `al-auto-dev` orchestrator already creates Draft PRs. No new tool is needed
for GitHub. The DevOps-Reader uses `gh` CLI for reading. The `gsd-ship` skill handles
PR creation. This is sufficient.

**One addition:** `gh` CLI authentication via `gh auth status` check in the DevOps-Reader's
startup procedure — fail-fast with a clear error if not authenticated, rather than a
cryptic API failure.

---

## 5. Code Research Helpers

### 5a. WebSearch-Hilfsagent

**Agent:** `.github/agents/al-websearch.agent.md`
**Tools:** `["search", "web_search", "fetch"]`
**Invoked by:** Main-Agent, Architect-Agent, Coder-Agent (on demand, never autonomously)

**Primary information sources:**

| Source | URL Pattern | Use Case |
|--------|-------------|----------|
| **Microsoft Learn AL Docs** | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/` | AL API reference, events, tables |
| **MS Learn API** (free, no auth) | `learn.microsoft.com/api/search/?search={q}&locale=en-us&category=Documentation` | Programmatic doc search |
| **ALAppExtensions (GitHub)** | `github.com/microsoft/ALAppExtensions` | Standard app AL code examples |
| **BCApps (GitHub)** | `github.com/microsoft/BCApps` | BC platform extension examples |
| **Dynamics User Community** | `dynamicsuser.net` | Community workarounds, edge cases |
| **Stack Overflow** | `stackoverflow.com/questions/tagged/business-central` | Error messages, known issues |

**Microsoft Learn API query pattern:**

```
GET https://learn.microsoft.com/api/search/?search=AL+SalesLine+events&locale=en-us&category=Documentation&facet=category&$top=5
```

Returns structured JSON: `{ value: [{ title, description, url, lastUpdatedDate }] }`

**WebSearch-Hilfsagent output format:**

```markdown
## Research Result: [Query]

**Source:** [URL]
**Date:** [Publikationsdatum]
**Relevance:** HIGH / MEDIUM

### Kernaussagen
- [Finding 1]
- [Finding 2]

### AL Code Beispiel (falls gefunden)
```al
[code snippet]
```

### Weiterführende Links
- [Link 1]
```

### 5b. Code-Research-Hilfsagent

**Agent:** `.github/agents/al-code-research.agent.md`
**Tools:** `["read", "search", "vscode_listCodeUsages", "al_downloadsymbols"]`
**Invoked by:** Architect-Agent (extension point discovery), Coder-Agent (symbol lookup)

**Capabilities:**

1. **AL Symbol Lookup** — finds where a BC standard object is used in the current codebase:
   ```
   vscode_listCodeUsages → Table 36 "Sales Header" → returns all usages in sibling extension
   ```

2. **Symbol Discovery** — reads `.alpackages/` symbol packages to find:
   - Table IDs and field IDs in Base Application
   - Codeunit procedure signatures
   - Event publisher declarations (`[IntegrationEvent]`, `[BusinessEvent]`)
   - Page/PageExtension object IDs

3. **Extension Point Discovery** — identifies valid AL extension hooks:
   ```
   Search .alpackages/ for IntegrationEvent on Table 36 → returns event list for Coder-Agent
   ```

4. **Standard Object ID Lookup** — BC standard object ID ranges are well-known;
   Code-Research maps names to IDs when the Coder-Agent needs them:
   ```
   "Vendor" table → Table 23
   "Sales & Receivables Setup" → Table 311
   ```

**Code-Research output format:**

```markdown
## Code Research Result: [Query]

**Object:** Table 36 "Sales Header"
**Symbols loaded from:** .alpackages/Microsoft_Base Application_*.app

### Relevante Felder
- Field 19 "Sell-to Vendor No." (Code[20])
- Field 1220 "Vendor Blocked" (Enum "Vendor Blocked") — NICHT vorhanden, Feld auf Vendor-Tabelle

### Integration Events (gefunden in Base App)
- OnBeforeInsertSalesHeader
- OnAfterGetRelatedRecord

### Empfohlene Extension Points
- TableExtension auf Table 36 für neues Feld
- PageExtension auf Page 42 "Sales Order" für Anzeige-Feld

### Bestehende Extension in Projekt
- SalesHeaderExt.TableExt.al (Zeile 15): bestehende TableExtension gefunden
```

**Why separate WebSearch and Code-Research agents:**
- Different tool access: WebSearch needs `web_search`/`fetch` (external network); Code-Research needs `al/*` (local LSP)
- Different latency: Code-Research is fast (local); WebSearch is slow (network) — separate agents avoid blocking
- Different invocation frequency: Code-Research runs on almost every ticket; WebSearch runs only when a pattern is unknown

**Confidence: HIGH** — `vscode_listCodeUsages` and `al_downloadsymbols` are already
declared and working in the framework. The MS Learn Search API is publicly documented and
free. Both agents follow the existing `.agent.md` pattern exactly.

---

## 6. Recommendations

### What to Build (Priority Order)

| Priority | Component | Pattern | Rationale |
|----------|-----------|---------|-----------|
| 1 | **Main-Agent** (`main-agent.agent.md`) | New agent, extends al-auto-dev | Single conversation partner; all other agents invisible to user |
| 2 | **SESSION.md schema + write logic** | `.planning/al-workflow/SESSION.md` | Without state persistence, checkpoint pattern has no memory |
| 3 | **Checkpoint Protocol** | Standardized `## CHECKPOINT` block in every specialist | Core of HiTL — Main-Agent cannot present checkpoints without standardized output |
| 4 | **model: frontmatter in all agents** | Add to every `.agent.md` | Required for model-routing hints to Main-Agent |
| 5 | **DevOps-Reader** (`al-devops-reader.agent.md`) | New agent, read-only `ado/read` + `gh` CLI | Blocks Architect-Agent — needs ticket context |
| 6 | **Architect-Agent** (`al-architect.agent.md`) | New agent, replaces al-planner for design work | Specialization: al-planner = requirements analysis, Architect = object design |
| 7 | **Validator-Agent** (`al-validator.agent.md`) | New agent, Opus 4 | Closes the loop: validates implementation against acceptance criteria |
| 8 | **Kunden-Doku-Agents (3×)** | New agents per customer | Low risk, high value for PR quality |
| 9 | **WebSearch-Hilfsagent** | New agent, `web_search` + `fetch` | Nice-to-have for unknown BC patterns |
| 10 | **Code-Research-Hilfsagent** | New agent, `al/*` + `vscode_listCodeUsages` | Nice-to-have, already partially covered by al-codebase-analyst |

### What NOT to Use

| Tool / Framework | Reason to Avoid | Better Alternative |
|------------------|-----------------|-------------------|
| **LangGraph** (Python) | Python runtime incompatible with VS Code Copilot agent system; conceptually identical to checkpoint protocol but requires separate runtime | Checkpoint Protocol in `.agent.md` (this doc) |
| **AutoGen** (Python) | Requires local `uvicorn` agent server; two debug paths; imports Pythonic patterns alien to markdown-native system | `runSubagent` + `## CHECKPOINT` blocks |
| **Semantic Kernel** (.NET/Python) | SDK dependency chain; separate compilation; non-markdown runtime | GSD workflow engine (already present) |
| **CrewAI** (Python) | Duplicates `.agent.md` + `SKILL.md` structure in Python — maintaining two definitions is error-prone | Existing markdown agent definitions |
| **Pinecone / ChromaDB / Weaviate** | Vector DB — massive overhead for a single-developer workflow; BC codebase context is already handled by LSP + `.alpackages/` | `.alpackages/` + `vscode_listCodeUsages` |
| **Redis / PostgreSQL / SQLite** | Server/file overhead unjustified for local tool; harder to debug than markdown | `SESSION.md` + `session_store_sql` (hot) |
| **GitHub Actions for orchestration** | Async, event-driven, no conversational turn-taking — antithetical to HiTL | Main-Agent conversation-driven checkpoint flow |
| **Custom MCP servers** | Node.js server setup + runtime management for capabilities already covered by `ado/*`, `al/*`, `terminal` tools | Existing tool namespaces + `gh` CLI |
| **n8n / Zapier / Make** | Fire-and-forget automation; no HiTL; external dependency for a local workflow | Main-Agent checkpoint flow |
| **GPT-4o / Azure OpenAI** | Different provider ecosystem; PAT management complexity; moves away from Claude's strength in long-context reasoning | Claude Opus/Sonnet via Copilot / Claude Code |
| **Direct `main` commits from Coder-Agent** | Already forbidden by policy — mentioned here because the Coder-Agent spec must repeat this constraint | Feature branch + Draft PR (existing policy) |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Checkpoint Protocol | HIGH | Direct extension of proven GSD H2-marker pattern |
| Model Assignment Matrix | HIGH | Based on documented Opus vs Sonnet capability gap; cost ratio verified |
| SESSION.md State Pattern | HIGH | Identical to GSD's STATE.md pattern — proven in production |
| DevOps-Reader (ADO REST) | HIGH | ADO REST API v7.1 is stable; `ado/*` tool already in use |
| DevOps-Reader (GitHub CLI) | HIGH | `gh` CLI is standard; straightforward read operations |
| WebSearch-Hilfsagent (MS Learn API) | MEDIUM | API is public and documented but rate limits for dev use not formally published |
| Code-Research-Hilfsagent | HIGH | All tools (`vscode_listCodeUsages`, `al_downloadsymbols`) already in framework |
| model: frontmatter support | MEDIUM | VS Code Copilot agent `model:` field support depends on Copilot version; Claude Code supports it fully |

---

## Open Questions / Gaps

1. **VS Code Copilot `model:` frontmatter support** — needs verification against current
   Copilot agent spec. If not supported, the fallback is text-based model hints in the
   Main-Agent's conversation output (lower confidence).

2. **session_store_sql semantics** — the exact durability guarantee of `session_store_sql`
   in VS Code Copilot is not publicly documented. Treat it as conversation-scoped only;
   SESSION.md is the durable layer.

3. **`ado/read` vs `ado/*` scoping** — whether VS Code Copilot allows namespace-scoped
   tool access (`ado/read` vs full `ado/*`) needs testing. If not, the DevOps-Reader's
   read-only constraint must be enforced via agent instructions rather than tool-level
   restriction.

4. **MS Learn API rate limits** — the API is free and undocumented for rate limits.
   The WebSearch-Hilfsagent should implement a fallback to `web_search` if the API
   returns 429. Cache results in `.planning/research/ms-learn-cache/` for repeat queries.

5. **Kunden-Doku-Agent style definitions** — each of the 3 customer agents (Betzold,
   Hermes, Tröber) needs a documented style guide (PR language, formality level, section
   headings). These do not exist yet; gathering them is a phase-1 research task.

---

*Research completed: 2026-06-18 | Consumed by: ROADMAP phase planning*
