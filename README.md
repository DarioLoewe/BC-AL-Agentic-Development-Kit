# BC AL Agentic Development Kit

Dieses Repository enthält ein internes Agentic-AI-Setup für die Entwicklung von Microsoft Dynamics 365 Business Central Extensions mit AL.

Ziel ist es, AL-Entwicklung strukturierter, schneller und nachvollziehbarer zu unterstützen – von der Kundenanforderung oder dem Azure-DevOps-Work-Item bis zum Draft Pull Request.

Der Fokus liegt aktuell ausschließlich auf **Agenten für die AL-Entwicklung**.

Business-Central-interne Copilot-/AI-Funktionen innerhalb einer BC-App sind bewusst **nicht Bestandteil** dieses Setups.

---

## Zielbild

Das BC AL Agentic Development Kit unterstützt einen vollautomatisierten Entwicklungsfluss bis zum Draft Pull Request:

```text
Azure DevOps Work Item / Kundenanforderung
        ↓
al-auto-dev
        ↓
Planning
        ↓
Codebase Analysis
        ↓
Implementation
        ↓
Build / Diagnostics
        ↓
Fix Loop
        ↓
Review
        ↓
Documentation
        ↓
Draft Pull Request
```

Der Mensch bleibt verantwortlich für:

- fachliche Prüfung
- Code Review
- Merge
- Release
- produktive Veröffentlichung

---

## Grundprinzip

Das Setup besteht aus fünf Ebenen:

| Ebene            | Zweck                                      |
| ---------------- | ------------------------------------------ |
| **Policies**     | Verbindliche Sicherheits- und Ablaufregeln |
| **Instructions** | Allgemeine fachliche und technische Regeln |
| **Skills**       | Wiederverwendbare Fähigkeiten              |
| **Agents**       | Spezialisierte Rollen                      |
| **Prompts**      | Schnellstarter für häufige Aufgaben        |

Kurz gesagt:

> **Policies setzen Grenzen. Instructions geben Standards. Skills sind Fähigkeiten. Agents sind Rollen.**

---

## Repository-Struktur

```text
.github/
  copilot-instructions.md

  policies/
    agent-policy.md

  instructions/
    al-coding-standards.instructions.md
    al-testing.instructions.md
    al-review.instructions.md
    azure-devops.instructions.md

  agents/
    al-auto-dev.agent.md
    al-planner.agent.md
    al-codebase-analyst.agent.md
    al-implementer.agent.md
    al-build-tester.agent.md
    al-reviewer.agent.md
    al-documenter.agent.md

  prompts/
    analyze-work-item.prompt.md
    plan-al-change.prompt.md
    review-al-pr.prompt.md
    explain-build-error.prompt.md

  skills/
    al-object-analysis/
      SKILL.md
    al-build-validation/
      SKILL.md
    al-code-review/
      SKILL.md
    al-test-design/
      SKILL.md
    al-devops-workitem/
      SKILL.md
```

---

## Zentrale Dateien

### `.github/copilot-instructions.md`

Diese Datei enthält die allgemeinen Grundregeln für Copilot und alle agentischen Workflows in diesem Repository.

Dazu gehören unter anderem:

- upgradefähiger AL-Code
- kleine, nachvollziehbare Änderungen
- keine direkten Änderungen auf `main`
- keine produktiven Veröffentlichungen
- keine Secrets oder Kundendaten im Prompt-Kontext
- sichtbare Texte als Labels
- Businesslogik nicht unnötig in Pages
- Performance bei großen Tabellen beachten
- Build und Diagnostics nach Codeänderungen prüfen
- Verweis auf die zentrale Agent Policy

---

### `.github/policies/agent-policy.md`

Die zentrale Policy ist verbindlich für alle Agents, Skills und Prompts.

Sie regelt:

- erlaubte Aktionen
- verbotene Aktionen
- Thin-Requirement-Verhalten
- Confidence-Regel
- Build-Regel
- Stop-Regeln
- Abschlussdokumentation

Die Policy hat Vorrang vor normalen Instructions, Skills und Agent-Beschreibungen.

---

## Agent Policy

Die zentrale Agent Policy liegt hier:

```text
.github/policies/agent-policy.md
```

Sie gilt für alle automatisierten Abläufe.

### Erlaubt

Agents dürfen:

