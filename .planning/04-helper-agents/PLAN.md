# Phase 4: Helper Agents — PLAN.md

**Erstellt:** 2026-06-18  
**Milestone:** v1 — Main-Agent Architecture  
**Sprache:** Deutsch (user-visible) / Englisch (Code, Pfade, YAML)

---

## Ziel

> Architect und Coder haben on-demand Zugriff auf Echtzeit-BC-Dokumentation via WebSearch und
> auf AL-Symbol-Lookups via Code-Research. Beide Helpers sind unsichtbar für den Entwickler —
> reine Infrastruktur für die Spezialisten.

---

## Anforderungen

| ID | Beschreibung | Ziel-Artefakt |
|----|-------------|---------------|
| HELP-01 | `al-websearch.agent.md` — MS Learn + Web durchsuchen | `.github/agents/al-websearch.agent.md` |
| HELP-02 | `al-code-research.agent.md` — AL-Symbole, Code-Usages | `.github/agents/al-code-research.agent.md` |
| HELP-03 | Leaf-Nodes — kommunizieren nie mit Entwickler | Kein `## ERGEBNIS`, kein Checkpoint |
| HELP-04 | Dokumentiertes Aufruf-Protokoll in Helper-Dateien | Abschnitt in jeder Helper-Datei + Caller-Updates |

---

## Ausführungs-Übersicht

```
Wave 1 (parallel):
  T1: al-websearch.agent.md erstellen         [HELP-01, HELP-03, HELP-04]
  T2: al-code-research.agent.md erstellen     [HELP-02, HELP-03, HELP-04]

Wave 2 (parallel, nach Wave 1):
  T3: al-architect.agent.md erweitern         [HELP-04]
  T4: al-coder.agent.md erweitern             [HELP-04]

Wave 3 (parallel, nach Wave 2):
  T5: main-agent.agent.md aktualisieren       [HELP-03]
  T6: AGENTS.md Roster aktualisieren          [HELP-03]

T7: Verifikations-Skript erstellen            [alle HELP-*]
```

**Dateien ohne Kompilierung oder Deployment** — alle Artefakte sind Markdown-Dateien.
Verifizierung erfolgt durch Lesen und Prüfen der Datei-Inhalte via `verify-phase-4.ps1`.

---

## Architektur-Grundlage: Kanonisches Leaf-Node-Muster

Das bestehende `al-codebase-analyst.agent.md` ist das verbindliche Muster. Neue Helpers folgen
exakt dieser Struktur:

| Eigenschaft | Spezialist (z. B. al-architect) | Leaf-Node (Helper) |
|-------------|--------------------------------|--------------------|
| Output-Header | `## ERGEBNIS — {Name}` | `## Output` (kein ERGEBNIS-Parsing) |
| Confidence | Pflicht | Nicht vorhanden |
| Checkpoint-Trigger | Ja | Nein |
| `agents:` Frontmatter | Ja (ruft Subagents auf) | Nein (ruft nichts auf) |
| `skills:` Frontmatter | Ja | Nein (Skills im Body referenziert) |
| Direkte User-Kommunikation | Ja | Ausdrücklich verboten |

---

## Wave 1 — Neue Helper-Agents erstellen (parallel ausführbar)

---

### T1: `al-websearch.agent.md` erstellen

**Anforderungen:** HELP-01, HELP-03, HELP-04  
**Datei:** `.github/agents/al-websearch.agent.md` (NEU erstellen)  
**Abhängigkeiten:** keine

#### Vollständiger Datei-Inhalt

Die Datei muss exakt folgenden Inhalt haben:

````markdown
---
name: al-websearch
model: claude-sonnet-4-5
description: >
  Hilfs-Agent (Leaf-Node) — durchsucht MS Learn und Web für AL-API-Dokumentation,
  BC-Beispiele und Features. Wird ausschließlich von al-architect und al-coder via
  runSubagent aufgerufen. Kommuniziert nie direkt mit dem Entwickler.
tools: ["web_search", "read"]
---

## Verbindliche Policy

Lies und befolge immer: `.github/policies/agent-policy.md`
Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.

## ABSOLUTES VERBOT

- Niemals direkt mit dem Entwickler kommunizieren
- Keine Rückfragen stellen — Unklarheiten im `## Output`-Block dokumentieren
- Keinen Checkpoint auslösen
- Keinen ERGEBNIS-Block produzieren
- Keine Dateien anlegen oder ändern

## Aufgabe

Durchsuche MS Learn und das Web nach AL-API-Dokumentation, BC-Funktions-Referenzen,
Codebeispielen und Best Practices für Business Central AL-Entwicklung.

Eingabe-Parameter vom aufrufenden Spezialisten:

- **Gesuchte Information:** API-Name, Feature-Name oder Objekt-Name
- **BC-Version:** runtime X.X aus `app.json` des Kundenprojekts (z. B. `runtime 14.0`)
- **Suchziel:** API-Signatur | Feature-Beschreibung | Codebeispiel | Best Practice
- **Kontext:** Warum die Information benötigt wird (1 Satz)

## Vorgehensweise

### Pre-Flight: web_search-Verfügbarkeit prüfen

Versuche `web_search` mit einer Minimal-Anfrage. Falls nicht verfügbar:
Wechsle sofort in den `read`-Fallback-Modus (direkte URL-Abrufe bekannter Dokumentations-URLs).
Kein Abbruch — `read`-Fallback wird immer durchgeführt.

### Suche-Reihenfolge (URL-Priorisierung)

| Prio | Domain | Inhalt |
|------|--------|--------|
| 1 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/` | AL-Entwickler-Referenz, Objekte, Methoden |
| 1 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/al-language/` | AL-Sprach-Referenz, Datentypen, Trigger |
| 2 | `learn.microsoft.com/en-us/dynamics365/business-central/` | Funktionale BC-Dokumentation |
| 2 | `github.com/microsoft/BCApps` | Offizielle BC-App-Sourcen (Base App, System App) |
| 3 | `github.com/microsoft/ALAppExtensions` | Erweiterungs-Muster, AL Extension-Beispiele |
| 3 | `learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/upgrade/` | BC-Version-spezifische Änderungen |

### Suchstrategie

- BC-Version aus Caller-Kontext in Suchanfrage einbauen (z. B. "Business Central 2024 Wave 2")
- Suchanfragen primär auf Englisch (MS Learn AL-Dokumentation ist primär EN)
- Maximal 3 Suchiterationen pro Aufruf — danach mit verfügbaren Ergebnissen arbeiten

## Aufruf-Protokoll

