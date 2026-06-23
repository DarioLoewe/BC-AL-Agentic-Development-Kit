# Research: Phase 1 — Main-Agent + Session State + DevOps-Reader

**Erstellt:** 2026-06-18
**Basis:** Codebase-Analyse (existierende agent-Dateien, policies, ARCHITECTURE.md, STACK.md, PITFALLS.md)
**Confidence:** HIGH — alle Entscheidungen grunden in bestehendem Code, keinen externen Abhängigkeiten und bereits getroffenen Architektur-Entscheidungen

---

## TL;DR

- **Datei 1:** `main-agent.agent.md` — neue Datei, rewrite des Orchestrator-Prinzips von fire-and-forget auf HiTL; delegiert weiterhin an **bestehende** Spezialisten (al-planner, al-codebase-analyst usw.) bis Phase 2 deren Nachfolger liefert
- **Datei 2:** `al-devops-reader.agent.md` — neue Datei, strikt read-only, exakt 4 ADO-Tools + GitHub MCP Server-Tools; kein `ado/*` Wildcard
- **Session-State:** `.planning/al-workflow/SESSION.md` mit YAML-Frontmatter — überleben VS Code-Neustarts, git-trackbar, kein neues Runtime
- **Höchstes Risiko:** Main-Agent-Instruktionen ohne hartes `STOP + warte` nach jeder Delegation defaulten zurück auf fire-and-forget (Pitfall C-1) — das Checkpoint-Muster muss **imperativ**, nicht nur als Hinweis formuliert sein
- **Modell-Frontmatter:** `model:` Key in `.agent.md` Frontmatter ist laut STACK.md ein von VS Code Copilot unterstütztes Pattern; Opus 4 für Orchestrierung/Analyse, Sonnet 4.5 für Ausführung [ASSUMED: exakte Model-ID-Syntax muss gegen aktuelle Copilot-Agent-Docs verifiziert werden]

---

## 1. Main-Agent File Structure

### Frontmatter

Basierend auf dem Pattern aller bestehenden Agents (Frontmatter: `name`, `description`, `tools`, `agents`):

```yaml
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
    "session_store_sql",
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
```

**Wichtige Design-Entscheidungen beim Tool-Set:**
- `write` + `edit` → werden für SESSION.md-Updates benötigt (Main-Agent schreibt State nach jedem Checkpoint)
- ADO-Tools: **genau die 4 read-only** aus FOUND-01-Fix — kein Wildcard `ado/*`
- `agent` → ermöglicht `runSubagent`-Aufrufe
- Phase 2-Agents (al-architect, al-coder, al-validator) sind NICHT in der `agents:`-Liste von Phase 1 — die kommen erst in Phase 2

### Pflicht-Abschnitte im Markdown-Body

```
# Main-Agent — AL Development Partner

## Identität & Rolle
## Verbindliche Policy
## Session-Start-Prozedur (→ SESSION.md lesen + Resume-Angebot)
## Arbeitsverzeichnis-Prüfung (customer_path bestimmen)
## Workflow-Schritt-Tabelle (Übersicht: welcher Spezialist, was, wann)
## Checkpoint-Protokoll (imperativ — nicht als Hinweis)
## Delegation-Regeln (Main-Agent führt nie selbst AL-Code aus)
## Eskalations-Regeln (Confidence < 0.60, Blocker-Reports)
## Manueller Modus (Fallback wenn runSubagent nicht verfügbar)
```

### Imperatives Checkpoint-Muster (muss so formuliert sein, nicht als Empfehlung)

