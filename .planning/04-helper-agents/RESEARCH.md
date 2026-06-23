# Phase 4: Helper Agents — Research

**Recherchiert:** 2026-06-18
**Domäne:** Agent-Design / BC AL Agentic Framework — Leaf-Node-Subagents
**Confidence:** HIGH

---

## Zusammenfassung

Phase 4 ergänzt das BC AL Agentic Development Kit um zwei schlanke Hilfs-Agents (Leaf-Nodes),
die ausschließlich von den Spezialisten `al-architect` und `al-coder` on-demand aufgerufen
werden: `al-websearch` für Echtzeit-MS-Learn-Dokumentation und `al-code-research` für
AL-Symbol-Lookups und Code-Usages. Beide Helpers sind dem Entwickler vollständig unsichtbar —
sie produzieren keinen `## ERGEBNIS`-Block, erscheinen nicht in der Checkpoint-Tabelle und
kommunizieren nie direkt mit dem Nutzer.

Das bestehende `al-codebase-analyst.agent.md` ist das **kanonische Muster** für Leaf-Node-Agents:
minimales Frontmatter (`name`, `model`, `description`, `tools` — kein `skills:`, kein
`agents:`), klarer Output-Header (`## Output`, NICHT `## ERGEBNIS`), keine Checkpoint-Logik,
keine Confidence-Bewertung. Dieses Muster wird für beide neuen Helpers direkt adaptiert.

**Primäre Empfehlung:** Beide Helpers strikt nach al-codebase-analyst-Muster bauen — schlanke
Agents ohne eigene Planungslogik. Die Aufruf-Bedingungen werden in den **Caller-Agents**
(al-architect, al-coder) als explizite "Wann aufrufen?"-Anweisungen dokumentiert. Jede
Helper-Datei enthält zusätzlich ihr eigenes Aufruf-Protokoll für Rückwärts-Referenzierung
(HELP-04).

---

## Phase-Anforderungen

| ID | Beschreibung | Research-Unterstützung |
|----|-------------|----------------------|
| HELP-01 | `al-websearch.agent.md` — MS Learn + Web suchen | Frontmatter, Tool-Scope, URL-Priorisierung, Return-Format → Abschnitt 2 |
| HELP-02 | `al-code-research.agent.md` — AL-Symbole, Code-Usages | vscode_listCodeUsages, .alpackages-Lookup, Return-Format → Abschnitt 3 |
| HELP-03 | Leaf-Nodes — kommunizieren nie mit Entwickler | Kein ERGEBNIS-Block, Verbots-Regeln, Caller-Deklaration → Abschnitte 1 + 5 + 6 |
| HELP-04 | Dokumentiertes Aufruf-Protokoll in Helper-Datei | runSubagent-Syntax, Bedingungen, Rückgabe-Format → Abschnitt 4 |

---

## Architektur-Verantwortlichkeiten

| Fähigkeit | Primäre Schicht | Sekundäre Schicht | Begründung |
|-----------|-----------------|-------------------|------------|
| MS-Learn-Suche | `al-websearch` (Leaf-Node) | — | Spezialisierte Abfrage, kein Fließtext-Overhead im Caller |
| AL-Symbol-Lookup | `al-code-research` (Leaf-Node) | al-object-analysis Skill | Erweitert Skill-Logik um vscode_listCodeUsages |
| Aufrufentscheidung | al-architect / al-coder | — | Spezialisten entscheiden wann ein Helper nötig ist |
| User-Output / Checkpoints | main-agent | — | Helpers erzeugen **keinen** User-Output und **keinen** Checkpoint-Trigger |
| Helper-Roster (Discovery) | main-agent (`agents:` Frontmatter) | AGENTS.md | Infrastruktur-Sichtbarkeit ohne Workflow-Integration |

---

## 1. Helper-Agent-Muster-Analyse

### 1.1 Kanonisches Leaf-Node-Muster: al-codebase-analyst

Das einzige vollständig implementierte Leaf-Node-Beispiel im Codebase ist
`al-codebase-analyst.agent.md`. Direkte Codebase-Analyse (VERIFIED):

**Frontmatter-Struktur:**
```yaml
---
name: al-codebase-analyst
model: claude-sonnet-4-5
description: Analysiert bestehende Business-Central-AL-Repositories...
tools: ["read", "search"]
---
```

**Kritische Beobachtungen:**
- **Kein `agents:` Frontmatter-Feld** — Leaf-Node ruft nichts auf
- **Kein `skills:` Frontmatter-Feld** — Skills werden im Body als Anweisung referenziert:
  ```
  ## Nutze diese Skills
  - al-object-analysis
  ```
- **Output-Block:** `## Output` (NICHT `## ERGEBNIS`) — verhindert ungewolltes ERGEBNIS-Parsing durch main-agent
- Keine Confidence-Bewertung, kein "Interpretation für Main-Agent" Footer
- Feste Markdown-Sektionen: Relevante Dateien, AL-Objekte, Patterns, Erweiterungspunkte
- Explicit rule: **"keine Rückfragen"**, **"kein Code ändern"**

