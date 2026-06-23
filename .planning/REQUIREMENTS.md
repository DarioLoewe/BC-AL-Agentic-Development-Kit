# Requirements: BC AL Agentic Development Kit

**Defined:** 2026-06-18
**Core Value:** Der Entwickler beschreibt eine Anforderung — der Main-Agent holt alle nötigen Infos, plant, baut, testet und dokumentiert, mit Checkpoint-Zustimmung bei jedem Übergang.

---

## v1 Requirements

### Pre-Phase: Foundations Cleanup

- [ ] **FOUND-01**: `ado/*` Wildcard in `al-auto-dev.agent.md` durch explizite read-only Allowlist ersetzen
- [ ] **FOUND-02**: `AGENTS.md` mit echtem Projektkontext befüllen (Framework-Beschreibung, Agent-Rollen, Policy-Verweis)
- [ ] **FOUND-03**: Policy-Regeln deduplizieren — `agent-policy.md` als Single Source of Truth, Duplikate in Agent-Dateien entfernen
- [ ] **FOUND-04**: Fehlende Prompt-Dateien erstellen: `analyze-work-item.prompt.md`, `explain-build-error.prompt.md`
- [ ] **FOUND-05**: `.gitignore` erstellen mit `debug.log`, `*.log`, `.alpackages/`, `.snapshots/`, `.altestrunner/`
- [ ] **FOUND-06**: `debug.log` aus Repository entfernen
- [ ] **FOUND-07**: Confidence-Rubrik in `agent-policy.md` ergänzen (Beispiele für typische AL-Tasks mit erwarteten Confidence-Werten)
- [ ] **FOUND-08**: Fix-Loop-Eskalationspfad in `agent-policy.md` und `al-build-tester.agent.md` dokumentieren (nach 3 Schleifen: Blocker-Report + Stop)

### Phase 1: Main-Agent + Session State + DevOps-Reader

- [ ] **MAIN-01**: `main-agent.agent.md` — einziger Gesprächspartner, orchestriert alle Spezialisten, antwortet immer nur er
- [ ] **MAIN-02**: Checkpoint-Protokoll — Main-Agent gibt nach jedem Spezialisten-Ergebnis ein strukturiertes `## CHECKPOINT`-Summary aus und wartet auf `ja` / `nein` / `anpassen`
- [ ] **MAIN-03**: 5 Pflicht-Checkpoint-Positionen definiert: nach DevOps-Read, nach Architect, nach Validator, nach Reviewer, bei Confidence < 0.60
- [ ] **MAIN-04**: `.planning/al-workflow/SESSION.md` Schema — persistiert `ticket_id`, `current_step`, `awaiting_checkpoint`, `approved_steps`, `build_fix_loop_count`, Kundenpfad
- [ ] **MAIN-05**: Main-Agent schreibt SESSION.md nach jedem Checkpoint (Cross-Session-Persistenz)
- [ ] **MAIN-06**: Main-Agent liest SESSION.md beim Start — erkennt offene Workflows und bietet Fortsetzung an
- [ ] **DEVOPS-01**: `al-devops-reader.agent.md` — liest GitHub Issues/PRs (GitHub MCP Server) und Azure DevOps Work Items (ADO read-only), gibt strukturiertes Ticket-Summary zurück
- [ ] **DEVOPS-02**: DevOps-Reader ist strikt read-only — keine Write-Operationen, keine State-Änderungen
- [ ] **MODEL-01**: `model:` Frontmatter in allen Agenten-Dateien — Opus 4.x für Main-Agent/Architect/Validator, Sonnet 4.x für alle Ausführungs-Agents
- [ ] **MODEL-02**: Dokumentiertes Modell-Switching-Konzept im Framework (welcher Agent welches Modell, warum)

### Phase 2: Spezialist-Refactoring

- [ ] **ARCH-01**: `al-architect.agent.md` — plant BC-Objekte, Felder, Extensions, Beziehungen auf Basis von Ticket + Symbolinfos
- [ ] **ARCH-02**: Architect liest `app.json` und `.alpackages/` Symbole vor der Planung (BC-Version-Awareness)
- [ ] **ARCH-03**: Architect liefert Aufwandsschätzung (T-Shirt-Size oder Stunden) als Teil des Plans
- [ ] **ARCH-04**: Structured JSON Plan Contract — Architect-Output ist maschinenlesbar (Objekte, Felder, IDs, Methoden) — nicht nur Fließtext
- [ ] **VALID-01**: `al-validator.agent.md` — prüft ob implementierter AL-Code alle Akzeptanzkriterien aus dem Ticket abdeckt
- [ ] **VALID-02**: Validator verwendet 5-Layer-Prüfung: AC→Objekt-Mapping, AL-Konventionen, Test-Coverage, Diff-Verifikation, Korrektur-Trigger
- [ ] **VALID-03**: Validator löst bei Lücken max. 2 Korrekturschleifen aus — danach eskaliert er an Main-Agent mit Blocker-Report
- [ ] **TEST-01**: `al-tester.agent.md` — erstellt und führt AL-Tests durch, nur auf explizite Anforderung
- [ ] **TEST-02**: Tester nutzt GIVEN/WHEN/THEN-Pattern aus `al-testing.instructions.md`
- [ ] **CODER-01**: `al-coder.agent.md` konsolidiert `al-implementer` + Build-Logik — schreibt Code, verwaltet Objekt-IDs, führt Build durch, erstellt Übersetzungen
- [ ] **CONTRACT-01**: Alle Spezialisten liefern strukturierte `## ERGEBNIS`-Blöcke, die Main-Agent für Checkpoint-Summaries parsen kann

### Phase 3: Customer Docs Pipeline