- Anforderungen analysieren
- AL-Code lesen
- technische Pläne erstellen
- Code auf Feature-Branches vorbereiten
- Build und Diagnostics ausführen
- Reviews erstellen
- Dokumentation erzeugen
- Draft Pull Requests vorbereiten

### Nicht erlaubt

Agents dürfen nicht:

- direkt auf `main` committen
- automatisch mergen
- produktiv veröffentlichen
- Secrets lesen oder ausgeben
- produktive Kundendaten in Prompts verwenden
- Datenmigrationen ohne explizites Review erstellen
- Berechtigungen ungeprüft erweitern
- große Refactorings ohne explizite Anforderung durchführen

---

## Thin Requirement Policy

Da Kundenanforderungen häufig sehr knapp sind, gilt eine eigene Thin-Requirement-Regel.

Wenn eine Anforderung dünn ist, aber eine sichere technische Umsetzung naheliegt:

- kleinste sinnvolle Änderung umsetzen
- Annahmen dokumentieren
- Testhinweise ergänzen
- PR als Draft markieren

Wenn mehrere fachliche Interpretationen möglich sind:

- keine riskante Logikänderung durchführen
- Analyse, Plan und Rückfrage als Work-Item-Kommentar erzeugen
- Work Item als `ai:blocked` markieren, falls möglich

Wenn die Änderung folgende Bereiche betrifft, wird besonders konservativ entschieden:

- Buchungslogik
- Preise
- Lager
- Posten
- Berechtigungen
- Datenmigration
- Schnittstellen
- produktive Daten

---

## Confidence-Regel

Jede Aufgabe wird nach Umsetzbarkeit bewertet.

|  Confidence | Aktion                                            |
| ----------: | ------------------------------------------------- |
| 0.80 - 1.00 | implementieren                                    |
| 0.60 - 0.79 | vorsichtig implementieren, Annahmen dokumentieren |
| 0.40 - 0.59 | nur technische Vorbereitung oder Spike            |
| 0.00 - 0.39 | nicht implementieren, Blocker dokumentieren       |

Der Agent fragt im vollautomatischen Modus nicht nach, sondern entscheidet anhand dieser Regel.

---

## Instructions

Die Instructions liegen im Ordner:

```text
.github/instructions/
```

Sie enthalten thematische Zusatzregeln, die von Copilot, Agents und Skills berücksichtigt werden sollen.

| Datei                                 | Zweck                                                   |
| ------------------------------------- | ------------------------------------------------------- |
| `al-coding-standards.instructions.md` | AL-Coding-Regeln, Naming, Patterns, Performance, Labels |
| `al-testing.instructions.md`          | Testregeln, Testplanung, manuelle Testhinweise          |
| `al-review.instructions.md`           | Review-Kriterien für AL-Codeänderungen                  |
| `azure-devops.instructions.md`        | Work Items, Branches, PRs, Tags und Kommentare          |

---

## `al-coding-standards.instructions.md`

Diese Datei definiert die AL-Coding-Standards.

Sie gilt für:

```text
**/*.al
```

Wichtige Inhalte:

- upgradefähiger AL-Code
- bestehende Patterns verwenden
- ein AL-Objekt pro Datei
- sprechende Objekt- und Variablennamen
- sichtbare Texte als Labels
- Businesslogik nicht unnötig in Pages
- Events und Erweiterungspunkte bevorzugen
- Performance bei großen Tabellen beachten
- keine unnötigen `COMMIT`s
- keine Secrets oder hartcodierten Zugangsdaten

---

## `al-testing.instructions.md`

Diese Datei definiert Testregeln für AL-Änderungen.

Sie gilt für:

```text
**/*.al
```

Wichtige Inhalte:

- fachliche Tests
- technische Tests
- Regressionstests
- Berechtigungstests
- manuelle Testhinweise
- automatisierte AL-Tests
- GIVEN/WHEN/THEN-Struktur
- Testdokumentation im PR
- Regeln für Build und Diagnostics

Jede Änderung muss entweder getestet oder mit klaren Testhinweisen dokumentiert werden.

---

## `al-review.instructions.md`

Diese Datei definiert Review-Kriterien.

Sie gilt für:

```text
**/*.al
```

Wichtige Prüfpunkte:

- fachliche Nachvollziehbarkeit
- AL-Best-Practices
- Architektur
- Performance
- Fehlerbehandlung
- Buchungs- und Prozessrisiken
- Berechtigungen
- Tests
- Sicherheit
- Dokumentation