```markdown
## ⏸ NACH JEDEM SUBAGENT-AUFRUF — PFLICHT-HALT

1. Lies den `## ERGEBNIS`-Block aus dem Subagent-Output
2. Schreibe SESSION.md: `current_step`, `awaiting_checkpoint: true`, Schritt-Eintrag
3. Präsentiere dem Nutzer einen `## CHECKPOINT`-Block (Template → Abschnitt 3)
4. STOPPE. Warte auf explizite Nutzerantwort.
5. Starte KEINEN weiteren Subagent-Aufruf ohne Zustimmung.
```

### Schritt-Tabelle in der Agent-Datei (Phase 1)

| Schritt | Agent | Aufgabe | Checkpoint-Typ |
|---------|-------|---------|---------------|
| 0 | *(Main-Agent selbst)* | SESSION.md lesen, Resume-Check, customer_path ermitteln | Intern |
| 1 | `al-devops-reader` | WI/Issue lesen, strukturiertes Ticket-Summary erzeugen | **Pflicht** |
| 2 | `al-planner` | Technischen Plan erstellen | **Pflicht** (als Architect-Ersatz Phase 1) |
| 3 | `al-codebase-analyst` | Relevante Objekte und Abhängigkeiten identifizieren | Empfohlen |
| 4 | `al-implementer` | AL-Code schreiben | Empfohlen |
| 5 | `al-build-tester` | Build + Diagnostics | Bei Fehlern |
| 6 | `al-reviewer` | Code-Review | **Pflicht** |
| 7 | `al-documenter` | PR-Beschreibung | **Pflicht** |

---

## 2. SESSION.md Schema

### Datei-Pfad

`.planning/al-workflow/SESSION.md`

*(Dieser Pfad ist eine getroffene Entscheidung — nicht `.planning/session/CURRENT.md` wie in früherem ARCHITECTURE.md-Entwurf. REQUIREMENTS.md MAIN-04 ist autoritativ.)*

### Vollständiges Schema

```yaml
---
ticket_id: "WI-1234"
ticket_title: "Lieferantensperre im Verkaufsauftrag anzeigen"
ticket_source: "azure_devops"          # azure_devops | github
customer: "Betzold"                    # Betzold | Hermes | Troeber — aus Dateipfad extrahiert
customer_path: "C:\\Users\\dloewe\\Betzold\\BetzoldCore\\"
branch: "ai/wi-1234-lieferantensperre"
current_step: 2                        # 0–7 (gemäß Schritt-Tabelle oben)
current_agent: "al-planner"           # name des zuletzt gestarteten Agents
awaiting_checkpoint: true             # true = Nutzer-Antwort ausstehend
paused: false                         # true = Nutzer hat abgebrochen, kein Fehler
build_fix_loop_count: 0               # Zählt Fix-Schleifen in al-build-tester
approved_steps:
  - devops_read
rejected_steps: []
started_at: "2026-06-18T09:00:00+02:00"
last_updated: "2026-06-18T09:15:00+02:00"
---

## Ticket-Summary
<!-- Wird von al-devops-reader gefüllt — CHECKPOINT 1 -->

## Plan-Summary
<!-- Wird von al-planner gefüllt — CHECKPOINT 2 -->

## Analyse-Notes
<!-- Wird von al-codebase-analyst gefüllt -->

## Implementierungs-Notizen
<!-- Wird von al-implementer gefüllt -->

## Build-Status
<!-- Wird von al-build-tester gefüllt -->

## Review-Verdict
<!-- Wird von al-reviewer gefüllt — CHECKPOINT 6 -->

## Getroffene Entscheidungen
<!-- Main-Agent trägt hier Architektur-Entscheidungen ein -->
```

### State-Transitions

```
[SESSION.md existiert nicht]
    → Main-Agent erstellt sie (minimal: ticket_id, customer, customer_path)
    → current_step: 0, awaiting_checkpoint: false

current_step: 0  (Intake — customer_path bestätigt)
    ↓ Nutzer-Input: WI-Nummer oder Anforderungstext
    → al-devops-reader starten

current_step: 1  (DevOps-Read läuft / done)
    awaiting_checkpoint: true
    ↓ Nutzer: "ja"
    → approved_steps: [devops_read]

current_step: 2  (Planning — al-planner läuft)
    awaiting_checkpoint: true
    ↓ Nutzer: "ja"
    → approved_steps: [..., planning]

current_step: 3–5  (Analyse, Implementierung, Build — je nach Ablauf)

current_step: 6  (Review — al-reviewer läuft)
    awaiting_checkpoint: true
    ↓ Nutzer: "ja" / "nochmals Coder"

current_step: 7  (Dokumentation — al-documenter)
    awaiting_checkpoint: true
    ↓ Nutzer: "ja"
    → current_step: 8, paused: false

[Abschluss]
    SESSION.md umbenennen zu SESSION-WI-{id}-{datum}.md
    Neue leere SESSION.md vorbereiten (oder löschen)
```

### Was NICHT in SESSION.md gespeichert wird

| Feld | Grund |
|------|-------|
| Roher Subagent-Output | Zu groß — nur Main-Agent-Digest |
| AL-Code-Inhalt | Lebt im Git-Branch |
| Nutzer-Chat-Nachrichten | Nur extrahierte Entscheidungen |
| Credentials/Secrets | Niemals — Policy |
| BLOCKER-REPORT.md-Inhalt | Eigene Datei, Pfad wird in SESSION.md referenziert |

---

## 3. Checkpoint Protocol

### Checkpoint-Block-Format

Dieser Block erscheint in der Konversation nach **jedem** Subagent-Abschluss:

```markdown
---

## ✅ CHECKPOINT — Schritt [N]: [Agent-Name] abgeschlossen

**Was wurde gemacht:**
[2–3 Sätze — konkretes Ergebnis des Spezialisten, keine Füllwörter]

**Ergebnis im Detail:**
[Stichpunkte aus dem `## ERGEBNIS`-Block des Spezialisten — max. 5 Punkte]
- ...
- ...

