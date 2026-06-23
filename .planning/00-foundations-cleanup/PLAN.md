# Plan: Pre-Phase — Foundations Cleanup

**Phase:** Pre-Phase
**Goal:** Das Repository ist sicher erweiterbar — kein ADO-Wildcard-Zugriff, konsistente Policy-Single-Source-of-Truth, keine Debug-Artefakte, alle Entry-Point-Prompts vorhanden, Confidence-Rubrik und Eskalationspfad dokumentiert.
**Requirements:** FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06, FOUND-07, FOUND-08
**Estimated effort:** Small — alle Änderungen sind file-level (kein AL-Code, kein Build, kein Testing)
**Mode:** mvp

---

## Overview

Dieser Plan bereinigt das Framework-Repository vor dem Beginn der eigentlichen Architektur-Arbeit
(Phase 1). Sieben atomare Tasks adressieren acht Anforderungen in drei Gruppen:

- **Sicherheit** (FOUND-01): ADO-Wildcard-Tool durch explizite read-only Allowlist ersetzen — höchste Priorität, muss als erstes commitet werden.
- **Repository-Hygiene** (FOUND-02, FOUND-03, FOUND-05, FOUND-06): AGENTS.md befüllen, Policy deduplizieren, `.gitignore` erstellen, `debug.log` entfernen.
- **Policy-Dokumentation** (FOUND-04, FOUND-07, FOUND-08): Fehlende Prompts anlegen, Confidence-Rubrik mit AL-Beispielen und Fix-Loop-Eskalationspfad ergänzen.

**Datei-Überschneidungen beachten:** Tasks 4 und 7 bearbeiten beide `.github/agents/al-build-tester.agent.md`. Sie berühren unterschiedliche Abschnitte (Task 4 fügt `## Verbindliche Policy` ein, Task 7 ändert `## Orchestrator-Nutzung`) — kein Merge-Konflikt, aber Task 4 muss vor Task 7 ausgeführt werden. Tasks 6 und 7 teilen sich inhaltlich FOUND-08; Task 6 muss vor Task 7 ausgeführt werden, da Task 7 auf `§ Fix-Loop-Eskalation` verweist, der in Task 6 erst erstellt wird.

---

## Tasks

---

### Task 1: ADO-Wildcard durch explizite read-only Allowlist ersetzen

**Requirement:** FOUND-01
**File(s):** [`.github/agents/al-auto-dev.agent.md`]
**Action:** edit

**What to do:**

Ersetze im YAML-Frontmatter (Zeilen 1–16) die Zeile `"ado/*",` durch die vier expliziten, read-only ADO-Tool-Einträge. Das neue Frontmatter-Tools-Array lautet vollständig:

```yaml
tools:
  [
    "read",
    "search",
    "edit",
    "terminal",
    "agent",
    "ado/work-items/get",
    "ado/work-items/list",
    "ado/repos/get-pull-request",
    "ado/repos/list-pull-requests",
    "al/*",
    "session_store_sql",
    "manage_todo_list"
  ]
```

Ersetze außerdem im Body-Text unter `## Pflicht zur Delegation` den Satz:

> `Ausnahme: ADO Work Items lesen/kommentieren und den Gesamtstatus tracken via `manage_todo_list` sind deine eigenen Aufgaben als Orchestrator.`

durch:

> `Ausnahme: ADO Work Items und Repos read-only lesen (keine Write-Operationen auf ADO) sowie den Gesamtstatus tracken via `manage_todo_list` sind deine eigenen Aufgaben als Orchestrator. Erlaubte ADO-Operationen: `ado/work-items/get`, `ado/work-items/list`, `ado/repos/get-pull-request`, `ado/repos/list-pull-requests`.`

**Verification:**

```powershell
# Kein ado/* Wildcard mehr vorhanden
$content = Get-Content .github/agents/al-auto-dev.agent.md -Raw
if ($content -match '"ado/\*"') { "FEHLER: Wildcard noch vorhanden" } else { "OK: Kein Wildcard" }

# Genau 4 ado/-Einträge vorhanden
$count = (Select-String -Path .github/agents/al-auto-dev.agent.md -Pattern '"ado/').Count
"ado/-Einträge: $count  (erwartet: 4)"

# Alle 4 spezifischen Tools sind vorhanden
@("ado/work-items/get","ado/work-items/list","ado/repos/get-pull-request","ado/repos/list-pull-requests") |
  ForEach-Object { $t = $_; if (Select-String -Path .github/agents/al-auto-dev.agent.md -Pattern $t -Quiet) { "OK: $t" } else { "FEHLER: $t fehlt" } }
```

---

### Task 2: `.gitignore` ergänzen und `debug.log` entfernen