- [ ] **DOCS-01**: `al-docs-coordinator.agent.md` — wählt den richtigen Kunden-Doku-Agent basierend auf AL-Projektpfad (`C:\Users\dloewe\{Kunde}\`)
- [ ] **DOCS-02**: `al-docs-base/SKILL.md` — gemeinsame Doku-Prozedur (PR-Beschreibung, Release Notes, Testhinweise)
- [ ] **DOCS-03**: `al-docs-betzold.agent.md` — Betzold-spezifischer Doku-Stil, PR-Sprache, README-Konventionen
- [ ] **DOCS-04**: `al-docs-hermes.agent.md` — Hermes-spezifischer Doku-Stil *(benötigt Stil-Input vom Entwickler vor Planung)*
- [ ] **DOCS-05**: `al-docs-troeber.agent.md` — Tröber-spezifischer Doku-Stil *(benötigt Stil-Input vom Entwickler vor Planung)*
- [ ] **DOCS-06**: Kunden-Docs-Agents erben Stil aus Kunden-spezifischen Instruction-Files (`.github/instructions/docs-betzold.md` etc.) — nie aus Session-State

### Phase 4: Helper Agents

- [ ] **HELP-01**: `al-websearch.agent.md` — durchsucht MS Learn und Web für AL-Referenzen, API-Doku, BC-Beispiele
- [ ] **HELP-02**: `al-code-research.agent.md` — sucht AL-Symbole, Referenzen, Code-Usages via `al/*` und `vscode_listCodeUsages` Tools
- [ ] **HELP-03**: WebSearch und Code-Research sind Hilfs-Agents (Leaf-Nodes) — werden von Spezialisten aufgerufen, kommunizieren nie direkt mit dem Nutzer
- [ ] **HELP-04**: Dokumentiertes Aufruf-Protokoll: welcher Spezialist kann welchen Helper aufrufen und wann

---

## v2 Requirements

### Erweiterte Automatisierung

- **AUTO-01**: Automatisches ADO-Work-Item-Kommentieren nach Abschluss eines Workflows
- **AUTO-02**: Draft-PR-Erstellung direkt aus dem Main-Agent-Workflow
- **AUTO-03**: Automatische Branch-Erstellung nach Architect-Zustimmung

### Erweiterte Customer Docs

- **DOCS-EXT-01**: Kunden-Doku-Agent für weitere Kunden (on-demand neue Kunden anlegen)
- **DOCS-EXT-02**: Multi-Sprachen-Unterstützung für AL-Captions (DE/EN Strategie)

### BC SaaS / Cloud Support

- **SAAS-01**: SaaS-Konfiguration in `launch.json` Template (Sandbox, OAuth2)
- **SAAS-02**: AppSource-spezifische Validierungen (Access-Properties, dataClassification)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Produktive Deployments / Releases | Keine automatischen Veröffentlichungen — immer menschlicher Review |
| Direkte Commits auf `main`/`master` | Verstößt gegen agent-policy.md |
| Vollautomatische Pipeline ohne Checkpoints | Philosophie ist Human-in-the-Loop |
| Parallele Agent-Ausführung ohne Zustimmung | Sequenziell mit Checkpoints |
| ADO Write-Operationen durch Agents | DevOps-Reader ist read-only |
| AppSource / ISV-Anforderungen | Zunächst OnPrem/SaaS intern |
| LangGraph / AutoGen / CrewAI Runtime | Kein neues Runtime — reine Markdown-Erweiterung |
| Automatisches PR-Merging | Immer menschlicher Approve |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Pre-Phase | Pending |
| FOUND-02 | Pre-Phase | Pending |
| FOUND-03 | Pre-Phase | Pending |
| FOUND-04 | Pre-Phase | Pending |
| FOUND-05 | Pre-Phase | Pending |
| FOUND-06 | Pre-Phase | Pending |
| FOUND-07 | Pre-Phase | Pending |
| FOUND-08 | Pre-Phase | Pending |
| MAIN-01 | Phase 1 | Pending |
| MAIN-02 | Phase 1 | Pending |
| MAIN-03 | Phase 1 | Pending |
| MAIN-04 | Phase 1 | Pending |
| MAIN-05 | Phase 1 | Pending |
| MAIN-06 | Phase 1 | Pending |
| DEVOPS-01 | Phase 1 | Pending |
| DEVOPS-02 | Phase 1 | Pending |
| MODEL-01 | Phase 1 | Pending |
| MODEL-02 | Phase 1 | Pending |
| ARCH-01 | Phase 2 | Pending |
| ARCH-02 | Phase 2 | Pending |
| ARCH-03 | Phase 2 | Pending |
| ARCH-04 | Phase 2 | Pending |
| VALID-01 | Phase 2 | Pending |
| VALID-02 | Phase 2 | Pending |
| VALID-03 | Phase 2 | Pending |
| TEST-01 | Phase 2 | Pending |
| TEST-02 | Phase 2 | Pending |
| CODER-01 | Phase 2 | Pending |
| CONTRACT-01 | Phase 2 | Pending |
| DOCS-01 | Phase 3 | Pending |
| DOCS-02 | Phase 3 | Pending |
| DOCS-03 | Phase 3 | Pending |
| DOCS-04 | Phase 3 | Pending |
| DOCS-05 | Phase 3 | Pending |
| DOCS-06 | Phase 3 | Pending |
| HELP-01 | Phase 4 | Pending |
| HELP-02 | Phase 4 | Pending |
| HELP-03 | Phase 4 | Pending |
| HELP-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 39 individual IDs (8 + 10 + 11 + 6 + 4)
- Mapped to phases: 39
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-18*
*Last updated: 2026-06-18 after initial definition*
