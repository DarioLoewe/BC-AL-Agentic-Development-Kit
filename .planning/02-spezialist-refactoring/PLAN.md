# Phase 2: Spezialist-Refactoring — Plan

**Phase:** 2
**Goal:** Alle Kern-Spezialisten (Architect, Coder, Validator, Reviewer, Tester) sind als
eigenständige, dedizierte Agents refactored. Jeder liefert maschinenlesbare Outputs mit
`## ERGEBNIS`-Blöcken. Der Architect liefert einen JSON Plan Contract; Coder und Validator
schließen Korrekturschleifen kontrolliert ab.
**Created:** 2026-06-18
**Granularity:** fine (11 Tasks, 4 Wellen)
**Research:** `.planning/02-spezialist-refactoring/RESEARCH.md` (HIGH confidence, all findings
based on direct codebase analysis)

---

## Dateien-Übersicht

| Aktion | Datei | Requirements |
|--------|-------|-------------|
| CREATE | `.github/instructions/ergebnis-contract.instructions.md` | CONTRACT-01 |
| CREATE | `.github/agents/al-architect.agent.md` | ARCH-01..04, CONTRACT-01 |
| CREATE | `.github/agents/al-coder.agent.md` | CODER-01, CONTRACT-01 |
| CREATE | `.github/agents/al-validator.agent.md` | VALID-01..03, CONTRACT-01 |
| CREATE | `.github/agents/al-tester.agent.md` | TEST-01..02, CONTRACT-01 |
| MODIFY | `.github/agents/al-reviewer.agent.md` | CONTRACT-01 |
| MODIFY | `.github/agents/main-agent.agent.md` | Alle (Orchestrierung) |
| MODIFY | `.planning/al-workflow/SESSION.md` | ARCH-04, VALID-03, TEST-01 |
| MODIFY | `.github/agents/al-planner.agent.md` | Backward Compat |
| MODIFY | `.github/agents/al-implementer.agent.md` | Backward Compat |
| MODIFY | `.github/agents/al-build-tester.agent.md` | Backward Compat |
| MODIFY | `AGENTS.md` | Roster-Update |
| CREATE | `.planning/02-spezialist-refactoring/verify-phase-2.ps1` | Alle |

---

## Wave Structure

### Wave 1 — Neue Spezialisten-Agents (alle parallel)

T1, T2, T3, T4, T5 können gleichzeitig ausgeführt werden — keine Datei-Konflikte.

### Wave 2 — Orchestrator & Session Update (parallel)

T6, T7, T8 setzen auf den in Wave 1 definierten Agent-Namen und ERGEBNIS-Templates auf.
Benötigen Wave 1 als konzeptionelle Voraussetzung, aber keine harten File-Locks.

### Wave 3 — Cleanup & Dokumentation (parallel)

T9 (Deprecation) und T10 (AGENTS.md) sind unabhängig und können parallel laufen.

### Wave 4 — Verifikation

T11 schreibt und führt das PowerShell-Verifikationsskript aus. Setzt Wave 1–3 voraus.

---

## Tasks

---

### T1: ERGEBNIS-Contract Instructions File erstellen

**Wave:** 1
**Requirements:** CONTRACT-01
**Datei:** `.github/instructions/ergebnis-contract.instructions.md` (CREATE)

**Beschreibung:**

Erstelle `.github/instructions/ergebnis-contract.instructions.md` als kanonische Referenz
für das `## ERGEBNIS`-Block-Format. Alle Phase-2-Agents referenzieren dieses Format.

Die Datei muss folgendes enthalten:

**Frontmatter:**
```yaml
---
description: ERGEBNIS-Block-Standard für alle BC AL Agentic Development Kit Agents
applyTo: ".github/agents/*.agent.md"
---
```

**Abschnitt 1: Zweck**

Erklärt, dass alle Agents mit `## ERGEBNIS — {Agent-Name}` enden müssen. Main-Agent
scannt für diesen Header und baut daraus den Checkpoint-Block. Abweichende Casing oder
Leerzeichen brechen das Parsing.

**Abschnitt 2: Header-Regel (verbindlich)**

- Header MUSS exakt sein: `## ERGEBNIS — {Agent-Name}` (H2, Gedankenstrich mit Leerzeichen)
- Beispiele: `## ERGEBNIS — Architect`, `## ERGEBNIS — Coder`, `## ERGEBNIS — Validator`
- Kein `##ERGEBNIS`, kein `## Ergebnis`, kein `## ERGEBNIS — ` ohne Agent-Namen

**Abschnitt 3: Pflicht-Footer für alle Agents**

Jeder ERGEBNIS-Block endet mit:
```
### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: {Agent-Name} — {1 Satz was er tun wird}
- Offene Fragen: {oder "Keine"}
```

**Abschnitt 4: Templates pro Agent (als Referenz)**

Füge die vollständigen Templates für alle 5 Agents aus RESEARCH.md §2.3 ein:

*Template al-architect:*
```markdown
## ERGEBNIS — Architect

**Ticket-ID:** {WI-ID}
**BC-Version:** {runtime + application aus app.json}
**Symbol-Status:** Geladen ✓ | Fehler: {Details}
**Aufwandsschätzung:** {XS|S|M|L|XL} — {Begründung in 1 Satz}
**contract_path:** `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json`

### JSON Plan Contract
```json
{ ... vollständiger Contract ... }
```

### Annahmen
- {Annahme 1}

### Risiken
- {Risiko 1}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-coder — implementiert JSON Plan Contract
- Offene Fragen: {oder "Keine"}
```

*Template al-coder:*
```markdown
## ERGEBNIS — Coder

**Ticket-ID:** {WI-ID}
**Plan Contract Version:** {plan_contract_version aus Contract}

### Implementierte Objekte
| Objekt | Typ | Aktion | Datei |
|--------|-----|--------|-------|
| {Name} | {tableextension|...} | erstellt|erweitert | {Pfad} |

### Build-Ergebnis
- Status: ✓ Erfolgreich | ✗ Fehler | 🚨 BLOCKER
- Fix-Schleifen: {0|1|2|3}
- Diagnostics: {Warnungen / Fehler}

### Übersetzungseinträge
- {de-DE Einträge oder "Keine neuen"}

### Geänderte Dateien
- {Pfad 1}

### Offene Punkte
- {oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-validator — prüft AC-Abdeckung
- Offene Fragen: {oder "Keine"}
```

*Template al-validator:*
```markdown
## ERGEBNIS — Validator

**Ticket-ID:** {WI-ID}
**Korrekturschleifen:** {0|1|2} von max. 2

### 5-Layer Prüfung
| Layer | Prüfpunkt | Status | Detail |
|-------|-----------|--------|--------|
| 1 | AC→Objekt-Mapping | ✓ OK | Alle ACs abgedeckt |
| 2 | AL-Konventionen | ✓ OK | Labels, DataClassification gesetzt |
| 3 | Test-Coverage | ⚠ Lücke | Kein Test für AC-3 |
| 4 | Diff-Verifikation | ✓ OK | Alle Änderungen im Diff |
| 5 | Korrektur-Trigger | — | Keine Lücken → kein Trigger |

### AC-Abdeckung
| AC | Objekt | Status |
|----|--------|--------|
| AC-1 | {Objekt} | ✓ |

### Offene Lücken
- {oder "Keine"}

### Interpretation für Main-Agent
- Gesamtstatus: Freigabe | Korrektur erforderlich | BLOCKER
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer | al-coder (Korrektur) | ESKALATION
- Offene Fragen: {oder "Keine"}
```

*Template al-reviewer:*
```markdown
## ERGEBNIS — Reviewer

**Ticket-ID:** {WI-ID}
**Review-Status:** Freigabe | Änderungen notwendig | Blocker

### Prüfergebnis
| Kriterium | Status | Hinweis |
|-----------|--------|---------|
| Upgradefähigkeit | ✓ | Events genutzt |
| AL-Best-Practices | ✓ | Labels gesetzt |
| Performance | ⚠ | SetLoadFields prüfen |
| Fehlerbehandlung | ✓ | — |
| Testbarkeit | ✓ | — |
| Berechtigungen | ⚠ | PermissionSet fehlt |
| Labels | ✓ | — |
| Keine unnötigen COMMITs | ✓ | — |

### Blocker
- {oder "Keine"}

### Verbesserungsvorschläge
- {oder "Keine"}

### Testlücken
- {oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-documenter | Blocker → Entwickler
- Offene Fragen: {oder "Keine"}
```

*Template al-tester:*
```markdown
## ERGEBNIS — Tester

**Ticket-ID:** {WI-ID}
**Test-Modus:** AL-Test-Codeunit | Manuelle Testhinweise | Beides

### Erstellte Tests
| Testmethode | Typ | Abgedecktes AC |
|-------------|-----|----------------|
| {DescriptiveName} | Automatisiert | AC-{N} |

### Test-Datei
- Pfad: {src/Tests/...Test.al}

### GIVEN/WHEN/THEN Zusammenfassung
{Für jeden Test ein Kurzblock: [GIVEN] / [WHEN] / [THEN]}

### Nicht abdeckbare Testfälle
- {und Begründung, oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer (falls noch nicht erfolgt)
- Offene Fragen: {oder "Keine"}
```

**Verification:**
- [ ] `.github/instructions/ergebnis-contract.instructions.md` existiert
- [ ] Datei enthält `## ERGEBNIS` als Header-Pattern-Dokumentation
- [ ] Alle 5 Templates (Architect, Coder, Validator, Reviewer, Tester) enthalten
- [ ] `### Interpretation für Main-Agent` Footer in allen Templates vorhanden

**Commit:** `feat(phase-2): ERGEBNIS contract instructions — CONTRACT-01`

---

### T2: al-architect.agent.md erstellen

**Wave:** 1
**Requirements:** ARCH-01, ARCH-02, ARCH-03, ARCH-04, CONTRACT-01
**Datei:** `.github/agents/al-architect.agent.md` (CREATE)

**Beschreibung:**

Erstelle `.github/agents/al-architect.agent.md`. Der Architect ist der erste Spezialist
nach dem DevOps-Reader. Er liest die BC-Umgebung, analysiert den technischen Scope und
erzeugt den maschinenlesbaren JSON Plan Contract — nicht mehr Fließtext wie al-planner.

