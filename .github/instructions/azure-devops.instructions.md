---
description: Regeln für Azure-DevOps-Work-Items, Branches und Pull Requests
applyTo: "**/*"
---

# Azure DevOps Instructions

Diese Instructions gelten für die Arbeit mit Azure DevOps Work Items, Branches, Pull Requests und Entwicklungsabläufen.

## Grundprinzip

Azure DevOps ist die zentrale Aufgabenverwaltung.

Jede AI-unterstützte AL-Änderung soll nachvollziehbar mit einem Work Item, Branch und Pull Request verbunden sein.

## Work Items

Bei der Analyse eines Work Items immer erfassen:

- Titel
- Beschreibung
- Kundennutzen
- betroffener Prozess
- betroffene BC-Version
- betroffener Kunde oder Mandant, falls relevant
- Akzeptanzkriterien
- Annahmen
- Risiken
- technische Tasks
- Testhinweise

## Umgang mit dünnen Anforderungen

Wenn eine Anforderung knapp formuliert ist:

- nicht einfach raten
- Annahmen sichtbar dokumentieren
- kleinste sichere Umsetzung wählen
- bei Risiko automatisch blocken
- Rückfragen als Work-Item-Kommentar vorbereiten

Beispiel:

```markdown
## Annahmen

- Ich gehe davon aus, dass ...
- Nicht beschrieben ist ...
- Für die Umsetzung wurde angenommen ...

## Offene Fragen

- Soll ...
- Gilt das für ...
```

## Work-Item-Tags

Empfohlene Tags:

| Tag              | Bedeutung                              |
| ---------------- | -------------------------------------- |
| `ai:auto`        | darf vom Auto-Agent verarbeitet werden |
| `ai:plan-only`   | nur Analyse und Plan erstellen         |
| `ai:implement`   | Umsetzung erlaubt                      |
| `ai:review-only` | nur Review durchführen                 |
| `ai:blocked`     | Agent konnte nicht sicher fortfahren   |
| `ai:done`        | Agentenlauf abgeschlossen              |
| `bc-al`          | Business-Central-AL-Bezug              |

## Automatischer Workflow

Für vollautomatische Verarbeitung gilt:

```text
1. Work Item mit `ai:auto` markieren
2. Agent analysiert Anforderung
3. Agent erstellt oder nutzt Feature-Branch
4. Agent implementiert kleinste sichere Änderung
5. Agent führt Build/Diagnostics aus
6. Agent erstellt oder aktualisiert Pull Request
7. Agent kommentiert Ergebnis am Work Item
8. Mensch reviewed und merged
```

## Branch-Regeln

Keine direkten Änderungen auf:

```text
main
master
release/*
production/*
```

Branch-Namen sollen nachvollziehbar sein.

Empfohlen:

```text
feature/wi-{id}-kurzer-titel
bugfix/wi-{id}-kurzer-titel
ai/wi-{id}-kurzer-titel
```

Beispiel:

```text
ai/wi-12345-show-vendor-blocked-item
```

## Commit-Regeln

Commits sollen klein und verständlich sein.

Empfohlenes Format:

```text
WI #{id}: kurze Beschreibung
```

Beispiel:

```text
WI #12345: Show vendor block status on sales order
```

Keine Commits mit:

```text
fix
test
changes
wip
asdf
```

## Pull Requests

Jede AI-unterstützte Änderung soll über Pull Request laufen.

PRs sollen bei automatischer Umsetzung zunächst als Draft erstellt werden.

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

## Work-Item-Kommentar

Nach einem Agentenlauf soll ein Kommentar vorbereitet oder erstellt werden:

```markdown
## AI-Agent-Ergebnis

Status: Erfolgreich / Blockiert / Fehlerhaft

## Zusammenfassung

...

## Annahmen

- ...

## Umsetzung

- ...

## Build/Diagnostics

...

## Tests

...

## Nächste Schritte

- ...
```

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

## Definition of Done

Eine AI-unterstützte Änderung ist fertig, wenn:

```markdown
- [ ] Work Item analysiert
- [ ] Annahmen dokumentiert
- [ ] Branch erstellt
- [ ] Änderung umgesetzt oder Blocker dokumentiert
- [ ] Build/Compile ausgeführt
- [ ] Diagnostics geprüft
- [ ] Tests/Testhinweise dokumentiert
- [ ] Review durchgeführt
- [ ] Draft PR erstellt oder vorbereitet
- [ ] Work Item kommentiert
```

## Blocker

Ein Agent soll blocken, wenn:

- die Anforderung fachlich widersprüchlich ist
- mehrere gefährliche Interpretationen möglich sind
- produktive Daten benötigt werden
- Secrets fehlen oder sichtbar wären
- Datenmigration nötig ist
- Buchungslogik unklar betroffen ist
- Berechtigungen massiv erweitert werden müssten
- Buildumgebung nicht verfügbar ist und keine sichere Umsetzung möglich ist

## Azure-DevOps-Kommentare

Kommentare sollen sachlich, nachvollziehbar und knapp sein.

Nicht schreiben:

```text
Ich bin mir nicht sicher, aber vielleicht passt das.
```

Besser:

```markdown
Die Umsetzung wurde blockiert, weil unklar ist, ob die Änderung für alle Verkaufsbelegarten oder nur für Verkaufsaufträge gelten soll.
```

## AI-Agent-Regeln

Wenn ein Agent mit Azure DevOps arbeitet:

- keine Work Items ohne passenden Trigger automatisch ändern
- keine States blind ändern
- keine PRs automatisch mergen
- keine Releases starten
- keine produktiven Deployments auslösen
- alle Annahmen dokumentieren
- alle Blocker nachvollziehbar kommentieren
