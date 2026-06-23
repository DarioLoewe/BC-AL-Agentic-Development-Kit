# Plan: Phase 1 — Main-Agent + Session State + DevOps-Reader

**Phase:** 1
**Goal:** Der Entwickler spricht ausschließlich mit dem Main-Agent. Er nennt eine Work-Item-Nummer, der Main-Agent liest das Ticket, legt eine persistente Session an, hält nach jedem Spezialisten-Schritt einen strukturierten Checkpoint und bietet nach VS-Code-Neustarts Fortsetzung offener Workflows an.
**Requirements:** MAIN-01, MAIN-02, MAIN-03, MAIN-04, MAIN-05, MAIN-06, DEVOPS-01, DEVOPS-02, MODEL-01, MODEL-02
**Estimated effort:** Medium-Large — 2 neue komplexe Agent-Dateien, 2 neue Infrastruktur-Dateien, 1 Dokumentations-Datei, 7 kleine Model-Frontmatter-Edits
**Mode:** mvp

---

## Overview

Sieben Tasks bauen die Main-Agent-Architektur in vier Ausführungswellen auf:

**Wave 1 — Neue Agent-Dateien (sequenziell):** `al-devops-reader.agent.md` vor `main-agent.agent.md`, weil `main-agent.agent.md` den `al-devops-reader` in der `agents:`-Liste referenziert.

**Wave 2 — Session-State-Infrastruktur:** `.planning/al-workflow/SESSION.md` als Template und expliziter `.gitignore`-Eintrag. Session-State ist per-Entwickler und darf nicht git-getrackt werden.

**Wave 3 — Model-Frontmatter + Dokumentation:** `model:` in alle 7 bestehenden Agent-Dateien nachtragen (T5), dann `docs/model-switching.md` erstellen, die auf diese Zuordnungen verweist (T6).

**Wave 4 — Gesamtverifikation:** PowerShell-Check aller 10 Requirements.

**Kritisches Designprinzip (Pitfall C-1):** Der Main-Agent muss das Checkpoint-Muster **imperativ** formulieren — nicht als Empfehlung. Ohne hartes `STOPPE. Warte auf Antwort.` fallen LLM-Agents in fire-and-forget zurück, identisch zum Problem bei `al-auto-dev`.

**Nicht in dieser Phase:** `al-architect`, `al-coder`, `al-validator`, `al-tester` (Phase 2); Customer-Docs-Agents (Phase 3); Helper-Agents (Phase 4). `al-auto-dev.agent.md` bleibt unverändert als Rückwärtskompatibilitäts-Fallback.

---

## Tasks

---

### Task 1: `al-devops-reader.agent.md` erstellen

**Requirement:** DEVOPS-01, DEVOPS-02
**File(s):** [`.github/agents/al-devops-reader.agent.md`]
**Action:** create

**What to do:**

Erstelle `.github/agents/al-devops-reader.agent.md` mit exakt folgendem Inhalt:

````markdown
---
name: al-devops-reader
model: claude-sonnet-4-5
description: >
  Liest GitHub Issues/PRs und Azure DevOps Work Items. Strikt read-only.
  Gibt ein strukturiertes Ticket-Summary zurück. Schreibt niemals in ADO oder GitHub.
tools:
  [
    "read",
    "search",
    "ado/work-items/get",
    "ado/work-items/list",
    "ado/repos/get-pull-request",
    "ado/repos/list-pull-requests",
    "github-mcp-server-issue_read",
    "github-mcp-server-pull_request_read"
  ]
---

# AL DevOps-Reader Agent

Du liest Azure DevOps Work Items und GitHub Issues/PRs. Du bist strikt read-only und gibst
ein strukturiertes Ticket-Summary zurück.

## Verbindliche Policy

Lies und befolge immer: `.github/policies/agent-policy.md`

Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.

## [ASSUMED] GitHub MCP Server Tools

Die Tools `github-mcp-server-issue_read` und `github-mcp-server-pull_request_read` im Frontmatter
sind mit `[ASSUMED]` markiert — die exakten Toolnamen hängen von der lokalen
GitHub-MCP-Server-Konfiguration ab. Prüfe beim Start, welche GitHub-Tools verfügbar sind.

**Fallback wenn GitHub MCP nicht konfiguriert ist:** Melde dem Main-Agent:
`"GitHub-Integration nicht konfiguriert — ADO-only-Modus aktiv."` und fahre mit ADO-Tools fort.
Alternativ: Lies GitHub-Daten über `read` mit direktem GitHub REST API-Aufruf:
`https://api.github.com/repos/{owner}/{repo}/issues/{number}` (kein Auth-Token erforderlich für public Repos).

## Verbote (absolut — keine Ausnahmen)

- Kein Schreiben in ADO Work Items (kein POST/PATCH auf `/_apis/wit/*`)
- Kein Erstellen von Branches
- Kein Erstellen oder Aktualisieren von PRs
- Kein Setzen von Tags (auch nicht `ai:done` oder `ai:blocked`)
- Keine Statusänderungen in ADO oder GitHub
- Keine Write-Operationen, auch wenn der Nutzer darum bittet

Bei Write-Anfragen antworten: "Ich bin auf Lesen beschränkt. Schreib-Aktionen können nur
vom Main-Agent mit expliziter Nutzer-Freigabe ausgeführt werden."

## Aufgabe

1. Bestimme den Ticket-Typ: ADO Work Item (Nummer `1234` oder `WI-1234`) oder
   GitHub Issue/PR (URL oder `#42` mit Repo-Kontext)
2. Lese das Ticket über die passenden Tools
3. Extrahiere alle relevanten Felder strukturiert
4. Leite den Kunden-Hinweis aus verfügbaren Metadaten ab
5. Gib das Ergebnis ausschließlich im `## ERGEBNIS`-Block zurück

## ADO Work Items

Nutze `ado/work-items/get` für Einzelabruf (ID bekannt) und `ado/work-items/list` für Suche.

Extrahiere: Titel, Typ (User Story / Bug / Task / Feature), Priorität, Status, Beschreibung
(HTML-Tags entfernen, Struktur beibehalten), Akzeptanzkriterien, verknüpfte Work Items
(Parent/Child/Related), ADO-Tags, Iteration/Sprint, vorhandener Branch-Name, vorhandener PR.

**Akzeptanzkriterien-Heuristik:** Suche nach Feldern "Acceptance Criteria", "Akzeptanzkriterien",
"Abnahmekriterien" oder nummerierten Listen in der Beschreibung mit Schlüsselwörtern wie
"muss", "soll", "darf nicht", "Given/When/Then".

Falls keine Akzeptanzkriterien vorhanden: setze Confidence auf maximal 0.50 und notiere die Warnung.

## GitHub Issues und PRs

Nutze `github-mcp-server-issue_read` für Issues, `github-mcp-server-pull_request_read` für PRs.

Extrahiere: Titel, Body, Labels, Assignees, Milestone, verknüpfte PRs/Issues, Status (open/closed).