**Wer darf aufrufen:** `al-architect` und `al-coder` via `runSubagent("al-websearch", {...})`

**Wann aufrufen (al-architect):**
- BC-API/Feature im Ticket ist nicht in `.alpackages/`-Symbolen auffindbar
- BC-Version legt versions-spezifisches Verhalten nahe (runtime ≥ 13.0 + neues Feature)
- Ticket referenziert explizit MS-Learn-Dokumentation
- `al-object-analysis` Skill konnte beschriebenes BC-Standard-Verhalten nicht lokalisieren

**Wann aufrufen (al-coder):**
- `al_getdiagnostics` meldet Fehler bei unbekannter BC-API-Signatur (z. B. `procedure not found`)
- Ein Contract-Objekt hat kein Symbol-Äquivalent in `.alpackages/`

**NICHT als Default aufrufen** — nur bei konkreter Wissenslücke.

**Erwartetes Aufruf-Muster:**

```
runSubagent("al-websearch", {
  task: "Suche MS-Learn-Dokumentation für folgende BC-Funktion/Feature.

         Gesuchte Information: {API-Name | Feature-Name | Objekt-Name}
         BC-Version: runtime {X.X} aus app.json
         Suchziel: {API-Signatur | Feature-Beschreibung | Codebeispiel}
         Ticket-Kontext: {1 Satz was implementiert werden soll}
         Wissenslücke: {konkret was fehlt}"
})
```

## Output

Der Agent produziert den folgenden Markdown-Block direkt (ohne Wrapper-Code-Fence):

```markdown
## Suchergebnis — WebSearch

**Suchanfrage:** {originale Anfrage vom Caller}
**BC-Version-Kontext:** {z. B. "runtime 14.0 / BC 2024 Wave 1"}
**Suchdatum:** {Datum}

### Gefundene MS-Learn-Referenzen
| URL | Relevanz | Zusammenfassung |
|-----|----------|-----------------|
| {URL} | Hoch / Mittel / Niedrig | {1 Satz Kernaussage} |

### Relevante AL-Code-Beispiele
{Code-Snippet aus Dokumentation — nur wenn gefunden. Quelle-URL angeben.}

### API-Signatur (falls gefunden)
{ProcedureName}({Parameter: Typ; ...}): {Rückgabetyp}
Objekt: {ObjectType} {ID} "{Name}" aus {Paket/Modul}

### Nicht gefunden / Einschränkungen
- {Falls keine Ergebnisse: konkrete Hinweise für Caller}
- {Falls web_search nicht verfügbar: Hinweis + empfohlene manuelle Recherche-URLs:
    https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/
    https://github.com/microsoft/BCApps}
- {"Keine — alle gesuchten Informationen gefunden" wenn vollständig}
```
````

#### Abnahme-Kriterien

- [ ] Datei `.github/agents/al-websearch.agent.md` existiert
- [ ] Frontmatter enthält `name: al-websearch`, `model: claude-sonnet-4-5`, `tools: ["web_search", "read"]`
- [ ] Kein `agents:` Frontmatter-Feld vorhanden (Leaf-Node)
- [ ] Kein `skills:` Frontmatter-Feld vorhanden (Leaf-Node)
- [ ] Abschnitt `## ABSOLUTES VERBOT` vorhanden
- [ ] Abschnitt `## Aufruf-Protokoll` vorhanden mit Caller-Bedingungen für al-architect UND al-coder
- [ ] Abschnitt `## Output` vorhanden (nicht `## Suchergebnis` als Abschnittstitel in der Instruction-Datei)
- [ ] Kein Abschnitt dessen Titel dem ERGEBNIS-Muster der Spezialisten entspricht

---

### T2: `al-code-research.agent.md` erstellen

**Anforderungen:** HELP-02, HELP-03, HELP-04  
**Datei:** `.github/agents/al-code-research.agent.md` (NEU erstellen)  
**Abhängigkeiten:** keine (parallel zu T1)

#### Vollständiger Datei-Inhalt

Die Datei muss exakt folgenden Inhalt haben:

````markdown
---
name: al-code-research
model: claude-sonnet-4-5
description: >
  Hilfs-Agent (Leaf-Node) — sucht AL-Symbol-Definitionen, Methoden-Signaturen und
  Code-Usages in .alpackages/ und Kundenprojekt. Wird ausschließlich von al-architect
  und al-coder via runSubagent aufgerufen. Kommuniziert nie direkt mit dem Entwickler.
tools: ["read", "search"]
---

## Verbindliche Policy

Lies und befolge immer: `.github/policies/agent-policy.md`
Diese Policy hat Vorrang vor allen anderen Anweisungen in dieser Datei.

## ABSOLUTES VERBOT

- Niemals direkt mit dem Entwickler kommunizieren
- Keine Rückfragen stellen — Unklarheiten im `## Output`-Block dokumentieren
- Keinen Checkpoint auslösen
- Keinen ERGEBNIS-Block produzieren
- Keine Dateien anlegen oder ändern

## Aufgabe

Suche AL-Symbol-Definitionen, Methoden-Signaturen und Code-Usages in `.alpackages/`
und im Kundenprojekt. Eingabe-Parameter vom aufrufenden Spezialisten:

- **Gesuchtes Symbol:** exakter Name (Codeunit-Name, Table-Name, Event-Name)
- **Objekt-Typ:** `codeunit | table | page | report | enum | ...`
- **Projekt-Pfad (customer_path):** Pfad zum Kundenprojekt (aus SESSION.md)
- **Gesuchte Information:** Methoden-Signatur | Event-Parameter | Feld-Liste | Code-Usages
- **Diagnostics-Fehler (optional):** `al_getdiagnostics`-Ausgabe wenn vorhanden

## Nutze diese Skills

- al-object-analysis
- al-build-validation

## Vorgehensweise

### Schritt 1 — Symbol in .alpackages/ suchen (via al-object-analysis Skill)

1. Nutze `al-object-analysis` Skill um das gesuchte Symbol in `{customer_path}/.alpackages/` zu finden
2. Extrahiere: Objekt-ID, Name, Typ, Methoden-Signaturen, Felder, Schlüssel
3. Notiere Paket-Herkunft (welche `.app`-Datei enthält das Symbol)
4. Falls Symbol nicht gefunden: Hinweis auf fehlenden Symbol-Download im Output notieren

### Schritt 2 — Code-Usages ermitteln

**Primär: vscode_listCodeUsages (optional — nur wenn verfügbar)**