Jedes Review endet mit einer klaren Empfehlung:

```text
Freigabe
Änderungen notwendig
Blocker
```

---

## `azure-devops.instructions.md`

Diese Datei definiert den Umgang mit Azure DevOps.

Sie gilt für:

```text
**/*
```

Wichtige Inhalte:

- Work-Item-Analyse
- Branch-Regeln
- Commit-Regeln
- Pull-Request-Struktur
- Work-Item-Kommentare
- AI-Tags
- Definition of Ready
- Definition of Done
- Blocker-Regeln

Empfohlene AI-Tags:

| Tag              | Bedeutung                              |
| ---------------- | -------------------------------------- |
| `ai:auto`        | darf vom Auto-Agent verarbeitet werden |
| `ai:plan-only`   | nur Analyse und Plan erstellen         |
| `ai:implement`   | Umsetzung erlaubt                      |
| `ai:review-only` | nur Review durchführen                 |
| `ai:blocked`     | Agent konnte nicht sicher fortfahren   |
| `ai:done`        | Agentenlauf abgeschlossen              |
| `bc-al`          | Business-Central-AL-Bezug              |

---

## Agents

Agents sind spezialisierte Rollen.

Der wichtigste Einstiegspunkt für Vollautomatik ist:

```text
al-auto-dev
```

Die anderen Agents dienen als Phasen oder Subagents im Ablauf.

---

## `al-auto-dev`

Der `al-auto-dev` Agent ist der zentrale Orchestrator.

Er führt den kompletten Ablauf selbstständig aus:

1. Anforderung analysieren
2. Annahmen dokumentieren
3. Akzeptanzkriterien ableiten
4. relevante AL-Objekte finden
5. technischen Plan erstellen
6. Code ändern
7. Build/Diagnostics ausführen
8. Fehler beheben
9. Review durchführen
10. Dokumentation erstellen
11. Draft Pull Request vorbereiten

Dieser Agent ist der Standard-Einstiegspunkt für vollautomatische Verarbeitung.

---

## `al-planner`

Plant AL-Änderungen aus fachlichen Anforderungen.

Aufgaben:

- Work Item verstehen
- Annahmen sichtbar machen
- Akzeptanzkriterien formulieren
- technische Umsetzung planen
- Tests und Risiken benennen

Im vollautomatischen Ablauf wird er durch `al-auto-dev` als Planungsphase genutzt.

---

## `al-codebase-analyst`

Analysiert bestehende AL-Codebases.

Aufgaben:

- relevante AL-Objekte finden
- bestehende Logik verstehen
- Erweiterungspunkte suchen
- technische Abhängigkeiten erkennen
- ähnliche Umsetzungen identifizieren

Im vollautomatischen Ablauf liefert er die technische Grundlage für die Implementierung.

---

## `al-implementer`

Setzt kleine, klar geplante AL-Änderungen um.

Aufgaben:

- bestätigten technischen Plan umsetzen
- bestehende Patterns verwenden
- nur notwendige Dateien ändern
- sichtbare Texte als Labels anlegen
- Änderung für Build und Review vorbereiten

Im vollautomatischen Ablauf darf er nur auf Basis des Plans arbeiten.

---

## `al-build-tester`

Prüft Build, Compile, Diagnostics und Tests.

Aufgaben:

- Symbole prüfen
- Build/Compile ausführen
- Diagnostics auswerten
- Fehler erklären
- Fix-Vorschläge geben
- Testempfehlungen dokumentieren

Im vollautomatischen Ablauf darf er maximal drei Fix-Schleifen anstoßen.

---

## `al-reviewer`

Prüft AL-Codeänderungen als Reviewer.

Aufgaben:

- Diff prüfen
- AL-Best-Practices bewerten
- Risiken und Blocker finden
- Testlücken benennen
- PR-Kommentar vorbereiten

Im vollautomatischen Ablauf bewertet er, ob ein Draft PR fachlich und technisch reviewfähig ist.

---

## `al-documenter`

Erstellt Dokumentation zu AL-Änderungen.

Aufgaben:

- PR-Beschreibung schreiben
- technische Dokumentation erstellen
- Release Notes vorbereiten
- Testhinweise formulieren
- Schulungsnotizen ableiten