**Frontmatter (exakt):**
```yaml
---
name: al-architect
model: claude-opus-4
description: >
  Plant BC-Objekte, Felder, Extensions und Beziehungen auf Basis von Ticket + BC-Symbolen.
  Gibt einen maschinenlesbaren JSON Plan Contract zurück. Ersetzt al-planner ab Phase 2.
tools: ["read", "search"]
agents:
  - al-codebase-analyst
skills:
  - al-object-analysis
  - al-devops-workitem
  - al-build-validation
---
```

**Hinweis zu `terminal`:** Der Architect hat KEIN `terminal`-Tool. Symbol-Downloads
werden über die `al-build-validation`-Skill orchestriert, nicht über direkten Terminal-Zugriff.

**Abschnitt: Verbindliche Policy**

```
Lies und befolge immer: `.github/policies/agent-policy.md`
Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.
```

**Abschnitt: Aufgabe**

Erstelle aus Ticket-Inhalt + BC-Symbolen einen vollständigen JSON Plan Contract, der
`al-coder` als strukturierte Implementierungsgrundlage dient. Der Plan Contract beseitigt
Fließtext-Ambiguität: Objekt-IDs, Feldtypen, DataClassification, Captions sind explizit.

**Abschnitt: Verbote (absolut)**

- Kein AL-Code schreiben
- Keine Dateien im Kundenprojekt anlegen oder ändern
- Keine Annahmen zu Base-Objekten machen ohne Symbol-Prüfung
- BC-Version nicht annehmen — immer aus app.json lesen

**Abschnitt: Schritt-für-Schritt-Protokoll (PFLICHT-REIHENFOLGE)**

**Schritt 0 — BC-Version-Awareness (MUSS vor allem anderen erfolgen):**
1. Lese `{customer_path}/app.json` (customer_path aus SESSION.md)
2. Extrahiere: `runtime`, `application`, `platform`, `idRanges`
3. BC-Runtime-Guard: Wenn `runtime < 10.0` → SOFORT STOPP mit ERGEBNIS:
   `Confidence: 0.00, BC-Version zu alt für Agentic-Workflow`
4. Liste alle `.app`-Dateien in `{customer_path}/.alpackages/` auf
5. Notiere Symbol-Status im ERGEBNIS-Block

**Schritt 1 — Symbol-Download:**
- Rufe `al-build-validation`-Skill auf für `al_downloadsymbols`
- Wenn Symbole nicht ladbar (kein launch.json, Server nicht erreichbar):
  Notiere im ERGEBNIS: `Symbol-Status: Fehler — {Details}`
  Fahre mit Warnung fort (kein harter Stop außer BC-Version-Guard)

**Schritt 2 — Bestehende Objekte und ID-Vergabe:**
- Suche alle `.al`-Dateien im Kundenprojekt (`{customer_path}/src/`)
- Finde den höchsten verwendeten Objekt-ID-Wert pro Typ
- `proposed_id` = höchster_verwendeter_ID + 1 (innerhalb von `idRanges`)
- Falls `idRanges` in app.json fehlt: Annahme 50100+ dokumentieren

**Schritt 3 — Fachliche Analyse:**
- Lese Ticket-Summary und Akzeptanzkriterien aus SESSION.md
- Prüfe für jede geplante Tabelle: Gibt es ein Standard-BC-Äquivalent?
  (→ Verwende tableextension statt neue Tabelle, per al-coding-standards.instructions.md)
- Identifiziere alle benötigten AL-Objekte, Felder, Methoden, Beziehungen

**Schritt 4 — JSON Plan Contract erstellen:**

Schreibe Contract nach `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json`.
Schreibe Pfad in ERGEBNIS als `contract_path`.

JSON-Schema (alle Felder MÜSSEN ausgefüllt sein — keine optionalen Felder weglassen):

```json
{
  "plan_contract_version": "1.0",
  "ticket_id": "WI-{ID}",
  "ticket_title": "{Titel}",
  "bc_version": {
    "runtime": "{aus app.json}",
    "application": "{aus app.json}",
    "platform": "{aus app.json}"
  },
  "effort": {
    "size": "{XS|S|M|L|XL}",
    "hours_estimate": "{Bereich}",
    "rationale": "{1 Satz Begründung}"
  },
  "confidence": 0.00,
  "objects": [
    {
      "id": "contract_obj_1",
      "type": "{table|tableextension|page|pageextension|codeunit|report|reportextension|enum|enumextension|permissionset}",
      "proposed_id": 50100,
      "name": "{Objekt-Name}",
      "extends": "{Basis-Objekt oder null}",
      "file_path": "src/{Unterordner}/{Name}.{Type}.al",
      "action": "{create|modify}",
      "fields": [
        {
          "id": 50100,
          "name": "{Feldname}",
          "type": "{Boolean|Code[50]|Text[100]|Decimal|Integer|Date|...}",
          "caption": "{DE-Caption}",
          "data_classification": "{CustomerContent|SystemMetadata|EndUserIdentifiableInformation|...}",
          "tooltip": "{DE-Tooltip-Text}"
        }
      ],
      "keys": [],
      "triggers": [],
      "methods": [],
      "controls": []
    }
  ],
  "codeunits": [],
  "enums": [],
  "permission_sets": [],
  "translations": [
    {
      "language": "de-DE",
      "entries": []
    }
  ],
  "dependencies": [],
  "assumptions": [],
  "risks": [],
  "out_of_scope": []
}
```

**Pflicht-Checkliste vor Contract-Speicherung:** Der Architect muss sicherstellen:
- [ ] Jedes neue Tabellenfeld hat `caption`, `data_classification`, `tooltip`
- [ ] Jede PageExtension-Control hat `application_area`
- [ ] Jedes Objekt hat `proposed_id` innerhalb des `idRanges`-Bereichs
- [ ] `out_of_scope` enthält explizit was NICHT implementiert wird

**Abschnitt: T-Shirt-Sizing-Rubrik (ARCH-03)**

| Größe | Stunden | Typischer AL-Task | Confidence-Anker |
|-------|---------|-------------------|-----------------|
| XS | < 1h | Caption/Label-Text ändern | 0.95 |
| S | 1–4h | Feld zu TableExtension, PageControl hinzufügen | 0.85–0.90 |
| M | 4–8h | FlowField/FlowFilter, neues Objekt ohne Buchungslogik | 0.75–0.80 |
| L | 8–16h | Neue Tabelle, komplexe Codeunit, Schnittstelle | 0.40–0.70 |
| XL | > 16h | Buchungslogik, Datenmigration, Berechtigungen komplex | 0.25–0.39 |

Wenn `confidence < 0.60`: Markiere Contract mit
`"confidence_warning": "CP-5 — Confidence unter Schwellwert — Entwickler-Bestätigung vor al-coder erforderlich"`

**Abschnitt: ERGEBNIS (OUTPUT)**

Verwende exakt das Template aus `.github/instructions/ergebnis-contract.instructions.md`
(Template: al-architect). Pflichtfelder im ERGEBNIS:
- `BC-Version`, `Symbol-Status`, `Aufwandsschätzung`, `contract_path`
- `Confidence` (auch für CP-5-Trigger in main-agent)

**Verification:**
- [ ] `.github/agents/al-architect.agent.md` existiert
- [ ] Frontmatter hat `model: claude-opus-4` und tools `["read", "search"]`
- [ ] Schritt 0 liest explizit `app.json` (ARCH-02)
- [ ] Schritt 0 listet `.alpackages/` auf (ARCH-02)
- [ ] T-Shirt-Sizing-Rubrik (XS/S/M/L/XL) ist im Dokument (ARCH-03)
- [ ] JSON Plan Contract Schema mit `plan_contract_version`, `objects`, `fields`, `proposed_id` (ARCH-04)
- [ ] Contract wird nach `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json` geschrieben (ARCH-04)
- [ ] `## ERGEBNIS — Architect` Header vorhanden (CONTRACT-01)
- [ ] ERGEBNIS enthält `contract_path` Feld (CONTRACT-01)

**Commit:** `feat(phase-2): al-architect.agent.md — JSON Plan Contract + BC-Version-Awareness (ARCH-01, ARCH-02, ARCH-03, ARCH-04, CONTRACT-01)`

---

### T3: al-coder.agent.md erstellen

**Wave:** 1
**Requirements:** CODER-01, CONTRACT-01
**Datei:** `.github/agents/al-coder.agent.md` (CREATE)

**Beschreibung:**

Erstelle `.github/agents/al-coder.agent.md`. Dieser Agent konsolidiert `al-implementer`
(Code schreiben) und `al-build-tester` (Build, Diagnostics, Fix-Schleifen) in einem
einzigen Agenten. Akzeptiert den JSON Plan Contract als strukturierte Eingabe.

**Frontmatter (exakt):**
```yaml
---
name: al-coder
model: claude-sonnet-4-5
description: >
  Implementiert AL-Code auf Basis eines JSON Plan Contracts. Konsolidiert al-implementer
  und al-build-tester. Schreibt Code, verwaltet Objekt-IDs, führt Build durch,
  erstellt Übersetzungseinträge. Ersetzt al-implementer und al-build-tester ab Phase 2.
tools: ["read", "search", "edit", "terminal"]
skills:
  - al-object-analysis
  - al-build-validation
---
```

**Abschnitt: Verbindliche Policy**
`Lies und befolge immer: .github/policies/agent-policy.md`

**Abschnitt: Aufgabe**

Setze den JSON Plan Contract von al-architect in lauffähigen, build-verifizierten AL-Code um.
Kein eigenes fachliches Design — folge dem Contract präzise.

**Abschnitt: Verbote (absolut)**
- Keine Codeänderungen die nicht im JSON Plan Contract stehen
- Keine Annahmen zu BC-Objekten ohne vorherigen Symbol-Download (Schritt 0)
- Credentials (Benutzername/Passwort) niemals selbst in Dateien schreiben oder ausgeben
- Keine großen Refactorings ohne explizite Anforderung (von al-implementer geerbt)

**Abschnitt: Schritt-für-Schritt-Protokoll**

**Schritt 0 — JSON Plan Contract lesen:**
1. Lese `architect_contract_path` aus SESSION.md
2. Lese den JSON Contract von diesem Pfad
3. Wenn Contract nicht lesbar: STOPP mit ERGEBNIS `Confidence: 0.00, Contract nicht lesbar`
4. Extrahiere: `ticket_id`, `bc_version`, `objects`, `effort`, `idRanges` (aus `app.json`
   im Contract oder erneut aus `{customer_path}/app.json`)