Versuche `vscode_listCodeUsages` für das gesuchte Symbol aus dem `al-build-validation` Skill.
`vscode_listCodeUsages` steht nur zur Verfügung wenn:
1. Der Agent im Kontext der GitHub Copilot VS-Code-Extension läuft
2. Das AL-Projekt im Editor geöffnet ist
3. Die AL Language Extension aktiv ist

Bei Nicht-Verfügbarkeit: Sofort in Fallback wechseln — kein Abbruch.

**Fallback: grep/search (immer als Backup)**

Durchsuche `{customer_path}/src/**/*.al` via `search`-Tool nach dem Symbol-Namen.
Extrahiere: Datei, Zeilennummer, Code-Kontext (1 Zeile Umgebung).
Im Output kennzeichnen: `(Fallback: grep/search — vscode_listCodeUsages nicht verfügbar)`

### Schritt 3 — Paket-Zuordnung

Bestimme ob Symbol aus Base App, System App, Partnermodul oder Kundenprojekt stammt.
Lese `{customer_path}/app.json` → `dependencies`-Feld für Paket-Namen-Abgleich.

## Aufruf-Protokoll

**Wer darf aufrufen:** `al-architect` und `al-coder` via `runSubagent("al-code-research", {...})`

**Wann aufrufen (al-architect):**
- Plan erfordert Aufruf einer BC-Codeunit mit unbekannter Methoden-Signatur
  (z. B. Codeunit 80 "Sales-Post" — Schnittstelle muss vor Planung geklärt werden)
- Ticket erfordert Subscribe auf Publisher-Event, dessen Parameter nicht aus Symbolen lesbar sind
- Unsicherheit ob eine TableExtension oder PageExtension bereits im Kundenprojekt existiert

**Wann aufrufen (al-coder):**
- VOR dem Schreiben einer Prozedur die eine BC-Codeunit aufruft — zur Signatur-Verifikation
- `al_getdiagnostics` meldet `procedure ... not found` oder `type ... is not defined`
- `al_getdiagnostics` meldet falsche Parameter-Anzahl oder falschen Typ

**NICHT als Default aufrufen** — nur wenn Symbol-Download allein nicht ausreicht.
Wenn `al_downloadsymbols` (Schritt 1 im Caller) bereits die benötigte Signatur lieferte,
keinen weiteren Helper-Aufruf durchführen.

**Erwartetes Aufruf-Muster:**

```
runSubagent("al-code-research", {
  task: "Suche AL-Symbol-Informationen.

         Gesuchtes Symbol: {exakter Name}
         Objekt-Typ: {codeunit | table | ...}
         Projekt-Pfad (customer_path): {Pfad aus SESSION.md}
         Gesuchte Information: {Methodensignatur | Event-Parameter | Felder}
         Diagnostics-Fehler (falls vorhanden): {al_getdiagnostics Ausgabe}"
})
```

## Output

Der Agent produziert den folgenden Markdown-Block direkt (ohne Wrapper-Code-Fence):

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

### Code-Usages
| Datei | Zeile | Verwendungskontext |
|-------|-------|--------------------|
| {relativer Pfad} | {Zeilennr.} | {Code-Zeile als Kontext} |

*(Quelle: vscode_listCodeUsages | Fallback: grep/search — vscode_listCodeUsages nicht verfügbar)*

### Bestehende Patterns im Kundenprojekt
- {Pattern oder "Keine"}

### Nicht gefunden / Einschränkungen
- {Symbol nicht in .alpackages/ → Hinweis: al_downloadsymbols erforderlich}
- {vscode_listCodeUsages nicht verfügbar → Fallback auf grep-Ergebnisse}
- {"Keine" wenn alles gefunden}
```
````

#### Abnahme-Kriterien

- [ ] Datei `.github/agents/al-code-research.agent.md` existiert
- [ ] Frontmatter enthält `name: al-code-research`, `model: claude-sonnet-4-5`, `tools: ["read", "search"]`
- [ ] Kein `agents:` Frontmatter-Feld vorhanden (Leaf-Node)
- [ ] Kein `skills:` Frontmatter-Feld vorhanden — Skills stehen im Body unter `## Nutze diese Skills`
- [ ] Abschnitt `## ABSOLUTES VERBOT` vorhanden
- [ ] `vscode_listCodeUsages` ist im Body als **optional** dokumentiert mit explizitem Fallback auf `grep/search`
- [ ] Abschnitt `## Aufruf-Protokoll` vorhanden mit Caller-Bedingungen für al-architect UND al-coder
- [ ] Abschnitt `## Output` vorhanden (als Instruction-Section — nicht als direkter Output-Block)
- [ ] Kein Abschnitt dessen Titel dem ERGEBNIS-Muster der Spezialisten entspricht

---

## T1.5: Manuelle Verifikation — 3-Ebenen Subagent-Chaining (A3)

**Anforderungen:** A3 (Annahme — LOW confidence)
**Abhängigkeiten:** T1, T2 (vor Wave 2 ausführen)
**Art:** Manuelle Verifikation, kein automatisierter Task

**Warum:** Das Framework nutzt erstmals 3-Ebenen-Chaining (main-agent → al-architect → al-websearch/al-code-research).
Ob die Copilot-Agent-Runtime dies unterstützt ist ASSUMED (Annahme A3, Confidence: LOW).
Wenn die 3. Ebene nicht unterstützt wird, müssen T3 und T4 auf Fallback-Architektur umgestellt werden.

**Durchführung:**
1. Starte main-agent mit einem Test-Ticket
2. Lass al-architect `runSubagent("al-websearch", {...})` aufrufen
3. Prüfe: Wird al-websearch korrekt aufgerufen? Kommt ein Ergebnis zurück?

**Entscheidungsbaum:**
- ✅ **PASS:** 3-Ebenen funktionieren → Wave 2 (T3, T4) wie geplant starten
- ❌ **FAIL:** 3-Ebenen nicht unterstützt → Fallback aktivieren:
  Caller-Updates (T3, T4) so anpassen dass Helper-Aufruf-Protokoll auf main-agent-as-dispatcher zeigt:
  main-agent ruft Helper direkt auf und gibt Ergebnis an Spezialist weiter (als zusätzliches CP-1.5)

**Abnahme-Kriterium:** Entscheidung (PASS/FAIL) dokumentiert bevor T3/T4 gestartet werden.

---

## Wave 2 — Caller-Agents aktualisieren (parallel, nach Wave 1 + T1.5)

*Voraussetzung: T1 und T2 abgeschlossen; A3-Entscheidung aus T1.5 getroffen*

---

### T3: `al-architect.agent.md` erweitern

