# Agent Policy

Diese Policy gilt für alle Agents, Skills und Prompts im BC AL Agentic Development Kit.

## Verzeichnis-Policy

Das Repository `BC-AL-Agentic-Development-Kit` ist ein **Framework-Repository**.
Es enthält keine AL-Extensions.

**Regel:** Neue AL-Extension-Projekte werden immer als Geschwister-Ordner angelegt:

```
C:\Users\dloewe\{Kunde}\{ExtensionName}\
```

Niemals innerhalb von `BC-AL-Agentic-Development-Kit\` anlegen.
Keine `app.json`, keine `.al`-Dateien, kein `src\`-Verzeichnis im Framework-Repo erstellen.

Bei Unklarheit über den Zielpfad: **Benutzer fragen**, nicht raten.

Agents dürfen den Entwicklungsprozess unterstützen und automatisieren, aber nicht unkontrolliert produktive Änderungen ausführen.

## Erlaubt

- Anforderungen analysieren
- AL-Code lesen
- technische Pläne erstellen
- Code auf Feature-Branches vorbereiten
- Build und Diagnostics ausführen
- Reviews erstellen
- Dokumentation erzeugen
- Draft Pull Requests vorbereiten

## Nicht erlaubt

- direkt auf `main` committen
- automatisch mergen
- produktiv veröffentlichen
- Secrets lesen oder ausgeben
- produktive Kundendaten in Prompts verwenden
- Datenmigrationen ohne explizites Review erstellen
- Berechtigungen ungeprüft erweitern
- große Refactorings ohne explizite Anforderung durchführen

## Thin Requirement Policy

Wenn eine Anforderung dünn ist, aber eine sichere technische Umsetzung naheliegt:

- kleinste sinnvolle Änderung umsetzen
- Annahmen dokumentieren
- Testhinweise ergänzen
- PR als Draft markieren

Wenn mehrere fachliche Interpretationen möglich sind:

- keine riskante Logikänderung durchführen
- Analyse, Plan und Rückfrage als Work-Item-Kommentar erzeugen
- Work Item als `ai:blocked` markieren, falls möglich

Wenn die Änderung folgende Bereiche betrifft:

- Buchungslogik
- Preise
- Lager
- Posten
- Berechtigungen
- Datenmigration
- Schnittstellen
- produktive Daten

dann nur implementieren, wenn die Akzeptanzkriterien ausreichend klar sind.  
Ansonsten automatisch blocken und dokumentieren.

## Confidence-Regel

Bewerte jede Aufgabe intern:

|  Confidence | Aktion                                            |
| ----------: | ------------------------------------------------- |
| 0.80 - 1.00 | implementieren                                    |
| 0.60 - 0.79 | vorsichtig implementieren, Annahmen dokumentieren |
| 0.40 - 0.59 | nur technische Vorbereitung oder Spike            |
| 0.00 - 0.39 | nicht implementieren, Blocker dokumentieren       |

## Build-Regel

Nach jeder Codeänderung:

1. Build/Compile ausführen
2. Diagnostics prüfen
3. Fehler beheben
4. maximal 3 Fix-Schleifen
5. Ergebnis dokumentieren

## Abschlussregel

Am Ende muss immer dokumentiert werden:

- verstandene Anforderung
- getroffene Annahmen
- geänderte Dateien
- Build-/Diagnostics-Ergebnis
- Tests oder Testhinweise
- Risiken
- PR-Beschreibung
