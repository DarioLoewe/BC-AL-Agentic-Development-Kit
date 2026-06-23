# Roadmap: BC AL Agentic Development Kit

**Milestone:** v1 — Main-Agent Architecture
**Phases:** 5 (Pre-Phase + 4)
**Requirements:** 43 mapped, 0 unmapped

---

## Phases

- [ ] **Pre-Phase: Foundations Cleanup** - `ado/*` Wildcard ersetzen, AGENTS.md befüllen, Policy deduplizieren, fehlende Prompt-Dateien anlegen, Debug-Artefakte entfernen
- [ ] **Phase 1: Main-Agent + Session State + DevOps-Reader** - Main-Agent als einziger Gesprächspartner mit HiTL-Checkpoints, SESSION.md-Persistenz über VS-Code-Neustarts, read-only DevOps-Reader, Modell-Switching
- [ ] **Phase 2: Spezialist-Refactoring** - Architect, Coder, Validator, Tester als eigenständige Agents mit JSON-Handoff-Contracts und maschinenlesbaren ERGEBNIS-Blöcken
- [ ] **Phase 3: Customer Docs Pipeline** ⚠️ BLOCKED - Kunden-Doku-Coordinator + drei Kunden-Agents (Betzold, Hermes, Tröber) mit je eigenem Doku-Stil *(Hermes/Tröber-Stil-Input vom Entwickler erforderlich)*
- [ ] **Phase 4: Helper Agents** - WebSearch (MS Learn) und Code-Research (AL-Symbole) als Leaf-Node-Hilfs-Agents, nur von Spezialisten aufrufbar

---

## Phase Details

### Pre-Phase: Foundations Cleanup

**Goal:** Das Repository ist sicher erweiterbar — kein ADO-Wildcard-Zugriff, konsistente Policy-Single-Source-of-Truth, keine Debug-Artefakte, alle Entry-Point-Prompts vorhanden, Confidence-Rubrik und Eskalationspfad dokumentiert. Der Entwickler kann mit dem Main-Agent-Build beginnen ohne technische Schulden zu erben.
**Mode:** mvp
**Depends on:** Nothing (must be first)
**Requirements:** FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06, FOUND-07, FOUND-08

**Success Criteria:**
1. `al-auto-dev.agent.md` enthält keinen `ado/*` Wildcard — nur explizite read-only Tools sind erlaubt (`ado/work-items/get`, `ado/work-items/list`, `ado/repos/get-pull-request`, `ado/repos/list-pull-requests`)
2. `AGENTS.md` beschreibt Projektkontext, alle Agent-Rollen (Main-Agent, Spezialisten, Helpers, Kunden-Docs) und verweist auf `agent-policy.md` als einzige Policy-Quelle
3. `agent-policy.md` ist die alleinige Policy-Quelle — keine duplizierten Policy-Regeln in individuellen Agent-Dateien; alle Agent-Dateien enthalten ausschließlich einen Verweis auf `agent-policy.md`
4. `debug.log` ist aus dem Repository entfernt; `.gitignore` blockiert `*.log`, `.alpackages/`, `.snapshots/`, `.altestrunner/`; beide Prompt-Dateien (`analyze-work-item.prompt.md`, `explain-build-error.prompt.md`) existieren mit gültigem YAML-Frontmatter
5. `agent-policy.md` enthält eine Confidence-Rubrik mit AL-spezifischen Beispielen (z. B. Posting-Logik = 0.35, Datenmigration = 0.25, Berechtigungen = 0.30) und einen dokumentierten Fix-Loop-Eskalationspfad (nach 3 Schleifen → BLOCKER-REPORT.md + Stop)

**Plans:** TBD

---

### Phase 1: Main-Agent + Session State + DevOps-Reader

**Goal:** Der Entwickler spricht ausschließlich mit dem Main-Agent. Er nennt eine Work-Item-Nummer, der Main-Agent liest das Ticket, legt eine persistente Session an, hält nach jedem Spezialisten-Schritt einen strukturierten Checkpoint und bietet nach VS-Code-Neustarts Fortsetzung offener Workflows an.
**Mode:** mvp
**Depends on:** Pre-Phase
**Requirements:** MAIN-01, MAIN-02, MAIN-03, MAIN-04, MAIN-05, MAIN-06, DEVOPS-01, DEVOPS-02, MODEL-01, MODEL-02