**Anforderungen:** HELP-04  
**Datei:** `.github/agents/al-architect.agent.md` (BEARBEITEN)  
**Abhängigkeiten:** T1, T2 (Helper-Dateien müssen existieren)

#### Änderung 1: Frontmatter — `agents:` erweitern

**Aktuelle `agents:`-Liste im Frontmatter (Zeilen 8–9):**
```yaml
agents:
  - al-codebase-analyst
```

**Nach der Änderung:**
```yaml
agents:
  - al-codebase-analyst
  - al-websearch        # Phase 4 — On-demand MS-Learn-Suche bei Wissenslücken
  - al-code-research    # Phase 4 — On-demand Symbol-Lookup vor Planschritten
```

**Edit-Anweisung:** Ersetze den bestehenden `agents:`-Block durch die erweiterte Version.
Das `skills:`-Feld darunter bleibt unverändert.

#### Änderung 2: Body — Neuen Abschnitt nach Schritt 1 einfügen

**Einfügeposition:** Nach dem Ende von `### Schritt 1 — Symbol-Download` und VOR
`### Schritt 2 — Bestehende Objekte und ID-Vergabe`.

**Einzufügender Text:**

```markdown
### Helper-Aufruf (On-Demand — NICHT als Default)

Rufe Helper-Agents via `runSubagent` auf wenn eine konkrete Wissenslücke identifiziert ist.
Kein Helper wird als Standard-Schritt vor jeder Planung aufgerufen.

**`al-websearch` aufrufen wenn:**
- BC-API/Feature im Ticket ist nicht in `.alpackages/`-Symbolen auffindbar
- BC-Version legt versions-spezifisches Verhalten nahe (runtime ≥ 13.0 + neues Feature)
- Ticket referenziert explizit MS-Learn-Dokumentation
- `al-object-analysis` Skill konnte beschriebenes BC-Standard-Verhalten nicht lokalisieren

**`al-code-research` aufrufen wenn:**
- Methoden-Signatur einer BC-Codeunit für einen Plan-Schritt benötigt wird
- Event-Publisher-Parameter nicht aus den Symbolen lesbar sind
- Unsicherheit besteht ob ein Objekt bereits im Kundenprojekt existiert

Helper-Output wird intern für Planungsentscheidungen genutzt — nie in ERGEBNIS-Block weitergegeben.

```

**Hinweis:** Die Leerzeile vor `### Schritt 2` bleibt erhalten.

#### Abnahme-Kriterien

- [ ] `al-architect.agent.md` Frontmatter enthält `- al-websearch` unter `agents:`
- [ ] `al-architect.agent.md` Frontmatter enthält `- al-code-research` unter `agents:`
- [ ] `- al-codebase-analyst` ist weiterhin in der `agents:`-Liste vorhanden
- [ ] `skills:`-Block (al-object-analysis, al-devops-workitem, al-build-validation) ist unverändert
- [ ] Neuer Abschnitt `### Helper-Aufruf (On-Demand — NICHT als Default)` ist im Body vorhanden
- [ ] Abschnitt steht zwischen Schritt 1 und Schritt 2
- [ ] Abschnitt enthält Bedingungen für `al-websearch` UND `al-code-research`

---

### T4: `al-coder.agent.md` erweitern

**Anforderungen:** HELP-04  
**Datei:** `.github/agents/al-coder.agent.md` (BEARBEITEN)  
**Abhängigkeiten:** T1, T2 (parallel zu T3)

#### Änderung 1: Frontmatter — Neues `agents:`-Feld hinzufügen

**Aktueller Frontmatter (hat KEIN `agents:`-Feld):**
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

**Nach der Änderung — `agents:`-Feld zwischen `tools:` und `skills:` einfügen:**
```yaml
---
name: al-coder
model: claude-sonnet-4-5
description: >
  Implementiert AL-Code auf Basis eines JSON Plan Contracts. Konsolidiert al-implementer
  und al-build-tester. Schreibt Code, verwaltet Objekt-IDs, führt Build durch,
  erstellt Übersetzungseinträge. Ersetzt al-implementer und al-build-tester ab Phase 2.
tools: ["read", "search", "edit", "terminal"]
agents:
  - al-code-research    # Phase 4 — Signatur-Verifikation vor Code-Schreiben
  - al-websearch        # Phase 4 — API-Doku wenn Diagnostics unbekannte API meldet
skills:
  - al-object-analysis
  - al-build-validation
---
```

**Edit-Anweisung:** Ersetze die Zeile `skills:` (und die darauffolgende skills-Liste am Ende
des Frontmatters) durch die erweiterte Version mit dem neuen `agents:`-Block davor.
Konkret: Füge zwischen `tools: ["read", "search", "edit", "terminal"]` und `skills:` folgende
Zeilen ein:
```
agents:
  - al-code-research    # Phase 4 — Signatur-Verifikation vor Code-Schreiben
  - al-websearch        # Phase 4 — API-Doku wenn Diagnostics unbekannte API meldet
```

#### Änderung 2: Body — Neuen Abschnitt zwischen Schritt 1 und Schritt 2 einfügen

**Einfügeposition:** Nach dem Ende von `### Schritt 1 — Symbol-Download (PFLICHT vor Code-Schreiben)`
und VOR `### Schritt 2 — Objekt-ID-Verifikation`.

**Einzufügender Text:**

```markdown
### Helper-Aufruf (On-Demand — NICHT als Default)

Rufe Helper-Agents auf bei konkreter Wissenslücke — nie als Standard-Schritt.

**`al-code-research` aufrufen VOR dem Code-Schreiben wenn:**
- Eine Prozedur eine BC-Codeunit aufruft und die Signatur nicht aus Schritt 1 bekannt ist
- `al_getdiagnostics` meldet `procedure ... not found` oder Typ-Fehler
- `al_getdiagnostics` meldet falsche Parameter-Anzahl

**`al-websearch` aufrufen wenn:**
- `al_getdiagnostics` meldet BC-API-Fehler der nicht aus Symbolen erklärbar ist
- Ein Contract-Objekt hat kein Symbol-Äquivalent in `.alpackages/`

Helper-Output wird intern für Code-Korrektur genutzt — nie in ERGEBNIS-Block weitergegeben.

```

**Hinweis:** Die Leerzeile vor `### Schritt 2` bleibt erhalten.

#### Abnahme-Kriterien

