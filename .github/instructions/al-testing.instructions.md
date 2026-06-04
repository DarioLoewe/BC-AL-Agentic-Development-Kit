---
description: Testregeln und Testhinweise für Business-Central-AL-Entwicklung
applyTo: "**/*.al"
---

# AL Testing Instructions

Diese Instructions gelten für Tests, Testplanung und Testhinweise in Business-Central-AL-Projekten.

## Grundprinzip

Jede AL-Änderung muss fachlich und technisch testbar sein.

Wenn keine automatisierten Tests erstellt werden können, müssen mindestens klare manuelle Testhinweise dokumentiert werden.

## Ziel

Bei jeder Änderung sollen beantwortet werden:

- Was wurde geändert?
- Welches Verhalten soll geprüft werden?
- Welche Daten werden benötigt?
- Welche Randfälle sind relevant?
- Welche bestehenden Prozesse könnten betroffen sein?
- Wie erkennt man, dass die Änderung erfolgreich ist?

## Testarten

Je nach Änderung sollen folgende Testarten berücksichtigt werden:

| Testart           | Zweck                                              |
| ----------------- | -------------------------------------------------- |
| Fachlicher Test   | Prüft, ob die Anforderung erfüllt ist              |
| Technischer Test  | Prüft Codepfade, Validierung und Fehlerfälle       |
| Regressionstest   | Prüft, ob bestehende Prozesse weiter funktionieren |
| Berechtigungstest | Prüft Rollen- und Zugriffsthemen                   |
| Performancetest   | Prüft Verhalten bei größeren Datenmengen           |
| Integrationstest  | Prüft Schnittstellen oder abhängige Module         |

## Wann Tests besonders wichtig sind

Besonders sorgfältig testen bei Änderungen an:

- Buchungslogik
- Einkaufsprozessen
- Verkaufsprozessen
- Lagerprozessen
- Artikelposten
- Wertposten
- Preisen und Rabatten
- Reservierungen
- Artikelverfolgung
- Lieferterminzusagen
- Reklamationen
- Montage/Fertigung
- Schnittstellen
- Berechtigungen
- Datenmigrationen

## Testplanung

Für jede Änderung sollen Testfälle in dieser Struktur beschrieben werden:

```markdown
## Testfall: [Name]

### Ziel

Was soll geprüft werden?

### Voraussetzungen

Welche Stammdaten, Belege oder Einstellungen werden benötigt?

### Schritte

1. ...
2. ...
3. ...

### Erwartetes Ergebnis

Was muss passieren?

### Hinweise

Besondere Randfälle oder Risiken.
```

## Manuelle Testhinweise

Wenn keine automatisierten Tests erstellt werden, dokumentiere mindestens:

```markdown
## Manuelle Testhinweise

### Vorbereitung

- ...

### Testschritte

1. ...
2. ...
3. ...

### Erwartetes Ergebnis

- ...

### Regression

Zusätzlich prüfen:

- ...
```

## Automatisierte Tests

Wenn automatisierte AL-Tests sinnvoll sind:

- Testcode in Test-Codeunits schreiben
- sprechende Testmethodennamen verwenden
- Testdaten kontrolliert erzeugen
- keine Abhängigkeit von zufälligen Bestandsdaten
- Assert-Aussagen klar formulieren
- positive und negative Fälle testen
- Setup-Logik wiederverwendbar halten

Beispielstruktur:

```al
codeunit 50100 "Sales Validation Tests"
{
    Subtype = Test;

    [Test]
    procedure CustomerBlockedPreventsPosting()
    begin
        // [GIVEN] A blocked customer
        // [WHEN] A sales order is posted
        // [THEN] Posting is prevented
    end;
}
```

## GIVEN / WHEN / THEN

Tests und Testhinweise sollen möglichst nach diesem Muster beschrieben werden:

```markdown
### GIVEN

Ausgangssituation

### WHEN

Aktion des Benutzers oder Systems

### THEN

Erwartetes Ergebnis
```

## Randfälle

Bei jeder Änderung prüfen, ob Randfälle relevant sind:

- leere Werte
- gesperrte Debitoren/Kreditoren/Artikel
- fehlende Stammdaten
- mehrere Zeilen
- mehrere Mandanten
- unterschiedliche Belegarten
- unterschiedliche Währungen
- unterschiedliche Lagerorte
- unterschiedliche Einheiten
- Varianten
- Chargen/Seriennummern
- bereits gebuchte Belege
- stornierte oder korrigierte Belege

## Regression

Bei Änderungen an bestehenden Prozessen immer prüfen:

- funktioniert der Standardprozess noch?
- funktionieren bestehende Erweiterungen noch?
- gibt es Auswirkungen auf Reports?
- gibt es Auswirkungen auf Schnittstellen?
- gibt es Auswirkungen auf Buchungen?
- gibt es Auswirkungen auf Berechtigungen?

## Build und Diagnostics

Nach Codeänderungen gilt:

1. Projekt bauen oder kompilieren
2. Diagnostics prüfen
3. Fehler beheben
4. Warnungen bewerten
5. Ergebnis dokumentieren

Wenn Build oder Compile nicht möglich ist, muss das dokumentiert werden.

## Testdokumentation im PR

Jeder PR soll einen Abschnitt enthalten:

```markdown
## Tests

Durchgeführt:

- [ ] Build/Compile
- [ ] Diagnostics geprüft
- [ ] manueller Test
- [ ] automatisierter Test
- [ ] Regression geprüft

Testhinweise:

- ...

Nicht getestet:

- ...
```

## Nicht ausreichend

Nicht ausreichend sind Aussagen wie:

- "sollte funktionieren"
- "nicht getestet"
- "nur kleine Änderung"
- "Build nicht nötig"
- "keine Tests erforderlich"

Wenn wirklich nicht getestet werden kann, muss der Grund genannt werden.

## Fehleranalyse

Wenn ein Test fehlschlägt:

- Fehler reproduzieren
- Ursache beschreiben
- betroffene Objekte nennen
- konkrete Korrektur vorschlagen
- erneuten Test dokumentieren

## AI-Agent-Regeln

Wenn ein Agent Tests plant oder ausführt:

- keine Testlücken verschweigen
- keine erfolgreichen Tests behaupten, die nicht ausgeführt wurden
- Build/Diagnostics nur als erfolgreich melden, wenn sie wirklich erfolgreich waren
- Annahmen klar dokumentieren
- bei fehlender Testumgebung manuelle Testhinweise erzeugen