**Aufruf-Deklaration auf Caller-Seite (al-architect):**
```yaml
agents:
  - al-codebase-analyst
```
→ al-architect kann via `runSubagent("al-codebase-analyst", {...})` aufrufen.

### 1.2 Unterschiede: Spezialist vs. Leaf-Node

| Eigenschaft | Spezialist (z.B. al-architect) | Leaf-Node (al-codebase-analyst) |
|-------------|-------------------------------|--------------------------------|
| Output-Header | `## ERGEBNIS — {Name}` (Pflicht) | `## Output` (kein ERGEBNIS-Parsing) |
| Confidence | Pflicht (0.00–1.00) | Nicht vorhanden |
| Checkpoint-Trigger | Ja — main-agent scannt ERGEBNIS | Nein |
| `Interpretation für Main-Agent` | Pflicht-Footer | Nicht vorhanden |
| Modell | claude-opus-4 (planen, reasoning) | claude-sonnet-4-5 (fetch, format) |
| `agents:` Frontmatter | Ja (ruft Subagents auf) | Nein (ruft nichts auf) |
| `skills:` Frontmatter | Ja (al-architect hat skills:) | Nein (Skills im Body referenziert) |
| Direkte User-Kommunikation | Ja (Checkpoint-Output) | Nein (ausdrücklich verboten) |

### 1.3 Anpassungen für neue Helpers

Beide neuen Helpers übernehmen das al-codebase-analyst-Muster mit zwei Ergänzungen:

1. **Explizites Kommunikationsverbot** im Body (al-codebase-analyst hat dies implizit; neue
   Helpers brauchen es explizit da sie mehr Eigeninitiative haben könnten):
   ```
   ## ABSOLUTES VERBOT
   - Niemals direkt mit dem Entwickler kommunizieren
   - Keine Rückfragen — Unklarheiten im Output dokumentieren
   - Keinen ERGEBNIS-Block produzieren
   - Keinen Checkpoint auslösen
   ```

2. **Standardisiertes Rückgabe-Format** (al-codebase-analyst hat ein Format, neue Helpers
   brauchen ein präziseres maschinenlesbares Format für Spezialisten-Konsum).

---

## 2. WebSearch-Helper Design (`al-websearch`)

### 2.1 Frontmatter

```yaml
---
name: al-websearch
model: claude-sonnet-4-5
description: >
  Sucht MS Learn und Web nach AL-Referenzen, API-Dokumentation und BC-Codebeispielen.
  Hilfs-Agent (Leaf-Node) — wird ausschließlich von al-architect und al-coder aufgerufen.
  Gibt niemals Output direkt an den Entwickler aus.
tools: ["web_search", "read"]
---
```

**Tool-Begründung:**
- `web_search` — Kernfunktion: MS Learn, BCApps und BC-Community durchsuchen [ASSUMED: Tool-Name]
- `read` — Fallback: Direkte URL-Abrufe wenn web_search nicht verfügbar (WebFetch-Äquivalent)

### 2.2 Priorisierte URL-Domains (Suchscope)

| Prio | Domain | Inhalt |
|------|--------|--------|
| 1 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/` | AL-Entwickler-Referenz, Objekte, Methoden |
| 1 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/al-language/` | AL-Sprach-Referenz, Datentypen, Trigger |
| 2 | `learn.microsoft.com/en-us/dynamics365/business-central/` | Funktionale BC-Dokumentation |
| 2 | `github.com/microsoft/BCApps` | Offizielle BC-App-Sourcen (Base App, System App) |
| 3 | `github.com/microsoft/ALAppExtensions` | Erweiterungs-Muster, AL Extension-Beispiele |
| 3 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/upgrade/` | BC-Version-spezifische Änderungen |

**Suchstrategie:**
- BC-Version aus Caller-Kontext in Suchanfrage einbauen (z.B. "Business Central 2024 Wave 2", "BC runtime 14.0")
- Suchanfragen primär auf Englisch (MS Learn AL-Dokumentation ist primär EN)
- Maximal 3 Suchiterationen pro Aufruf — danach mit verfügbaren Ergebnissen arbeiten

### 2.3 Rückgabe-Format (Output)

```markdown
## Suchergebnis — WebSearch

**Suchanfrage:** {originale Anfrage vom Caller}
**BC-Version-Kontext:** {aus Caller-Input, z.B. "runtime 14.0 / BC 2024 Wave 1"}
**Suchdatum:** {Datum}

### Gefundene MS-Learn-Referenzen
| URL | Relevanz | Zusammenfassung |
|-----|----------|-----------------|
| {URL} | Hoch / Mittel / Niedrig | {1 Satz Kernaussage} |

### Relevante AL-Code-Beispiele
```al
// Quelle: {URL}
{Code-Snippet — nur wenn in Dokumentation gefunden}
```

### API-Signatur (falls gefunden)
```
{ProcedureName}({Parameter: Typ; ...}): {Rückgabetyp}
Objekt: {ObjectType} {ID} "{Name}" aus {Paket/Modul}
```