- [ ] `al-coder.agent.md` Frontmatter enthält neu `agents:` Feld
- [ ] `agents:` enthält `- al-code-research`
- [ ] `agents:` enthält `- al-websearch`
- [ ] `tools:` und `skills:` sind unverändert
- [ ] Neuer Abschnitt `### Helper-Aufruf (On-Demand — NICHT als Default)` ist im Body vorhanden
- [ ] Abschnitt steht zwischen Schritt 1 und Schritt 2

---

## Wave 3 — Roster und Dokumentation (parallel, nach Wave 2)

*Voraussetzung: T3 und T4 abgeschlossen*

---

### T5: `main-agent.agent.md` Frontmatter + Infrastruktur-Hinweis

**Anforderungen:** HELP-03  
**Datei:** `.github/agents/main-agent.agent.md` (BEARBEITEN)  
**Abhängigkeiten:** T3, T4

#### Änderung 1: Frontmatter — `agents:`-Liste um beide Helpers erweitern

**Aktueller `agents:`-Block (Zeilen 22–30 des Frontmatters):**
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

**Nach der Änderung:**
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

**Edit-Anweisung:** Füge die zwei neuen Zeilen am Ende des `agents:`-Blocks an, vor dem
schließenden `---` des Frontmatters.

#### Änderung 2: Body — Infrastruktur-Hinweis nach der Workflow-Tabelle einfügen

**Einfügeposition:** Direkt nach dem abschließenden Kursiv-Text nach der Workflow-Tabelle:

```
*Nach al-architect (CP-2): Entwickler sieht JSON Plan Contract + Aufwandsschätzung.
Bei Confidence < 0.60 im Contract: CP-5 vor al-coder-Delegation.*
```

**Einzufügender Text — kommt direkt nach diesem Absatz:**

```markdown

### Helper-Agents (Infrastruktur — nicht im Workflow sichtbar)

`al-websearch` und `al-code-research` sind reine Infrastruktur-Helpers. Sie werden
von `al-architect` und `al-coder` on-demand via `runSubagent` aufgerufen — **nicht** vom
Main-Agent. Main-Agent verarbeitet ihren Output NICHT direkt. Kein Checkpoint wird durch
Helper-Output ausgelöst. Helper erscheinen weder als Workflow-Schritt noch als optionaler
Schritt in der obigen Tabelle.

```

#### Abnahme-Kriterien

- [ ] `main-agent.agent.md` Frontmatter enthält `- al-websearch` in der `agents:`-Liste
- [ ] `main-agent.agent.md` Frontmatter enthält `- al-code-research` in der `agents:`-Liste
- [ ] Alle 8 bestehenden Einträge in `agents:` sind unverändert erhalten
- [ ] Abschnitt `### Helper-Agents (Infrastruktur — nicht im Workflow sichtbar)` ist im Body vorhanden
- [ ] Die Workflow-Schritt-Tabelle ist unverändert (kein Helper als Schritt eingetragen)

---

### T6: `AGENTS.md` Roster aktualisieren

**Anforderungen:** HELP-03  
**Datei:** `AGENTS.md` (BEARBEITEN, im Repository-Root)  
**Abhängigkeiten:** T3, T4 (parallel zu T5)

#### Änderung 1: Rows aus "Geplante Agents"-Tabelle entfernen

Aus der Tabelle `### Geplante Agents (noch nicht implementiert)` folgende zwei Zeilen entfernen:

```
| `al-websearch.agent.md` | MS Learn / Web-Suche — Hilfsagent für Spezialisten | Phase 4 |
| `al-code-research.agent.md` | AL-Symbole, Code-Usages — Hilfsagent für Architect/Coder | Phase 4 |
```

Nach dem Entfernen verbleiben nur noch die Phase-3-Rows in der "Geplante"-Tabelle:
```
| `al-docs-coordinator.agent.md` | Kunden-Doku-Routing nach Projektpfad | Phase 3 |
| `al-docs-betzold/hermes/troeber.agent.md` | Kunden-spezifische Doku-Agents | Phase 3 |
```

#### Änderung 2: Rows in "Aktuelle Agents"-Tabelle hinzufügen

Am Ende der Tabelle `### Aktuelle Agents (vorhanden)` — nach der Zeile für `al-tester.agent.md`
— folgende zwei Zeilen hinzufügen:

```
| `.github/agents/al-websearch.agent.md` | MS Learn / Web-Suche — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv (Phase 4) |
| `.github/agents/al-code-research.agent.md` | AL-Symbole, Code-Usages — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv (Phase 4) |
```

#### Abnahme-Kriterien

- [ ] `AGENTS.md` enthält `al-websearch` in der "Aktuelle Agents"-Tabelle mit Status `Aktiv (Phase 4)`
- [ ] `AGENTS.md` enthält `al-code-research` in der "Aktuelle Agents"-Tabelle mit Status `Aktiv (Phase 4)`
- [ ] In der "Geplante Agents"-Tabelle sind `al-websearch` und `al-code-research` nicht mehr vorhanden
- [ ] Die Phase-3-Rows in "Geplante Agents" sind unverändert erhalten

---

## T7: Verifikations-Skript erstellen

**Anforderungen:** alle HELP-01..04  
**Datei:** `.planning/04-helper-agents/verify-phase-4.ps1` (NEU erstellen)  
**Abhängigkeiten:** alle vorigen Tasks (Skript prüft Ergebnis aller Tasks)

#### Vollständiger Skript-Inhalt

```powershell
<#
.SYNOPSIS
    Phase 4 Verifikations-Skript — prüft alle HELP-01..04 Anforderungen.
.DESCRIPTION
    Überprüft ob alle Phase-4-Artefakte korrekt erstellt und aktualisiert wurden:
    - HELP-01: al-websearch.agent.md (Frontmatter, Verbote, Aufruf-Protokoll, Output-Header)
    - HELP-02: al-code-research.agent.md (Frontmatter, Verbote, Aufruf-Protokoll, Fallback)
    - HELP-03: Leaf-Node-Verifikation (kein ERGEBNIS-Block in Helpers)
    - HELP-04: Caller-Updates (al-architect, al-coder, main-agent, AGENTS.md)
.EXAMPLE
    cd C:\Users\dloewe\BC-AL-Agentic-Development-Kit
    .\.planning\04-helper-agents\verify-phase-4.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Repo-Root: zwei Ebenen über dem Skript-Verzeichnis
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$AgentsDir = Join-Path $RepoRoot ".github\agents"

$PassedChecks = [System.Collections.Generic.List[string]]::new()
$FailedChecks = [System.Collections.Generic.List[string]]::new()

function Assert-Check {
    param(
        [string]$RequirementId,
        [string]$Description,
        [bool]$Result
    )
    $label = "[$RequirementId] $Description"
    if ($Result) {
        $PassedChecks.Add($label)
        Write-Host "  PASS  $label" -ForegroundColor Green
    } else {
        $FailedChecks.Add($label)
        Write-Host "  FAIL  $label" -ForegroundColor Red
    }
}

function Get-AgentContent {
    param([string]$FileName)
    $path = Join-Path $AgentsDir $FileName
    if (Test-Path $path) {
        return (Get-Content $path -Raw -Encoding UTF8)
    }
    return $null
}

Write-Host "`nPhase 4: Helper Agents — Verifikation" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# ──────────────────────────────────────────────────────────────
# HELP-01: al-websearch.agent.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-01] al-websearch.agent.md" -ForegroundColor Yellow