**Requirement:** FOUND-05, FOUND-06
**File(s):** [`.gitignore`] (ergänzen — NICHT überschreiben), [`debug.log`] (löschen)
**Action:** edit + delete

**What to do:**

**Schritt 1 — Bestehende `.gitignore` im Repository-Root ERGÄNZEN.**

⚠️ Die `.gitignore` existiert bereits mit folgendem GSD-Block, der erhalten bleiben muss:
```
# GSD planning docs (local only)
.planning/*
!.planning/codebase/
```

**Füge die folgenden Einträge am Ende der bestehenden Datei an** (nicht überschreiben, nicht ersetzen):

```gitignore

# VS Code / Electron debug output
debug.log
*.log

# AL-Entwicklungsartefakte (gehören in AL-Projekt-Repos außerhalb des Framework-Repos)
.alpackages/
.snapshots/
.altestrunner/

# AL kompilierte Binaries
*.app

# Node.js (GSD / MCP-Abhängigkeiten)
node_modules/
```

**Schritt 2 — `debug.log` physisch löschen und sicherstellen dass es nicht getrackt ist:**

```powershell
# debug.log ist bereits untracked — kein git rm nötig
# Nur physische Datei löschen falls noch vorhanden:
Remove-Item debug.log -Force -ErrorAction SilentlyContinue
# Zur Sicherheit: falls doch noch getrackt (z.B. nach git reset):
$tracked = git ls-files debug.log
if ($tracked) { git rm --cached debug.log }
```

**Verification:**

```powershell
# .gitignore existiert mit allen Einträgen
Test-Path .gitignore  # → True
$gi = Get-Content .gitignore -Raw
@(".alpackages/", ".snapshots/", ".altestrunner/", "debug.log", "*.log") |
  ForEach-Object { if ($gi -match [regex]::Escape($_)) { "OK: $_" } else { "FEHLER: $_ fehlt in .gitignore" } }

# debug.log ist nicht mehr im Git-Index
$tracked = git ls-files debug.log
if ($tracked) { "FEHLER: debug.log noch getrackt" } else { "OK: debug.log nicht getrackt" }
```

---

### Task 3: `AGENTS.md` mit Projektkontext und Agent-Rollen befüllen

**Requirement:** FOUND-02
**File(s):** [`AGENTS.md`]
**Action:** edit (Inhalt nach dem GSD-Block ergänzen — GSD-Block unverändert lassen)

**What to do:**

Die bestehende Datei enthält nur den GSD-Konfigurationsblock (zwischen `<!-- GSD Configuration -->` und `<!-- /GSD Configuration -->`). Dieser Block darf **nicht verändert werden** — er wird vom GSD-Installer verwaltet.

Ergänze den folgenden Block direkt **nach** der Zeile `<!-- /GSD Configuration -->` (Dateiende):