### Nicht gefunden / Einschränkungen
- {Falls keine Ergebnisse: konkrete Hinweise für Caller}
- {Oder "Keine — alle gesuchten Informationen gefunden"}
```

### 2.4 Aufruf-Bedingungen

**al-architect ruft al-websearch auf wenn (ALLE Bedingungen alternativ):**
1. Ein Ticket-AC referenziert eine BC-Methode/API, die NICHT in den heruntergeladenen
   `.alpackages/`-Symbolen auffindbar ist
2. BC-Version in `app.json` ist aktuell (runtime ≥ 13.0 / BC 2024+) und das Ticket
   referenziert ein potenziell versions-spezifisches Feature (z.B. "neue Sustainability API")
3. Der Ticket-Text enthält explizite MS-Learn-Verweise oder fordert Implementierung nach
   spezifischer Microsoft-Dokumentation
4. `al-object-analysis` Skill konnte ein beschriebenes BC-Standard-Verhalten nicht lokalisieren

**al-architect ruft NICHT auf bei:**
- Standard-TableExtension / PageExtension ohne neue API-Interaktion
- Wenn Symbol-Paket bereits die vollständige Methoden-Signatur enthält
- Als Default-Schritt vor jeder Planung (nur bei konkreter Informationslücke)

**al-coder ruft al-websearch auf wenn:**
1. `al_getdiagnostics` meldet einen Fehler der auf eine unbekannte BC-API-Signatur hinweist
   (z.B. `procedure not found`, `wrong number of arguments`)
2. Ein BC-Feature im Contract hat kein Symbol-Äquivalent in `.alpackages/`

---

## 3. Code-Research-Helper Design (`al-code-research`)

### 3.1 Frontmatter

```yaml
---
name: al-code-research
model: claude-sonnet-4-5
description: >
  Sucht AL-Symbole, Code-Usages und Objekt-Referenzen. Kombiniert al-object-analysis
  mit vscode_listCodeUsages. Hilfs-Agent (Leaf-Node) — wird ausschließlich von al-architect
  und al-coder aufgerufen. Gibt niemals Output direkt an den Entwickler aus.
tools: ["read", "search"]
---
```

**Skills im Body referenziert (KEIN `skills:` Frontmatter — analog zu al-codebase-analyst):**
```
## Nutze diese Skills
- al-object-analysis
- al-build-validation
```

**Tool-Begründung:**
- `read` — `.alpackages/*.app`-Dateien und `.al`-Quelldateien lesen
- `search` — Symbol-Suche in `.alpackages/`, grep über Kundenprojekt-Sourcen

**Skills (im Body als Anweisung):**
- `al-object-analysis` — strukturierte Symbol-Suche in `.alpackages/`
- `al-build-validation` — gibt Zugriff auf `vscode_listCodeUsages` und `al_downloadsymbols`

### 3.2 Untersuchungs-Scope

| Quelle | Was wird gesucht | Primär-Tool |
|--------|-----------------|-------------|
| `.alpackages/*.app` | Objekt-ID, Name, Felder, Methoden-Signaturen | al-object-analysis Skill |
| `{customer_path}/src/**/*.al` | Bestehende Usages, Patterns im Kundenprojekt | search / grep |
| VS Code Extension | Code-Usages eines AL-Symbols | vscode_listCodeUsages [ASSUMED: Tool-Name] |
| `{customer_path}/app.json` | idRanges, Abhängigkeits-Liste | read |

### 3.3 Rückgabe-Format (Output)

```markdown
## Suchergebnis — Code-Research

**Gesuchtes Symbol:** {Symbol-Name / Objekt-Name vom Caller}
**Projekt-Pfad:** {customer_path}
**Suchdatum:** {Datum}

### Symbol-Definition
- **Typ:** {table | codeunit | page | report | enum | ...}
- **Objekt-ID:** {ID oder "nicht gefunden"}
- **Name:** "{Name}"
- **Paket:** {.app-Dateiname aus .alpackages/ oder "Kundenprojekt"}

### Methoden / Felder
| Name | Typ | Signatur / Datentyp |
|------|-----|---------------------|
| {Name} | Procedure / Field / Key | {procedure Name(Param: Typ): ReturnType oder FieldType[Len]} |

### Code-Usages (vscode_listCodeUsages)
| Datei | Zeile | Verwendungskontext |
|-------|-------|--------------------|
| {relativer Pfad} | {Zeilennr.} | {Code-Zeile als Kontext} |

### Bestehende Patterns im Kundenprojekt
- {Pattern 1 — z.B. "SalesValidationMgt.Codeunit.al ruft Codeunit 80 via OnAfterReleaseSalesDoc"}
- {"Keine" wenn nichts gefunden}