$wsPath = Join-Path $AgentsDir "al-websearch.agent.md"
$wsExists = Test-Path $wsPath
Assert-Check "HELP-01" "al-websearch.agent.md existiert" $wsExists

if ($wsExists) {
    $ws = Get-Content $wsPath -Raw -Encoding UTF8

    Assert-Check "HELP-01" "model: claude-sonnet-4-5" ($ws -match 'model:\s*claude-sonnet-4-5')
    Assert-Check "HELP-01" "tools enthaelt web_search" ($ws -match 'web_search')
    Assert-Check "HELP-01" 'tools enthaelt "read"' ($ws -match '"read"')
    Assert-Check "HELP-01" "Abschnitt ABSOLUTES VERBOT vorhanden" ($ws -match '##\s*ABSOLUTES VERBOT')
    Assert-Check "HELP-01" "Abschnitt Aufruf-Protokoll vorhanden" ($ws -match '##\s*Aufruf-Protokoll')
    Assert-Check "HELP-01" "## Output Header vorhanden" ($ws -match '(?m)^##\s+Output\s*$')
    Assert-Check "HELP-01" "Pre-Flight web_search-Verfuegbarkeit dokumentiert" ($ws -match 'Pre-Flight')
    Assert-Check "HELP-01" "URL-Prioritaetsliste mit learn.microsoft.com" (
        $ws -match 'learn\.microsoft\.com.*dynamics365.*business-central'
    )
    Assert-Check "HELP-01" "Aufruf-Protokoll nennt al-architect als zugelassenen Caller" (
        $ws -match 'al-architect'
    )
    Assert-Check "HELP-01" "Aufruf-Protokoll nennt al-coder als zugelassenen Caller" (
        $ws -match 'al-coder'
    )
} else {
    # Folge-Checks als FAIL markieren wenn Datei fehlt
    @(
        "model: claude-sonnet-4-5",
        "tools enthaelt web_search",
        'tools enthaelt "read"',
        "Abschnitt ABSOLUTES VERBOT vorhanden",
        "Abschnitt Aufruf-Protokoll vorhanden",
        "## Output Header vorhanden",
        "Pre-Flight web_search-Verfuegbarkeit dokumentiert",
        "URL-Prioritaetsliste mit learn.microsoft.com",
        "Aufruf-Protokoll nennt al-architect als zugelassenen Caller",
        "Aufruf-Protokoll nennt al-coder als zugelassenen Caller"
    ) | ForEach-Object { Assert-Check "HELP-01" $_ $false }
}

# ──────────────────────────────────────────────────────────────
# HELP-02: al-code-research.agent.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-02] al-code-research.agent.md" -ForegroundColor Yellow

$crPath = Join-Path $AgentsDir "al-code-research.agent.md"
$crExists = Test-Path $crPath
Assert-Check "HELP-02" "al-code-research.agent.md existiert" $crExists

if ($crExists) {
    $cr = Get-Content $crPath -Raw -Encoding UTF8

    Assert-Check "HELP-02" "model: claude-sonnet-4-5" ($cr -match 'model:\s*claude-sonnet-4-5')
    Assert-Check "HELP-02" 'tools enthaelt "read"' ($cr -match '"read"')
    Assert-Check "HELP-02" 'tools enthaelt "search"' ($cr -match '"search"')
    Assert-Check "HELP-02" "Abschnitt ABSOLUTES VERBOT vorhanden" ($cr -match '##\s*ABSOLUTES VERBOT')
    Assert-Check "HELP-02" "Abschnitt Aufruf-Protokoll vorhanden" ($cr -match '##\s*Aufruf-Protokoll')
    Assert-Check "HELP-02" "## Output Header vorhanden" ($cr -match '(?m)^##\s+Output\s*$')
    Assert-Check "HELP-02" "vscode_listCodeUsages erwaehnt" ($cr -match 'vscode_listCodeUsages')
    Assert-Check "HELP-02" "vscode_listCodeUsages als optional dokumentiert" (
        $cr -match 'vscode_listCodeUsages' -and ($cr -match 'optional' -or $cr -match '[Ff]allback')
    )
    Assert-Check "HELP-02" "grep/search Fallback dokumentiert" ($cr -match 'grep')
    Assert-Check "HELP-02" "Nutze diese Skills (al-object-analysis) vorhanden" (
        $cr -match 'al-object-analysis'
    )
    Assert-Check "HELP-02" "Aufruf-Protokoll nennt al-architect als zugelassenen Caller" (
        $cr -match 'al-architect'
    )
    Assert-Check "HELP-02" "Aufruf-Protokoll nennt al-coder als zugelassenen Caller" (
        $cr -match 'al-coder'
    )
} else {
    @(
        "model: claude-sonnet-4-5",
        'tools enthaelt "read"',
        'tools enthaelt "search"',
        "Abschnitt ABSOLUTES VERBOT vorhanden",
        "Abschnitt Aufruf-Protokoll vorhanden",
        "## Output Header vorhanden",
        "vscode_listCodeUsages erwaehnt",
        "vscode_listCodeUsages als optional dokumentiert",
        "grep/search Fallback dokumentiert",
        "Nutze diese Skills (al-object-analysis) vorhanden",
        "Aufruf-Protokoll nennt al-architect als zugelassenen Caller",
        "Aufruf-Protokoll nennt al-coder als zugelassenen Caller"
    ) | ForEach-Object { Assert-Check "HELP-02" $_ $false }
}

# ──────────────────────────────────────────────────────────────
# HELP-03: Leaf-Node Verifikation (kein ERGEBNIS in Helpers)
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-03] Leaf-Node Verifikation" -ForegroundColor Yellow