**Schritt 1 — Symbol-Download (PFLICHT vor Code-Schreiben):**
- Prüfe ob `.vscode/launch.json` existiert und valide BC-Server-Konfiguration hat
- Falls kein launch.json: Frage Entwickler nach Server-URL, Instanz, Auth-Typ
  Lege launch.json an (ohne Credentials)
- Führe `al_downloadsymbols` aus
- Bei Fehler: STOPP — kein Code ohne Symbole

**Schritt 2 — Objekt-ID-Verifikation:**
- Durchsuche alle `.al`-Dateien im Kundenprojekt nach `proposed_id`-Werten aus dem Contract
- Wenn ID bereits verwendet: ERGEBNIS-Notiz + nächste freie ID ermitteln
- Dokumentiere finale verwendete IDs im ERGEBNIS-Block

**Schritt 3 — Code schreiben:**
- Erstelle für jedes Contract-Objekt eine separate `.al`-Datei (ein Objekt pro Datei)
- Dateiname-Konvention aus `al-coding-standards.instructions.md`:
  `{Name}.{ObjectTypeShort}.al`
  Beispiele: `VendorExt.TableExt.al`, `SalesOrderExt.PageExt.al`, `SalesValidationMgt.Codeunit.al`
- Alle sichtbaren Texte als Labels (Caption, ToolTip, Error, Message)
- DataClassification für alle neuen Tabellenfelder (aus Contract)
- ApplicationArea für alle Page-Controls (aus Contract)
- Businesslogik NICHT in Page-Triggern — in Codeunits auslagern

**Schritt 4 — Build + Diagnostics:**
- `al_build` ausführen
- `al_getdiagnostics` auswerten
- Bei Fehlern: Fix-Schleife starten (max. 3 gemäß `agent-policy.md § Fix-Loop-Eskalation`)

**Fix-Schleife-Protokoll (max. 3 — aus agent-policy.md):**
```
Schleife 1-3:
  1. Code-Fehler analysieren (al_getdiagnostics)
  2. Minimale Korrektur durchführen (edit)
  3. al_build → al_getdiagnostics
  4. Wenn keine Fehler mehr → weiter mit Schritt 5
  5. Wenn noch Fehler → nächste Schleife

Nach Schleife 3 mit verbleibenden Fehlern:
  1. STOP — kein weiterer Code wird geändert
  2. Erstelle .planning/al-workflow/BLOCKER-REPORT.md mit:
     - Ticket-ID und Workflow-Schritt
     - Vollständige Fehlermeldungen (al_getdiagnostics Output)
     - Protokoll der 3 Korrekturversuche
     - Empfohlene manuelle Eingriffspunkte
  3. ERGEBNIS: Confidence = 0.00, Build-Status = BLOCKER
  4. Warte auf explizite Freigabe
```

**Schritt 5 — Übersetzungseinträge:**
- Prüfe ob `{customer_path}/translations/` Verzeichnis und `*.g.xlf` existieren
- Falls ja: Scanne `.g.xlf` nach neuen Einträgen von Caption/ToolTip-Labels
- Kopiere Einträge in Zielsprach-`.xlf` (z.B. `de-DE.xlf`) mit deutschen Übersetzungen
- Falls keine `.xlf`-Infrastruktur: Im ERGEBNIS notieren, KEIN automatisches Erstellen
- Dokumentiere alle neuen Übersetzungseinträge im ERGEBNIS-Block

**Abschnitt: ERGEBNIS (OUTPUT)**

Verwende exakt das Template aus `.github/instructions/ergebnis-contract.instructions.md`
(Template: al-coder). Pflichtfelder:
- `Build-Ergebnis` mit Status (✓/✗/BLOCKER), Fix-Schleifen-Zähler, Diagnostics-Zusammenfassung
- `Implementierte Objekte` als Tabelle (Objekt, Typ, Aktion, Datei)
- `Übersetzungseinträge`
- `Geänderte Dateien` (vollständige Pfade)

**Verification:**
- [ ] `.github/agents/al-coder.agent.md` existiert
- [ ] Frontmatter hat `model: claude-sonnet-4-5` und tools `["read", "search", "edit", "terminal"]`
- [ ] Liest JSON Plan Contract aus `architect_contract_path` (CODER-01)
- [ ] Führt `al_downloadsymbols` vor Code-Schreiben aus (CODER-01)
- [ ] Verwaltet `proposed_id` Verifikation (CODER-01)
- [ ] Übersetzungseinträge (`.xlf`) werden behandelt (CODER-01)
- [ ] Max. 3 Fix-Schleifen + BLOCKER-REPORT.md Eskalation (aus policy)
- [ ] `## ERGEBNIS — Coder` Header vorhanden (CONTRACT-01)
- [ ] ERGEBNIS enthält Build-Status und Fix-Schleifen-Zähler (CONTRACT-01)

**Commit:** `feat(phase-2): al-coder.agent.md — konsolidiert al-implementer + al-build-tester (CODER-01, CONTRACT-01)`

---

### T4: al-validator.agent.md erstellen

**Wave:** 1
**Requirements:** VALID-01, VALID-02, VALID-03, CONTRACT-01
**Datei:** `.github/agents/al-validator.agent.md` (CREATE)

**Beschreibung:**

Erstelle `.github/agents/al-validator.agent.md`. Der Validator prüft ob implementierter
AL-Code alle Akzeptanzkriterien abdeckt. Er verwendet 5 klar definierte Prüfschichten
und löst bei Lücken Korrekturschleifen aus (max. 2). Er schreibt KEINEN Code.

**Frontmatter (exakt):**
```yaml
---
name: al-validator
model: claude-opus-4
description: >
  Prüft ob implementierter AL-Code alle Akzeptanzkriterien aus dem Ticket abdeckt.
  Führt 5-Layer-Prüfung durch. Löst bei Lücken max. 2 Korrekturschleifen aus.
  Nach 2 Schleifen ohne Vollabdeckung: BLOCKER-REPORT.md für Main-Agent.
tools: ["read", "search"]
skills:
  - al-code-review
  - al-object-analysis
---
```

**Kein `edit`-Tool, kein `terminal`-Tool.** Der Validator verändert NIEMALS Codezeilen.

**Abschnitt: Verbindliche Policy**
`Lies und befolge immer: .github/policies/agent-policy.md`

**Abschnitt: Aufgabe**

Prüfe ob al-coder alle Akzeptanzkriterien aus dem Ticket implementiert hat.
Koordiniere bis zu 2 Korrekturschleifen mit al-coder. Eskaliere nach 2 Schleifen.