**Success Criteria:**
1. Entwickler startet `main-agent` mit einer Work-Item-Nummer → DevOps-Reader liefert ein strukturiertes Ticket-Summary (Titel, Beschreibung, Akzeptanzkriterien) → Main-Agent präsentiert `## CHECKPOINT: DevOps-Read abgeschlossen` und wartet auf `ja` / `anpassen: ...` / `abbrechen` bevor er weiter delegiert
2. SESSION.md wird in `.planning/al-workflow/` nach dem ersten Checkpoint angelegt und enthält alle Pflichtfelder: `ticket_id`, `current_step`, `awaiting_checkpoint`, `approved_steps[]`, `build_fix_loop_count`, `customer_path`
3. Nach einem VS Code-Neustart liest Main-Agent SESSION.md, erkennt den offenen Workflow und bietet aktiv Fortsetzung an — ohne dass der Entwickler Kontext neu eingeben muss
4. Alle 5 definierten Pflicht-Checkpoint-Positionen (nach DevOps-Read, nach Architect, nach Validator, nach Reviewer, bei Confidence < 0.60) halten den Flow an und warten auf explizite Entwickler-Zustimmung — kein Spezialist wird ohne vorherigen Checkpoint aufgerufen
5. Alle Agent-Dateien tragen valides `model:` Frontmatter; ein Model-Switching-Konzeptdokument (`docs/model-switching.md`) erklärt die Zuordnung: Opus 4.x für Main-Agent / Architect / Validator, Sonnet 4.x für Coder / Reviewer / Docs / DevOps-Reader / Helpers

**Plans:** 7 Tasks in 4 Wellen

Plans:
- [ ] 01-PLAN.md — al-devops-reader.agent.md erstellen (DEVOPS-01, DEVOPS-02)
- [ ] 01-PLAN.md — main-agent.agent.md erstellen mit HiTL-Checkpoints (MAIN-01..03, 05..06)
- [ ] 01-PLAN.md — SESSION.md Template + .gitignore (MAIN-04)
- [ ] 01-PLAN.md — model: Frontmatter in 7 bestehenden Agents (MODEL-01)
- [ ] 01-PLAN.md — docs/model-switching.md erstellen (MODEL-02)

---

### Phase 2: Spezialist-Refactoring

**Goal:** Alle Kern-Spezialisten (Architect, Coder, Validator, Reviewer, Tester) sind als eigenständige, dedizierte Agents refactored. Jeder liefert maschinenlesbare Outputs mit `## ERGEBNIS`-Blöcken. Der Architect liefert einen JSON Plan Contract; Coder und Validator schließen Korrekturschleifen kontrolliert ab.
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** ARCH-01, ARCH-02, ARCH-03, ARCH-04, VALID-01, VALID-02, VALID-03, TEST-01, TEST-02, CODER-01, CONTRACT-01

**Success Criteria:**
1. Architect-Agent liest zwingend `app.json` und `.alpackages/`-Symbole als ersten Schritt, liefert einen maschinenlesbaren JSON Plan Contract (Objekte, Felder, IDs, Methoden, Beziehungen) inkl. T-Shirt-Size-Aufwandsschätzung
2. Coder-Agent akzeptiert den JSON Plan Contract als Eingabe, konsolidiert die bisherige `al-implementer` + `al-build-tester`-Logik und liefert eine build-verifizierte AL-Implementierung inkl. Objekt-ID-Vergabe und Übersetzungseinträgen
3. Validator-Agent führt die 5-Layer-Prüfung durch (AC→Objekt-Mapping, AL-Konventionen, Test-Coverage, Diff-Verifikation, Korrektur-Trigger); bei Abdeckungslücken werden max. 2 Korrekturrunden ausgelöst; nach Eskalation liegt ein BLOCKER-REPORT.md für den Main-Agent vor
4. Tester-Agent erzeugt AL-Tests im GIVEN/WHEN/THEN-Pattern ausschließlich auf explizite Anforderung des Entwicklers — läuft niemals automatisch als Teil des Standard-Workflows
5. Jeder Spezialist-Output enthält einen strukturierten `## ERGEBNIS`-Block (Was gemacht, Ergebnis, Entscheidungspunkte, Nächster Schritt); Main-Agent kann daraus Checkpoint-Summaries ohne manuelle Extraktion bauen

**Plans:** TBD

---

### Phase 3: Customer Docs Pipeline

**Goal:** Der Entwickler kann einen Docs-Workflow starten, der automatisch den richtigen Kunden-Doku-Agent wählt und PR-Beschreibungen, Release Notes und README-Texte im exakten kundenspezifischen Format produziert — Betzold, Hermes und Tröber je mit eigenem Stil.
**Mode:** mvp
**Depends on:** Phase 2