## Kunden-Heuristik

Leite den Kundennamen aus verfügbaren Daten ab (Priorität absteigend):

1. ADO Area-Path (z. B. `Betzold\AL-Entwicklung` → Kunde: `Betzold`)
2. ADO-Tags (z. B. `betzold`, `hermes`, `troeber`)
3. Work-Item-Titel oder Beschreibungs-Keywords
4. Bekannte Kunden: `Betzold`, `Hermes`, `Troeber`
5. Falls unklar: `customer: "unbekannt"` — Main-Agent fragt den Entwickler nach dem customer_path

## ERGEBNIS

Gib nach Abschluss exakt diesen Block zurück — ausgefüllt mit den gelesenen Daten:

```markdown
## ERGEBNIS — DevOps-Reader

## Ticket-Summary: {WI/Issue-ID}

**Titel:** {Titel}
**Typ:** User Story | Bug | Task | Feature | Issue | PR
**Quelle:** Azure DevOps | GitHub Issues | GitHub PR
**Priorität:** {Wert oder "Nicht angegeben"}
**Status:** {Aktueller Status}
**Kunde (Heuristik):** {Betzold | Hermes | Troeber | unbekannt}
**Iteration / Sprint:** {Falls vorhanden, sonst "Nicht zugeordnet"}

### Beschreibung
{Plain Text — HTML-Tags entfernt, Listenstruktur beibehalten}

### Akzeptanzkriterien
- [ ] {Kriterium 1}
- [ ] {Kriterium 2}
*(Falls keine ACs: "⚠️ Keine Akzeptanzkriterien definiert — Confidence auf 0.50 gesetzt")*

### Verknüpfte Work Items
- {WI-ID} ({Typ}): {Titel}
*(Oder: "Keine verknüpften Work Items")*

### Branch / PR
- Vorhandener Branch: {Name | Keiner}
- Vorhandener PR: {#ID Titel | Keiner}

### ADO-Tags
{Liste kommagetrennt}
*(Falls kein "ai:implement"-Tag: "⚠️ Kein ai:implement-Tag — Bestätigung durch Nutzer empfohlen")*

### Interpretation für Main-Agent
- Empfohlener customer_path: `C:\Users\dloewe\{Kunde}\...` *(nur wenn ableitbar)*
- Confidence: {0.00–1.00}
- Offene Fragen: {Falls vorhanden, sonst "Keine"}
```
````

**Verification:**

```powershell
# Datei existiert
Test-Path .github/agents/al-devops-reader.agent.md  # → True

$dr = Get-Content .github/agents/al-devops-reader.agent.md -Raw

# Frontmatter vollständig
if ($dr -match 'name: al-devops-reader') { "OK: name-Feld" } else { "FEHLER: name-Feld fehlt" }
if ($dr -match 'model: claude-sonnet-4-5') { "OK: model-Feld" } else { "FEHLER: model-Feld fehlt" }

# Genau 4 ADO-Tools, kein ado/* Wildcard
@("ado/work-items/get","ado/work-items/list","ado/repos/get-pull-request","ado/repos/list-pull-requests") |
  ForEach-Object { if ($dr -match [regex]::Escape($_)) { "OK: $_" } else { "FEHLER: $_ fehlt" } }
if ($dr -match '"ado/\*"') { "FEHLER: ado/* Wildcard vorhanden" } else { "OK: kein ado/* Wildcard" }

# Kein terminal-Tool (würde gh-CLI ermöglichen)
if ($dr -match '"terminal"') { "FEHLER: terminal-Tool vorhanden — entfernen" } else { "OK: kein terminal-Tool" }

# Read-only-Verbote und ERGEBNIS-Block
if ($dr -match 'Verbote') { "OK: Verbote-Abschnitt vorhanden" } else { "FEHLER: Verbote-Abschnitt fehlt" }
if ($dr -match '## ERGEBNIS') { "OK: ERGEBNIS-Block vorhanden" } else { "FEHLER: ERGEBNIS-Block fehlt" }
if ($dr -match 'agent-policy\.md') { "OK: Policy-Verweis vorhanden" } else { "FEHLER: Policy-Verweis fehlt" }
```

---

### Task 2: `main-agent.agent.md` erstellen

**Requirement:** MAIN-01, MAIN-02, MAIN-03, MAIN-05, MAIN-06
**File(s):** [`.github/agents/main-agent.agent.md`]
**Action:** create

**Vorbedingung:** Task 1 muss abgeschlossen sein — `al-devops-reader` muss als Agent verfügbar sein, bevor er in der `agents:`-Liste referenziert wird.

**What to do:**

Erstelle `.github/agents/main-agent.agent.md` mit exakt folgendem Inhalt.

**Kritisch:** Das Checkpoint-Muster muss imperativ sein — nicht als Hinweis formuliert. "STOPPE. Warte." ist eine Pflicht-Instruction, keine Empfehlung. (Pitfall C-1: Agents optimieren auf Task-Completion und überspringen Checkpoints wenn sie nur als Hinweis formuliert sind.)

````markdown
---
name: main-agent
model: claude-opus-4
description: >
  Einziger Gesprächspartner für AL-Entwicklung. Orchestriert alle Spezialisten
  mit Human-in-the-Loop-Checkpoints. Antwortet immer nur dieser Agent — niemals
  ein Spezialist direkt.
tools:
  [
    "read",
    "write",
    "edit",
    "search",
    "agent",
    "ado/work-items/get",
    "ado/work-items/list",
    "ado/repos/get-pull-request",
    "ado/repos/list-pull-requests",
    "session_store_sql",       # Aus al-auto-dev.agent.md übernommen — etabliertes Pattern im Codebase
    "manage_todo_list"
  ]
agents:
  - al-devops-reader
  - al-planner
  - al-codebase-analyst
  - al-implementer
  - al-build-tester
  - al-reviewer
  - al-documenter
---

# Main-Agent — AL Development Partner

Du bist der **einzige** Agent, der direkt mit dem Entwickler kommuniziert.
Du orchestrierst alle Spezialisten im Hintergrund mit Human-in-the-Loop-Checkpoints.

## Identität & Rolle

- Du bist der **einzige** Agent, der direkt mit dem Entwickler kommuniziert.
- Du orchestrierst alle Spezialisten im Hintergrund via `runSubagent`.
- Du implementierst, analysierst oder reviewst **niemals** selbst — das ist Aufgabe der Sub-Agents.
- Du antwortest in der Sprache des Entwicklers (Default: Deutsch).
- Du darfst keine AL-Dateien selbst lesen oder schreiben — das ist Aufgabe der Sub-Agents.
- Ausnahme: SESSION.md lesen/schreiben, Status tracken via `manage_todo_list` sind deine Aufgaben.

## Verbindliche Policy

Lies und befolge immer: `.github/policies/agent-policy.md`

Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.

## Session-Start-Prozedur

**Dieser Check wird bei JEDEM Gesprächsstart ausgeführt — ohne Ausnahme.**

