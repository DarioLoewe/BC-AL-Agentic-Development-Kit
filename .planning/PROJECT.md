# BC AL Agentic Development Kit

## What This Is

Ein agentic Coding-Framework für Business Central AL-Entwicklung. Der Entwickler spricht ausschließlich mit einem **Main-Agent**, der als Orchestrator fungiert und alle Spezialisten im Hintergrund koordiniert. Jeder Schritt wird mit dem Nutzer abgestimmt — kein Fire-and-Forget, sondern ein echter Human-in-the-Loop-Dialog.

## Core Value

Der Entwickler beschreibt eine Anforderung — der Main-Agent holt alle nötigen Infos, plant, baut, testet und dokumentiert, mit Checkpoint-Zustimmung bei jedem Übergang.

## Business Context

- **Nutzer**: AL-Entwickler (Dario Löwe) bei Kunden-Projekten (Betzold, Hermes, Tröber)
- **Kontext**: Interne Entwicklungseffizienz — nicht AppSource/SaaS
- **Erfolgsmetrik**: Ein vollständiges Feature (Ticket→Code→PR) ohne direkten AL-Eingriff des Entwicklers

## Requirements

### Validated

<!-- Bereits vorhandene Capabilities aus dem Codebase-Map -->

- ✓ AL-Agent-Orchestrierung via `al-auto-dev` (Planner→Analyst→Implementer→Tester→Reviewer→Documenter) — existing
- ✓ AL-Codeanalyse mit `al-codebase-analyst` (Objekte, Events, Abhängigkeiten finden) — existing
- ✓ AL-Planung mit `al-planner` (Anforderung→technischer Plan) — existing
- ✓ AL-Implementierung mit `al-implementer` (AL-Code schreiben, Build) — existing
- ✓ AL Build/Diagnostics-Validierung mit `al-build-tester` (max. 3 Fix-Schleifen) — existing
- ✓ AL Code Review mit `al-reviewer` (Qualität, Upgradefähigkeit, BC-Konventionen) — existing
- ✓ AL Dokumentation mit `al-documenter` (PR-Beschreibung, Release Notes) — existing
- ✓ Policy-geregeltes Agent-Verhalten (`agent-policy.md` — Confidence, Stop-Rules, Blocker) — existing
- ✓ GSD Planungs-Workflow (70+ Skills, Phasen, Roadmap, Execute) — existing
- ✓ AL Coding Standards, Testing- und Review-Instructions — existing

### Active

<!-- Zielarchitektur: Main-Agent + Spezialisten + Kunden-Doku-Agents -->

- [ ] **Main-Agent** als einziger Gesprächspartner — orchestriert alle Spezialisten, antwortet nur er
- [ ] **Human-in-the-Loop Checkpoint-System** — Main-Agent fasst Ergebnis jedes Spezialisten zusammen und wartet auf Zustimmung bevor weiter delegiert wird
- [ ] **Modell-Switching** — Opus 4.8→4.6 für Analyse/Planung, Sonnet 4.6 für Ausführung
- [ ] **Session-Persistenz** — Main-Agent erinnert sich workflowübergreifend wo man gerade steht (Ticket, Schritt, Status)
- [ ] **DevOps-Reader** — read-only Spezialist für GitHub Issues/PRs und Azure DevOps Work Items
- [ ] **Architect-Agent** — plant Objekte, Felder, Extensions + Aufwandsschätzung
- [ ] **Coder-Agent** — schreibt AL-Code, vergibt IDs, führt Build aus, verwaltet Übersetzungen
- [ ] **Reviewer-Agent** — read-only Qualitätsprüfung nach BC-Konventionen
- [ ] **Tester-Agent** — AL- und AI-Tests, nur auf Anforderung
- [ ] **Validator-Agent** — prüft Anforderungsabdeckung, Korrekturschleife bei Lücken
- [ ] **Docs-Agent** — Dokumentationskoordinator, nur auf Anforderung
- [ ] **Kunden-Doku-Agents** — je ein Agent pro Kunde (Betzold, Hermes, Tröber) mit individuellem Doku-Stil, PR-Texten, README-Sprache
- [ ] **WebSearch-Hilfsagent** — Microsoft Learn / Web-Suche für Spezialisten
- [ ] **Code-Research-Hilfsagent** — AL-Symbole, Referenzen, MS-Beispiele für Architect/Coder

### Out of Scope

- Produktive Deployments und Releases — keine automatischen Veröffentlichungen, immer menschlicher Review
- Direkte Commits auf `main` / `master` — verstößt gegen agent-policy.md
- Vollautomatische Pipeline ohne Nutzer-Checkpoints — Philosophie ist Human-in-the-Loop
- AppSource / ISV-spezifische Anforderungen (dataClassification Enforcement, Access-Properties) — zunächst OnPrem/SaaS intern
- Parallele Agent-Ausführung ohne Zustimmung — sequenziell mit Checkpoints

## Context

- Repository ist das Framework-Repo; AL-Extensions entstehen als Geschwister-Ordner außerhalb
- Vorhandene Basis: `al-auto-dev` als Orchestrator mit 6 Unter-Agenten — aber fire-and-forget, kein echtes Gespräch
- GSD v1.5.0 als Planungs-Workflow-Engine installiert
- Zielarchitektur (Bild): Main-Agent (Opus→Sonnet) → 7 Spezialisten → Projekt-Doku-Agents (3 Kunden) + Hilfs-Agents (WebSearch, Code-Research)
- Entwicklungsumgebung: Windows, VS Code + AL Extension, Node.js, PowerShell
- Kunden: Betzold, Hermes, Tröber — je eigene Doku-Konventionen

## Constraints

- **Policy**: agent-policy.md hat höchste Priorität — Confidence-Rules, Stop-Rules, Blocker-Verhalten nicht verhandelbar
- **AL-Scope**: Extensions immer außerhalb des Framework-Repos in `C:\Users\dloewe\{Kunde}\{ExtensionName}\`
- **Human Gate**: Kein Schritt ohne explizite Nutzer-Zustimmung — der Main-Agent darf nicht autonom durchlaufen
- **No Secrets**: Keine Credentials in Dateien, keine produktiven Kundendaten in Prompts
- **Kein direkter main-Commit**: Alles über Feature-Branch + Draft-PR

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Main-Agent als einziger Gesprächspartner | Nutzer soll sich nicht um Spezialisierung kümmern müssen | — Pending |
| Human-in-the-Loop nach jedem Delegations-Schritt | Kontrolle über Planung/Code ohne direkten Eingriff | — Pending |
| Kunden-Doku-Agents nur für Stil, nicht für Code-Konventionen | Code-Standards sind framework-weit einheitlich | — Pending |
| DevOps-Reader is read-only | Tickets/PRs nur lesen, nie schreiben — Sicherheit | — Pending |
| Modell-Switching Opus→Sonnet | Kosten/Qualität optimieren — teures Modell nur wo nötig | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-18 after initialization*