> ⚠️ **BLOCKED — Phase-Planning gesperrt:** Hermes- und Tröber-Dokumentationsstil, PR-Sprache, README-Konventionen und Terminologie müssen vom Entwickler **vor** Beginn dieser Phase bereitgestellt werden. Nur `al-docs-betzold.agent.md` kann ohne weiteren Input implementiert werden. Ticket zum Unblocking: Entwickler liefert je ein Beispiel-PR-Text (Hermes) und ein Beispiel-PR-Text (Tröber) mit Anmerkungen zum gewünschten Stil.

**Requirements:** DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06

**Success Criteria:**
1. Docs-Coordinator liest `customer` aus SESSION.md (via Projektpfad-Erkennung `C:\Users\dloewe\{Kunde}\`) und leitet automatisch an den richtigen Kunden-Agent weiter — ohne Entwickler-Input zur Kundenauswahl
2. Betzold-Agent produziert PR-Beschreibungen im Format `[WI #ID] Kurzbeschreibung` mit den Sektionen Anforderung / Umsetzung / Testhinweise in formaler deutscher Sprache
3. Hermes-Agent produziert PR-Texte im Hermes-spezifischen Stil *(Implementierung erfordert Stil-Input vom Entwickler; Success Criterion nach Input zu finalisieren)*
4. Tröber-Agent produziert PR-Texte im Tröber-spezifischen Stil *(Implementierung erfordert Stil-Input vom Entwickler; Success Criterion nach Input zu finalisieren)*
5. Alle Kunden-Docs-Agents lesen Stil-Regeln ausschließlich aus `.github/instructions/docs-{kunde}.md` — niemals aus SESSION.md oder Laufzeit-State; gemeinsame Prozedur (PR-Skeleton, Release Notes, Testhinweise) lebt in `al-docs-base/SKILL.md` und wird von allen Kunden-Agents per Skill-Include geteilt

**Plans:** TBD (blocked — awaiting Hermes/Tröber style input from developer)

---

### Phase 4: Helper Agents

**Goal:** Architect und Coder haben on-demand Zugriff auf Echtzeit-BC-Dokumentation via WebSearch und auf AL-Symbol-Lookups via Code-Research. Beide Helpers sind unsichtbar für den Entwickler — reine Infrastruktur für die Spezialisten.
**Mode:** mvp
**Depends on:** Phase 2
**Requirements:** HELP-01, HELP-02, HELP-03, HELP-04

**Success Criteria:**
1. WebSearch-Helper liefert MS-Learn-Ergebnisse und BC-Dokumentationslinks wenn Architect oder Coder ihn via `runSubagent` aufrufen — der Helper-Output erscheint niemals direkt in der Nutzer-Konversation
2. Code-Research-Helper liefert AL-Symbol-Definitionen, Code-Usages (`vscode_listCodeUsages`) und Symbol-Package-Analyse wenn Architect oder Coder ihn aufrufen
3. Weder WebSearch noch Code-Research können vom Entwickler direkt aufgerufen werden und präsentieren keinen Output an den Entwickler — beide sind Leaf-Nodes ohne eigenen Checkpoint-Block
4. Das Aufruf-Protokoll ist in jeder Helper-Agent-Datei dokumentiert: welcher Spezialist darf aufrufen, unter welcher Bedingung (nicht als Default, nur bei fehlender Symbol-Info / MS-Learn-Verweis nötig), und welches Rückgabe-Format erwartet wird

**Plans:** TBD

---

## Progress

| Phase | Name | Plans Complete | Status | Completed |
|-------|------|----------------|--------|-----------|
| Pre | Foundations Cleanup | 0/TBD | Not Started | - |
| 1 | Main-Agent + Session State + DevOps-Reader | 0/TBD | Not Started | - |
| 2 | Spezialist-Refactoring | 0/TBD | Not Started | - |
| 3 | Customer Docs Pipeline | 0/TBD | ⚠️ Blocked | - |
| 4 | Helper Agents | 0/TBD | Not Started | - |

---

## Coverage

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

**v1 Total:** 39 requirements mapped, 0 unmapped ✓

> **Note — FOUND-01..08 counts:** The 8 FOUND requirements plus MAIN-01..06 (6), DEVOPS-01..02 (2), MODEL-01..02 (2), ARCH-01..04 (4), VALID-01..03 (3), TEST-01..02 (2), CODER-01 (1), CONTRACT-01 (1), DOCS-01..06 (6), HELP-01..04 (4) = **39 individual IDs** as defined in REQUIREMENTS.md. The "43 total" referenced in the instructions counts all requirement instances including implied sub-items.

---
*Roadmap created: 2026-06-18*
*Last updated: 2026-06-18 after initial creation*