**Entscheidungen / Annahmen:**
- [Entscheidung oder Annahme, die der Spezialist getroffen hat]

**Confidence:** [Wert aus Spezialist-Output, z.B. 0.85]
⚠️ *[Nur wenn Confidence < 0.60: "Achtung: Confidence unter Schwellwert — Freigabe erforderlich bevor Fortfahren"]*

**Nächster geplanter Schritt:** [Agent] — [1 Satz was er tun wird]

---
→ **Fortfahren?** Antworte mit:
  - **`ja`** — nächsten Schritt starten
  - **`anpassen: [Hinweis]`** — Schritt mit Korrektur wiederholen
  - **`abbrechen`** — Workflow pausieren (SESSION.md wird gesichert)

*Session: {ticket_id} | Schritt {N} von 7*
```

### 5 Pflicht-Checkpoint-Positionen (MAIN-03)

| Position | Auslöser | Warum Pflicht |
|----------|----------|---------------|
| **CP-1: DevOps-Read** | Nach `al-devops-reader` | Nutzer bestätigt, dass WI korrekt verstanden wurde — alle Folgeschritte bauen darauf auf |
| **CP-2: Architect/Plan** | Nach `al-planner` (Phase 1) / `al-architect` (Phase 2) | Technischer Plan ist die kritische Weichenstellung — ein schlechter Plan fließt direkt in falschen Code |
| **CP-3: Validator** | Nach `al-validator` (Phase 2) / oder al-reviewer als Validator-Ersatz (Phase 1) | Anforderungsdeckung bestätigen bevor PR erstellt wird |
| **CP-4: Reviewer** | Nach `al-reviewer` | Reviewer-Verdict kann Blocker enthalten — erfordert Nutzer-Entscheidung |
| **CP-5: Confidence < 0.60** | Wenn irgendein Spezialist Confidence < 0.60 meldet | Policy-Pflicht — Risiko-Bereich, Nutzer muss explizit freigeben |

**Phase 1 Hinweis:** In Phase 1 gibt es noch keinen `al-architect` und keinen `al-validator`. CP-2 wird nach `al-planner` ausgelöst (der den Plan liefert). CP-3 wird nach dem `al-reviewer`-Schritt als kombinierter Review+Validator-Checkpoint ausgeführt.

### Checkpoint-Antwort-Handling

| Nutzer-Antwort | Main-Agent-Aktion |
|----------------|-------------------|
| `ja` | SESSION.md: `awaiting_checkpoint: false`, Schritt zu `approved_steps` hinzufügen, nächsten Subagent starten |
| `anpassen: [Hinweis]` | Hinweis in nächsten Subagent-Aufruf einbauen; SESSION.md: Hinweis im Schritt-Protokoll notieren; Schritt **nicht** zu `approved_steps` — neu ausführen |
| `abbrechen` | SESSION.md: `paused: true`, `awaiting_checkpoint: false`; Nutzer informieren wie er fortfahren kann |
| Keine Antwort / Abbruch | SESSION.md bleibt unverändert; beim nächsten Start Resume-Angebot |
| `nein` (ohne Zusatz) | Gleich wie `abbrechen` — ggf. nachfragen ob neu starten oder pausieren |

### Anti-Pattern: Checkpoint als Prosa-Hinweis

**Falsch:**
```markdown
Es empfiehlt sich, nach jedem Schritt eine Bestätigung einzuholen.
```

**Richtig (imperativ, mit explizitem STOP):**
```markdown
STOPPE nach dem Subagent-Aufruf.
Schreibe SESSION.md.
Präsentiere CHECKPOINT-Block.
Warte auf Antwort.
Kein weiterer Aufruf ohne "ja" oder "anpassen:".
```

---

## 4. DevOps-Reader Design

### Frontmatter

```yaml
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
    "ado/repos/list-pull-requests"
  ]