Im vollautomatischen Ablauf erzeugt er die finale Dokumentation für PR und Work Item.

---

## Skills

Skills sind wiederverwendbare Fähigkeiten, die von mehreren Agents genutzt werden können.

---

## `al-object-analysis`

Analysiert ein AL-Repository und findet relevante Objekte.

Typische Nutzung:

- betroffene Tables, Pages, Codeunits, Reports und Enums finden
- bestehende Patterns erkennen
- mögliche Erweiterungspunkte identifizieren
- technische Risiken benennen

---

## `al-build-validation`

Prüft Build, Compile, Symbole und Diagnostics.

Typische Nutzung:

- Symbole prüfen oder herunterladen
- AL-Projekt bauen
- Compilerfehler auswerten
- Diagnostics zusammenfassen
- konkrete Korrekturen vorschlagen

---

## `al-code-review`

Führt ein strukturiertes AL-Code-Review durch.

Geprüft werden unter anderem:

- Upgradefähigkeit
- Performance
- Fehlerbehandlung
- Labels
- Berechtigungen
- Testbarkeit
- Events statt invasiver Änderungen
- keine unnötigen `COMMIT`s
- keine produktionskritischen Aktionen

---

## `al-test-design`

Erstellt fachliche und technische Testfälle für AL-Änderungen.

Typische Ergebnisse:

- manuelle Testfälle
- technische Testideen
- Randfälle
- benötigte Testdaten
- Hinweise für Regressionstests

---

## `al-devops-workitem`

Zerlegt Azure-DevOps-Work-Items in eine umsetzbare AL-Planung.

Typische Ergebnisse:

- Zusammenfassung der Anforderung
- Annahmen
- Akzeptanzkriterien
- technische Tasks
- Definition of Done

---

## Prompts

Prompts sind Schnellstarter für häufige Aufgaben.

---

## `plan-al-change.prompt.md`

Erstellt einen technischen Umsetzungsplan für eine AL-Änderung.

---

## `review-al-pr.prompt.md`

Führt ein strukturiertes Review einer AL-Codeänderung durch.

---

## Standardworkflow für Vollautomatik

Der empfohlene vollautomatische Ablauf:

```text
1. Work Item oder Kundenanforderung erfassen
2. Tag `ai:auto` setzen
3. al-auto-dev starten
4. Agent analysiert Anforderung
5. Agent dokumentiert Annahmen
6. Agent analysiert Codebasis
7. Agent erstellt technischen Plan
8. Agent implementiert kleinste sichere Änderung
9. Agent führt Build/Diagnostics aus
10. Agent behebt Fehler in maximal 3 Fix-Schleifen
11. Agent führt Review durch
12. Agent erstellt Dokumentation
13. Agent erstellt oder vorbereitet Draft Pull Request
14. Agent kommentiert Work Item
15. Mensch reviewed, merged und released
```

---

## Standardworkflow für Plan-only

Für Analyse ohne Umsetzung:

```text
1. Work Item mit `ai:plan-only` markieren
2. al-auto-dev oder al-planner starten
3. Anforderung analysieren
4. Annahmen dokumentieren
5. Akzeptanzkriterien ableiten
6. betroffene Objekte suchen
7. technischen Plan erstellen
8. Work Item kommentieren
```

---

## Standardworkflow für Review-only

Für reine Reviews:

```text
1. Pull Request oder Diff bereitstellen
2. al-reviewer starten
3. Änderung prüfen
4. Blocker, Risiken und Testlücken dokumentieren
5. PR-Kommentar vorbereiten
```

---

## Branch-Regeln

Agents dürfen keine direkten Änderungen auf folgenden Branches durchführen:

```text
main
master
release/*
production/*
```

Empfohlene Branch-Namen:

```text
ai/wi-{id}-kurzer-titel
feature/wi-{id}-kurzer-titel
bugfix/wi-{id}-kurzer-titel
```

Beispiel:

```text
ai/wi-12345-show-vendor-blocked-item
```

---

## Commit-Regeln

Commits sollen klein und nachvollziehbar sein.

Empfohlenes Format:

```text
WI #{id}: kurze Beschreibung
```

Beispiel:

```text
WI #12345: Show vendor block status on sales order
```

Nicht erwünscht:

```text
fix
test
changes
wip
asdf
```

---

## Pull-Request-Regeln

Jede AI-unterstützte Änderung soll über einen Pull Request laufen.