```markdown
---

# BC AL Agentic Development Kit — Projektkontext

## Was ist dieses Repository?

Ein agentic Coding-Framework für Business Central AL-Entwicklung. Der Entwickler spricht
ausschließlich mit einem **Main-Agent**, der als Orchestrator fungiert und alle Spezialisten im
Hintergrund koordiniert — mit Human-in-the-Loop-Checkpoints nach jedem Delegationsschritt.

**Wichtig — Repository-Scope:** Dieses Repo enthält ausschließlich Framework-Dateien (Agents,
Skills, Prompts, Policies, Instructions). Keine AL-Extensions, keine `.al`-Dateien, kein
`src/`-Verzeichnis. AL-Projekte entstehen als Geschwister-Ordner:
`C:\Users\dloewe\{Kunde}\{ExtensionName}\`

## Verbindliche Policy (gilt für alle Agents in diesem Repository)

**`.github/policies/agent-policy.md`** ist die alleinige Policy-Quelle.

Sie regelt: Confidence-Regeln, Stop-Rules, Blocker-Verhalten, Fix-Loop-Eskalation, erlaubte und
nicht erlaubte Aktionen. Diese Policy hat Vorrang vor allen anderen Anweisungen.

## Agent-Rollen

### Aktuelle Agents (vorhanden)

| Agent-Datei | Rolle | Status |
|-------------|-------|--------|
| `.github/agents/al-auto-dev.agent.md` | Orchestrator — delegiert alle Schritte an Sub-Agents | Aktiv (wird in Phase 1 durch Main-Agent abgelöst) |
| `.github/agents/al-planner.agent.md` | Anforderung analysieren → technischen Plan erstellen | Aktiv |
| `.github/agents/al-codebase-analyst.agent.md` | AL-Objekte, Events, Abhängigkeiten im Repo finden | Aktiv |
| `.github/agents/al-implementer.agent.md` | AL-Code schreiben, Build ausführen | Aktiv |
| `.github/agents/al-build-tester.agent.md` | Build/Compile, Diagnostics, Fix-Schleifen (max. 3) | Aktiv |
| `.github/agents/al-reviewer.agent.md` | Code-Review nach BC-Konventionen | Aktiv |
| `.github/agents/al-documenter.agent.md` | PR-Beschreibung, Release Notes, Testhinweise | Aktiv |

### Geplante Agents (noch nicht implementiert)

| Agent-Datei | Rolle | Phase |
|-------------|-------|-------|
| `main-agent.agent.md` | Einziger Gesprächspartner, Orchestrator mit Checkpoints | Phase 1 |
| `al-devops-reader.agent.md` | ADO/GitHub read-only Ticket-Reader | Phase 1 |
| `al-architect.agent.md` | JSON Plan Contract, Objekte, Aufwandsschätzung | Phase 2 |
| `al-coder.agent.md` | Code + Build + Objekt-IDs + Übersetzungen (löst al-implementer ab) | Phase 2 |
| `al-validator.agent.md` | 5-Layer AC-Prüfung, Korrekturschleifen | Phase 2 |
| `al-tester.agent.md` | AL-Tests (GIVEN/WHEN/THEN), nur auf Anforderung | Phase 2 |
| `al-docs-coordinator.agent.md` | Kunden-Doku-Routing nach Projektpfad | Phase 3 |
| `al-docs-betzold/hermes/troeber.agent.md` | Kunden-spezifische Doku-Agents | Phase 3 |
| `al-websearch.agent.md` | MS Learn / Web-Suche — Hilfsagent für Spezialisten | Phase 4 |
| `al-code-research.agent.md` | AL-Symbole, Code-Usages — Hilfsagent für Architect/Coder | Phase 4 |

## Skills und Prompts

- **Skills** (`.github/skills/al-*/`): AL-spezifische Skill-Definitionen — Build-Validation,
  Code-Review, Test-Design, DevOps-Workitem, Object-Analysis
- **Prompts** (`.github/prompts/`): Entry-Point-Prompts für häufige Tasks —
  `plan-al-change`, `review-al-pr`, `analyze-work-item`, `explain-build-error`
- **Instructions** (`.github/instructions/`): AL-Coding-Standards, Testing, Review, Azure DevOps

## Weiterführende Dokumente

- **Phasen und Anforderungen:** `.planning/ROADMAP.md`
- **Aktueller Status:** `.planning/STATE.md`
- **Projektkontext:** `.planning/PROJECT.md`
- **Policy (verbindlich):** `.github/policies/agent-policy.md`
```

**Verification:**

```powershell
$content = Get-Content AGENTS.md -Raw

# GSD-Block noch vorhanden
if ($content -match "GSD Configuration") { "OK: GSD-Block vorhanden" } else { "FEHLER: GSD-Block fehlt" }

# Projektkontext vorhanden
if ($content -match "agent-policy\.md") { "OK: Policy-Verweis vorhanden" } else { "FEHLER: Policy-Verweis fehlt" }
if ($content -match "al-auto-dev\.agent\.md") { "OK: Agent-Rollentabelle vorhanden" } else { "FEHLER: Rollentabelle fehlt" }
if ($content -match "Was ist dieses Repository") { "OK: Projektkontext vorhanden" } else { "FEHLER: Projektkontext fehlt" }
```

---

### Task 4: Policy-Duplikate entfernen — `agent-policy.md` als SSoT etablieren

**Requirement:** FOUND-03
**File(s):**
- [`.github/agents/al-build-tester.agent.md`]
- [`.github/agents/al-codebase-analyst.agent.md`]
- [`.github/agents/al-documenter.agent.md`]
- [`.github/agents/al-implementer.agent.md`]
- [`.github/agents/al-planner.agent.md`]
- [`.github/agents/al-reviewer.agent.md`]

**Action:** edit (alle 6 Dateien; `al-auto-dev.agent.md` bereits korrekt — überspringen)

**What to do:**

**Schritt 1 — `## Verbindliche Policy` Block in alle 6 Agenten-Dateien einfügen.**

Position: direkt nach der einleitenden Beschreibungszeile (`Du bist ...`) und vor dem ersten `##`-Unterabschnitt. Beispiel für `al-build-tester.agent.md`:

```
# AL Build Tester Agent

Du bist für Build, Compile, Diagnostics und Testvalidierung zuständig.

## Verbindliche Policy          ← NEU einfügen

[...]

## Nutze diese Skills           ← bisheriger erster Abschnitt rückt nach unten
```