# Pruefe al-websearch: kein ERGEBNIS-Abschnittstitel
if ($wsExists) {
    $ws = Get-Content $wsPath -Raw -Encoding UTF8
    $wsHasErgebnis = $ws -match '(?m)^##\s+ERGEBNIS'
    Assert-Check "HELP-03" "al-websearch hat keinen ## ERGEBNIS Abschnittstitel" (-not $wsHasErgebnis)
} else {
    Assert-Check "HELP-03" "al-websearch hat keinen ## ERGEBNIS Abschnittstitel" $false
}

# Pruefe al-code-research: kein ERGEBNIS-Abschnittstitel
if ($crExists) {
    $cr = Get-Content $crPath -Raw -Encoding UTF8
    $crHasErgebnis = $cr -match '(?m)^##\s+ERGEBNIS'
    Assert-Check "HELP-03" "al-code-research hat keinen ## ERGEBNIS Abschnittstitel" (-not $crHasErgebnis)
} else {
    Assert-Check "HELP-03" "al-code-research hat keinen ## ERGEBNIS Abschnittstitel" $false
}

# Pruefe dass Helpers kein agents:-Frontmatter haben
if ($wsExists) {
    $ws = Get-Content $wsPath -Raw -Encoding UTF8
    # Nur Frontmatter-Bereich pruefen (zwischen erstem und zweitem ---)
    $frontmatterMatch = [regex]::Match($ws, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-03" "al-websearch hat kein agents: im Frontmatter (Leaf-Node)" (-not ($fm -match '^agents:'))
        Assert-Check "HELP-03" "al-websearch hat kein skills: im Frontmatter (Leaf-Node)" (-not ($fm -match '^skills:'))
    } else {
        Assert-Check "HELP-03" "al-websearch hat kein agents: im Frontmatter (Leaf-Node)" $false
    }
}

if ($crExists) {
    $cr = Get-Content $crPath -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($cr, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-03" "al-code-research hat kein agents: im Frontmatter (Leaf-Node)" (-not ($fm -match '^agents:'))
        Assert-Check "HELP-03" "al-code-research hat kein skills: im Frontmatter (Leaf-Node)" (-not ($fm -match '^skills:'))
    } else {
        Assert-Check "HELP-03" "al-code-research hat kein agents: im Frontmatter (Leaf-Node)" $false
    }
}

# ──────────────────────────────────────────────────────────────
# HELP-04: Aufruf-Protokoll in Caller-Agents
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-04] Caller-Agent Updates" -ForegroundColor Yellow

# al-architect
$archPath = Join-Path $AgentsDir "al-architect.agent.md"
if (Test-Path $archPath) {
    $arch = Get-Content $archPath -Raw -Encoding UTF8
    Assert-Check "HELP-04" "al-architect agents: enthaelt al-websearch" ($arch -match 'agents:[\s\S]*?al-websearch')
    Assert-Check "HELP-04" "al-architect agents: enthaelt al-code-research" ($arch -match 'agents:[\s\S]*?al-code-research')
    Assert-Check "HELP-04" "al-architect agents: enthaelt noch al-codebase-analyst" ($arch -match 'al-codebase-analyst')
    Assert-Check "HELP-04" "al-architect Body enthaelt Helper-Aufruf Sektion" ($arch -match 'Helper-Aufruf')
    Assert-Check "HELP-04" "al-architect Helper-Aufruf Sektion ist On-Demand (nicht Default)" (
        $arch -match 'NICHT als Default' -or $arch -match 'nicht.*Default'
    )
} else {
    Write-Host "  WARN  al-architect.agent.md nicht gefunden — ueberspringen" -ForegroundColor DarkYellow
}

# al-coder
$coderPath = Join-Path $AgentsDir "al-coder.agent.md"
if (Test-Path $coderPath) {
    $coder = Get-Content $coderPath -Raw -Encoding UTF8

    # Pruefe ob agents: im Frontmatter-Bereich steht
    $frontmatterMatch = [regex]::Match($coder, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-04" "al-coder hat agents: Frontmatter-Feld (neu)" ($fm -match '^agents:')
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-code-research" ($fm -match 'al-code-research')
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-websearch" ($fm -match 'al-websearch')
    } else {
        Assert-Check "HELP-04" "al-coder hat agents: Frontmatter-Feld (neu)" $false
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-code-research" $false
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-websearch" $false
    }
    Assert-Check "HELP-04" "al-coder Body enthaelt Helper-Aufruf Sektion" ($coder -match 'Helper-Aufruf')
    Assert-Check "HELP-04" "al-coder Helper-Aufruf Sektion ist On-Demand (nicht Default)" (
        $coder -match 'NICHT als Default' -or $coder -match 'nicht.*Default'
    )
} else {
    Write-Host "  WARN  al-coder.agent.md nicht gefunden — ueberspringen" -ForegroundColor DarkYellow
}

# ──────────────────────────────────────────────────────────────
# Roster: main-agent.agent.md + AGENTS.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[Roster] main-agent.agent.md + AGENTS.md" -ForegroundColor Yellow

$mainPath = Join-Path $AgentsDir "main-agent.agent.md"
if (Test-Path $mainPath) {
    $main = Get-Content $mainPath -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($main, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "Roster" "main-agent agents: enthaelt al-websearch" ($fm -match 'al-websearch')
        Assert-Check "Roster" "main-agent agents: enthaelt al-code-research" ($fm -match 'al-code-research')
    } else {
        Assert-Check "Roster" "main-agent agents: enthaelt al-websearch" $false
        Assert-Check "Roster" "main-agent agents: enthaelt al-code-research" $false
    }
    Assert-Check "Roster" "main-agent Body enthaelt Helper-Agents Infrastruktur-Hinweis" (
        $main -match 'Helper-Agents'
    )
} else {
    Write-Host "  WARN  main-agent.agent.md nicht gefunden" -ForegroundColor DarkYellow
}

$agentsMdPath = Join-Path $RepoRoot "AGENTS.md"
if (Test-Path $agentsMdPath) {
    $agentsMd = Get-Content $agentsMdPath -Raw -Encoding UTF8

    # al-websearch muss in "Aktuelle Agents" Tabelle stehen (mit "Aktiv")
    Assert-Check "Roster" "AGENTS.md: al-websearch in Aktuelle Agents Tabelle" (
        $agentsMd -match 'al-websearch.*Aktiv'
    )
    # al-code-research muss in "Aktuelle Agents" Tabelle stehen
    Assert-Check "Roster" "AGENTS.md: al-code-research in Aktuelle Agents Tabelle" (
        $agentsMd -match 'al-code-research.*Aktiv'
    )
    # Weder sollte mehr in "Geplante Agents" stehen
    # Pruefe indem wir suchen ob "Geplante"-Tabelle noch Phase-4-Entries hat
    $geplantBlock = [regex]::Match($agentsMd, '(?s)### Geplante Agents.*?(?=###|\z)')
    if ($geplantBlock.Success) {
        $geplant = $geplantBlock.Value
        Assert-Check "Roster" "AGENTS.md: al-websearch nicht mehr in Geplante Agents" (
            -not ($geplant -match 'al-websearch\.agent\.md.*Phase 4')
        )
        Assert-Check "Roster" "AGENTS.md: al-code-research nicht mehr in Geplante Agents" (
            -not ($geplant -match 'al-code-research\.agent\.md.*Phase 4')
        )
    }
} else {
    Write-Host "  WARN  AGENTS.md nicht gefunden" -ForegroundColor DarkYellow
}

