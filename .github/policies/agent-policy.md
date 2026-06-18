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

## Build-Regel

Nach jeder Codeänderung:

1. Build/Compile ausführen
2. Diagnostics prüfen
3. Fehler beheben
4. maximal 3 Fix-Schleifen
5. Ergebnis dokumentieren

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

## Abschlussregel

Am Ende muss immer dokumentiert werden:

- verstandene Anforderung
- getroffene Annahmen
- geänderte Dateien
- Build-/Diagnostics-Ergebnis
- Tests oder Testhinweise
- Risiken
- PR-Beschreibung