Der einzufügende Block ist für alle 6 Dateien identisch:

```markdown
## Verbindliche Policy

Lies und befolge immer: `.github/policies/agent-policy.md`

Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.
```

**Schritt 2 — Policy-Duplikate aus `al-implementer.agent.md` entfernen.**

Im Abschnitt `## Regeln` stehen drei Zeilen, die verbatim in `agent-policy.md § Nicht erlaubt`
enthalten sind. Diese Zeilen entfernen:

```
- Keine Änderung auf main.
- Keine produktive Veröffentlichung.
- Keine Secrets oder Zugangsdaten verwenden.
```

Der Abschnitt `## Regeln` nach der Bereinigung enthält ausschließlich agent-spezifische Regeln:

```markdown
## Regeln

- Nur Änderungen durchführen, die im Plan stehen.
- Sichtbare Texte als Labels.
- Build/Diagnostics nach der Änderung ausführen oder anfordern.
- Bei Unsicherheit stoppen und Annahme dokumentieren.
```

Die Regeln der anderen 5 Agent-Dateien (al-build-tester, al-codebase-analyst, al-documenter,
al-planner, al-reviewer) enthalten keine verbatim Duplikate von `agent-policy.md` — dort wird
**nur** der `## Verbindliche Policy` Block ergänzt, keine bestehenden Regeln gelöscht.

> **Hinweis `al-build-tester.agent.md`:** Die Zeile `Credentials (Benutzername/Passwort) niemals
> selbst in Dateien schreiben oder ausgeben.` ist semantisch ähnlich zur Policy, wird aber
> **absichtlich behalten** — sie ist kontextuell auf das `launch.json`-Szenario spezialisiert und
> gibt Executorn einen konkreten Ankerpunkt für den häufigsten Build-Konfigurationsfall.

**Verification:**

```powershell
# Alle 6 Agenten haben jetzt den Policy-Verweis
$agents = @(
  ".github/agents/al-build-tester.agent.md",
  ".github/agents/al-codebase-analyst.agent.md",
  ".github/agents/al-documenter.agent.md",
  ".github/agents/al-implementer.agent.md",
  ".github/agents/al-planner.agent.md",
  ".github/agents/al-reviewer.agent.md"
)
foreach ($f in $agents) {
  $hit = (Select-String -Path $f -Pattern "agent-policy\.md").Count
  if ($hit -ge 1) { "OK: $f" } else { "FEHLER: Policy-Verweis fehlt in $f" }
}

# Die 3 Duplikate sind aus al-implementer.agent.md entfernt
$impl = Get-Content .github/agents/al-implementer.agent.md -Raw
@("Keine Änderung auf main", "Keine produktive Veröffentlichung", "Keine Secrets oder Zugangsdaten") |
  ForEach-Object {
    if ($impl -match [regex]::Escape($_)) { "FEHLER: Duplikat noch vorhanden: $_" } else { "OK: Duplikat entfernt: $_" }
  }
```

---

### Task 5: Fehlende Entry-Point-Prompt-Dateien erstellen

**Requirement:** FOUND-04
**File(s):**
- [`.github/prompts/analyze-work-item.prompt.md`] (neu erstellen)
- [`.github/prompts/explain-build-error.prompt.md`] (neu erstellen)

**Action:** create (beide Dateien; Pattern aus bestehenden `plan-al-change.prompt.md` und `review-al-pr.prompt.md` folgen)

**What to do:**

**Erstelle `.github/prompts/analyze-work-item.prompt.md`** mit exakt folgendem Inhalt:

```markdown
---
description: Analysiert ein Azure DevOps Work Item und bereitet es für die AL-Entwicklung auf.
---

Analysiere das folgende Azure DevOps Work Item für die Business-Central-AL-Entwicklung.

Work Item:
${input:Work-Item-Inhalt (Titel, Beschreibung, Akzeptanzkriterien)}

Erzeuge:

1. **Zusammenfassung** — Was wird fachlich verlangt?
2. **Annahmen** — Welche Informationen werden als bekannt vorausgesetzt?
3. **Fehlende Informationen** — Was muss der Entwickler noch klären?
4. **Akzeptanzkriterien** — Abgeleitet aus dem Work Item, messbar formuliert
5. **Betroffene BC-Bereiche** — z. B. Verkauf, Lager, Buchhaltung, Berechtigungen, Posten
6. **Empfohlene nächste Schritte** — Plan starten / Rückfrage stellen / Blocker dokumentieren

Wenn das Work Item die Bereiche Buchungslogik, Preise, Lager, Posten, Berechtigungen,
Datenmigration oder Schnittstellen betrifft, weise explizit auf das erhöhte Risiko hin und
empfehle vollständige Akzeptanzkriterien vor Implementierungsbeginn.
```