**Abschnitt: Verbote (absolut)**
- KEIN Code schreiben oder ändern — ausschließlich lesen und prüfen
- Build-Fehler sind NICHT Bestandteil der 5-Layer-Prüfung (das ist al-coder's Aufgabe)
- Wenn al-coder-ERGEBNIS `Build-Status: Fehler` zeigt: sofort an main-agent melden,
  KEINE 5-Layer-Prüfung starten

**Abschnitt: Voraussetzung**

Validator wird nur aufgerufen wenn al-coder-ERGEBNIS `Build-Status: ✓ Erfolgreich` zeigt.
Prüfe diese Bedingung als ersten Schritt.

**Abschnitt: 5-Layer-Prüfung (VALID-02)**

Führe alle 5 Layer sequenziell durch. Dokumentiere jedes Ergebnis in der Layer-Tabelle.

**Layer 1 — AC→Objekt-Mapping:**
- Eingabe: Akzeptanzkriterien aus SESSION.md (DevOps-Reader ERGEBNIS)
- Eingabe: JSON Plan Contract (Pfad aus SESSION.md `architect_contract_path`)
- Prüfung: Für jedes AC-Item — gibt es ein konkretes Objekt/Feld/Methode im Contract?
- Prüfung: Ist dieses Objekt/Feld in den geänderten Dateien tatsächlich vorhanden?
  (Suche nach Objekt-Namen + Feld-Namen in den Dateipfaden aus `coder.ERGEBNIS.Geänderte Dateien`)
- Pass: Alle ACs haben ≥1 implementierendes Objekt/Feld im Diff
- Fail: AC ohne Implementierungsnachweis → Layer-5-Trigger

**Layer 2 — AL-Konventionen (aus al-coding-standards.instructions.md):**
Auto-verifizierbare Regeln (lese die geänderten Dateien):
- Labels für alle sichtbaren Texte (`Error()`, `Message()`, `Caption`, `ToolTip` — keine Hardcoded-Strings)
- `Caption` auf allen neuen Feldern gesetzt
- `DataClassification` auf allen neuen Tabellenfeldern gesetzt
- `ApplicationArea` auf allen Page-Controls gesetzt
- Kein unkommentiertes `COMMIT` in Codeunits
- Businesslogik nicht in Page-Triggern (kein Geschäftslogik-Code in `OnValidate` auf Pages)
- Ein Objekt pro Datei (Datei-Anzahl = Objekt-Anzahl aus Contract)
- Pass: Alle Regeln erfüllt
- Fail: Regelverstoß annotiert → Layer-5-Trigger

**Layer 3 — Test-Coverage (aus al-testing.instructions.md):**
- Prüfung: Gibt es eine Test-Codeunit ODER explizite manuelle Testhinweise im al-coder ERGEBNIS?
- Kritische Prüfung: Wenn Task Buchungslogik, Preise, Lager, Berechtigungen berührt
  (erkennbar an Contract-Objekt-Typ oder AC-Text) → Test-Codeunit ist PFLICHT
- Pass: Tests oder manuelle Hinweise vorhanden
- Warnung (kein Fail für unkritische Änderungen): Keine Tests bei nicht-kritischen Änderungen
- Fail (nur für Risikobereiche): Keine Tests bei Buchungslogik/Schnittstellen → Layer-5-Trigger

**Layer 4 — Diff-Verifikation:**
- Prüfung 1: Jedes Contract-Objekt → Datei existiert im erwarteten `file_path`
- Prüfung 2: Jedes Contract-Feld → ist tatsächlich in der Datei vorhanden
  (Suche nach Feldnamen in der AL-Datei)
- Prüfung 3: Keine Phantom-Claims — Coder kann nicht AC-Abdeckung behaupten ohne Code-Nachweis
- Pass: Alle Contract-Items haben passende Datei+Inhalt-Nachweise
- Fail: Diskrepanz zwischen Contract und tatsächlichen Dateien → Layer-5-Trigger

**Layer 5 — Korrektur-Trigger:**
- Wenn Layer 1–4 keine Fails → Layer 5: `—` (kein Trigger)
- Wenn ≥1 Layer Fail → Korrekturschleife starten

**Abschnitt: Korrekturschleifen-Protokoll (max. 2 — VALID-03)**

Lese aktuellen `validator_loop_count` aus SESSION.md.

```
Schleife 1 (wenn validator_loop_count = 0):
  1. Erstelle spezifische Lücken-Beschreibung je Layer (was fehlt, welche Datei, welches Feld)
  2. Übergib Lücken-Beschreibung an main-agent → main-agent delegiert an al-coder
  3. Al-coder liefert neues ERGEBNIS
  4. Validiere erneut alle 5 Layer (validator_loop_count → 1)

Schleife 2 (wenn validator_loop_count = 1):
  Gleiche Prozedur. validator_loop_count → 2.

Nach 2 Schleifen ohne Vollabdeckung (validator_loop_count = 2):
  1. Erstelle .planning/al-workflow/BLOCKER-REPORT.md mit:
     - Ticket-ID, Datum, Workflow-Schritt
     - Alle verbleibenden Layer-Fails mit Details
     - Protokoll der 2 Korrekturversuche (was wurde gefixed, was blieb offen)
     - Empfohlene manuelle Eingriffspunkte für Entwickler
  2. ERGEBNIS: Gesamtstatus = BLOCKER, Confidence = 0.00
  3. Main-Agent erhält BLOCKER und eskaliert an Entwickler
```

**Besondere Blocker (sofort, ohne Schleifen):**
- Buchungslogik nicht verifizierbar (Confidence < 0.39 nach policy) → SOFORT BLOCKER
- Sicherheitsrisiko (kein Auth-Check auf API-Endpoint) → SOFORT BLOCKER
- Phantom-Claim (Contract sagt "erstellt" aber Datei nicht vorhanden) → SOFORT BLOCKER

**Abschnitt: ERGEBNIS (OUTPUT)**

Verwende exakt das Template aus `.github/instructions/ergebnis-contract.instructions.md`
(Template: al-validator). Pflichtfelder:
- Layer-Tabelle (alle 5 Layer mit Status und Detail)
- AC-Abdeckungs-Tabelle
- `Korrekturschleifen`-Zähler
- `blocker_path` wenn BLOCKER-REPORT erstellt wurde

**Verification:**
- [ ] `.github/agents/al-validator.agent.md` existiert
- [ ] Frontmatter hat `tools: ["read", "search"]` — KEIN `edit`, KEIN `terminal` (VALID-01)
- [ ] Layer 1 (AC→Objekt-Mapping) beschrieben (VALID-02)
- [ ] Layer 2 (AL-Konventionen) beschrieben mit Verweis auf al-coding-standards.instructions.md (VALID-02)
- [ ] Layer 3 (Test-Coverage) beschrieben mit Verweis auf al-testing.instructions.md (VALID-02)
- [ ] Layer 4 (Diff-Verifikation) beschrieben (VALID-02)
- [ ] Layer 5 (Korrektur-Trigger) beschrieben (VALID-02)
- [ ] Max. 2 Korrekturschleifen explizit dokumentiert (VALID-03)
- [ ] BLOCKER-REPORT.md Erstellung nach 2 Schleifen beschrieben (VALID-03)
- [ ] `## ERGEBNIS — Validator` Header vorhanden (CONTRACT-01)
- [ ] ERGEBNIS enthält Layer-Tabelle und AC-Abdeckung (CONTRACT-01)

**Commit:** `feat(phase-2): al-validator.agent.md — 5-Layer-Prüfung + Korrekturschleifen (VALID-01, VALID-02, VALID-03, CONTRACT-01)`

---

### T5: al-tester.agent.md erstellen

**Wave:** 1
**Requirements:** TEST-01, TEST-02, CONTRACT-01
**Datei:** `.github/agents/al-tester.agent.md` (CREATE)

**Beschreibung:**

Erstelle `.github/agents/al-tester.agent.md`. Dieser Agent erstellt AL-Tests im
GIVEN/WHEN/THEN-Pattern — **ausschließlich** wenn der Entwickler es explizit anfordert.
Er ist KEIN Teil des Standard-Workflows. Der Guard ist `tester_requested: true` in SESSION.md.

**Frontmatter (exakt):**
```yaml
---
name: al-tester
model: claude-sonnet-4-5
description: >
  Erstellt und führt AL-Tests durch — ausschließlich auf explizite Anforderung.
  Niemals automatisch als Teil des Standard-Workflows.
  Nutzt GIVEN/WHEN/THEN-Pattern aus al-testing.instructions.md.
tools: ["read", "search", "edit", "terminal"]
skills:
  - al-build-validation
  - al-test-design
---
```

**Abschnitt: Verbindliche Policy**
`Lies und befolge immer: .github/policies/agent-policy.md`

**Abschnitt: EXPLIZIT-ANFORDERUNGS-GUARD (TEST-01)**

Setze diesen Block ganz oben nach der Policy — vor allen anderen Abschnitten:

```
## ⚠️ EXPLIZIT-ANFORDERUNGS-GUARD

Du wirst AUSSCHLIESSLICH aufgerufen wenn SESSION.md `tester_requested: true` enthält.

Überprüfe als ERSTEN Schritt:
1. Lese SESSION.md
2. Wenn `tester_requested: false` oder Feld fehlt:
   Antworte: "al-tester wurde aufgerufen ohne tester_requested: true in SESSION.md.
   Bitte Main-Agent die Anforderung korrekt delegieren."
   STOPP — keine weiteren Schritte.

Du läufst NIEMALS automatisch nach al-coder oder al-validator.
Du bist KEIN Schritt im Standard-Workflow.
```

**Abschnitt: Aufgabe**

Erstelle AL-Test-Codeunits für die implementierten Objekte. Orientiere dich an den
Akzeptanzkriterien aus dem Ticket. Nutze GIVEN/WHEN/THEN-Pattern.

**Abschnitt: Nutze diese Instructions**
- `al-testing.instructions.md` — GIVEN/WHEN/THEN-Pattern, Testarten, Testplanung

**Abschnitt: Input-Daten (aus SESSION.md / ERGEBNIS-Blocks)**

- `ticket_id` — für Test-Codeunit-Benennung
- AC-Liste aus DevOps-Reader ERGEBNIS (in SESSION.md)
- JSON Plan Contract (Pfad aus `architect_contract_path`) — Objekt-Namen, IDs, idRanges
- Geänderte Dateien-Liste aus Coder ERGEBNIS (in SESSION.md)

**Abschnitt: GIVEN/WHEN/THEN-Pattern (TEST-02)**

Jede Test-Methode folgt exakt diesem Muster (aus al-testing.instructions.md):

```al
codeunit 50100 "WI-{ticket_id} Tests"
{
    Subtype = Test;

    [Test]
    procedure {DescriptiveVerbPhrase}()
    var
        {Variablen}
    begin
        // [GIVEN] Kontrollierte Testdaten (keine zufälligen Existenzdaten)
        {Testdaten aufbauen}

        // [WHEN] Aktion auslösen
        {Getestete Aktion}

        // [THEN] Erwartetes Ergebnis prüfen
        Assert.AreEqual({Erwartet}, {Actual}, '{Fehlermeldung}');
    end;
}
```

**Regeln für Test-Methoden:**
- Test-Codeunit-ID aus `idRanges` des JSON Plan Contracts
- Methodennamen: sprechende Verb-Phrasen (z.B. `CustomerBlockedPreventsPosting`, `ExternalRefMandatory`)
- Keine Abhängigkeit von zufällig existierenden Produktivdaten — IMMER kontrollierte Testdaten im GIVEN-Block
- Pro Akzeptanzkriterium: mindestens ein positiver UND ein negativer Testfall
- Assertion: `Assert.AreEqual`, `Assert.IsTrue`, `Assert.IsFalse` oder `Error` bei unerwartetem Zustand
- Keine Produktiv-Commits, keine COMMIT-Statements in Tests

**Abschnitt: Build-Verifikation**
Nach Test-Erstellung: `al_build` + `al_getdiagnostics` ausführen.
Fix-Schleife bei Build-Fehlern: max. 3 (per agent-policy.md).

**Abschnitt: ERGEBNIS (OUTPUT)**

Verwende exakt das Template aus `.github/instructions/ergebnis-contract.instructions.md`
(Template: al-tester). Pflichtfelder:
- Tabelle aller erstellten Tests (Methode, Typ, abgedecktes AC)
- Test-Datei-Pfad
- GIVEN/WHEN/THEN Kurzblock pro Test
- Liste nicht abdeckbarer Testfälle (falls vorhanden)

**Verification:**
- [ ] `.github/agents/al-tester.agent.md` existiert
- [ ] Explizit-Anforderungs-Guard vorhanden mit `tester_requested: true` Check (TEST-01)
- [ ] Guard-Text enthält "NIEMALS automatisch" (TEST-01)
- [ ] GIVEN/WHEN/THEN-Pattern als AL-Code-Beispiel enthalten (TEST-02)
- [ ] Verweis auf `al-testing.instructions.md` vorhanden (TEST-02)
- [ ] `## ERGEBNIS — Tester` Header vorhanden (CONTRACT-01)
- [ ] ERGEBNIS enthält Test-Tabelle und Datei-Pfade (CONTRACT-01)

**Commit:** `feat(phase-2): al-tester.agent.md — GIVEN/WHEN/THEN + Explizit-Guard (TEST-01, TEST-02, CONTRACT-01)`

---

### T6: al-reviewer.agent.md um ERGEBNIS-Block erweitern

**Wave:** 2
**Requirements:** CONTRACT-01
**Datei:** `.github/agents/al-reviewer.agent.md` (MODIFY)

**Beschreibung:**

Der al-reviewer existiert bereits mit einem `## Output`-Abschnitt (Fließtext-Format).
Ersetze den `## Output`-Abschnitt durch den strukturierten `## ERGEBNIS`-Block.
Alle anderen Abschnitte (Policy, Nutze diese Skills, Prüfe besonders, Orchestrator-Nutzung)
bleiben unverändert.

**Zu ersetzender Abschnitt (genau dieser Block in al-reviewer.agent.md):**
```markdown
## Output

```markdown
## Review-Ergebnis

Freigabe / Änderungen notwendig / Blocker

## Blocker

- ...

## Verbesserungsvorschläge

- ...

## Testlücken

- ...

## PR-Kommentar

...
```
```

**Ersatz (füge diesen Block ein):**
```markdown
## ERGEBNIS (OUTPUT)

Verwende immer dieses strukturierte Format. Abweichungen verhindern Main-Agent-Parsing.

```markdown
## ERGEBNIS — Reviewer

**Ticket-ID:** {WI-ID}
**Review-Status:** Freigabe | Änderungen notwendig | Blocker

### Prüfergebnis
| Kriterium | Status | Hinweis |
|-----------|--------|---------|
| Upgradefähigkeit | ✓ / ⚠ / ✗ | {Detail} |
| AL-Best-Practices | ✓ / ⚠ / ✗ | {Detail} |
| Performance | ✓ / ⚠ / ✗ | {Detail} |
| Fehlerbehandlung | ✓ / ⚠ / ✗ | {Detail} |
| Testbarkeit | ✓ / ⚠ / ✗ | {Detail} |
| Berechtigungen | ✓ / ⚠ / ✗ | {Detail} |
| Labels | ✓ / ⚠ / ✗ | {Detail} |
| Keine unnötigen COMMITs | ✓ / ⚠ / ✗ | {Detail} |

### Blocker
- {oder "Keine"}

### Verbesserungsvorschläge
- {oder "Keine"}

### Testlücken
- {oder "Keine"}

### PR-Kommentar (Kurzfassung)
{2–3 Sätze für PR-Beschreibung}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-documenter | Blocker → Entwickler-Entscheidung
- Offene Fragen: {oder "Keine"}
```
```

Zusätzlich: Ergänze unter `## Orchestrator-Nutzung` einen Hinweis:

```markdown
Nach der Prüfung immer den strukturierten `## ERGEBNIS — Reviewer` Block ausgeben.
Main-Agent parsed diesen Block für den CP-4-Checkpoint.
```

**Verification:**
- [ ] `## ERGEBNIS — Reviewer` Header im Dokument vorhanden (CONTRACT-01)
- [ ] Prüfergebnis-Tabelle mit Kriterium/Status-Spalten vorhanden (CONTRACT-01)
- [ ] `### Interpretation für Main-Agent` Footer mit Confidence-Feld vorhanden (CONTRACT-01)
- [ ] Alle anderen Abschnitte des al-reviewer unverändert (kein Breaking Change)

**Commit:** `feat(phase-2): al-reviewer.agent.md — strukturierter ERGEBNIS-Block (CONTRACT-01)`

---

### T7: main-agent.agent.md aktualisieren

**Wave:** 2
**Requirements:** ARCH-01..04, VALID-01..03, TEST-01, CODER-01, CONTRACT-01 (Orchestrierung aller)
**Datei:** `.github/agents/main-agent.agent.md` (MODIFY)

**Beschreibung:**

Der main-agent.agent.md muss 7 gezielte Änderungen erhalten. Führe sie als separate
Edit-Operationen durch, um Fehler zu minimieren. Lese die Datei vollständig vor den Edits.

**Edit 1 — Frontmatter `agents:` Liste ersetzen:**

Altes `agents:` in der Frontmatter:
```yaml
agents:
  - al-devops-reader
  - al-planner
  - al-codebase-analyst
  - al-implementer
  - al-build-tester
  - al-reviewer
  - al-documenter
```

Neues `agents:` (Phase 2):
```yaml
agents:
  - al-devops-reader
  - al-architect        # Ersetzt al-planner — JSON Plan Contract
  - al-codebase-analyst
  - al-coder            # Ersetzt al-implementer + al-build-tester
  - al-validator        # NEU — 5-Layer AC-Prüfung
  - al-reviewer
  - al-documenter
  - al-tester           # NEU — optional, nur auf explizite Anforderung
```

**Edit 2 — Workflow-Schritt-Tabelle ersetzen:**

Ersetze die gesamte Tabelle unter `## Workflow-Schritt-Tabelle`:

```markdown
| Schritt | Agent | Aufgabe | Checkpoint |
|---------|-------|---------|-----------|
| 0 | *(Main-Agent)* | Session-Start, Resume-Check, customer_path ermitteln | Intern |
| 1 | `al-devops-reader` | WI/Issue lesen, Ticket-Summary erzeugen | **Pflicht CP-1** |
| 2 | `al-architect` | JSON Plan Contract erstellen, Aufwand schätzen | **Pflicht CP-2** |
| 3 | `al-codebase-analyst` | Relevante Objekte und Abhängigkeiten identifizieren | Nach Bedarf |
| 4 | `al-coder` | AL-Code schreiben, Build + Fix-Schleifen, Übersetzungen | Bei Fehlern |
| 5 | `al-validator` | 5-Layer AC-Prüfung, max. 2 Korrekturschleifen | **Pflicht CP-3** |
| 6 | `al-reviewer` | Code-Review + Best-Practices | **Pflicht CP-4** |
| 7 | `al-documenter` | PR-Beschreibung erstellen | **Pflicht CP-Ende** |
| (opt) | `al-tester` | AL-Tests erstellen — nur wenn `tester_requested: true` | Nur auf Anforderung |

*Nach al-architect (CP-2): Entwickler sieht JSON Plan Contract + Aufwandsschätzung.
Bei Confidence < 0.60 im Contract: CP-5 vor al-coder-Delegation.*
```

**Edit 3 — Pflicht-Checkpoint-Tabelle aktualisieren:**

Ersetze den `### 5 Pflicht-Checkpoint-Positionen (MAIN-03)` Abschnitt:

```markdown
### 5 Pflicht-Checkpoint-Positionen (MAIN-03)

| # | Position | Auslöser | Gesperrt bis |
|---|----------|----------|-------------|
| CP-1 | DevOps-Read | Nach `al-devops-reader` | Kein Schritt 2 ohne Zustimmung |
| CP-2 | Architect-Plan | Nach `al-architect` JSON Contract | Kein Schritt 4 (al-coder) ohne Zustimmung |
| CP-3 | Validator | Nach `al-validator` 5-Layer-Prüfung | Kein Schritt 6 ohne Zustimmung |
| CP-4 | Reviewer-Verdict | Nach `al-reviewer` Hauptergebnis oder Blocker | Kein Schritt 7 ohne Zustimmung |
| CP-5 | Confidence < 0.60 | Wenn irgendein Spezialist < 0.60 meldet | SOFORT stoppen — VOR Delegation |

**CP-5 gilt präventiv:** Besonders nach al-architect: wenn Contract-Confidence < 0.60
(z.B. XL-Sizing = Buchungslogik), stoppe VOR al-coder-Delegation.
```

**Edit 4 — SESSION.md-Management: Neuen Abschnitt einfügen**

Füge unter `## SESSION.md-Management` vor `### Schreiben nach Checkpoint` ein:

```markdown
### Phase-2-Felder (nach al-architect)

Nach CP-2 (al-architect genehmigt):
- Schreibe `architect_contract_path` in SESSION.md (Pfad aus ERGEBNIS — Architect)
- Setze `validator_loop_count: 0` (Ausgangswert vor al-validator)

Nach al-validator-Delegation:
- Erhöhe `validator_loop_count` nach jeder Korrekturschleife
- Wenn `validator_loop_count >= 2` und noch Lücken: al-validator eskaliert → BUILD-ESKALATION-Block

Tester-Guard:
- Prüfe `tester_requested` in SESSION.md vor JEDER al-tester-Delegation
- Wenn `tester_requested: false` → al-tester NIEMALS aufrufen
- Setze `tester_requested: true` nur wenn Entwickler explizit Tests anfordert
```

**Edit 5 — Delegation-Regeln: Tester-Guard einfügen**

Füge unter `## Delegation-Regeln` vor `### Delegations-Syntax` ein:

```markdown
### al-tester Delegation — EXPLIZIT-GUARD

**al-tester wird NIEMALS automatisch aufgerufen.**

Voraussetzungen für al-tester-Delegation (ALLE müssen erfüllt sein):
1. Entwickler hat explizit "Tests erstellen" / "AL-Tests" / "testen" angefordert
2. `tester_requested: true` in SESSION.md gesetzt
3. al-coder ERGEBNIS: Build-Status ✓ Erfolgreich
4. (Optional) al-validator hat Freigabe gegeben

Ohne alle 4 Bedingungen: al-tester NICHT aufrufen.
```

**Edit 6 — `build_fix_loop_count pflegen` auf al-coder aktualisieren**

Aktualisiere den Abschnitt:

```markdown
### build_fix_loop_count pflegen

Erhöhe `build_fix_loop_count` um 1 nach jeder Korrekturschleife von `al-coder`.
Wenn `build_fix_loop_count >= 3`: sofort eskalieren (→ `## Eskalations-Regeln`).

Hinweis: al-validator hat einen eigenen Schleifenzähler (`validator_loop_count`, max. 2).
```

**Edit 7 — Phase-1-Hinweis-Kommentar entfernen**

Entferne diese Zeile (den Phase-1 Übergangshinweis):
```
*Phase-1-Hinweis: CP-2 = nach al-planner; CP-3 = nach al-reviewer (kombinierter Review + Validator-Schritt,
da al-validator erst in Phase 2 kommt).*
```

**Verification:**
- [ ] Frontmatter `agents:` enthält al-architect, al-coder, al-validator, al-tester
- [ ] Frontmatter `agents:` enthält NICHT mehr al-planner, al-implementer, al-build-tester
- [ ] Workflow-Tabelle zeigt al-architect in Schritt 2, al-coder in 4, al-validator in 5
- [ ] CP-3 = Validator, CP-4 = Reviewer (Phase-2-Umbenennung vollzogen)
- [ ] SESSION.md-Sektion erwähnt `architect_contract_path`, `validator_loop_count`, `tester_requested`
- [ ] al-tester-Guard ist dokumentiert ("NIEMALS automatisch")
- [ ] Phase-1-Hinweis-Kommentar entfernt

**Commit:** `feat(phase-2): main-agent.agent.md — Phase-2-Workflow-Update + Tester-Guard (ARCH-01, CODER-01, VALID-01, TEST-01)`

---

### T8: SESSION.md-Template um Phase-2-Felder erweitern

**Wave:** 2
**Requirements:** ARCH-04 (contract_path), VALID-03 (loop_count), TEST-01 (tester_requested)
**Datei:** `.planning/al-workflow/SESSION.md` (MODIFY)

**Beschreibung:**

Das SESSION.md-Template hat derzeit Phase-1-Felder. Füge die 3 neuen Phase-2-Felder
zum YAML-Frontmatter hinzu und erweitere die Kommentarabschnitte.

**Edit 1 — YAML-Frontmatter: 3 neue Felder einfügen**

Füge nach der Zeile `build_fix_loop_count: 0` ein:

```yaml
architect_contract_path: ""    # Pfad zu PLAN-CONTRACT-{ticket_id}.json (gesetzt nach CP-2)
validator_loop_count: 0        # Zählt al-validator Korrekturschleifen (max. 2)
tester_requested: false        # true = Entwickler hat explizit Tests angefordert
```

**Edit 2 — Neue Kommentarabschnitte am Ende der Datei einfügen**

Füge nach `## Blocker` ein:

```markdown
## Architect-Contract
<!-- Wird von al-architect gefüllt — nach CHECKPOINT CP-2 -->
<!-- Format: contract_path + BC-Version + T-Shirt-Größe + Confidence -->

## Validator-Prüfung
<!-- Wird von al-validator gefüllt — nach CHECKPOINT CP-3 -->
<!-- Format: Layer-Ergebnis, Korrekturschleifenanzahl, Blocker-Pfad falls eskaliert -->

## Tester-Notes
<!-- Wird von al-tester gefüllt — nur wenn tester_requested: true -->
<!-- Format: Erstellte Tests, Testdatei-Pfad -->
```

**Verification:**
- [ ] SESSION.md enthält `architect_contract_path: ""` Feld (ARCH-04)
- [ ] SESSION.md enthält `validator_loop_count: 0` Feld (VALID-03)
- [ ] SESSION.md enthält `tester_requested: false` Feld (TEST-01)
- [ ] Kommentarabschnitte ## Architect-Contract, ## Validator-Prüfung, ## Tester-Notes vorhanden

**Commit:** `feat(phase-2): SESSION.md — Phase-2-Felder architect_contract_path, validator_loop_count, tester_requested (ARCH-04, VALID-03, TEST-01)`

---

### T9: Deprecation-Notices in Legacy-Agents eintragen

**Wave:** 3
**Requirements:** Rückwärtskompatibilität (al-auto-dev referenziert diese Agents noch)
**Dateien:** al-planner, al-implementer, al-build-tester (MODIFY)

**Beschreibung:**

`al-auto-dev.agent.md` (legacy Orchestrator) referenziert noch al-planner, al-implementer
und al-build-tester. Diese Agents NICHT löschen — nur mit Deprecation-Hinweis versehen.

**Edit an `.github/agents/al-planner.agent.md`:**

Ersetze die `description`-Zeile im Frontmatter:

Alt:
```yaml
description: Plant AL-Änderungen aus fachlichen Anforderungen und erstellt technische Umsetzungspläne.
```

Neu:
```yaml
description: >
  [DEPRECATED — Phase 2] Verwende al-architect.agent.md für neue Workflows.
  al-planner bleibt für Rückwärtskompatibilität mit al-auto-dev (legacy) erhalten.
  Plant AL-Änderungen aus fachlichen Anforderungen und erstellt technische Umsetzungspläne.
```

Füge zudem unter der Policy-Zeile einen sichtbaren Hinweis ein:

```markdown
## ⚠️ DEPRECATED

Dieser Agent ist ab Phase 2 durch `al-architect.agent.md` ersetzt.
Verwende al-architect für alle neuen Workflows mit main-agent.
Dieser Agent wird nur noch von al-auto-dev (legacy) aufgerufen.
```

**Edit an `.github/agents/al-implementer.agent.md`:**

Ersetze `description` im Frontmatter:

Alt:
```yaml
description: Implementiert kleine, klar geplante AL-Änderungen auf Basis eines bestätigten Plans.
```

Neu:
```yaml
description: >
  [DEPRECATED — Phase 2] Verwende al-coder.agent.md für neue Workflows.
  al-implementer bleibt für Rückwärtskompatibilität mit al-auto-dev (legacy) erhalten.
  Implementiert kleine, klar geplante AL-Änderungen auf Basis eines bestätigten Plans.
```

Füge unter der Policy-Zeile ein:

```markdown
## ⚠️ DEPRECATED

Dieser Agent ist ab Phase 2 durch `al-coder.agent.md` ersetzt.
al-coder konsolidiert al-implementer + al-build-tester mit JSON-Plan-Contract-Input.
Dieser Agent wird nur noch von al-auto-dev (legacy) aufgerufen.
```

**Edit an `.github/agents/al-build-tester.agent.md`:**

Ersetze `description` im Frontmatter:

Alt:
```yaml
description: Führt AL Build, Compile, Symbolprüfung, Diagnostics und Testauswertung durch.
```

Neu:
```yaml
description: >
  [DEPRECATED — Phase 2] Build-Logik ist in al-coder.agent.md integriert.
  al-build-tester bleibt für Standalone-Build-Diagnosen und al-auto-dev (legacy) erhalten.
  Führt AL Build, Compile, Symbolprüfung, Diagnostics und Testauswertung durch.
```

Füge unter der Policy-Zeile ein:

```markdown
## ⚠️ DEPRECATED

Dieser Agent ist ab Phase 2 in `al-coder.agent.md` integriert.
al-coder übernimmt Symbol-Download, Build, Diagnostics und Fix-Schleifen.
al-build-tester bleibt für Standalone-Diagnosen erhalten.
```

**Verification:**
- [ ] `al-planner.agent.md` enthält `[DEPRECATED` im description-Frontmatter
- [ ] `al-implementer.agent.md` enthält `[DEPRECATED` im description-Frontmatter
- [ ] `al-build-tester.agent.md` enthält `[DEPRECATED` im description-Frontmatter
- [ ] Alle 3 Dateien haben sichtbaren `## ⚠️ DEPRECATED` Abschnitt
- [ ] Kein Inhalt der Legacy-Agents gelöscht (nur Deprecation-Hinweise hinzugefügt)

**Commit:** `feat(phase-2): Deprecation-Notices in al-planner, al-implementer, al-build-tester`

---

### T10: AGENTS.md mit Phase-2-Roster aktualisieren

**Wave:** 3
**Requirements:** Alle (Dokumentations-Update)
**Datei:** `AGENTS.md` (MODIFY)

**Beschreibung:**

AGENTS.md enthält aktuell die Tabelle "Geplante Agents" mit 4 Phase-2-Agents.
Diese müssen in "Aktuelle Agents" verschoben werden. Legacy-Agents erhalten Status-Update.

**Edit 1 — "Aktuelle Agents" Tabelle erweitern:**

Füge in der Tabelle `### Aktuelle Agents (vorhanden)` nach al-documenter folgende Zeilen ein:

```markdown
| `.github/agents/al-architect.agent.md` | JSON Plan Contract, BC-Symbole, T-Shirt-Sizing, Objekt-Planung | Aktiv (Phase 2) |
| `.github/agents/al-coder.agent.md` | Code + Build + Objekt-IDs + Übersetzungen (löst al-implementer + al-build-tester ab) | Aktiv (Phase 2) |
| `.github/agents/al-validator.agent.md` | 5-Layer AC-Prüfung, max. 2 Korrekturschleifen, BLOCKER-Report | Aktiv (Phase 2) |
| `.github/agents/al-tester.agent.md` | AL-Tests (GIVEN/WHEN/THEN), nur auf explizite Anforderung | Aktiv (Phase 2) |
```

**Edit 2 — Status-Update für Legacy-Agents:**

Ändere die Status-Spalte für al-planner, al-implementer, al-build-tester:

```markdown
| `.github/agents/al-planner.agent.md` | Anforderung analysieren → technischen Plan erstellen | ⚠️ DEPRECATED (ersetzt durch al-architect in Phase 2) |
| `.github/agents/al-implementer.agent.md` | AL-Code schreiben | ⚠️ DEPRECATED (ersetzt durch al-coder in Phase 2) |
| `.github/agents/al-build-tester.agent.md` | Build/Compile, Diagnostics, Fix-Schleifen (max. 3) | ⚠️ DEPRECATED (integriert in al-coder in Phase 2) |
```

**Edit 3 — "Geplante Agents" Tabelle: Phase-2-Agents entfernen**

Entferne die 4 Phase-2-Zeilen aus `### Geplante Agents (noch nicht implementiert)`:
- al-architect.agent.md
- al-coder.agent.md
- al-validator.agent.md
- al-tester.agent.md

(Die Phase-3 und Phase-4 Agents bleiben als "Geplant".)

**Edit 4 — Phase-2-Hinweis in Abschnitt "Was ist dieses Repository?" ergänzen**

Füge nach dem ersten Absatz ein:

```markdown
**Phase-2-Status:** Spezialist-Refactoring abgeschlossen — al-architect (JSON Plan Contract),
al-coder (Code+Build), al-validator (5-Layer-Prüfung), al-tester (GIVEN/WHEN/THEN, optional)
sind aktiv. Veraltete Agents (al-planner, al-implementer, al-build-tester) mit Deprecation-Notice.
```

**Verification:**
- [ ] AGENTS.md enthält al-architect in der Aktive-Agents-Tabelle
- [ ] AGENTS.md enthält al-coder in der Aktive-Agents-Tabelle
- [ ] AGENTS.md enthält al-validator in der Aktive-Agents-Tabelle
- [ ] AGENTS.md enthält al-tester in der Aktive-Agents-Tabelle
- [ ] al-planner, al-implementer, al-build-tester sind als DEPRECATED markiert

**Commit:** `feat(phase-2): AGENTS.md — Phase-2-Roster aktualisiert`

---

### T11: PowerShell-Verifikationsskript schreiben und ausführen

**Wave:** 4
**Requirements:** Alle (ARCH-01..04, VALID-01..03, TEST-01..02, CODER-01, CONTRACT-01)
**Datei:** `.planning/02-spezialist-refactoring/verify-phase-2.ps1` (CREATE + RUN)

**Beschreibung:**

Erstelle das Verifikationsskript und führe es aus. Das Skript prüft alle 11 Requirements
der Phase durch Dateiexistenz und Inhalts-Regex-Prüfungen.

**Kritische PowerShell-Regex-Regel:** Verwende immer `(?m)^` für multiline Matches.
Ohne `(?m)` matcht `^` nur den Anfang des gesamten Strings, nicht der einzelnen Zeilen.
Beispiel: `$content -match '(?m)^## ERGEBNIS'` (korrekt) vs `$content -match '^## ERGEBNIS'` (falsch).

**Skript-Inhalt (schreibe exakt so nach `.planning/02-spezialist-refactoring/verify-phase-2.ps1`):**

```powershell
#!/usr/bin/env pwsh
# Phase 2: Spezialist-Refactoring — Verifikationsskript
# Prüft alle 11 Requirements: ARCH-01..04, VALID-01..03, TEST-01..02, CODER-01, CONTRACT-01
#
# Ausführung vom Repo-Root:
#   pwsh .planning\02-spezialist-refactoring\verify-phase-2.ps1
#
# Wichtig: Nutzt (?m)^ für multiline Regex (PowerShell-Bug ohne (?m): ^ matcht nur String-Anfang)

param(
    [string]$RepoRoot = ""
)

# Repo-Root ermitteln (2 Ebenen über dem Skript-Verzeichnis)
if ([string]::IsNullOrEmpty($RepoRoot)) {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
}
$RepoRoot = $RepoRoot.ToString().TrimEnd('\')

$ErrorCount = 0
$PassCount  = 0

function Check {
    param([string]$Req, [string]$Description, [bool]$Condition)
    if ($Condition) {
        Write-Host ("  PASS [{0}] {1}" -f $Req, $Description) -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host ("  FAIL [{0}] {1}" -f $Req, $Description) -ForegroundColor Red
        $script:ErrorCount++
    }
}

function Get-FileContent {
    param([string]$Path)
    if (Test-Path $Path) { return (Get-Content $Path -Raw) } else { return "" }
}

Write-Host ""
Write-Host "=== Phase 2: Spezialist-Refactoring — Verifikation ===" -ForegroundColor Cyan
Write-Host ("Repo: {0}" -f $RepoRoot)
Write-Host ("Datum: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm"))
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# ARCH-01..04: al-architect.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- ARCH: al-architect.agent.md ---" -ForegroundColor Yellow
$archPath = Join-Path $RepoRoot ".github\agents\al-architect.agent.md"
$archOK   = Test-Path $archPath
Check "ARCH-01" "al-architect.agent.md existiert" $archOK

if ($archOK) {
    $c = Get-FileContent $archPath
    Check "ARCH-01" "model: claude-opus-4 im Frontmatter" ($c -match 'model:\s*claude-opus-4')
    Check "ARCH-02" "Liest app.json (BC-Version-Awareness)" ($c -match 'app\.json')
    Check "ARCH-02" "Listet .alpackages Verzeichnis auf" ($c -match '\.alpackages')
    Check "ARCH-03" "T-Shirt-Sizing Rubrik vorhanden (XS..XL)" ($c -match '(?i)\bXS\b' -and $c -match '(?i)\bXL\b')
    Check "ARCH-04" "plan_contract_version im JSON-Schema" ($c -match 'plan_contract_version')
    Check "ARCH-04" "JSON-Schema hat objects-Array" ($c -match '"objects"')
    Check "ARCH-04" "JSON-Schema hat fields-Struktur" ($c -match '"fields"')
    Check "ARCH-04" "JSON-Schema hat proposed_id" ($c -match 'proposed_id')
    Check "ARCH-04" "JSON-Schema hat data_classification" ($c -match 'data_classification')
    Check "ARCH-04" "Contract-Pfad PLAN-CONTRACT referenziert" ($c -match 'PLAN-CONTRACT')
    Check "CONTRACT-01" "## ERGEBNIS — Architect Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat contract_path Feld" ($c -match 'contract_path')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# CODER-01: al-coder.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- CODER-01: al-coder.agent.md ---" -ForegroundColor Yellow
$coderPath = Join-Path $RepoRoot ".github\agents\al-coder.agent.md"
$coderOK   = Test-Path $coderPath
Check "CODER-01" "al-coder.agent.md existiert" $coderOK

if ($coderOK) {
    $c = Get-FileContent $coderPath
    Check "CODER-01" "model: claude-sonnet-4-5 im Frontmatter" ($c -match 'model:\s*claude-sonnet-4-5')
    Check "CODER-01" "tools: terminal im Frontmatter" ($c -match '"terminal"')
    Check "CODER-01" "tools: edit im Frontmatter" ($c -match '"edit"')
    Check "CODER-01" "Liest JSON Plan Contract (architect_contract_path)" ($c -match 'architect_contract_path')
    Check "CODER-01" "al_downloadsymbols vor Code-Schreiben" ($c -match 'al_downloadsymbols')
    Check "CODER-01" "Objekt-ID Vergabe (proposed_id)" ($c -match 'proposed_id')
    Check "CODER-01" "Uebersetzungseintraege (.xlf) behandelt" ($c -match '\.xlf')
    Check "CODER-01" "Max 3 Fix-Schleifen (aus policy)" ($c -match '3.*Schleife|Fix-Loop|max.*3')
    Check "CODER-01" "BLOCKER-REPORT.md Erstellung bei Eskalation" ($c -match 'BLOCKER-REPORT')
    Check "CODER-01" "Konsolidiert al-implementer (skills: al-object-analysis)" ($c -match 'al-object-analysis')
    Check "CODER-01" "Konsolidiert al-build-tester (skills: al-build-validation)" ($c -match 'al-build-validation')
    Check "CONTRACT-01" "## ERGEBNIS — Coder Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Build-Ergebnis / Build-Status" ($c -match 'Build-Ergebnis|Build-Status|Buildstatus')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# VALID-01..03: al-validator.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- VALID: al-validator.agent.md ---" -ForegroundColor Yellow
$validPath = Join-Path $RepoRoot ".github\agents\al-validator.agent.md"
$validOK   = Test-Path $validPath
Check "VALID-01" "al-validator.agent.md existiert" $validOK

if ($validOK) {
    $c = Get-FileContent $validPath
    Check "VALID-01" "model: claude-opus-4 im Frontmatter (reasoning-heavy task)" ($c -match 'model:\s*claude-opus-4')
    Check "VALID-01" "Kein edit-Tool (Validator schreibt keinen Code)" (-not ($c -match '"edit"'))
    Check "VALID-01" "Kein terminal-Tool" (-not ($c -match '"terminal"'))
    Check "VALID-02" "Layer 1: AC-Objekt-Mapping erwaehnt" ($c -match 'Layer 1|AC.*Mapping|AC.*Objekt')
    Check "VALID-02" "Layer 2: AL-Konventionen erwaehnt" ($c -match 'Layer 2|AL-Konventionen|Konventionen')
    Check "VALID-02" "Layer 3: Test-Coverage erwaehnt" ($c -match 'Layer 3|Test-Coverage|Testabdeckung')
    Check "VALID-02" "Layer 4: Diff-Verifikation erwaehnt" ($c -match 'Layer 4|Diff-Verifikation')
    Check "VALID-02" "Layer 5: Korrektur-Trigger erwaehnt" ($c -match 'Layer 5|Korrektur-Trigger')
    Check "VALID-03" "Max 2 Korrekturschleifen dokumentiert" ($c -match 'max.*2|2.*Schleife|2.*Korrektur')
    Check "VALID-03" "BLOCKER-REPORT.md Erstellung bei Eskalation" ($c -match 'BLOCKER-REPORT')
    Check "VALID-03" "validator_loop_count Tracking erwaehnt" ($c -match 'validator_loop_count|Schleifenzaehler|Korrekturschleifen')
    Check "CONTRACT-01" "## ERGEBNIS — Validator Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat 5-Layer Prueftabelle" ($c -match 'Layer.*Pruefpunkt|5-Layer|Layer.*Status')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# TEST-01..02: al-tester.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- TEST: al-tester.agent.md ---" -ForegroundColor Yellow
$testerPath = Join-Path $RepoRoot ".github\agents\al-tester.agent.md"
$testerOK   = Test-Path $testerPath
Check "TEST-01" "al-tester.agent.md existiert" $testerOK

if ($testerOK) {
    $c = Get-FileContent $testerPath
    Check "TEST-01" "Explizit-Guard: tester_requested in SESSION.md" ($c -match 'tester_requested')
    Check "TEST-01" "Guard: NIEMALS automatisch aufgerufen" ($c -match '(?i)niemals automatisch|never.*automat')
    Check "TEST-01" "Guard am Anfang des Dokuments (vor Aufgabe)" (($c.IndexOf('tester_requested')) -lt ($c.IndexOf('## Aufgabe') + 1))
    Check "TEST-02" "GIVEN/WHEN/THEN Pattern vorhanden" ($c -match '\[GIVEN\]|\[WHEN\]|\[THEN\]|GIVEN.*WHEN.*THEN')
    Check "TEST-02" "Verweis auf al-testing.instructions.md" ($c -match 'al-testing\.instructions')
    Check "TEST-02" "Subtype = Test im AL-Beispiel" ($c -match 'Subtype\s*=\s*Test')
    Check "CONTRACT-01" "## ERGEBNIS — Tester Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Erstellte Tests Tabelle" ($c -match 'Erstellte Tests|tests_created|Testmethode')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# CONTRACT-01: al-reviewer.agent.md — ERGEBNIS-Block vorhanden
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- CONTRACT-01: al-reviewer.agent.md ---" -ForegroundColor Yellow
$reviewerPath = Join-Path $RepoRoot ".github\agents\al-reviewer.agent.md"
if (Test-Path $reviewerPath) {
    $c = Get-FileContent $reviewerPath
    Check "CONTRACT-01" "## ERGEBNIS — Reviewer Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Pruefergebnis Tabelle" ($c -match 'Pruefer?gebnis|Kriterium.*Status|Review-Status')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
} else {
    Check "CONTRACT-01" "al-reviewer.agent.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# SESSION.md: Phase-2-Felder
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- SESSION.md: Phase-2-Felder ---" -ForegroundColor Yellow
$sessionPath = Join-Path $RepoRoot ".planning\al-workflow\SESSION.md"
if (Test-Path $sessionPath) {
    $c = Get-FileContent $sessionPath
    Check "ARCH-04"  "SESSION.md: architect_contract_path Feld vorhanden" ($c -match 'architect_contract_path')
    Check "VALID-03" "SESSION.md: validator_loop_count Feld vorhanden" ($c -match 'validator_loop_count')
    Check "TEST-01"  "SESSION.md: tester_requested Feld vorhanden" ($c -match 'tester_requested')
} else {
    Check "ARCH-04"  "SESSION.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# Deprecation: Legacy-Agents
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- Deprecation: Legacy-Agents ---" -ForegroundColor Yellow
foreach ($agentName in @("al-planner", "al-implementer", "al-build-tester")) {
    $agentPath = Join-Path $RepoRoot ".github\agents\$agentName.agent.md"
    if (Test-Path $agentPath) {
        $c = Get-FileContent $agentPath
        Check "Compat" "$agentName hat [DEPRECATED] im Frontmatter" ($c -match '\[DEPRECATED')
    } else {
        Check "Compat" "$agentName.agent.md existiert noch (backward compat)" $false
    }
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# AGENTS.md: Phase-2-Roster
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- AGENTS.md: Roster-Update ---" -ForegroundColor Yellow
$agentsPath = Join-Path $RepoRoot "AGENTS.md"
if (Test-Path $agentsPath) {
    $c = Get-FileContent $agentsPath
    Check "Roster" "AGENTS.md erwaehnt al-architect" ($c -match 'al-architect')
    Check "Roster" "AGENTS.md erwaehnt al-coder" ($c -match 'al-coder')
    Check "Roster" "AGENTS.md erwaehnt al-validator" ($c -match 'al-validator')
    Check "Roster" "AGENTS.md erwaehnt al-tester" ($c -match 'al-tester')
} else {
    Check "Roster" "AGENTS.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# main-agent.agent.md: Phase-2-Updates
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- main-agent.agent.md: Phase-2-Updates ---" -ForegroundColor Yellow
$mainPath = Join-Path $RepoRoot ".github\agents\main-agent.agent.md"
if (Test-Path $mainPath) {
    $c = Get-FileContent $mainPath
    Check "Orchestr" "main-agent agents: enthaelt al-architect" ($c -match 'al-architect')
    Check "Orchestr" "main-agent agents: enthaelt al-coder" ($c -match 'al-coder')
    Check "Orchestr" "main-agent agents: enthaelt al-validator" ($c -match 'al-validator')
    Check "Orchestr" "main-agent agents: enthaelt al-tester" ($c -match 'al-tester')
    Check "TEST-01"  "main-agent hat tester_requested Guard" ($c -match 'tester_requested')
    Check "VALID-03" "main-agent hat validator_loop_count Referenz" ($c -match 'validator_loop_count')
    Check "ARCH-04"  "main-agent hat architect_contract_path Referenz" ($c -match 'architect_contract_path')
} else {
    Check "Orchestr" "main-agent.agent.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# Zusammenfassung
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("  Bestanden:       {0}" -f $PassCount) -ForegroundColor Green
Write-Host ("  Fehlgeschlagen:  {0}" -f $ErrorCount) -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Host "  Alle Phase-2-Anforderungen erfuellt!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("  {0} Pruefung(en) fehlgeschlagen." -f $ErrorCount) -ForegroundColor Red
    Write-Host "  Bitte offene Punkte beheben und Skript erneut ausfuehren." -ForegroundColor Yellow
    exit 1
}
```

**Nach dem Erstellen:** Führe das Skript vom Repo-Root aus:
```
pwsh .planning\02-spezialist-refactoring\verify-phase-2.ps1
```

Dokumentiere das Ergebnis. Alle Prüfungen müssen PASS sein.

**Verification:**
- [ ] `.planning/02-spezialist-refactoring/verify-phase-2.ps1` existiert
- [ ] Skript prüft alle 4 neuen Agents auf Existenz
- [ ] Skript prüft ERGEBNIS-Blöcke in allen 5 Agents
- [ ] Skript prüft SESSION.md Phase-2-Felder
- [ ] Skript prüft Deprecation-Notices in 3 Legacy-Agents
- [ ] Skript prüft AGENTS.md Roster
- [ ] Skript verwendet `(?m)^` für multiline Matches (nicht nacktes `^`)
- [ ] Skript läuft durch ohne Exit-Code 1

**Commit:** `test(phase-2): Verifikationsskript — alle 11 Requirements (ARCH-01..04, VALID-01..03, TEST-01..02, CODER-01, CONTRACT-01)`

---

## Verification Script

Das vollständige Skript ist in T11 eingebettet.
Pfad: `.planning/02-spezialist-refactoring/verify-phase-2.ps1`
Ausführung: `pwsh .planning\02-spezialist-refactoring\verify-phase-2.ps1`

---

## Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| **ERGEBNIS-Header-Inkonsistenz** — Agents verwenden abweichende Casing/Leerzeichen → Main-Agent-Parsing bricht | Mittel | Hoch | T1 erstellt kanonische Instructions-Datei; alle Agents referenzieren sie; Skript in T11 verifiziert Header |
| **JSON Plan Contract truncation** — Großer Contract wird inline übergeben statt als Datei | Mittel | Hoch | al-architect schreibt Contract nach Disk; al-coder liest von Pfad; Pfad in SESSION.md gespeichert |
| **al-tester wird automatisch aufgerufen** — Entwickler sagt "ja" → main-agent ruft al-tester auf | Mittel | Mittel | Explizit-Guard in T5 als erster Abschnitt; main-agent-Guard in T7; `tester_requested`-Flag in SESSION.md |
| **Validator prüft trotz Build-Fehler** — al-validator wird aufgerufen obwohl Build noch fehlerhaft ist | Mittel | Mittel | al-validator-Protokoll: erste Prüfung ist Build-Status; main-agent darf al-validator nur nach ✓ Build aufrufen |
| **Symbol-Download fehlt in al-coder** — al-coder schreibt Code ohne Symbol-Download → wasted Fix-Loop | Hoch | Mittel | al-coder Protokoll: Schritt 1 ist al_downloadsymbols; ohne Symbole harter Stop |
| **xlf-Infrastruktur fehlt** — al-coder versucht Übersetzungseinträge zu schreiben wo keine xlf-Datei existiert | Mittel | Niedrig | al-coder prüft Existenz von translations/; wenn nicht vorhanden: notiert in ERGEBNIS, erstellt KEINE neue Infrastruktur |
| **BC-Runtime-Mismatch** — Architect nimmt falsche Base-Object-Version an | Niedrig | Hoch | ARCH-02: app.json-Lesen ist Pflicht; BC-Runtime-Guard bei < 10.0 |
| **ID-Konflikt** — Architect proposed_id ist bereits vergeben | Mittel | Mittel | al-coder verifiziert proposed_id vor Code-Erstellung; passt ID an wenn nötig |
| **main-agent.agent.md Edit zu groß** — Zu viele Edits in einer Operation → Datei beschädigt | Niedrig | Hoch | T7 definiert 7 gezielte Edits; vollständige Datei vor Edits lesen; Edit-for-Edit vorgehen |

---

## Assumptions

Alle `[ASSUMED]`-Items aus RESEARCH.md §11 die diesen Plan betreffen:

| ID | Annahme | Konsequenz wenn falsch |
|----|---------|----------------------|
| A1 | T-Shirt-Sizing-Stunden sind Richtwerte (XS < 1h, S 1–4h, M 4–8h, L 8–16h, XL > 16h) | Fehler in Erwartungssteuerung beim Entwickler |
| A2 | `.xlf` Translation-Dateien existieren in Kundenprojekten | al-coder erstellt Einträge die nicht platzierbar sind → in ERGEBNIS notieren statt Fehler |
| A3 | `idRanges` in app.json ist die Source of Truth für ID-Reservierung | ID-Konflikte zwischen Agents und Entwicklern möglich |
| A4 | `runSubagent` übergibt JSON Plan Contract per Pfad, nicht inline | Wenn path-passing nicht unterstützt: Contract muss inline übergeben werden (Größen-Limit-Risiko) |
| A5 | al-architect hat KEIN `terminal`-Tool — nutzt `al-build-validation` Skill für Symbol-Download | Wenn Skill kein symbol-download exposed: Architect kann Base-Objekte nicht verifizieren |
| A6 | `validator_loop_count` Feld wird zu SESSION.md hinzugefügt und von main-agent korrekt inkrementiert | Validator verliert Loop-Zählung zwischen Aufrufen |

---

## Requirements-Coverage-Audit

| Requirement | Abgedeckt in | Status |
|-------------|-------------|--------|
| ARCH-01 | T2 (al-architect erstellen) | ✓ |
| ARCH-02 | T2 (app.json + alpackages lesen) | ✓ |
| ARCH-03 | T2 (T-Shirt-Sizing-Rubrik) | ✓ |
| ARCH-04 | T2 (JSON Plan Contract Schema) + T8 (SESSION.md contract_path) | ✓ |
| VALID-01 | T4 (al-validator erstellen, read-only) | ✓ |
| VALID-02 | T4 (5-Layer-Prüfung vollständig) | ✓ |
| VALID-03 | T4 (max. 2 Schleifen + BLOCKER-REPORT) + T8 (validator_loop_count) | ✓ |
| TEST-01 | T5 (al-tester + Explizit-Guard) + T7 (main-agent Guard) + T8 (tester_requested) | ✓ |
| TEST-02 | T5 (GIVEN/WHEN/THEN-Pattern) | ✓ |
| CODER-01 | T3 (al-coder erstellen, konsolidiert implementer+build-tester) | ✓ |
| CONTRACT-01 | T1 (ERGEBNIS Contract Instructions) + T2,T3,T4,T5 (alle neuen Agents) + T6 (al-reviewer) | ✓ |

**Keine ungedeckten Requirements. Keine Gaps.**

---

*Plan erstellt: 2026-06-18*
*Phase: 2 — Spezialist-Refactoring*
*Granularität: fine (11 Tasks, 4 Wellen)*