Automatisch erzeugte PRs sollen zunächst als Draft erstellt werden.

PRs müssen enthalten:

- Zusammenfassung
- Work-Item-Bezug
- Umsetzung
- Annahmen
- geänderte Dateien
- Build-/Diagnostics-Ergebnis
- Tests oder Testhinweise
- Risiken
- Review-Hinweise

---

## PR-Beschreibung

Empfohlene Struktur:

```markdown
## Zusammenfassung

...

## Work Item

AB#{id}

## Umsetzung

- ...

## Annahmen

- ...

## Geänderte Dateien

- ...

## Build / Diagnostics

- ...

## Tests

- [ ] Build/Compile erfolgreich
- [ ] Diagnostics geprüft
- [ ] manueller Test dokumentiert
- [ ] automatisierte Tests ergänzt
- [ ] Regression geprüft

## Risiken

- ...

## Review-Hinweise

- ...
```

---

## Work-Item-Kommentar

Nach einem Agentenlauf soll ein Kommentar am Work Item erstellt oder vorbereitet werden.

```markdown
## AI-Agent-Ergebnis

Status: Erfolgreich / Blockiert / Fehlerhaft

## Zusammenfassung

...

## Annahmen

- ...

## Umsetzung

- ...

## Build / Diagnostics

...

## Tests

...

## Risiken

...

## Nächste Schritte

- ...
```

---

## Definition of Ready

Ein Work Item ist bereit für AI-Umsetzung, wenn möglichst viele Punkte erfüllt sind:

```markdown
- [ ] fachliche Beschreibung vorhanden
- [ ] betroffener Prozess genannt
- [ ] gewünschtes Ergebnis beschrieben
- [ ] Akzeptanzkriterien vorhanden
- [ ] Kunde/Projekt klar
- [ ] Priorität klar
- [ ] `ai:auto` oder passender AI-Tag gesetzt
```

Wenn nicht alles vorhanden ist, darf der Agent trotzdem arbeiten, muss aber Annahmen dokumentieren.

---

## Definition of Done

Eine AI-unterstützte Änderung ist fertig, wenn:

```markdown
- [ ] Work Item analysiert
- [ ] Annahmen dokumentiert
- [ ] Akzeptanzkriterien formuliert oder abgeleitet
- [ ] Branch erstellt
- [ ] Änderung umgesetzt oder Blocker dokumentiert
- [ ] Build/Compile ausgeführt
- [ ] Diagnostics geprüft
- [ ] Tests/Testhinweise dokumentiert
- [ ] Review durchgeführt
- [ ] Draft PR erstellt oder vorbereitet
- [ ] Work Item kommentiert
- [ ] keine Secrets oder produktiven Kundendaten verwendet
```

---

## Build-Regel

Nach jeder Codeänderung gilt:

```text
1. Build/Compile ausführen
2. Diagnostics prüfen
3. Fehler analysieren
4. Fehler beheben
5. Build erneut ausführen
6. maximal 3 Fix-Schleifen
7. Ergebnis dokumentieren
```

Wenn Build oder Compile nicht möglich ist, muss der Grund dokumentiert werden.

---

## Stop-Regeln

Der Agent stoppt und ändert keinen weiteren Code, wenn:

- produktive Kundendaten benötigt würden
- Secrets fehlen oder sichtbar wären
- eine Datenmigration notwendig wäre
- Berechtigungen massiv erweitert werden müssten
- die Anforderung fachlich widersprüchlich ist
- die Buildumgebung nicht verfügbar ist und keine sichere Umsetzung möglich ist
- mehrere gefährliche Interpretationen möglich sind

In diesem Fall wird automatisch eine Analyse mit Blocker-Hinweis erzeugt.

---

## Tool-Rechte je Agent

| Agent                 | Lesen | Suchen |    Editieren | Build/Terminal | Publish | Merge |
| --------------------- | ----: | -----: | -----------: | -------------: | ------: | ----: |
| `al-auto-dev`         |    ja |     ja |           ja |             ja |    nein |  nein |
| `al-planner`          |    ja |     ja |         nein |           nein |    nein |  nein |
| `al-codebase-analyst` |    ja |     ja |         nein |           nein |    nein |  nein |
| `al-implementer`      |    ja |     ja |           ja |       optional |    nein |  nein |
| `al-build-tester`     |    ja |     ja |   nein/klein |             ja |    nein |  nein |
| `al-reviewer`         |    ja |     ja |         nein |           nein |    nein |  nein |
| `al-documenter`       |    ja |     ja | ja, nur Doku |           nein |    nein |  nein |