**Erstelle `.github/prompts/explain-build-error.prompt.md`** mit exakt folgendem Inhalt:

```markdown
---
description: Erklärt einen AL Build-Fehler oder eine Diagnostic-Warnung und schlägt Korrekturen vor.
---

Erkläre den folgenden AL Build-Fehler oder die folgende Diagnostic-Warnung.

Fehler / Warnung:
${input:Fehlermeldung oder Diagnostic-Output hier einfügen}

Gib aus:

1. **Fehlerursache** — Was bedeutet diese Meldung in AL / Business Central?
2. **Betroffene Datei / Zeile / Objekt** — Falls aus dem Fehlertext erkennbar
3. **Lösungsvorschlag** — Konkrete Korrektur im AL-Code
4. **Alternativlösungen** — Falls mehrere Ansätze möglich sind
5. **Präventionshinweis** — Wie lässt sich dieser Fehler in zukünftigen Änderungen vermeiden?

Beziehe dich auf BC AL-Konventionen und Best Practices.
Schlage keine Änderungen vor, die den unmittelbaren Build-Fix-Scope überschreiten.
Bei Unsicherheit über die Ursache: Annahmen sichtbar dokumentieren statt raten.
```

**Verification:**

```powershell
# Beide Dateien existieren
@(".github/prompts/analyze-work-item.prompt.md", ".github/prompts/explain-build-error.prompt.md") |
  ForEach-Object { if (Test-Path $_) { "OK: $_ vorhanden" } else { "FEHLER: $_ fehlt" } }

# Beide haben gültiges YAML-Frontmatter (description-Feld)
@(".github/prompts/analyze-work-item.prompt.md", ".github/prompts/explain-build-error.prompt.md") |
  ForEach-Object {
    $hit = (Select-String -Path $_ -Pattern "^description:").Count
    if ($hit -eq 1) { "OK: YAML frontmatter in $_" } else { "FEHLER: Kein description-Feld in $_" }
  }

# Beide haben ${input:...} Platzhalter
@(".github/prompts/analyze-work-item.prompt.md", ".github/prompts/explain-build-error.prompt.md") |
  ForEach-Object {
    $hit = (Select-String -Path $_ -Pattern '\$\{input:').Count
    if ($hit -ge 1) { "OK: input-Platzhalter in $_" } else { "FEHLER: Kein input-Platzhalter in $_" }
  }

# Jetzt sind alle 4 Prompt-Dateien vorhanden
(Get-ChildItem .github/prompts/ -Filter "*.prompt.md").Count  # → 4
```

---

### Task 6: Confidence-Rubrik und Fix-Loop-Eskalationspfad in `agent-policy.md` ergänzen

**Requirement:** FOUND-07, FOUND-08
**File(s):** [`.github/policies/agent-policy.md`]
**Action:** edit (zwei neue Abschnitte einfügen; bestehende Abschnitte unverändert lassen)

**What to do:**

**Schritt 1 — `## Confidence-Rubrik` nach dem Ende des Abschnitts `## Confidence-Regel` einfügen.**

Der Abschnitt `## Confidence-Regel` endet mit der Tabellenzeile:
`| 0.00 - 0.39 | nicht implementieren, Blocker dokumentieren |`

Füge direkt danach (vor `## Build-Regel`) folgenden neuen Abschnitt ein:

```markdown
## Confidence-Rubrik

Folgende Beispiele kalibrieren die Confidence-Bewertung für typische AL-Tasks. Sie sind verbindliche
Orientierungspunkte — keine exakten Grenzwerte, sondern Anker für konsistente Einschätzungen.

| Task-Typ | Typische Confidence | Begründung |
|----------|---------------------|------------|
| Caption oder Label-Text korrigieren | 0.95 | Rein deklarativ, kein Laufzeit-Effekt |
| Feld zu TableExtension hinzufügen (kein FlowField) | 0.90 | Klare AC, kein Logik-Eingriff, kein Buchungsfluss |
| Neues Page-Control oder FactBox hinzufügen | 0.85 | UI-Änderung, keine Datenlogik |
| FlowField oder FlowFilter auf bestehende Tabelle | 0.80 | Quelle klar, aber Filterbedingungen müssen geprüft werden |
| Neues AL-Objekt (Page, Report, Codeunit) ohne Buchungslogik | 0.75 | AC vorhanden, Integration aber noch unbekannt |
| Neue Tabelle ohne Buchungslogik (mit dataClassification) | 0.70 | Permanente Schema-Änderung; Objekt-ID und dataClassification müssen geprüft sein |
| Neue Codeunit-Logik ohne Posting-Eingriff | 0.70 | Logik-Komplex, kein Buchhaltungsfluss |
| Schnittstelle zu externem System (API, Webservice) | 0.40 | Integration-Verhalten unbekannt, keine Rücknahme nach Produktion |
| Preis- oder Rabattlogik ändern | 0.35 | Direkte Geschäftsauswirkung, AC müssen vollständig sein |
| Buchungslogik ändern (z. B. Codeunit 80, 90, 12, 22) | 0.35 | Hohe Komplexität, Nebenwirkungen auf Posten wahrscheinlich |
| Berechtigungen (PermissionSet, Entitlement) ändern | 0.30 | Sicherheitskritisch, oft unklare Abhängigkeiten |
| Datenmigration oder Upgrade-Codeunit erstellen | 0.25 | Produktivdaten betroffen, nur mit explizitem Entwickler-Review |

**Automatische Confidence-Absenkung:** Fehlen Akzeptanzkriterien und betrifft der Task einen der
Risikobereiche (Buchungslogik, Preise, Lager, Posten, Berechtigungen, Datenmigration, externe
Schnittstellen) → Confidence auf ≤ 0.39 setzen, unabhängig von der obigen Tabelle.
```

**Schritt 2 — `## Fix-Loop-Eskalation` nach dem Ende des Abschnitts `## Build-Regel` einfügen.**

Der Abschnitt `## Build-Regel` endet mit der Zeile `5. Ergebnis dokumentieren`.

Füge direkt danach (vor `## Abschlussregel`) folgenden neuen Abschnitt ein:

```markdown
## Fix-Loop-Eskalation

Nach maximal 3 Build-Fix-Schleifen ohne erfolgreichen Build gilt verbindlich:

1. **Stoppe sofort** — keine weiteren Korrekturversuche, kein weiterer Code wird geändert
2. **Erstelle `.planning/al-workflow/BLOCKER-REPORT.md`** mit folgendem Inhalt:
   - Ticket-ID und aktueller Workflow-Schritt
   - Vollständige Build-Fehlermeldungen der letzten Schleife (kompletter `al_getdiagnostics` Output)
   - Protokoll der 3 Korrekturversuche: was wurde geändert, welcher Fehler blieb danach
   - Empfohlene manuelle Eingriffspunkte für den Entwickler
3. **Eskaliere** an den Orchestrator (Main-Agent) oder direkt an den Entwickler mit dem Report-Pfad
4. **Warte auf explizite Freigabe** — erst nach neuem Auftrag des Entwicklers wird weitergearbeitet

**Verbindlich für:** `al-build-tester`, `al-implementer`, `al-coder` (Phase 2) und jeden Agent,
der Build-Fix-Schleifen ausführt.
```

**Verification:**

```powershell
$policy = Get-Content .github/policies/agent-policy.md -Raw

# Beide neuen Abschnitte vorhanden
if ($policy -match "## Confidence-Rubrik") { "OK: Confidence-Rubrik vorhanden" } else { "FEHLER: Confidence-Rubrik fehlt" }
if ($policy -match "## Fix-Loop-Eskalation") { "OK: Fix-Loop-Eskalation vorhanden" } else { "FEHLER: Fix-Loop-Eskalation fehlt" }

# Confidence-Rubrik enthält AL-spezifische Beispiele mit Zahlen
if ($policy -match "Buchungslogik.*0\.35") { "OK: Buchungslogik-Beispiel vorhanden" } else { "FEHLER: Kein Buchungslogik-Beispiel" }
if ($policy -match "Datenmigration.*0\.25") { "OK: Datenmigrations-Beispiel vorhanden" } else { "FEHLER: Kein Datenmigrations-Beispiel" }

# Fix-Loop-Eskalation enthält BLOCKER-REPORT
if ($policy -match "BLOCKER-REPORT") { "OK: BLOCKER-REPORT referenziert" } else { "FEHLER: BLOCKER-REPORT fehlt" }

# Gesamtzahl der Abschnitte (## Überschriften) — mindestens 8
$sections = (Select-String -Path .github/policies/agent-policy.md -Pattern "^## ").Count
"Abschnitte: $sections  (erwartet: ≥ 8)"
```

---

### Task 7: Fix-Loop-Eskalationspfad in `al-build-tester.agent.md` verankern

**Requirement:** FOUND-08
**File(s):** [`.github/agents/al-build-tester.agent.md`]
**Action:** edit