### Nicht gefunden / Einschränkungen
- {Symbol nicht in .alpackages/ → Hinweis: al_downloadsymbols erforderlich}
- {vscode_listCodeUsages nicht verfügbar → Fallback auf grep-Ergebnisse}
- {"Keine" wenn alles gefunden}
```

### 3.4 Aufruf-Bedingungen

**al-architect ruft al-code-research auf wenn (alternativ):**
1. Der Plan erfordert das Aufrufen einer BC-Codeunit mit unbekannter Methoden-Signatur
   (z.B. Codeunit 80 "Sales-Post" — Schnittstelle muss vor Planung geklärt werden)
2. Das Ticket erfordert das Subscriben auf einen Publisher-Event, dessen genaue Parameter
   nicht aus dem Symbol-Paket lesbar sind
3. Unsicherheit ob eine TableExtension oder PageExtension bereits im Kundenprojekt existiert

**al-coder ruft al-code-research auf wenn (alternativ):**
1. VOR dem Schreiben einer Prozedur die eine bestehende BC-Codeunit aufruft — zur Verifikation
   der exakten Methoden-Signatur
2. `al_getdiagnostics` meldet `procedure ... not found` oder `type ... is not defined`
3. `al_getdiagnostics` meldet falsche Parameter-Anzahl oder falschen Typ — Signatur-Korrektur nötig

**NICHT aufrufen bei:**
- Einfachen Tabellen-/Page-Extensionen ohne Codeunit-Aufrufe
- Wenn Schritt 1 (Symbol-Download via al-build-validation) bereits die benötigten Signaturen lieferte
- Als Default-Schritt vor jedem Code-Schreib-Schritt

---

## 4. Aufruf-Protokoll-Spezifikation

### 4.1 Basis-Syntax (aus main-agent.agent.md — VERIFIED)

```
runSubagent("{agent-name}", {
  task: "{Aufgabenbeschreibung}
         {Kontextfelder}"
})
```

### 4.2 al-websearch Aufruf-Muster (von al-architect)

```
runSubagent("al-websearch", {
  task: "Suche MS-Learn-Dokumentation für folgende BC-Funktion/Feature.

         Gesuchte Information: {API-Name | Feature-Name | Objekt-Name}
         BC-Version: runtime {X.X} aus app.json (z.B. runtime 14.0 = BC 2024 Wave 1)
         Suchziel: {API-Signatur | Feature-Beschreibung | Codebeispiel | Best Practice}

         Kontext für Relevanz-Filterung:
         Ticket-Kontext: {1 Satz was implementiert werden soll}
         Bekannte Symbol-Info aus .alpackages/: {was bereits bekannt ist}
         Wissenslücke: {konkret was fehlt}"
})
```

**Erwarteter Return:** Markdown mit `## Suchergebnis — WebSearch` Header.

### 4.3 al-websearch Aufruf-Muster (von al-coder)

```
runSubagent("al-websearch", {
  task: "Suche BC-API-Dokumentation für Fehler aus Diagnostics.

         Diagnostics-Fehler: {vollständige al_getdiagnostics Fehlermeldung}
         BC-Version: runtime {X.X} aus app.json
         Kundenpfad: {customer_path}

         Gesuchte Information: Korrekte API-Signatur oder Alternativlösung
         Kontext: {was der Coder implementieren will}"
})
```

### 4.4 al-code-research Aufruf-Muster (von al-architect)

```
runSubagent("al-code-research", {
  task: "Suche AL-Symbol-Informationen vor der Planung.

         Gesuchtes Symbol: {Codeunit-Name | Table-Name | Event-Name}
         Objekt-Typ: {codeunit | table | page | ...}
         Projekt-Pfad (customer_path): {aus SESSION.md}

         Gesuchte Information: {Methodensignatur | Event-Parameter | Tabellen-Felder}

         Planungs-Kontext:
         Ticket-Anforderung: {1 Satz was geplant wird}
         Warum diese Info nötig: {welcher Plan-Schritt davon abhängt}"
})
```

### 4.5 al-code-research Aufruf-Muster (von al-coder)

```
runSubagent("al-code-research", {
  task: "Verifiziere AL-Symbol-Signatur vor Code-Schreiben.

         Gesuchtes Symbol: {exakter Name wie im Code verwendet werden soll}
         Objekt-Typ: {codeunit | table | ...}
         Projekt-Pfad (customer_path): {aus SESSION.md}

         Diagnostics-Fehler (falls vorhanden): {al_getdiagnostics Ausgabe}
         Geplante Verwendung: {wie der Coder das Symbol verwenden will}
         Code-Kontext: {Ausschnitt des geplanten AL-Codes}"
})
```

### 4.6 Idempotenz und Mehrfach-Aufrufe

- Helpers **können mehrfach** in einem Workflow aufgerufen werden (kein technisches Verbot)
- Ergebnisse werden **nicht automatisch gecacht** — aufrufender Spezialist integriert den Output
  in seinen eigenen Kontext (Working Memory / nächste Plan-Schritte)
- `al-code-research` liefert bei identischer Anfrage stabilen Output (Symbole sind statisch)
- `al-websearch` kann bei Mehrfach-Aufruf leicht abweichen (Web-Suche)
- Empfehlung im Caller: Helper nur einmal pro Feature/Symbol aufrufen, Output in Arbeitsnotizen festhalten

---

## 5. Modell- und Tool-Zuweisung

### 5.1 Modell-Strategie

| Helper | Modell | Begründung |
|--------|--------|------------|
| al-websearch | `claude-sonnet-4-5` | Reine Fetch-und-Format-Aufgabe — kein reasoning-intensives Planen nötig |
| al-code-research | `claude-sonnet-4-5` | Symbol-Lookup und Strukturierung — kein Planungs-Overhead |