---

## Nutzung in der Praxis

### Beispiel 1: Vollautomatische Umsetzung

Eingabe:

```text
Kunde möchte im Verkaufsauftrag sehen, ob der Artikel eine Lieferantensperre hat.
```

Empfohlener Agent:

```text
al-auto-dev
```

Erwartetes Ergebnis:

- Annahmen
- Akzeptanzkriterien
- Codebase-Analyse
- Implementierung
- Build/Diagnostics
- Review
- PR-Beschreibung
- Draft Pull Request oder Blocker-Kommentar

---

### Beispiel 2: Dünne Anforderung

Eingabe:

```text
Kunde will bessere Info bei gesperrtem Artikel.
```

Erwartetes Verhalten:

- Agent dokumentiert Annahmen
- Agent prüft betroffene Prozesse
- Agent entscheidet anhand der Confidence-Regel
- bei sicherer Umsetzung: kleinste sinnvolle Änderung
- bei Risiko: Blocker-Kommentar mit Rückfragen

---

### Beispiel 3: Nur Planung

Tag:

```text
ai:plan-only
```

Erwartetes Ergebnis:

- Zusammenfassung
- Annahmen
- Akzeptanzkriterien
- betroffene Objekte
- technischer Plan
- Tests
- Risiken

---

### Beispiel 4: Nur Review

Tag:

```text
ai:review-only
```

Erwartetes Ergebnis:

- Review-Ergebnis
- Blocker
- Verbesserungsvorschläge
- Testlücken
- Risiken
- PR-Kommentar

---

## Qualitätskriterien für AL-Code

Bei jeder Änderung sollen mindestens folgende Punkte geprüft werden:

```markdown
- Ist die Änderung upgradefähig?
- Werden vorhandene Events und Erweiterungspunkte genutzt?
- Sind sichtbare Texte als Labels definiert?
- Wurde Businesslogik nicht unnötig in Pages platziert?
- Gibt es unnötige COMMITs?
- Wurden große Tabellen performant verarbeitet?
- Gibt es saubere Fehlerbehandlung?
- Sind Berechtigungen berücksichtigt?
- Gibt es Tests oder Testhinweise?
- Ist die Änderung klein und nachvollziehbar?
```

---

## Aktueller Scope

Enthalten:

```markdown
- AL-Entwicklungsunterstützung
- Work-Item-Analyse
- Codebase-Analyse
- technische Planung
- vollautomatische Umsetzung bis Draft PR
- Build-/Diagnostics-Unterstützung
- Fix-Schleifen
- Code Review
- Dokumentation
- Work-Item-Kommentare
```

Nicht enthalten:

```markdown
- Business-Central-interne Copilot-Funktionen
- AI-Features direkt in AL-Apps
- produktive Veröffentlichungen durch Agents
- automatische Merges
- unbeaufsichtigte Datenmigrationen
- automatische Release-Ausführung
```

---

## Empfohlene Einführung im Team

Die Einführung sollte schrittweise erfolgen:

```text
Phase 1: Copilot Instructions und Instructions nutzen
Phase 2: Skills für wiederkehrende Aufgaben verwenden
Phase 3: Agents für Planung, Review und Dokumentation einsetzen
Phase 4: al-auto-dev für kontrollierte Vollautomatik nutzen
Phase 5: Build-/Diagnostics-Automatisierung anbinden
Phase 6: Azure-DevOps-Work-Item-Automatisierung einführen
```

---

## Kurzbeschreibung für das Team

Das BC AL Agentic Development Kit ist unser internes Setup für AI-unterstützte AL-Entwicklung.

Es besteht aus:

- zentraler Agent Policy
- gemeinsamen Copilot Instructions
- thematischen Instructions
- wiederverwendbaren Skills
- spezialisierten Agents
- einem Auto-Orchestrator
- Prompts für Standardaufgaben
- einem kontrollierten Entwicklungsworkflow

Ziel ist nicht unkontrollierter Autopilot, sondern ein sicherer automatisierter Ablauf bis zum Draft Pull Request.

Der Mensch bleibt verantwortlich für fachliche Bewertung, Review, Merge und Release.