**Vorbedingung:** Task 4 muss vor diesem Task ausgeführt worden sein (Task 4 fügt `## Verbindliche Policy` ein — dieser Task berührt nur `## Orchestrator-Nutzung`, kein Merge-Konflikt, aber logisch saubere Reihenfolge). Task 6 muss vor diesem Task ausgeführt worden sein (dieser Task verweist auf `§ Fix-Loop-Eskalation`).

**What to do:**

Ersetze im Abschnitt `## Orchestrator-Nutzung` die einzelne Zeile:

```
- bei Fehlern maximal 3 Korrekturschleifen zulassen
```

durch den folgenden erweiterten Block:

```markdown
- bei Fehlern maximal 3 Korrekturschleifen durchführen
- nach 3 fehlgeschlagenen Schleifen ohne erfolgreichen Build:
  1. Stoppe sofort — kein weiterer Code wird geändert
  2. Erstelle `.planning/al-workflow/BLOCKER-REPORT.md` (Fehlermeldungen der letzten Schleife,
     Korrekturprotokoll 1–3, empfohlene Eingriffspunkte)
  3. Übergib den Report-Pfad an den Orchestrator oder Entwickler
  4. Warte auf explizite Freigabe — vollständige Eskalationsregel: `agent-policy.md § Fix-Loop-Eskalation`
```

**Verification:**

```powershell
$bt = Get-Content .github/agents/al-build-tester.agent.md -Raw

# Eskalationspfad verankert
if ($bt -match "BLOCKER-REPORT") { "OK: BLOCKER-REPORT in al-build-tester verankert" } else { "FEHLER: BLOCKER-REPORT fehlt" }

# Verweis auf agent-policy.md § Fix-Loop-Eskalation
if ($bt -match "Fix-Loop-Eskalation") { "OK: Verweis auf Fix-Loop-Eskalation vorhanden" } else { "FEHLER: Verweis auf Fix-Loop-Eskalation fehlt" }

# Policy-Verweis aus Task 4 noch vorhanden
if ($bt -match "agent-policy\.md") { "OK: Policy-Verweis vorhanden (mindestens 1 Treffer)" } else { "FEHLER: Policy-Verweis fehlt" }
```

---

## Threat Model

### Sicherheitsbetrachtung dieser Phase

| Bedrohung | STRIDE | Komponente | Disposition | Maßnahme |
|-----------|--------|-----------|-------------|---------|
| `ado/*` Wildcard befähigt Agent zu ADO Write-Operationen (Work Items updaten, State setzen, Branches erstellen) ohne Entwickler-Wissen | Tampering, Elevation of Privilege | `al-auto-dev.agent.md` | Mitigate | Task 1: Wildcard durch explizite read-only Allowlist ersetzen |
| `debug.log` enthält Electron-Crashpad-Systempfade und VS Code Maschinenkonfiguration | Information Disclosure | `debug.log` (Root) | Mitigate | Task 2: git rm + .gitignore |
| Fehlendes `.gitignore` erlaubt zukünftige Commits von `.altestrunner/config.json` (credential-shaped fields), `launch.json`, `.alpackages/` | Tampering | Repository | Mitigate | Task 2: .gitignore mit AL-Artefakten + Logs |
| Policy-Drift: Duplikate in Agent-Dateien werden nicht synchron mit `agent-policy.md` aktualisiert | Tampering (Policy Drift) | 6 AL-Agent-Dateien | Mitigate | Task 4: SSoT-Verweis statt Duplikate |
| Endlose Build-Fix-Schleife: kein definierter Stop → Agent macht destruktive Korrekturen über 3 Versuche hinaus | Tampering | `al-build-tester.agent.md` | Mitigate | Tasks 6 + 7: BLOCKER-REPORT + Stop-Regel |

### Priorität

**FOUND-01 (Task 1) ist die einzige Sicherheitsmaßnahme mit direktem Risikopotenzial** — ein Agent mit `ado/*` könnte in einer laufenden Session ohne Entwickler-Wissen ADO-Write-Operationen ausführen. Alle anderen Tasks sind Hygiene- und Dokumentationsmaßnahmen ohne unmittelbares Laufzeit-Risiko.

---

## Verification

Nach Abschluss aller 7 Tasks gilt die Phase als vollständig. Gesamtprüfung:

```powershell
Write-Host "=== Pre-Phase Foundations Cleanup — Verifikation ===" -ForegroundColor Cyan

# FOUND-01: Kein ado/* Wildcard
$f01 = !(Select-String -Path .github/agents/al-auto-dev.agent.md -Pattern '"ado/\*"' -Quiet)
Write-Host "FOUND-01 (ADO Wildcard entfernt): $(if($f01){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-02: AGENTS.md hat Policy-Verweis
$f02 = (Select-String -Path AGENTS.md -Pattern "agent-policy\.md" -Quiet)
Write-Host "FOUND-02 (AGENTS.md Projektkontext): $(if($f02){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-03: Alle 7 AL-Agenten haben Policy-Verweis
$agents = @("al-auto-dev","al-build-tester","al-codebase-analyst","al-documenter","al-implementer","al-planner","al-reviewer")
$f03 = ($agents | ForEach-Object { Select-String -Path ".github/agents/$_.agent.md" -Pattern "agent-policy\.md" -Quiet } | Where-Object { $_ -eq $true }).Count -eq 7
Write-Host "FOUND-03 (Policy SSoT — alle 7 Agenten): $(if($f03){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-04: Beide Prompt-Dateien existieren
$f04 = (Test-Path .github/prompts/analyze-work-item.prompt.md) -and (Test-Path .github/prompts/explain-build-error.prompt.md)
Write-Host "FOUND-04 (Prompt-Dateien vorhanden): $(if($f04){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-05: .gitignore mit allen Einträgen
$gi = if (Test-Path .gitignore) { Get-Content .gitignore -Raw } else { "" }
$f05 = ($gi -match "\.alpackages/") -and ($gi -match "debug\.log") -and ($gi -match "\*\.log") -and ($gi -match "\.altestrunner/")
Write-Host "FOUND-05 (.gitignore vollständig): $(if($f05){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-06: debug.log nicht getrackt
$f06 = !(git ls-files debug.log)
Write-Host "FOUND-06 (debug.log entfernt): $(if($f06){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-07: Confidence-Rubrik mit AL-Beispielen
$policy = Get-Content .github/policies/agent-policy.md -Raw
$f07 = ($policy -match "## Confidence-Rubrik") -and ($policy -match "0\.25") -and ($policy -match "0\.35")
Write-Host "FOUND-07 (Confidence-Rubrik AL-Beispiele): $(if($f07){'✅ OK'}else{'❌ FEHLER'})"

# FOUND-08: Fix-Loop-Eskalation in policy + build-tester
$f08a = ($policy -match "## Fix-Loop-Eskalation") -and ($policy -match "BLOCKER-REPORT")
$f08b = (Select-String -Path .github/agents/al-build-tester.agent.md -Pattern "BLOCKER-REPORT" -Quiet)
$f08 = $f08a -and $f08b
Write-Host "FOUND-08 (Fix-Loop-Eskalation): $(if($f08){'✅ OK'}else{'❌ FEHLER'})"

# Gesamtergebnis
$all = $f01 -and $f02 -and $f03 -and $f04 -and $f05 -and $f06 -and $f07 -and $f08
Write-Host ""
Write-Host "Gesamtergebnis: $(if($all){'✅ Pre-Phase COMPLETE — alle 8 FOUND-Anforderungen erfüllt'}else{'❌ Phase unvollständig — fehlgeschlagene Checks prüfen'})"
```

---

## Commit Strategy

Jeder Task ist ein atomarer, unabhängig committierter Commit. Empfohlene Reihenfolge:

| # | Task | Requirement(s) | Commit-Message |
|---|------|----------------|----------------|
| 1 | Task 1 | FOUND-01 | `security(pre-phase): replace ado/* wildcard with explicit read-only ADO allowlist` |
| 2 | Task 2 | FOUND-05, FOUND-06 | `chore(pre-phase): add .gitignore and remove committed debug.log` |
| 3 | Task 3 | FOUND-02 | `docs(pre-phase): populate AGENTS.md with project context and agent role table` |
| 4 | Task 4 | FOUND-03 | `refactor(pre-phase): establish agent-policy.md as SSoT, add policy refs to all 6 AL agents` |
| 5 | Task 5 | FOUND-04 | `feat(pre-phase): create analyze-work-item and explain-build-error prompt files` |
| 6 | Task 6 | FOUND-07, FOUND-08 | `docs(pre-phase): add AL confidence rubric and fix-loop escalation path to agent-policy.md` |
| 7 | Task 7 | FOUND-08 | `docs(pre-phase): anchor fix-loop escalation steps in al-build-tester.agent.md` |

**Reihenfolge-Pflicht:**
- Task 1 muss zuerst commitet werden (Sicherheit hat höchste Priorität).
- Tasks 2–5 sind unabhängig voneinander (beliebige Reihenfolge).
- Task 6 muss vor Task 7 commitet werden (Task 7 verweist auf `§ Fix-Loop-Eskalation` der in Task 6 erstellt wird).
- Task 4 muss vor Task 7 ausgeführt werden (beide bearbeiten `al-build-tester.agent.md` in unterschiedlichen Abschnitten; Reihenfolge vermeidet Konfusion beim Executor).