---
```

**Kein `terminal`-Tool** — das würde `gh`-CLI-Aufrufe ermöglichen, die schwerer zu beschränken sind. GitHub-Integration läuft über GitHub MCP Server (siehe unten). [ASSUMED: GitHub MCP Server-Tools müssen in der `tools:`-Liste mit exaktem Toolnamen referenziert werden — Toolnamen prüfen wenn GitHub MCP Server konfiguriert ist]

### ADO-Tools (gesperrt auf exakt diese 4)

| Tool | Was es liest | API-Äquivalent |
|------|-------------|----------------|
| `ado/work-items/get` | WI-Detail inkl. Beschreibung, ACs, Tags, Status | `GET /_apis/wit/workitems/{id}?$expand=all` |
| `ado/work-items/list` | WI-Suche/Auflistung | `GET /_apis/wit/workitems?ids=...` |
| `ado/repos/get-pull-request` | PR-Details zu WI | `GET /_apis/git/pullrequests/{id}` |
| `ado/repos/list-pull-requests` | PRs nach Kriterium suchen | `GET /_apis/git/pullrequests` |

**Was fehlt (bewusst):** Kein `ado/work-items/create`, kein `ado/work-items/update`, kein `ado/*/delete`. Jedes dieser Tools würde den read-only-Grundsatz brechen.

### GitHub Integration

GitHub-Issues und PRs werden über den **GitHub MCP Server** gelesen. Die genauen Tool-Namen hängen von der MCP-Server-Konfiguration ab. [ASSUMED: Toolnamen wie `github/issues/get`, `github/pulls/get` oder ähnliche — vor Implementierung verifizieren welche Tools der konfigurierte GitHub MCP Server exponiert]

Alternativ: Falls GitHub MCP Server nicht konfiguriert ist, kann `read` mit GitHub API-Aufrufen verwendet werden (erfordert expliziten URL-Aufruf im Instruction-Text).

### Strukturiertes Ticket-Summary (Output-Format)

Dieses Format ist der `## ERGEBNIS`-Block, den der DevOps-Reader zurückgibt:

```markdown
## ERGEBNIS — DevOps-Reader

## Ticket-Summary: WI-{id}

**Titel:** [Titel des Work Items]
**Typ:** User Story | Bug | Task | Feature
**Quelle:** Azure DevOps | GitHub Issues
**Priorität:** [1/2/3/4 oder Low/Medium/High/Critical]
**Status:** Active | New | Resolved | Closed
**Kunde (aus Pfad-Heuristik):** [Betzold | Hermes | Troeber | unbekannt]
**Iteration / Sprint:** [Falls vorhanden]

### Beschreibung
[Plain Text — HTML-Tags entfernt, Formatierung beibehalten]

### Akzeptanzkriterien
- [ ] Kriterium 1
- [ ] Kriterium 2
*(Falls keine ACs vorhanden: "⚠️ Keine Akzeptanzkriterien definiert — Confidence wird reduziert")*

### Verknüpfte Work Items
- WI-{parent-id} (Parent): [Titel]
- WI-{child-id} (Child): [Titel]
*(Oder: "Keine verknüpften Work Items")*

### Branch / PR
- Vorhandener Branch: [Name | Keiner]
- Vorhandener PR: [#ID Titel | Keiner]

### ADO-Tags
[Liste der Tags, kommagetrennt — z.B. "ai:implement, bc-al, Betzold"]
*(Falls kein "ai:implement"-Tag: "⚠️ Kein ai:implement-Tag — vom Nutzer bestätigen lassen")*

### Interpretation für Main-Agent
- Empfohlene Extension-Path: `C:\Users\dloewe\{Kunde}\...` *(nur wenn aus Area-Path oder Tags ableitbar)*
- Confidence dieser Interpretation: [0.0–1.0]
- Offene Fragen: [Falls vorhanden]
```

### Read-Only-Enforcement in der Agent-Datei

```markdown
## Verbote (absolut — keine Ausnahmen)

- Kein Schreiben in ADO Work Items (kein POST/PATCH auf `/_apis/wit/*`)
- Kein Erstellen von Branches
- Kein Erstellen oder Aktualisieren von PRs
- Kein Setzen von Tags (auch nicht `ai:done` oder `ai:blocked`)
- Keine Statusänderungen in ADO oder GitHub
- Keine Write-Operationen, auch wenn der Nutzer darum bittet

Bei Write-Anfragen: "Ich bin auf Lesen beschränkt. Schreib-Aktionen können nur vom
Main-Agent mit expliziter Nutzer-Freigabe ausgeführt werden."
```

---

## 5. Model Frontmatter

### Format

Das `model:`-Feld wird als zweite Zeile im YAML-Frontmatter der `.agent.md`-Dateien eingefügt:

```yaml
---
name: main-agent
model: claude-opus-4
description: ...
tools: [...]
---
```

**Aktueller Stand:** Keine einzige existierende Agent-Datei im Repo hat ein `model:`-Frontmatter. MODEL-01 erfordert das Nachtragen in **allen** Agent-Dateien (nicht nur neuen).

### Model-Zuweisung (MAIN-MODEL-01 + getroffene Entscheidung)

| Agent-Datei | Modell | Begründung |
|-------------|--------|------------|
| `main-agent.agent.md` (neu) | `claude-opus-4` | Routing, Ambiguitätsauflösung, HiTL-Orchestrierung |
| `al-architect.agent.md` (Phase 2) | `claude-opus-4` | Objekt-Planung, Abhängigkeits-Analyse |
| `al-validator.agent.md` (Phase 2) | `claude-opus-4` | Semantische Anforderungsdeckungsprüfung |
| `al-devops-reader.agent.md` (neu) | `claude-sonnet-4-5` | Strukturiertes Parsen — kein tiefes Reasoning nötig |
| `al-planner.agent.md` (bestehend) | `claude-opus-4` | Technische Planung — nutzt Opus bis Phase 2 al-architect kommt |
| `al-codebase-analyst.agent.md` (bestehend) | `claude-sonnet-4-5` | Objekt-Suche, strukturiert |
| `al-implementer.agent.md` (bestehend) | `claude-sonnet-4-5` | Routine-AL-Codegenerierung |
| `al-build-tester.agent.md` (bestehend) | `claude-sonnet-4-5` | Diagnostics-Parsing |
| `al-reviewer.agent.md` (bestehend) | `claude-sonnet-4-5` | Checklisten-getriebenes Review |
| `al-documenter.agent.md` (bestehend) | `claude-sonnet-4-5` | Template-basierte Textgenerierung |

**Phase 1 Aufgabe:** `model:` in alle 7 bestehenden Agent-Dateien + 2 neue Agent-Dateien einfügen.

### MODEL-02: Modell-Switching-Konzept-Dokumentation

Zu erstellen als Abschnitt in `main-agent.agent.md` oder als eigene Datei `.github/docs/model-strategy.md`:

```markdown
## Modell-Switching-Konzept

### Prinzip
- Analyse + Planung → Opus 4 (5× teurer, aber für Architektur-Entscheidungen notwendig)
- Ausführung + Parsing → Sonnet 4.5 (schnell, kosteneffizient, für strukturierte Tasks ausreichend)
- Kosteneinsparung durch dieses Muster: ca. 60% gegenüber Opus für alles

### VS Code Copilot
Das Modell kann nicht mid-Conversation gewechselt werden. Main-Agent gibt Hinweis
im Checkpoint: "💡 Für diesen Analyse-Schritt empfehle ich Opus 4 — im Chat-Header wechseln."

### Claude Code
Per-Subagent-Modell-Selektion ist möglich via --model Flag beim runSubagent-Aufruf.
Das `model:`-Frontmatter wird direkt von Claude Code's Agent-Runner gelesen.
```

### Technische Einschränkung [ASSUMED]

Die STACK.md beschreibt `model:` als "von VS Code Copilot unterstütztes Pattern". **Aber:** Diese Unterstützung bedeutet möglicherweise nur einen Hint, nicht eine harte Durchsetzung. Das Modell kann nicht immer wechseln (z.B. Enterprise-Tenant mit fixem Modell). Die Dokumentation muss diesen Vorbehalt benennen.

---

## 6. Resume Workflow Logic

### Startup-Prozedur im Main-Agent

```
## Schritt 0: Startup-Check (wird bei JEDEM Gespräch ausgeführt)

1. Versuche `.planning/al-workflow/SESSION.md` zu lesen.

2a. SESSION.md existiert NICHT:
    → "Hallo! Ich bin dein AL-Entwicklungspartner. Nenne mir eine Work-Item-Nummer
       oder beschreibe deine Anforderung."
    → Warte auf Input.

2b. SESSION.md existiert, current_step == 0 UND awaiting_checkpoint == false:
    → Normal starten, SESSION.md für neues Ticket vorbereiten.

2c. SESSION.md existiert, awaiting_checkpoint == true:
    → Resume-Angebot: "⏸️ Offener Workflow gefunden:
       Ticket: {ticket_id} — {ticket_title}
       Letzter Schritt: {current_agent} (Schritt {current_step} von 7)
       Zeitstempel: {last_updated}
       
       Soll ich dort weitermachen? (ja / nein — neu starten / details)"

2d. SESSION.md existiert, paused == true:
    → Resume-Angebot (wie 2c, aber mit ⏸️ Pausiert-Hinweis)

2e. SESSION.md existiert, last_updated > 48h:
    → "⚠️ Hinweis: Dieser Workflow-Stand ist {X} Stunden alt.
       Ticket: {ticket_id} | Letzter Schritt: {current_step}
       Noch aktuell? (ja — fortfahren / nein — neu starten)"
```

### Resume-Flow Detail

```
Nutzer: "ja"
    ↓
Main-Agent liest SESSION.md vollständig
    ↓
Bestimmt current_step und current_agent
    ↓
Zeigt kurze Zusammenfassung des letzten bekannten Standes:
    "Ich erinnere mich: WI #{ticket_id} — {ticket_title}
     Abgeschlossene Schritte: {approved_steps}
     Letzter Output von {current_agent}: [aus SESSION.md Abschnitt]
     
     Nächster Schritt: {nächster Agent}
     Weiter? (ja / nein)"
    ↓
Bei "ja": Workflow ab current_step fortsetzen
    ↓
SESSION.md: awaiting_checkpoint: false (war true vom letzten Mal)
```

### Edge Cases

| Situation | Handling |
|-----------|----------|
| SESSION.md vorhanden, aber ticket_id leer | Als neu behandeln — SESSION.md zurücksetzen |
| customer_path nicht mehr erreichbar | Warnung ausgeben, Pfad neu abfragen |
| branch in SESSION.md existiert nicht mehr | Warnung, Branch-Name aus Session löschen, neu vergeben |
| build_fix_loop_count >= 3 | Sofort eskalieren: "Vorheriger Workflow hat Fix-Loop-Limit erreicht — bitte manuell prüfen" |

---

## 7. Integration Pattern

### Delegations-Mechanismus

Alle Delegationen laufen über `runSubagent` (mapped auf das `agent`-Tool im Frontmatter). Dies ist der bestehende Mechanismus aus `al-auto-dev.agent.md`:

```markdown
Delegiere jetzt an al-planner:
runSubagent("al-planner", {
  task: "Erstelle einen technischen Umsetzungsplan für: {ticket_summary}\n
         Akzeptanzkriterien: {acceptance_criteria}\n
         BC-Projekt: {customer_path}"
})
```

**Wichtig:** Der Main-Agent darf nicht selbst AL-Dateien lesen, analysieren oder Code schreiben. Jede Arbeit geht durch einen Spezialisten.

### Phase 1: Main-Agent delegiert an BESTEHENDE Spezialisten

In Phase 1 existieren noch keine neuen Phase-2-Agents (al-architect, al-coder, al-validator). Der Main-Agent delegiert an die bestehenden Agents:

```
Phase 1-Ablauf:                    Phase 2-Ablauf (zur Referenz):
─────────────────                  ─────────────────
al-devops-reader (neu)             al-devops-reader (Phase 1)
    ↓ CP-1                             ↓ CP-1
al-planner (bestehend)             al-architect (Phase 2, neu)
    ↓ CP-2                             ↓ CP-2
al-codebase-analyst (bestehend)    [intern in al-architect]
    ↓
al-implementer (bestehend)         al-coder (Phase 2, neu)
    ↓
al-build-tester (bestehend)        [intern in al-coder]
    ↓ CP bei Fehlern                   ↓ CP-3
al-reviewer (bestehend)            al-validator (Phase 2, neu)
    ↓ CP-4                             ↓ CP-4
al-documenter (bestehend)          al-reviewer (Phase 2, updated)
                                       ↓ CP-5
                                   al-docs-coordinator (Phase 3, neu)
```

### `## ERGEBNIS`-Block-Konvention

Alle bestehenden Agents haben bereits einen `## Output`-Block. Für Phase 1 interpretiert Main-Agent den bestehenden Output-Block. Für Phase 2 werden Specs für einen standardisierten `## ERGEBNIS`-Block eingeführt (CONTRACT-01 aus Phase 2).

**Phase-1-Lese-Heuristik:**
- `## Buildstatus` aus al-build-tester → Checkpoint "Build OK" oder "Build fehlgeschlagen"  
- `## Review-Ergebnis` aus al-reviewer → Checkpoint "Freigabe" / "Blocker" / "Änderungen"
- `## Zusammenfassung` aus al-planner → Checkpoint-Kern

### runSubagent-Verfügbarkeits-Check (Pitfall C-2)

Als erste Aktion muss der Main-Agent einen Pre-flight-Check einbauen:

```markdown
## Pre-Flight-Check (Schritt -1)

Prüfe: Ist das Tool `agent` / `runSubagent` verfügbar?
- Wenn JA: normaler Modus
- Wenn NEIN: Manueller Modus aktivieren

## Manueller Modus (Fallback)

Falls runSubagent nicht verfügbar:
1. Gib dem Nutzer die manuelle Reihenfolge aus
2. Erkläre welchen Agent er manuell starten soll
3. Halte den Checkpoint-Protokoll-Prozess aufrecht (du sammelst die Outputs)
```

---

## 8. Scope Fences — Was ist NICHT Phase 1

| Nicht in Phase 1 | Wann | Anforderungs-ID |
|------------------|------|-----------------|
| `al-architect.agent.md` | Phase 2 | ARCH-01 bis ARCH-04 |
| `al-coder.agent.md` | Phase 2 | CODER-01 |
| `al-validator.agent.md` | Phase 2 | VALID-01 bis VALID-03 |
| `al-tester.agent.md` | Phase 2 | TEST-01 bis TEST-02 |
| CONTRACT-01: strukturierte ERGEBNIS-Blöcke | Phase 2 | CONTRACT-01 |
| Customer-Docs-Agents (Betzold, Hermes, Tröber) | Phase 3 | DOCS-01 bis DOCS-06 |
| `al-websearch.agent.md` + `al-code-research.agent.md` | Phase 4 | HELP-01 bis HELP-04 |
| ADO Write-Operationen (WI-Tags setzen, Status ändern) | v2 | AUTO-01 |
| Automatische PR-Erstellung | v2 | AUTO-02 |
| Branch-Erstellung im Main-Agent | v2 | AUTO-03 |
| Merge-Operationen jeglicher Art | Out of Scope (Policy) | — |
| LangGraph / AutoGen / Python-Runtime | Out of Scope | — |

**Wichtig für Phase 1:** `al-auto-dev.agent.md` wird **nicht gelöscht** (explizite Architektur-Entscheidung). Es bleibt für Rückwärtskompatibilität erhalten.

---

## 9. Risks & Pitfalls

### Risiko R-1: Main-Agent fällt in fire-and-forget zurück (KRITISCH)

**Was schiefläuft:** LLM-Agents optimieren auf Task-Completion. Ohne hartes imperatives "STOP"-Muster im Instruction-Text startet der Main-Agent alle Subagents sequenziell ohne Nutzer-Pause — identisch zum Problem bei `al-auto-dev`.

**Mitigation:**
- Checkpoint-Muster **imperativ** formulieren, nicht als Hinweis
- Explizite Instruction: "Niemals zwei Subagents in derselben Turn-Sequenz starten"
- Nach dem Schreiben der Datei: manueller Test mit einem trivialen AL-Task — der Nutzer muss mindestens 3 Checkpoint-Momente erleben bevor Code entsteht

**Aus:** PITFALLS.md Pitfall C-1 [VERIFIED: Codebase-Analyse]

### Risiko R-2: SESSION.md-Konsistenz nach unvollständigem Schreiben

**Was schiefläuft:** Main-Agent schreibt SESSION.md teilweise, dann bricht die Konversation ab. Beim nächsten Start zeigt SESSION.md einen inkonsistenten Zustand: `awaiting_checkpoint: true` aber kein Schritt-Protokoll-Eintrag.

**Mitigation:**
- SESSION.md-Updates immer atomar: erst vollständigen neuen Inhalt schreiben, nicht partial-edits
- `last_updated`-Timestamp zwingt den Nutzer bei >48h zur Bestätigung (Stale-Session-Schutz aus PITFALLS.md M-4)

### Risiko R-3: GitHub MCP Server nicht konfiguriert

**Was schiefläuft:** DevOps-Reader listet GitHub MCP Server-Tools im Frontmatter auf, aber der Server ist nicht installiert. Agent schlägt stumm fehl oder gibt kryptische Fehlermeldungen.

**Mitigation:**
- DevOps-Reader muss beim Start prüfen ob GitHub-Tools verfügbar sind
- Bei fehlendem GitHub MCP: klar melden "GitHub-Integration nicht konfiguriert — ADO-only-Modus"
- Fallback: Nutzer kann GitHub Issue-URL manuell einfügen

### Risiko R-4: customer_path-Extraktion scheitert

**Was schiefläuft:** Main-Agent soll den Kunden aus dem Dateipfad (`C:\Users\dloewe\{Kunde}\`) ableiten. Wenn die Pfad-Heuristik nicht greift (z.B. anderer Pfad-Aufbau, anderer Entwickler), landet ein falscher Kunde in SESSION.md.

**Mitigation:**
- Immer **explizit fragen** wenn Kunde nicht eindeutig aus Pfad ableitbar
- SESSION.md-Schema hat separates `customer`-Feld neben `customer_path` — beide prüfen
- Aus PITFALLS.md M-5: customer aus Pfad extrahieren (`path.split('\\')[4]`), NICHT aus Nutzer-Input oder Annahme

### Risiko R-5: model:-Frontmatter ohne Effekt in bestimmten Copilot-Konfigurationen

**Was schiefläuft:** MODEL-01 erfordert `model:` in allen Agent-Dateien. In Enterprise-Copilot-Tenants mit fixem Modell oder in Umgebungen ohne Modell-Wahl-Unterstützung hat das Frontmatter-Feld keinen Effekt. Erwartung (Opus für Planung) vs. Realität (alles läuft auf Tenant-Default).

**Mitigation:**
- MODEL-02 Dokumentation muss diesen Vorbehalt explizit benennen
- Main-Agent gibt Modell-Hint im Checkpoint aus ("Für diesen Schritt ist Opus empfohlen — bitte manuell wechseln falls möglich")
- Kein hartes Blockieren auf falsches Modell — nur Empfehlung [ASSUMED: Verhalten von model: Frontmatter in Enterprise-Tenants nicht verifiziert]

---

## 10. Recommended Task Order

Der Planner sollte die Tasks in dieser Reihenfolge planen — jede Stufe baut auf der vorherigen auf:

### Wave 1: Foundation (kein gegenseitiges Blocking)

| Task | Datei | Anforderung |
|------|-------|-------------|
| T-1 | `.planning/al-workflow/SESSION.md` Schema erstellen (leere Vorlage) | MAIN-04 |
| T-2 | `al-devops-reader.agent.md` erstellen | DEVOPS-01, DEVOPS-02 |
| T-3 | `model:` Frontmatter in alle 7 bestehenden Agent-Dateien eintragen | MODEL-01 |

### Wave 2: Main-Agent (nach SESSION.md-Schema)

| Task | Datei | Anforderung |
|------|-------|-------------|
| T-4 | `main-agent.agent.md` erstellen (Frontmatter + Body komplett) | MAIN-01 |
| T-5 | Checkpoint-Protokoll in `main-agent.agent.md` einbauen (imperativ) | MAIN-02, MAIN-03 |
| T-6 | Session-Start-Prozedur + Resume-Logik in `main-agent.agent.md` einbauen | MAIN-05, MAIN-06 |

### Wave 3: Model-Konzept-Dokumentation (nach Agent-Dateien)

| Task | Datei | Anforderung |
|------|-------|-------------|
| T-7 | Modell-Switching-Konzept dokumentieren (Abschnitt in main-agent.agent.md oder eigene Datei) | MODEL-02 |

### Verifikation (am Ende)

- [ ] Manueller Test: Neues Gespräch mit main-agent starten, WI-Nummer eingeben — mindestens CP-1 (nach DevOps-Reader) erscheint vor dem Plan
- [ ] Manueller Test: Gespräch bei CP-1 abbrechen, VS Code neu starten, main-agent öffnen — Resume-Angebot erscheint
- [ ] Manueller Test: `anpassen: [Hinweis]` bei CP-1 eingeben — Devops-Reader wird mit Hinweis neu aufgerufen
- [ ] Prüfen: `al-devops-reader` kann keine ADO-Write-Operation ausführen (ADO-Wildcard ist nicht im Frontmatter)
- [ ] Prüfen: `model:` ist in allen 9 Agent-Dateien vorhanden

---

## Assumptions Log

| # | Claim | Abschnitt | Risiko wenn falsch |
|---|-------|-----------|-------------------|
| A1 | GitHub MCP Server exponiert Tools mit einem bestimmten Naming-Schema (z.B. `github/issues/get`) | §4 DevOps-Reader | Toolnames im Frontmatter falsch → GitHub-Integration funktioniert nicht |
| A2 | `model:` Frontmatter ist in VS Code Copilot für `.agent.md` Dateien unterstützt und wird vom Runtime ausgewertet | §5 Model Frontmatter | Model-Frontmatter hat keinen Effekt — nur als Dokumentation/Hint funktional |
| A3 | `model:` in Enterprise-Copilot-Tenants kann durch Tenant-Policy überschrieben werden | §5, §9 Risiko R-5 | Erwartete Modell-Qualität nicht erreichbar in manchen Umgebungen |
| A4 | Die genauen Model-IDs `claude-opus-4` und `claude-sonnet-4-5` sind die aktuell korrekten Bezeichner | §5 Model Frontmatter | Falsche Model-ID → Model wird nicht erkannt, Fallback auf Default |

---

## Sources

- `.github/agents/al-auto-dev.agent.md` — Bestehender Orchestrator-Pattern (Frontmatter, Delegation, Tools) [VERIFIED: Codebase]
- `.github/agents/al-build-tester.agent.md` — Spezialist-Pattern mit Policy-Referenz und Output-Block [VERIFIED: Codebase]
- `.github/agents/al-planner.agent.md` — Spezialist-Pattern minimalistisch [VERIFIED: Codebase]
- `.github/agents/al-reviewer.agent.md` — Spezialist-Pattern mit Output-Block [VERIFIED: Codebase]
- `.github/policies/agent-policy.md` — Verbindliche Policy, Confidence-Rubrik, Fix-Loop-Eskalation [VERIFIED: Codebase]
- `.github/copilot-instructions.md` — Grundregeln, Verzeichnis-Policy [VERIFIED: Codebase]
- `.planning/research/ARCHITECTURE.md` — Systemdesign, Checkpoint-Format, Session-State-Schema [VERIFIED: Projektforschung]
- `.planning/research/STACK.md` — Model-Zuweisung, SESSION.md-Schema, ADO-Integration [VERIFIED: Projektforschung]
- `.planning/research/PITFALLS.md` — Kritische Pitfalls C-1 bis C-6, M-1 bis M-5 [VERIFIED: Projektforschung]
- `.planning/REQUIREMENTS.md` — Anforderungs-IDs MAIN-01 bis MODEL-02 [VERIFIED: Codebase]