# ──────────────────────────────────────────────────────────────
# Zusammenfassung
# ──────────────────────────────────────────────────────────────
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Ergebnis Phase 4 Verifikation" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "  Bestanden: $($PassedChecks.Count)" -ForegroundColor Green
Write-Host "  Fehler:    $($FailedChecks.Count)" -ForegroundColor $(if ($FailedChecks.Count -eq 0) { "Green" } else { "Red" })

if ($FailedChecks.Count -gt 0) {
    Write-Host "`nFehlgeschlagene Pruefungen:" -ForegroundColor Red
    $FailedChecks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host "`nAlle Phase-4-Anforderungen erfuellt. Phase 4 ist abgeschlossen." -ForegroundColor Green
    exit 0
}
```

#### Abnahme-Kriterien

- [ ] Datei `.planning/04-helper-agents/verify-phase-4.ps1` existiert
- [ ] Skript kann mit `powershell -File .\verify-phase-4.ps1` aus dem Repo-Root ausgeführt werden
- [ ] Nach Abschluss aller T1–T6: Skript gibt Exit-Code 0 zurück mit "Alle Phase-4-Anforderungen erfüllt"
- [ ] Bei fehlenden Artefakten: Skript gibt Exit-Code 1 zurück mit Liste der fehlgeschlagenen Prüfungen

---

## Annahmen-Log (A1–A5)

| # | Annahme | Auswirkung wenn falsch |
|---|---------|----------------------|
| A1 | `web_search` ist der korrekte Tool-Name in der Copilot-Agent-Runtime | `al-websearch.agent.md` Frontmatter muss angepasst werden (anderer Tool-Name) |
| A2 | `vscode_listCodeUsages` ist der korrekte Tool-Name (aus Anforderungstext) | `al-code-research.agent.md` Body muss angepasst werden |
| A3 | 3-Ebenen Subagent-Chaining (main → architect → helper) wird von der Runtime unterstützt | Fallback-Architektur: main-agent delegiert Helpers direkt und gibt Ergebnis an Spezialist weiter — Architektur-Anpassung in al-architect/al-coder Body erforderlich |
| A4 | Skills im Body (ohne `skills:` im Frontmatter) sind in per-`runSubagent` aufgerufenen Leaf-Nodes aktiv | Skills nicht verfügbar → `search`+`read` als Primär-Tools verwenden; `al-code-research` ist so gebaut dass es auch ohne Skills funktioniert |
| A5 | `main-agent.agent.md` benötigt alle transitiv genutzten Agents im `agents:` Frontmatter für Runtime-Discovery | Falls nein: main-agent-Update (T5) ist unnötig aber nicht schädlich |

**Priorisierte Verifikation nach Implementierung:**
Wenn Wave 1 abgeschlossen ist, einen manuellen Test der 3-Ebenen-Chaining-Tiefe durchführen
(Annahme A3 — LOW confidence laut Research). Falls nicht unterstützt, Fallback-Plan aktivieren
bevor T3/T4 abgeschlossen werden.

---

## Abnahme-Kriterien (Phase 4 gesamt)

Die Phase 4 gilt als abgeschlossen wenn alle folgenden Punkte erfüllt sind:

1. **HELP-01 ✓** `al-websearch.agent.md` existiert mit korrektem Frontmatter (`model: claude-sonnet-4-5`,
   `tools: ["web_search", "read"]`), enthält `## ABSOLUTES VERBOT`, `## Aufruf-Protokoll` mit
   Bedingungen für beide Caller, `## Output` als Instruction-Section, Pre-Flight-Check für `web_search`

2. **HELP-02 ✓** `al-code-research.agent.md` existiert mit korrektem Frontmatter (`model: claude-sonnet-4-5`,
   `tools: ["read", "search"]`), enthält `## ABSOLUTES VERBOT`, `vscode_listCodeUsages` als optionales
   Tool mit grep/search-Fallback, `## Aufruf-Protokoll` mit Bedingungen für beide Caller, `## Output`

3. **HELP-03 ✓** Weder `al-websearch.agent.md` noch `al-code-research.agent.md` enthalten einen
   Abschnitt dessen Titel dem ERGEBNIS-Muster der Spezialisten entspricht; beide haben kein
   `agents:` Frontmatter-Feld (echte Leaf-Nodes)

4. **HELP-04 ✓** `al-architect.agent.md` enthält `al-websearch` + `al-code-research` in `agents:` und
   einen `Helper-Aufruf (On-Demand — NICHT als Default)` Body-Abschnitt; `al-coder.agent.md`
   hat neues `agents:` Frontmatter-Feld und denselben On-Demand-Abschnitt

5. **Roster ✓** `main-agent.agent.md` enthält beide Helpers in `agents:` (Runtime-Discovery) + Hinweis-Block;
   `AGENTS.md` zeigt beide als `Aktiv (Phase 4)` in der "Aktuelle Agents"-Tabelle

6. **Skript ✓** `verify-phase-4.ps1` läuft durch und gibt Exit-Code 0

---

## Nicht-Ziele dieser Phase

Die folgenden Punkte sind bewusst ausgeschlossen und sollen NICHT implementiert werden:

- Kein Caching von Helper-Ergebnissen (Spezialisten halten Output im Working Memory)
- Keine Änderung der Workflow-Schritt-Tabelle in `main-agent.agent.md`
- Kein neuer Checkpoint-Typ für Helper-Aufrufe
- Keine Änderung an `agent-policy.md` oder `ergebnis-contract.instructions.md`
- Kein Deployment-Schritt (Markdown-Dateien, kein Build-Prozess)
- Phase 3 (Customer Docs Pipeline) bleibt geblockt — nicht berühren

---

*Plan erstellt: 2026-06-18*  
*Phase: 4 — Helper Agents | Milestone: v1 — Main-Agent Architecture*