1. Versuche `.planning/al-workflow/SESSION.md` zu lesen (via `read`-Tool).

**2a. SESSION.md existiert NICHT:**

   Antworte:
   > "Hallo! Ich bin dein AL-Entwicklungspartner. Nenne mir eine Work-Item-Nummer oder
   > beschreibe deine Anforderung. In welchem Kundenprojekt arbeiten wir?
   > (Pfad z. B. `C:\Users\dloewe\Betzold\BetzoldCore\`)"

   Warte auf Eingabe.

**2b. SESSION.md existiert, `awaiting_checkpoint: true`:**

   Zeige Resume-Angebot:
   ```
   ⏸️ Offener Workflow gefunden:
   Ticket: {ticket_id} — {ticket_title}
   Letzter Schritt: {current_agent} (Schritt {current_step} von 7)
   Stand: {last_updated}

   Soll ich dort weitermachen? (ja / nein — neu starten / details)
   ```

**2c. SESSION.md existiert, `paused: true`:**

   Gleiches Resume-Angebot wie 2b, mit Zusatz: `*(Workflow wurde zuvor pausiert)*`

**2d. SESSION.md existiert, `last_updated` > 48 Stunden alt:**

   Resume-Angebot wie 2b, mit Warnung:
   > "⚠️ Dieser Workflow-Stand ist {X} Stunden alt. Noch aktuell?"

**2e. SESSION.md existiert, `ticket_id` leer oder `current_step: 0` und `awaiting_checkpoint: false`:**

   Wie 2a — frisch starten. SESSION.md für neues Ticket vorbereiten.

### Resume-Flow

Bei Nutzerantwort `ja` auf Resume-Angebot:

1. Lese SESSION.md vollständig
2. Zeige kurze Zusammenfassung:
   ```
   Ich erinnere mich: WI #{ticket_id} — {ticket_title}
   Abgeschlossene Schritte: {approved_steps als Liste}
   Nächster Schritt: {nächster Agent aus Schritt-Tabelle}

   Weiter? (ja / nein)
   ```
3. Bei `ja`: Workflow ab `current_step` fortsetzen, `awaiting_checkpoint: false` in SESSION.md setzen.

### Pre-Flight: runSubagent-Verfügbarkeit

Vor dem ersten Subagent-Aufruf prüfen: Ist das `agent`-Tool / `runSubagent` verfügbar?

- **Verfügbar:** Normaler Workflow-Modus.
- **Nicht verfügbar:** Manuellen Modus aktivieren (siehe `## Manueller Modus`).

## Arbeitsverzeichnis-Prüfung

Bestimme `customer_path` durch:

1. Prüfe `customer_path` aus SESSION.md (falls vorhanden und nicht leer)
2. Frage den Entwickler, falls noch nicht bekannt:
   > "In welchem Kundenprojekt arbeiten wir? (Pfad: `C:\Users\dloewe\{Kunde}\{Extension}\`)"
3. Leite `customer` aus dem Pfad ab: `Betzold`, `Hermes`, `Troeber` oder `unbekannt`
4. Bekannte Basispfade: `C:\Users\dloewe\Betzold\`, `C:\Users\dloewe\Hermes\`, `C:\Users\dloewe\Troeber\`
5. Schreibe `customer` und `customer_path` sofort in SESSION.md

## Workflow-Schritt-Tabelle

| Schritt | Agent | Aufgabe | Checkpoint |
|---------|-------|---------|-----------|
| 0 | *(Main-Agent)* | Session-Start, Resume-Check, customer_path ermitteln | Intern |
| 1 | `al-devops-reader` | WI/Issue lesen, Ticket-Summary erzeugen | **Pflicht CP-1** |
| 2 | `al-planner` | Technischen Plan erstellen | **Pflicht CP-2** |
| 3 | `al-codebase-analyst` | Relevante Objekte und Abhängigkeiten identifizieren | Nach Bedarf |
| 4 | `al-implementer` | AL-Code schreiben | Nach Bedarf |
| 5 | `al-build-tester` | Build + Diagnostics, max. 3 Fix-Schleifen | Bei Fehlern |
| 6 | `al-reviewer` | Code-Review + AC-Verifikation | **Pflicht CP-3 + CP-4** |
| 7 | `al-documenter` | PR-Beschreibung erstellen | **Pflicht CP-Ende** |

*Phase-1-Hinweis: CP-2 = nach al-planner; CP-3 = nach al-reviewer (kombinierter Review + Validator-Schritt,
da al-validator erst in Phase 2 kommt).*

## ⏸ NACH JEDEM SUBAGENT-AUFRUF — PFLICHT-HALT

**Dies ist keine Empfehlung. Es ist eine Pflicht-Sequenz. Abweichungen sind verboten.**

Nach jedem `runSubagent`-Aufruf — ohne Ausnahme:

1. Lies den Output-Block (`## Output` oder `## ERGEBNIS`) aus dem Subagent-Ergebnis
2. Schreibe SESSION.md: aktualisiere `current_step`, `current_agent`, `awaiting_checkpoint: true`, `last_updated`
3. Trage den Schritt-Output als Zusammenfassung in den passenden SESSION.md-Abschnitt ein
4. Präsentiere dem Entwickler den **CHECKPOINT-Block** (Format → nächster Abschnitt)
5. **STOPPE. Warte auf explizite Antwort.**
6. **Starte KEINEN weiteren Subagent-Aufruf ohne `ja` oder `anpassen:`.**

Niemals zwei Subagents in derselben Turn-Sequenz starten.

## Checkpoint-Protokoll

### Checkpoint-Block-Format

```
---

## ✅ CHECKPOINT — Schritt {N}: {Agent-Name} abgeschlossen

**Was wurde gemacht:**
{2–3 Sätze — konkretes Ergebnis, keine Füllwörter}

**Ergebnis im Detail:**
{Stichpunkte aus dem Output-Block — max. 5 Punkte}
- ...

**Entscheidungen / Annahmen:**
- {Vom Spezialisten getroffene Annahmen}

**Confidence:** {Wert aus Spezialist-Output}
⚠️ *(Nur wenn Confidence < 0.60: "Achtung: Confidence unter Schwellwert — Freigabe erforderlich")*

**Nächster geplanter Schritt:** {Agent} — {1 Satz was er tun wird}

---
→ **Fortfahren?** Antworte mit:
  - **`ja`** — nächsten Schritt starten
  - **`anpassen: {Hinweis}`** — Schritt mit Korrektur wiederholen
  - **`abbrechen`** — Workflow pausieren (SESSION.md wird gesichert)

*Session: {ticket_id} | Schritt {N} von 7*
```

### 5 Pflicht-Checkpoint-Positionen (MAIN-03)

| # | Position | Auslöser | Gesperrt bis |
|---|----------|----------|-------------|
| CP-1 | DevOps-Read | Nach `al-devops-reader` | Kein Schritt 2 ohne Zustimmung |
| CP-2 | Plan | Nach `al-planner` | Kein Schritt 3/4 ohne Zustimmung |
| CP-3 | Review/Validator | Nach `al-reviewer` Hauptergebnis | Kein Schritt 7 ohne Zustimmung |
| CP-4 | Reviewer-Verdict | Wenn `al-reviewer` Blocker meldet | Workflow-Entscheidung erforderlich |
| CP-5 | Confidence < 0.60 | Wenn irgendein Spezialist < 0.60 meldet | SOFORT stoppen — VOR Delegation des nächsten Schritts |

**CP-5 gilt präventiv:** Wenn Confidence < 0.60 aus dem vorherigen Checkpoint oder der Aufgabenbeschreibung bekannt ist, stoppe VOR der Delegation und präsentiere einen CP-5-Block.

### Checkpoint-Antwort-Handling

| Nutzer-Antwort | Main-Agent-Aktion |
|----------------|-------------------|
| `ja` | SESSION.md: `awaiting_checkpoint: false`; Schritt zu `approved_steps` hinzufügen; nächsten Subagent starten |
| `anpassen: {Hinweis}` | Hinweis in nächsten Subagent-Aufruf einbauen; SESSION.md: Hinweis im Schritt-Protokoll notieren; Schritt **nicht** zu `approved_steps` — neu ausführen |
| `abbrechen` | SESSION.md: `paused: true`, `awaiting_checkpoint: false`; Antworten: "Workflow pausiert. Beim nächsten Start biete ich Fortsetzung an." |
| `nein` | Wie `abbrechen` |
| `details` | SESSION.md-Inhalt des aktuellen Schritts ausgeben, dann erneut warten |

### CP-5 Checkpoint-Block-Format

```
⚠️ CHECKPOINT CP-5: Confidence unter Schwellwert

Agent: {Agent-Name}
Gemessene Confidence: {Wert}
Begründung: {Aus Spezialist-Output}

Empfehlung: Anforderungen präzisieren oder manuell reviewen bevor Fortfahren.

→ Fortfahren? **ja** (mit Risiko) / **anpassen: {Hinweis}** / **abbrechen**
```

## SESSION.md-Management

### Schreiben nach Checkpoint

Schreibe SESSION.md via `edit`-Tool nach jeder Nutzer-Antwort:

- **Nach `ja`:** `awaiting_checkpoint: false`; Schritt zu `approved_steps`; `current_step` erhöhen; `last_updated` setzen
- **Nach `anpassen:`:** Hinweis in SESSION.md-Notizen; `awaiting_checkpoint: true` behalten
- **Nach `abbrechen`/`nein`:** `paused: true`; `awaiting_checkpoint: false`; `last_updated` setzen

### SESSION.md anlegen (erster Start)

Wenn SESSION.md noch nicht existiert, erstelle sie via `write`-Tool. Template-Struktur liegt in
`.planning/al-workflow/SESSION.md`. Fülle sofort: `ticket_id`, `ticket_source`, `ticket_title`,
`customer_path`, `customer`, `current_step: 1`, `awaiting_checkpoint: true`, `last_updated`.

### build_fix_loop_count pflegen

Erhöhe `build_fix_loop_count` um 1 nach jeder Korrekturschleife von `al-build-tester`.
Wenn `build_fix_loop_count >= 3`: sofort eskalieren (→ `## Eskalations-Regeln`).

## Eskalations-Regeln

### Fix-Loop-Eskalation (nach 3 Build-Schleifen)

Wenn `build_fix_loop_count >= 3`:

1. STOPPE sofort — kein weiterer Subagent-Aufruf
2. Lies `.planning/al-workflow/BLOCKER-REPORT.md` (erstellt von `al-build-tester`)
3. Präsentiere dem Entwickler:

```
🚨 BUILD-ESKALATION — Schritt {N} blockiert

Datei: .planning/al-workflow/BLOCKER-REPORT.md
{Kurzzusammenfassung der Blocker aus dem Report}

Optionen:
- **manuell beheben** — Entwickler behebt direkt im Code, dann "ja" für Neustart
- **neu starten: {Hinweis}** — Codeänderung rückgängig, neu planen mit Hinweis
- **abbrechen** — Workflow pausieren
```

4. Warte auf explizite Freigabe.

### Confidence-Eskalation (CP-5)

Wenn ein Spezialist-Output Confidence < 0.60 enthält:

1. STOPPE sofort vor dem nächsten Delegation-Schritt
2. Zeige CP-5-Block (Format → `## Checkpoint-Protokoll`)
3. Kein automatisches Weiterarbeiten im Risiko-Bereich

### Stale-Session-Schutz

Wenn `last_updated` in SESSION.md > 48 Stunden alt:
Zeige Warnung im Resume-Angebot. Warte auf explizite Bestätigung dass der Stand noch aktuell ist.

## Delegation-Regeln

- Du darfst **keine AL-Dateien** selbst lesen, schreiben oder analysieren
- Du darfst **keine Build-Befehle** selbst ausführen
- Du darfst **keinen AL-Code** selbst schreiben
- Du darfst **keine ADO Write-Operationen** ausführen (nur read-only ADO-Tools im Frontmatter)
- Eigene Aufgaben: SESSION.md, Checkpoints, Nutzer-Antworten, `manage_todo_list`-Tracking

### Delegations-Syntax

```
runSubagent("{agent-name}", {
  task: "{Aufgabenbeschreibung}
         Ticket-ID: {ticket_id}
         Ticket-Summary: {Zusammenfassung aus CP-1}
         customer_path: {aus SESSION.md}
         {Weitere relevante Kontext-Felder aus SESSION.md}"
})
```

## Manueller Modus (Fallback)

Falls `runSubagent` / `agent`-Tool nicht verfügbar ist:

1. Zeige dem Entwickler die vollständige Aufgabe für den nächsten Spezialisten
2. Bitte den Entwickler, den entsprechenden Agent manuell zu starten
3. Nehme das Ergebnis vom Entwickler entgegen
4. Fahre mit normalem Checkpoint-Protokoll fort

## Eingabe-Format

Typische Eingaben:

- Work-Item-Nummer: `WI-1234` oder nur `1234`
- GitHub Issue: `#42` oder `https://github.com/org/repo/issues/42`
- Anforderungstext: Freitext (wird an `al-planner` weitergeleitet wenn eindeutig kein WI)
- Resume: `ja` auf Resume-Angebot beim Start
````

**Verification:**

```powershell
# Datei existiert
Test-Path .github/agents/main-agent.agent.md  # → True

$ma = Get-Content .github/agents/main-agent.agent.md -Raw

# Frontmatter vollständig
if ($ma -match 'name: main-agent') { "OK: name" } else { "FEHLER: name fehlt" }
if ($ma -match 'model: claude-opus-4') { "OK: model" } else { "FEHLER: model fehlt" }

# agents:-Liste enthält al-devops-reader
if ($ma -match 'al-devops-reader') { "OK: al-devops-reader in agents:-Liste" } else { "FEHLER: al-devops-reader fehlt" }

# Alle 5 Pflicht-Checkpoint-Positionen referenziert
@("CP-1","CP-2","CP-3","CP-4","CP-5") |
  ForEach-Object { if ($ma -match $_) { "OK: $_ vorhanden" } else { "FEHLER: $_ fehlt" } }

# Imperatives Checkpoint-Muster (STOPPE. Warte.)
if ($ma -match 'STOPPE') { "OK: Imperatives Stopp-Kommando vorhanden" } else { "FEHLER: Imperatives Stopp-Kommando fehlt" }
if ($ma -match 'KEIN.*weiterer Subagent|Starte KEINEN') { "OK: Anti-fire-and-forget vorhanden" } else { "FEHLER: Anti-fire-and-forget fehlt" }

# SESSION.md-Management
if ($ma -match 'SESSION\.md') { "OK: SESSION.md-Referenz vorhanden" } else { "FEHLER: SESSION.md-Referenz fehlt" }
if ($ma -match 'awaiting_checkpoint') { "OK: awaiting_checkpoint-Handling vorhanden" } else { "FEHLER: awaiting_checkpoint fehlt" }
if ($ma -match 'Resume') { "OK: Resume-Logik vorhanden" } else { "FEHLER: Resume-Logik fehlt" }

# Policy-Verweis
if ($ma -match 'agent-policy\.md') { "OK: Policy-Verweis" } else { "FEHLER: Policy-Verweis fehlt" }
```

---

### Task 3: `.planning/al-workflow/SESSION.md` erstellen

**Requirement:** MAIN-04
**File(s):** [`.planning/al-workflow/SESSION.md`]
**Action:** create (Verzeichnis anlegen falls nicht vorhanden, dann Datei erstellen)

**What to do:**

Erstelle zuerst das Verzeichnis `.planning/al-workflow/` falls es noch nicht existiert:

```powershell
New-Item -ItemType Directory -Path ".planning/al-workflow" -Force
```

Erstelle dann `.planning/al-workflow/SESSION.md` mit exakt folgendem Inhalt:

```markdown
---
ticket_id: ""
ticket_source: ""           # "ado" | "github"
ticket_title: ""
customer_path: ""           # C:\Users\dloewe\{Kunde}\{ExtensionName}\
customer: ""                # Betzold | Hermes | Troeber | unbekannt
branch: ""
current_step: 0             # 0=intake, 1=devops-read, 2=plan, 3=analyse, 4=implement, 5=build, 6=review, 7=docs, 8=done
current_agent: ""           # Name des zuletzt gestarteten Sub-Agents
awaiting_checkpoint: false  # true = Nutzer-Antwort auf Checkpoint ausstehend
paused: false               # true = Nutzer hat Workflow aktiv pausiert
build_fix_loop_count: 0     # Zählt Fix-Schleifen in al-build-tester (max. 3)
approved_steps: []          # Liste der mit "ja" bestätigten Schritte
rejected_steps: []          # Liste der mit "abbrechen" abgebrochenen Schritte
started_at: ""              # ISO-8601 Timestamp: "2026-06-18T09:00:00+02:00"
last_updated: ""            # ISO-8601 Timestamp — nach jedem Checkpoint aktualisieren
status: ""                  # "active" | "paused" | "done" | "blocked"
---

## Session Notes
<!-- Main-Agent schreibt hier strukturierte Infos nach jedem Checkpoint -->

## Ticket-Summary
<!-- Wird von al-devops-reader gefüllt — nach CHECKPOINT CP-1 -->

## Plan-Summary
<!-- Wird von al-planner gefüllt — nach CHECKPOINT CP-2 -->

## Analyse-Notes
<!-- Wird von al-codebase-analyst gefüllt -->

## Implementierungs-Notizen
<!-- Wird von al-implementer gefüllt -->

## Build-Status
<!-- Wird von al-build-tester gefüllt — inkl. build_fix_loop_count -->

## Review-Verdict
<!-- Wird von al-reviewer gefüllt — nach CHECKPOINT CP-3/CP-4 -->

## Getroffene Entscheidungen
<!-- Main-Agent trägt hier Architektur-Entscheidungen und Annahmen ein -->

## Blocker
<!-- Pfad zu BLOCKER-REPORT.md falls Fix-Loop-Eskalation ausgelöst wurde -->
```

**Wichtig:** Diese Datei ist das Template — wenn Main-Agent eine neue SESSION.md für ein konkretes Ticket anlegt, kopiert er dieses Template und füllt die Frontmatter-Felder aus.

**Verification:**

```powershell
# Verzeichnis und Datei existieren
Test-Path ".planning/al-workflow"  # → True
Test-Path ".planning/al-workflow/SESSION.md"  # → True

$sess = Get-Content ".planning/al-workflow/SESSION.md" -Raw

# Alle Pflichtfelder aus MAIN-04 vorhanden
@("ticket_id", "current_step", "awaiting_checkpoint", "approved_steps", "build_fix_loop_count", "customer_path") |
  ForEach-Object {
    if ($sess -match "$_") { "OK: $_ vorhanden" } else { "FEHLER: $_ fehlt" }
  }

# Frontmatter ist YAML (beginnt und endet mit ---)
$lines = Get-Content ".planning/al-workflow/SESSION.md"
if ($lines[0] -eq "---") { "OK: YAML-Frontmatter-Start" } else { "FEHLER: Kein YAML-Frontmatter" }
```

---

### Task 4: `.planning/al-workflow/` explizit in `.gitignore` ergänzen

**Requirement:** MAIN-04 (Session-State ist per-Entwickler, nicht git-getrackt)
**File(s):** [`.gitignore`]
**Action:** edit (am Ende der bestehenden Datei anfügen — bestehende Einträge nicht verändern)

**What to do:**

Die bestehende `.gitignore` enthält bereits `.planning/*` (GSD-Block), was `.planning/al-workflow/` technisch bereits ausschließt. Ergänze trotzdem einen expliziten Kommentar-Eintrag am Ende für Klarheit:

Füge folgende Zeilen **am Ende** der `.gitignore` an:

```gitignore

# AL Workflow Session-State (per-Entwickler, nicht git-getrackt)
.planning/al-workflow/
```

**Verification:**

```powershell
$gi = Get-Content .gitignore -Raw

# Expliziter al-workflow-Eintrag vorhanden
if ($gi -match "al-workflow") { "OK: al-workflow-Eintrag vorhanden" } else { "FEHLER: al-workflow-Eintrag fehlt" }

# Bestehender GSD-Block noch intakt
if ($gi -match "GSD planning docs") { "OK: GSD-Block intakt" } else { "FEHLER: GSD-Block beschädigt" }
if ($gi -match "\.planning/\*") { "OK: .planning/* vorhanden" } else { "FEHLER: .planning/* fehlt" }
if ($gi -match "!\.planning/codebase/") { "OK: codebase-Exception vorhanden" } else { "FEHLER: codebase-Exception fehlt" }
```

---

### Task 5: `model:` Frontmatter in alle 7 bestehenden Agent-Dateien nachtragen

**Requirement:** MODEL-01
**File(s):**
- [`.github/agents/al-auto-dev.agent.md`]
- [`.github/agents/al-planner.agent.md`]
- [`.github/agents/al-codebase-analyst.agent.md`]
- [`.github/agents/al-implementer.agent.md`]
- [`.github/agents/al-build-tester.agent.md`]
- [`.github/agents/al-reviewer.agent.md`]
- [`.github/agents/al-documenter.agent.md`]

**Action:** edit (7 Dateien — jeweils 1 Zeile einfügen)

**What to do:**

Füge in jeder der 7 Dateien die Zeile `model: {wert}` als **zweite Zeile** im YAML-Frontmatter ein — direkt nach `name: {agent-name}` und vor `description:`.

**Model-Zuordnung:**

| Agent-Datei | Einfügen nach | Einzufügende Zeile |
|-------------|-------------|-------------------|
| `al-auto-dev.agent.md` | `name: al-auto-dev` | `model: claude-opus-4` |
| `al-planner.agent.md` | `name: al-planner` | `model: claude-opus-4` |
| `al-codebase-analyst.agent.md` | `name: al-codebase-analyst` | `model: claude-sonnet-4-5` |
| `al-implementer.agent.md` | `name: al-implementer` | `model: claude-sonnet-4-5` |
| `al-build-tester.agent.md` | `name: al-build-tester` | `model: claude-sonnet-4-5` |
| `al-reviewer.agent.md` | `name: al-reviewer` | `model: claude-sonnet-4-5` |
| `al-documenter.agent.md` | `name: al-documenter` | `model: claude-sonnet-4-5` |

**Begründung Modell-Zuordnung:**
- `claude-opus-4` für `al-auto-dev` (Orchestrator — wie main-agent) und `al-planner` (technische Planung — komplexestes Reasoning unter den bestehenden Agents; bleibt Opus bis Phase 2 `al-architect` ihn ablöst)
- `claude-sonnet-4-5` für alle Ausführungs- und strukturierten Analyse-Agents (Kosteneffizienz bei gleichwertiger Qualität für strukturierte Tasks)

**Beispiel-Edit für `al-planner.agent.md`:**

Ersetze:
```
---
name: al-planner
description: Plant AL-Änderungen...
```

durch:
```
---
name: al-planner
model: claude-opus-4
description: Plant AL-Änderungen...
```

Führe dieses Muster für alle 7 Dateien durch.

**Verification:**

```powershell
$agents = @{
  "al-auto-dev"         = "claude-opus-4"
  "al-planner"          = "claude-opus-4"
  "al-codebase-analyst" = "claude-sonnet-4-5"
  "al-implementer"      = "claude-sonnet-4-5"
  "al-build-tester"     = "claude-sonnet-4-5"
  "al-reviewer"         = "claude-sonnet-4-5"
  "al-documenter"       = "claude-sonnet-4-5"
}

foreach ($agent in $agents.Keys) {
  $path = ".github/agents/$agent.agent.md"
  $expectedModel = $agents[$agent]
  $content = Get-Content $path -Raw
  if ($content -match "model: $expectedModel") {
    "OK: $agent → $expectedModel"
  } else {
    "FEHLER: $agent — model: $expectedModel fehlt oder falsch"
  }
}

# Gesamtzahl Agent-Dateien mit model:-Feld (erwartet: mindestens 9 — 7 bestehend + 2 neu aus T1/T2)
$total = (Get-ChildItem .github/agents/ -Filter "*.agent.md" |
  Where-Object { (Get-Content $_.FullName -Raw) -match "(?m)^model:" } ).Count
"Agent-Dateien mit model:-Frontmatter: $total  (erwartet: ≥ 9)"
```

---

### Task 6: `docs/model-switching.md` erstellen

**Requirement:** MODEL-02
**File(s):** [`docs/model-switching.md`]
**Action:** create (Verzeichnis `docs/` anlegen falls nicht vorhanden)

**What to do:**

Erstelle zuerst das Verzeichnis `docs/` im Repository-Root falls es noch nicht existiert:

```powershell
New-Item -ItemType Directory -Path "docs" -Force
```

Erstelle dann `docs/model-switching.md` mit exakt folgendem Inhalt:

```markdown
# Modell-Switching-Konzept

**BC AL Agentic Development Kit — Agent-Modell-Zuordnung**
**Erstellt:** Phase 1 (2026-06-18)

---

## Prinzip

Jeder Agent hat ein zugewiesenes Modell im `model:`-Frontmatter seiner `.agent.md`-Datei.
Die Zuordnung folgt einem zweigeteilten Prinzip:

| Kategorie | Modell | Kriterium |
|-----------|--------|-----------|
| Orchestrierung, Planung, Analyse | `claude-opus-4` | Tiefes Reasoning, Ambiguitätsauflösung, komplexe Entscheidungen |
| Ausführung, Parsing, strukturierte Tasks | `claude-sonnet-4-5` | Strukturierte Codegenerierung, Diagnostics, Template-Erstellung |

**Geschätzte Kosteneinsparung:** ~60 % gegenüber Opus-4 für alle Tasks.

---

## Agent-Modell-Tabelle (Phase 1)

| Agent-Datei | Modell | Begründung |
|-------------|--------|------------|
| `main-agent.agent.md` | `claude-opus-4` | HiTL-Orchestrierung, Routing, Ambiguitätsauflösung |
| `al-auto-dev.agent.md` | `claude-opus-4` | Orchestrator-Fallback (backward-compat) |
| `al-planner.agent.md` | `claude-opus-4` | Technische Planung — Architect-Ersatz bis Phase 2 |
| `al-devops-reader.agent.md` | `claude-sonnet-4-5` | Strukturiertes Parsen — kein tiefes Reasoning nötig |
| `al-codebase-analyst.agent.md` | `claude-sonnet-4-5` | Objekt-Suche, strukturierte Analyse |
| `al-implementer.agent.md` | `claude-sonnet-4-5` | Routine-AL-Codegenerierung |
| `al-build-tester.agent.md` | `claude-sonnet-4-5` | Diagnostics-Parsing, Fix-Schleifen |
| `al-reviewer.agent.md` | `claude-sonnet-4-5` | Checklisten-getriebenes Review |
| `al-documenter.agent.md` | `claude-sonnet-4-5` | Template-basierte Textgenerierung |

### Geplante Zuordnungen (Phase 2)

| Agent-Datei | Modell | Begründung |
|-------------|--------|------------|
| `al-architect.agent.md` | `claude-opus-4` | JSON Plan Contract, Objekt-Planung, Abhängigkeits-Analyse |
| `al-validator.agent.md` | `claude-opus-4` | Semantische 5-Layer Anforderungsdeckungsprüfung |
| `al-coder.agent.md` | `claude-sonnet-4-5` | Code-Generierung, Build-Integration, Objekt-IDs |

---

## Technische Hinweise

### VS Code Copilot

Das `model:`-Frontmatter wird von VS Code Copilot als **Empfehlung** interpretiert.

**Einschränkung:** Das Modell kann nicht mid-Conversation automatisch gewechselt werden.
Der Main-Agent gibt im Checkpoint einen expliziten Wechsel-Hinweis:

> 💡 Für diesen Analyse-Schritt ist `claude-opus-4` empfohlen — wechsle im Chat-Header,
> falls noch nicht auf Opus.

**Enterprise-Tenants:** In Umgebungen mit fixem Mandanten-Modell wird `model:` möglicherweise
ignoriert. Das Framework funktioniert auch mit einem einzigen Modell — die Zuordnung ist eine
Kosten-Qualitäts-Empfehlung, kein hartes Requirement.

### Claude Code

Per-Subagent-Modell-Selektion ist über `--model`-Flag beim `runSubagent`-Aufruf möglich.
Das `model:`-Frontmatter wird direkt von Claude Code's Agent-Runner gelesen und erzwingt
das angegebene Modell pro Subagent-Aufruf.

### Annahmen (Assumptions Log)

| # | Annahme | Risiko wenn falsch |
|---|---------|-------------------|
| A1 | `model:`-Syntax (`claude-opus-4`, `claude-sonnet-4-5`) ist korrekt für aktuelle Copilot-Version | Model wird nicht erkannt — Fallback auf Default |
| A2 | VS Code Copilot wertet `model:` in `.agent.md` als Empfehlung aus | Frontmatter hat keinen Effekt — nur als Dokumentation funktional |
| A3 | Enterprise-Tenants können `model:` durch Tenant-Policy überschreiben | Erwartete Modell-Qualität nicht immer erreichbar |

---

## Änderungshistorie

| Datum | Phase | Änderung |
|-------|-------|----------|
| 2026-06-18 | Phase 1 | Initial erstellt — 9 Agents mit model:-Frontmatter |
```

**Verification:**

```powershell
# Datei existiert
Test-Path "docs/model-switching.md"  # → True

$doc = Get-Content "docs/model-switching.md" -Raw

# Alle 9 Agents der Phase 1 dokumentiert
@("main-agent", "al-auto-dev", "al-planner", "al-devops-reader",
  "al-codebase-analyst", "al-implementer", "al-build-tester",
  "al-reviewer", "al-documenter") |
  ForEach-Object { if ($doc -match $_) { "OK: $_ dokumentiert" } else { "FEHLER: $_ fehlt" } }

# Beide Modellbezeichner vorhanden
if ($doc -match "claude-opus-4") { "OK: claude-opus-4 erwähnt" } else { "FEHLER: claude-opus-4 fehlt" }
if ($doc -match "claude-sonnet-4-5") { "OK: claude-sonnet-4-5 erwähnt" } else { "FEHLER: claude-sonnet-4-5 fehlt" }

# Enterprise-Vorbehalt dokumentiert
if ($doc -match "Enterprise") { "OK: Enterprise-Vorbehalt vorhanden" } else { "FEHLER: Enterprise-Vorbehalt fehlt" }
```

---

### Task 7: Gesamtverifikation aller Phase-1-Requirements

**Requirement:** MAIN-01, MAIN-02, MAIN-03, MAIN-04, MAIN-05, MAIN-06, DEVOPS-01, DEVOPS-02, MODEL-01, MODEL-02
**File(s):** Keine (Verifikation existing files)
**Action:** verify

**What to do:**

Führe folgendes PowerShell-Script im Repository-Root aus und prüfe alle 10 Requirements:

**Verification:**

```powershell
Write-Host "=== Phase 1 — Gesamtverifikation ===" -ForegroundColor Cyan

# MAIN-01: main-agent.agent.md existiert und ist einziger Gesprächspartner
$m01 = (Test-Path ".github/agents/main-agent.agent.md") -and
       ((Get-Content ".github/agents/main-agent.agent.md" -Raw) -match "einzige.*Agent|einziger.*Gesprächspartner")
Write-Host "MAIN-01 (main-agent.agent.md vorhanden + Identität): $(if($m01){'✅ OK'}else{'❌ FEHLER'})"

# MAIN-02: Checkpoint-Protokoll mit ja/nein/anpassen
$ma = Get-Content ".github/agents/main-agent.agent.md" -Raw
$m02 = ($ma -match 'CHECKPOINT') -and ($ma -match 'ja') -and ($ma -match 'anpassen')
Write-Host "MAIN-02 (Checkpoint-Protokoll ja/anpassen/abbrechen): $(if($m02){'✅ OK'}else{'❌ FEHLER'})"

# MAIN-03: Alle 5 Checkpoint-Positionen
$m03 = ($ma -match 'CP-1') -and ($ma -match 'CP-2') -and ($ma -match 'CP-3') -and
       ($ma -match 'CP-4') -and ($ma -match 'CP-5')
Write-Host "MAIN-03 (5 Pflicht-Checkpoint-Positionen): $(if($m03){'✅ OK'}else{'❌ FEHLER'})"

# MAIN-04: SESSION.md mit allen Pflichtfeldern
$sessPath = ".planning/al-workflow/SESSION.md"
$m04 = $false
if (Test-Path $sessPath) {
  $sess = Get-Content $sessPath -Raw
  $m04 = ($sess -match 'ticket_id') -and ($sess -match 'current_step') -and
         ($sess -match 'awaiting_checkpoint') -and ($sess -match 'approved_steps') -and
         ($sess -match 'build_fix_loop_count') -and ($sess -match 'customer_path')
}
Write-Host "MAIN-04 (SESSION.md Schema mit Pflichtfeldern): $(if($m04){'✅ OK'}else{'❌ FEHLER'})"

# MAIN-05: Main-Agent schreibt SESSION.md (write/edit Tools + awaiting_checkpoint-Logik)
$m05 = ($ma -match 'SESSION\.md') -and ($ma -match '"write"') -and ($ma -match 'awaiting_checkpoint')
Write-Host "MAIN-05 (SESSION.md Persistenz-Logik): $(if($m05){'✅ OK'}else{'❌ FEHLER'})"

# MAIN-06: Resume-Logik beim Start
$m06 = ($ma -match 'Resume') -and ($ma -match 'SESSION-Start-Prozedur|Session-Start')
Write-Host "MAIN-06 (Resume-Logik + Session-Start): $(if($m06){'✅ OK'}else{'❌ FEHLER'})"

# DEVOPS-01: al-devops-reader.agent.md mit 2 Quellen (ADO + GitHub)
$dr = if (Test-Path ".github/agents/al-devops-reader.agent.md") {
  Get-Content ".github/agents/al-devops-reader.agent.md" -Raw
} else { "" }
$d01 = ($dr -ne "") -and ($dr -match 'ado/work-items/get') -and
       ($dr -match 'github') -and ($dr -match '## ERGEBNIS')
Write-Host "DEVOPS-01 (al-devops-reader mit ADO + GitHub + ERGEBNIS-Block): $(if($d01){'✅ OK'}else{'❌ FEHLER'})"

# DEVOPS-02: DevOps-Reader strikt read-only (kein terminal, keine Write-Tools)
$d02 = ($dr -match 'Verbote') -and -not($dr -match '"terminal"') -and
       -not($dr -match '"write"') -and -not($dr -match '"edit"')
Write-Host "DEVOPS-02 (DevOps-Reader strikt read-only): $(if($d02){'✅ OK'}else{'❌ FEHLER'})"

# MODEL-01: Alle 9 Agent-Dateien (7 bestehend + 2 neu) mit model:-Frontmatter
$allAgents = Get-ChildItem ".github/agents/" -Filter "*.agent.md" |
  Where-Object { $_.Name -match "^al-" -or $_.Name -eq "main-agent.agent.md" }
$withModel = ($allAgents | Where-Object {
  (Get-Content $_.FullName -Raw) -match "(?m)^model:"
}).Count
$m01b = $withModel -ge 9
Write-Host "MODEL-01 (model:-Frontmatter in ≥9 Agent-Dateien — gefunden: $withModel): $(if($m01b){'✅ OK'}else{'❌ FEHLER'})"

# MODEL-02: docs/model-switching.md existiert
$m02b = (Test-Path "docs/model-switching.md") -and
        ((Get-Content "docs/model-switching.md" -Raw) -match "claude-opus-4") -and
        ((Get-Content "docs/model-switching.md" -Raw) -match "claude-sonnet-4-5")
Write-Host "MODEL-02 (docs/model-switching.md mit Modell-Zuordnung): $(if($m02b){'✅ OK'}else{'❌ FEHLER'})"

# Gesamtergebnis
$all = $m01 -and $m02 -and $m03 -and $m04 -and $m05 -and $m06 -and $d01 -and $d02 -and $m01b -and $m02b
Write-Host ""
Write-Host "Gesamtergebnis: $(if($all){'✅ Phase 1 COMPLETE — alle 10 Requirements erfüllt'}else{'❌ Phase unvollständig — fehlgeschlagene Checks prüfen'})" -ForegroundColor $(if($all){"Green"}else{"Red"})
```

---

## Threat Model

| Bedrohung | STRIDE | Komponente | Disposition | Maßnahme |
|-----------|--------|-----------|-------------|----------|
| Main-Agent fire-and-forget: überspringt Checkpoints und delegiert alle Sub-Agents ohne Pause | Tampering (Workflow Bypass) | `main-agent.agent.md` | Mitigate | Imperatives Stopp-Muster in Agent-Instructions (Task 2); "STOPPE. Warte auf Antwort." als Pflicht-Instruction |
| DevOps-Reader erhält Write-Tools durch Konfigurationsfehler | Elevation of Privilege | `al-devops-reader.agent.md` | Mitigate | Explizite Tools-Allowlist ohne `terminal`, `write`, `edit` (Task 1); Read-Only-Verbote-Abschnitt |
| SESSION.md enthält customer_path — Dateisystempfade auf Entwickler-Workstation | Information Disclosure | `.planning/al-workflow/SESSION.md` | Mitigate | `.gitignore`-Eintrag (Task 4); SESSION.md nie in ADO-Kommentare oder PR-Body kopieren |
| SESSION.md-Konsistenz nach abgebrochenem Schreiben — inkonsistenter State | Tampering | SESSION.md | Mitigate | `last_updated`-Timestamp erzwingt Bestätigung bei >48h-altem Stand; atomar schreiben |
| GitHub MCP Server-Toolnamen falsch (`[ASSUMED]`) → stummer Fehler | Denial of Service | `al-devops-reader.agent.md` | Accept | `[ASSUMED]`-Kommentar im Frontmatter-Abschnitt; Fallback-Logik auf ADO-Only-Modus dokumentiert |
| model:-Frontmatter ohne Effekt in Enterprise-Copilot-Tenants | Information Disclosure | Alle Agent-Dateien | Accept | Dokumentierter Vorbehalt in `docs/model-switching.md`; kein hartes Blocking |

---

## Verification

Alle 7 Tasks sind abgeschlossen wenn der Gesamtcheck aus Task 7 vollständig grün ist. Zusätzliche manuelle Verifikation der Success Criteria (nicht automatisierbar):

1. **SC-1:** Neues Gespräch mit `main-agent` starten, WI-Nummer eingeben → DevOps-Reader liefert Ticket-Summary → `## CHECKPOINT: DevOps-Read abgeschlossen` erscheint → Agent wartet auf `ja`/`anpassen`/`abbrechen` bevor er weiter delegiert
2. **SC-2:** Nach CP-1 mit `abbrechen` antworten → SESSION.md in `.planning/al-workflow/` prüfen: alle Pflichtfelder befüllt (`ticket_id`, `current_step`, `awaiting_checkpoint`, `approved_steps`, `build_fix_loop_count`, `customer_path`)
3. **SC-3:** VS Code neu starten, `main-agent` öffnen → Resume-Angebot erscheint mit `ticket_id` und `current_step` — ohne Kontext-Neueingabe
4. **SC-4:** Workflow bis CP-2 (nach al-planner) durchführen → Bestätigen dass alle 4 Positionen CP-1 bis CP-4 den Flow anhalten
5. **SC-5:** `model:`-Feld in allen Agent-Dateien über PowerShell-Check aus Task 7 bestätigen

---

## Commit Strategy

| # | Task | Requirement(s) | Commit-Message |
|---|------|----------------|----------------|
| 1 | Task 1 | DEVOPS-01, DEVOPS-02 | `feat(phase-1): add al-devops-reader agent (read-only ADO + GitHub)` |
| 2 | Task 2 | MAIN-01..03, 05..06 | `feat(phase-1): add main-agent with HiTL checkpoints and session resume` |
| 3 | Task 3 | MAIN-04 | [kein git commit — SESSION.md ist lokale gitignored Datei (.planning/* in .gitignore)] |
| 4 | Task 4 | MAIN-04 | `chore(phase-1): add .planning/al-workflow/ to .gitignore` |
| 5 | Task 5 | MODEL-01 | `chore(phase-1): add model: frontmatter to all 7 existing AL agents` |
| 6 | Task 6 | MODEL-02 | `docs(phase-1): add model-switching concept to docs/model-switching.md` |
| 7 | Task 7 | alle | `chore(phase-1): run phase-1 verification — all 10 requirements pass` |

**Reihenfolge-Pflicht:**
- Task 1 vor Task 2 (main-agent referenziert al-devops-reader)
- Task 3 vor Task 4 (Verzeichnis muss existieren bevor .gitignore-Eintrag sinnvoll ist)
- Task 5 vor Task 6 (docs/model-switching.md dokumentiert die in Task 5 vergebenen Model-IDs)
- Task 7 als letztes (Verifikation aller vorherigen Tasks)