**Konsistenz:** `docs/model-switching.md` (Phase 1) definiert Sonnet 4.x für Ausführungs-Agents
und Helpers — ✓ konsistent mit bestehendem Framework.

### 5.2 Tool-Matrix im Detail

**al-websearch:**
| Tool | Zweck | Fallback wenn nicht verfügbar |
|------|-------|-------------------------------|
| `web_search` | MS Learn + BCApps durchsuchen | `read` mit bekannten Doku-URLs |
| `read` | Direkte bekannte URLs abrufen (WebFetch) | — (muss immer verfügbar sein) |

**al-code-research:**
| Tool / Skill | Zweck | Fallback wenn nicht verfügbar |
|--------------|-------|-------------------------------|
| `read` | .alpackages/*.app und .al-Dateien lesen | — (Pflicht-Tool) |
| `search` | Symbols in .alpackages/, grep in Kundenprojekt | — (Pflicht-Tool) |
| al-object-analysis Skill | Strukturierte Symbol-Suche | `search` + `read` manuell |
| al-build-validation Skill | `vscode_listCodeUsages`, `al_downloadsymbols` | grep-basiertes Usage-Finding |

**Wichtige Einschränkung — vscode_listCodeUsages:**
`vscode_listCodeUsages` ist ein VS-Code-Extension-Tool (AL Language Extension for VS Code).
Es steht **nur** zur Verfügung wenn:
1. Der Agent im Kontext der GitHub Copilot VS-Code-Extension läuft
2. Das AL-Projekt im Editor geöffnet ist
3. Die AL Language Extension aktiv ist

→ al-code-research muss dieses Tool als **optional** behandeln und bei Nicht-Verfügbarkeit
automatisch auf grep/search umschalten.

---

## 6. main-agent.agent.md Integration

### 6.1 Frontmatter — agents: Liste erweitern

**Aktueller Stand (VERIFIED):**
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

**Nach Phase 4:**
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
  - al-websearch        # Phase 4 — Hilfs-Agent, NUR von al-architect/al-coder aufgerufen
  - al-code-research    # Phase 4 — Hilfs-Agent, NUR von al-architect/al-coder aufgerufen
```

**Begründung für Aufnahme in main-agent:** Das Agent-System benötigt möglicherweise die
Deklaration im Root-Orchestrator für Agent-Discovery/Routing. main-agent ruft diese Agents
**NICHT** direkt auf — die Deklaration dient nur der Runtime-Sichtbarkeit.

### 6.2 Workflow-Tabelle — unverändert

Die `## Workflow-Schritt-Tabelle` in main-agent.agent.md wird **NICHT** erweitert.
Helpers erscheinen weder als Schritt noch als optionaler Schritt.

### 6.3 Optionaler Erklärungsblock in main-agent.agent.md

Empfehlung: Kurzer Hinweis-Block unter der Workflow-Tabelle (nach Zeile mit `al-tester`):

```markdown
### Helper-Agents (Infrastruktur — nicht im Workflow sichtbar)

`al-websearch` und `al-code-research` sind reine Infrastruktur-Helpers. Sie werden
von `al-architect` und `al-coder` on-demand via `runSubagent` aufgerufen — **nicht** vom
Main-Agent. Main-Agent verarbeitet ihren Output NICHT direkt. Kein Checkpoint wird durch
Helper-Output ausgelöst.
```

### 6.4 al-architect.agent.md — Frontmatter-Update

**Aktuell (VERIFIED):**
```yaml
agents:
  - al-codebase-analyst
```

**Nach Phase 4:**
```yaml
agents:
  - al-codebase-analyst
  - al-websearch        # Phase 4 — On-demand MS-Learn-Suche bei Wissenslücken
  - al-code-research    # Phase 4 — On-demand Symbol-Lookup vor Planschritten
```

**Body-Ergänzung in al-architect.agent.md** (neuer Abschnitt, empfohlen nach Schritt 1):

```markdown
### Helper-Aufruf (On-Demand — NICHT als Default)

Rufe Helper-Agents auf wenn eine konkrete Wissenslücke identifiziert ist:

**al-websearch aufrufen wenn:**
- BC-API/Feature im Ticket ist nicht in .alpackages/-Symbolen auffindbar
- BC-Version legt versions-spezifisches Verhalten nahe (runtime ≥ 13.0 + neues Feature)
- Ticket referenziert explizit MS-Learn-Dokumentation

**al-code-research aufrufen wenn:**
- Methoden-Signatur einer BC-Codeunit für Plan-Schritt benötigt wird
- Event-Publisher-Parameter nicht aus Symbolen lesbar
- Unsicherheit ob Objekt bereits im Kundenprojekt existiert

Ergebnisse aus Helper-Aufrufen werden intern verwendet — nie in ERGEBNIS-Block weitergegeben.
```

### 6.5 al-coder.agent.md — Frontmatter-Update

**Aktuell (VERIFIED):** Kein `agents:` Frontmatter-Feld vorhanden.

**Nach Phase 4 — neues `agents:` Feld hinzufügen:**
```yaml
agents:
  - al-code-research    # Phase 4 — Signatur-Verifikation vor Code-Schreiben
  - al-websearch        # Phase 4 — API-Doku wenn Diagnostics unbekannte API meldet
```

**Body-Ergänzung in al-coder.agent.md** (empfohlen in Schritt 3 oder als separater
Pre-Schritt zwischen Schritt 1 und Schritt 3):

```markdown
### Helper-Aufruf (On-Demand — NICHT als Default)

Rufe al-code-research auf VOR dem Schreiben wenn:
- Eine Prozedur eine BC-Codeunit aufruft und die Signatur nicht aus Schritt 1 bekannt ist
- al_getdiagnostics meldet `procedure ... not found` oder Signatur-Fehler

Rufe al-websearch auf wenn:
- al_getdiagnostics meldet BC-API-Fehler der nicht aus Symbolen erklärbar ist
- Ein Contract-Objekt hat kein Symbol-Äquivalent in .alpackages/

Helper-Output wird intern für Code-Korrektur genutzt — nie in ERGEBNIS-Block weitergegeben.
```

---

## 7. AGENTS.md Update

### 7.1 Tabelle "Aktuelle Agents" — neue Zeilen hinzufügen

In der Tabelle `### Aktuelle Agents (vorhanden)` zwei Zeilen ergänzen:

```markdown
| `.github/agents/al-websearch.agent.md` | MS Learn / Web-Suche — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv (Phase 4) |
| `.github/agents/al-code-research.agent.md` | AL-Symbole, Code-Usages — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv (Phase 4) |
```

### 7.2 Tabelle "Geplante Agents" — Zeilen entfernen

Die folgenden zwei Zeilen aus `### Geplante Agents (noch nicht implementiert)` entfernen:

```
| `al-websearch.agent.md` | MS Learn / Web-Suche — Hilfsagent für Spezialisten | Phase 4 |
| `al-code-research.agent.md` | AL-Symbole, Code-Usages — Hilfsagent für Architect/Coder | Phase 4 |
```

---

## 8. Risiko-Analyse

### Risiko 1: `web_search` Tool nicht verfügbar

**Wahrscheinlichkeit:** Mittel — Tool-Verfügbarkeit hängt von Copilot-Runtime-Konfiguration ab.
**Auswirkung:** al-websearch funktioniert nicht als Such-Agent.

**Fallback-Verhalten für al-websearch:**
```markdown
### Nicht gefunden / Einschränkungen
- web_search nicht verfügbar in aktueller Runtime.
- Empfohlene manuelle Recherche-URLs für Caller:
  - https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/
  - https://github.com/microsoft/BCApps
- Caller-Agent soll mit vorhandenem Symbol-Wissen aus .alpackages/ fortfahren und
  Wissenslücke im ERGEBNIS-Block dokumentieren.
```

**Planner-Maßnahme:** al-websearch muss zu Beginn prüfen ob `web_search` verfügbar ist
(Pre-Flight-Check via Versuch) und bei Fehler sofort in Fallback-Modus wechseln — kein
Exception-Stop.

---

### Risiko 2: `vscode_listCodeUsages` nicht verfügbar

**Wahrscheinlichkeit:** Hoch außerhalb VS-Code-Extension-Kontext.
**Auswirkung:** Usage-Suche in al-code-research nicht möglich.

**Fallback-Verhalten:**
al-code-research wechselt automatisch auf grep/search-basiertes Usage-Finding:

```markdown
### Code-Usages (Fallback: grep/search — vscode_listCodeUsages nicht verfügbar)
| Datei | Zeile | Verwendungskontext |
|-------|-------|--------------------|
| {via grep-Ergebnis} | {ca. Zeile} | {Code-Zeile} |
```

**Planner-Maßnahme:** `vscode_listCodeUsages` als optional dokumentieren. Hauptfunktion
(Symbol-Definition aus .alpackages/) darf nie von diesem Tool abhängen.

---

### Risiko 3: Keine Suchergebnisse (al-websearch)

**Wahrscheinlichkeit:** Niedrig-Mittel — bei sehr neuen BC-Features ohne Doku.
**Auswirkung:** Helper liefert leere Antwort; Caller-Spezialist hat weiterhin Wissenslücke.

**Fallback-Verhalten:**
```markdown
### Nicht gefunden / Einschränkungen
- Keine MS-Learn-Ergebnisse für "{query}" gefunden.
- Alternative Suchvorschläge:
  - Suche ohne BC-Version-Einschränkung
  - github.com/microsoft/BCApps Issues für "{feature}"
- Empfehlung: Caller-Agent reduziert Confidence und dokumentiert Annahme im Contract.
```

---

### Risiko 4: Symbol nicht in `.alpackages/` (al-code-research)

**Wahrscheinlichkeit:** Mittel — Symbol-Download könnte nicht aktuell sein.
**Auswirkung:** Methoden-Signatur nicht abrufbar.

**Fallback-Verhalten:**
```markdown
### Symbol-Definition
- **Typ:** Nicht gefunden in .alpackages/
- **Empfehlung:** al_downloadsymbols erneut ausführen (al-build-validation Skill)
- **Bekannte Abhängigkeit:** {Paket-Name aus app.json "dependencies" falls ableitbar}
```

---

### Risiko 5: Helper wird als Default-Schritt aufgerufen (Token-Verbrauch)

**Wahrscheinlichkeit:** Mittel — ohne klare Regeln könnten Spezialisten Helper immer aufrufen.
**Auswirkung:** Erhöhter Token-Verbrauch, langsamerer Workflow, keine inhaltliche Verbesserung.

**Prävention:**
- Aufruf-Bedingungen sind **explizit** als "nur wenn fehlend" in Caller-Agents dokumentiert
- Helper-Dateien selbst enthalten die Bedingungen (HELP-04-Anforderung)
- Explizite Formulierung in Caller: "NICHT als Default — nur bei konkreter Wissenslücke"

---

### Risiko 6: Direkte Entwickler-Kommunikation durch Helper

**Wahrscheinlichkeit:** Niedrig — aber ohne explizites Verbot möglich.
**Auswirkung:** Verletzt HELP-03, bricht das HiTL-Checkpoint-Modell des Main-Agents.

**Prävention:** Explizites Verbot im Body beider Helpers:
```
## ABSOLUTES VERBOT
- Niemals direkt mit dem Entwickler kommunizieren
- Keine Rückfragen stellen — Unklarheiten im Output-Block dokumentieren
- Keinen ## ERGEBNIS-Block produzieren
- Keinen Checkpoint auslösen
```

---

### Risiko 7: Subagent-Chaining-Tiefe nicht unterstützt

**Wahrscheinlichkeit:** Niedrig aber unklar — main→architect→helper ist 3-Ebenen-Chaining.
**Auswirkung:** Helpers funktionieren nicht wenn Runtime nur 2-Ebenen-Chaining erlaubt.

**Prävention:** Im Plan einen Validierungsschritt einplanen. Falls 3 Ebenen nicht supported:
Fallback-Architektur = main-agent delegiert Helpers direkt und gibt Ergebnis an Spezialist weiter.
(Bedeutet Architektur-Anpassung in al-architect/al-coder Body.)

---

## 9. Implementierungsreihenfolge

### Wave 1 — Neue Helper-Agents erstellen (parallel ausführbar)

| Aufgabe | Zieldatei | Anforderungen | Inhalt |
|---------|-----------|--------------|--------|
| `al-websearch.agent.md` erstellen | `.github/agents/al-websearch.agent.md` | HELP-01, HELP-03, HELP-04 | Frontmatter, Tool-Scope, URL-Prios, Return-Format, Aufruf-Protokoll, Verbote |
| `al-code-research.agent.md` erstellen | `.github/agents/al-code-research.agent.md` | HELP-02, HELP-03, HELP-04 | Frontmatter, Skill-Referenzen im Body, Return-Format, vscode_listCodeUsages-Fallback, Aufruf-Protokoll, Verbote |

### Wave 2 — Caller-Agents aktualisieren (parallel, nach Wave 1)

| Aufgabe | Zieldatei | Anforderungen | Inhalt |
|---------|-----------|--------------|--------|
| al-architect Frontmatter erweitern | `.github/agents/al-architect.agent.md` | HELP-04 | `agents:` um al-websearch + al-code-research ergänzen |
| al-architect Body ergänzen | `.github/agents/al-architect.agent.md` | HELP-04 | "Helper-Aufruf (On-Demand)"-Abschnitt mit Bedingungen |
| al-coder Frontmatter hinzufügen | `.github/agents/al-coder.agent.md` | HELP-04 | Neues `agents:` Frontmatter-Feld mit al-code-research + al-websearch |
| al-coder Body ergänzen | `.github/agents/al-coder.agent.md` | HELP-04 | "Helper-Aufruf (On-Demand)"-Abschnitt mit Bedingungen |

### Wave 3 — Roster und Dokumentation (parallel, unabhängig von Wave 2)

| Aufgabe | Zieldatei | Anforderungen | Inhalt |
|---------|-----------|--------------|--------|
| main-agent Frontmatter erweitern | `.github/agents/main-agent.agent.md` | HELP-03 | `agents:` um al-websearch + al-code-research ergänzen + optionaler Erklärungsblock |
| AGENTS.md aktualisieren | `AGENTS.md` | HELP-03 | Zeilen von "Geplante" nach "Aktuelle Agents" verschieben, Beschreibungen anpassen |

### Keine separaten Build/Deploy-Tasks

Die Agents sind Markdown-Dateien — keine Kompilierung, kein Deployment.
Verifizierung: Dateien lesen und gegen ERGEBNIS-Kontrakt + Aufruf-Protokoll prüfen.

---

## Assumptions-Log

| # | Annahme | Abschnitt | Risiko wenn falsch |
|---|---------|-----------|-------------------|
| A1 | `web_search` ist der korrekte Tool-Name in der Copilot-Agent-Runtime | 2.1, 2.3 | Anderer Tool-Name → al-websearch-Frontmatter muss angepasst werden |
| A2 | `vscode_listCodeUsages` ist der korrekte Tool-Name (aus Anforderungstext) | 3.1, 3.2 | VS-Code-Extension exponiert anderen Tool-Namen → al-code-research anpassen |
| A3 | 3-Ebenen Subagent-Chaining (main→architect→helper) ist unterstützt | 4, 6 | Fallback: main-agent delegiert Helpers direkt mit Ergebnis-Weitergabe an Spezialist |
| A4 | Skills im Body (statt Frontmatter) funktionieren auch in Leaf-Nodes die via Subagent aufgerufen werden | 3.1 | Skills nicht verfügbar → `search`+`read` als Primär-Tools verwenden |
| A5 | main-agent benötigt alle transitiv genutzten Agents in seinem `agents:` Frontmatter für Runtime-Discovery | 6.1 | Falls nein: main-agent-Update ist unnötig (kein Funktionsrisiko) |

---

## Offene Fragen

### 1. Subagent-Chaining-Tiefe
- **Was wir wissen:** main-agent ruft al-architect auf; al-architect ruft al-codebase-analyst
  auf (etabliertes 2-Ebenen-Muster). Phase 4 benötigt 3 Ebenen.
- **Unklar:** Ob die Copilot-Agent-Runtime 3-Ebenen-Chaining unterstützt.
- **Empfehlung:** Im Planner-Task als Verifikationsschritt dokumentieren. Fallback-Architektur
  vorbereiten (main-agent als Helper-Dispatcher mit Ergebnis-Weitergabe).

### 2. Skill-Verfügbarkeit in per-Subagent-aufgerufenen Leaf-Nodes
- **Was wir wissen:** al-codebase-analyst referenziert al-object-analysis Skill im Body
  ohne `skills:` Frontmatter.
- **Unklar:** Ob Skills im Body auch für Subagents aktiv sind, die nicht direkt vom Nutzer
  gestartet werden.
- **Empfehlung:** al-code-research so aufbauen dass es auch ohne Skills funktioniert
  (`search`+`read` als Primärfunktion, Skills als optionale Enhancement).

### 3. web_search Tool-Verfügbarkeit
- **Was wir wissen:** Anforderungs-Constraint sagt "`web_search` — available for WebSearch helper".
- **Unklar:** Ob `web_search` Standard-Copilot-Tool oder nur in bestimmten Extension-Konfigurationen.
- **Empfehlung:** Pre-Flight-Check in al-websearch; `read` als vollwertiger Fallback.

---

## Quellen

### Primary — HIGH Confidence (Codebase direkt verifiziert)
- `.github/agents/al-codebase-analyst.agent.md` — Kanonisches Leaf-Node-Muster (direkt gelesen)
- `.github/agents/al-architect.agent.md` — Caller-Muster: agents: Frontmatter, Subagent-Delegation (direkt gelesen)
- `.github/agents/main-agent.agent.md` — runSubagent-Syntax, Workflow-Tabelle, agents: Liste (direkt gelesen)
- `.github/agents/al-coder.agent.md` — Zweiter Caller, Tools-Pattern, kein agents: Frontmatter (direkt gelesen)
- `.github/policies/agent-policy.md` — Policy-Constraints für alle Agents (direkt gelesen)
- `.github/instructions/ergebnis-contract.instructions.md` — ERGEBNIS-Block-Standard (Helpers nutzen ihn NICHT — direkt verifiziert)
- `AGENTS.md` — Aktueller Roster und geplante Agents (direkt gelesen)
- `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md` — HELP-01..04 Anforderungen (direkt gelesen)

### Secondary — ASSUMED (Training Knowledge, nicht in dieser Session verifiziert)
- Tool-Name `web_search` — aus Anforderungstext übernommen [ASSUMED]
- Tool-Name `vscode_listCodeUsages` — aus Anforderungstext übernommen [ASSUMED]
- MS-Learn-URL-Struktur für BC-Entwickler-Docs [HIGH — stabile Microsoft-Docs-URLs]
- Copilot-Agent-Runtime: agents: Frontmatter-Semantik für Subagent-Discovery [ASSUMED]

---

## Metadaten

**Confidence-Aufschlüsselung:**
- Leaf-Node-Pattern-Analyse: HIGH — direkt aus al-codebase-analyst abgeleitet, Codebase verifiziert
- Aufruf-Protokoll / runSubagent-Syntax: HIGH — direkt aus main-agent.agent.md abgeleitet
- Output-Format / Return-Format: HIGH — am al-codebase-analyst-Muster orientiert
- Tool-Namen (`web_search`, `vscode_listCodeUsages`): ASSUMED — nur aus Anforderungstext
- MS-Learn-URLs: HIGH — stabile, bekannte Microsoft-Dokumentations-Pfade
- 3-Ebenen Subagent-Chaining-Unterstützung: LOW — unklar, muss verifiziert werden

**Research-Datum:** 2026-06-18
**Gültig bis:** 2026-08-18 (stabiles Markdown-Framework, keine npm-Dependencies, keine externen APIs)

---

*Research erstellt für Phase 4: Helper Agents — BC AL Agentic Development Kit*
