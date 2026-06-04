---
description: Review-Kriterien für Business-Central-AL-Codeänderungen
applyTo: "**/*.al"
---

# AL Review Instructions

Diese Instructions gelten für Reviews von Business-Central-AL-Änderungen.

## Ziel des Reviews

Ein Review soll sicherstellen, dass die Änderung:

- fachlich nachvollziehbar ist
- technisch sauber umgesetzt wurde
- upgradefähig bleibt
- wartbar ist
- keine unnötigen Risiken erzeugt
- getestet oder testbar ist
- keine produktionskritischen Seiteneffekte verursacht

## Review-Ergebnis

Jedes Review soll mit einer klaren Empfehlung enden:

```markdown
## Review-Ergebnis

Status: Freigabe / Änderungen notwendig / Blocker

Kurzbegründung:
...
```

## Prüfkriterien

### 1. Fachliche Nachvollziehbarkeit

Prüfe:

- Ist die Anforderung erkennbar umgesetzt?
- Sind Annahmen dokumentiert?
- Gibt es Akzeptanzkriterien?
- Ist die Lösung nicht größer als nötig?
- Gibt es fachliche Seiteneffekte?

### 2. AL-Best-Practices

Prüfe:

- upgradefähige Erweiterung statt invasiver Änderung
- bestehende Events und Erweiterungspunkte genutzt
- bestehende Patterns im Repository eingehalten
- ein AL-Objekt pro Datei, wenn im Projekt üblich
- sprechende Objekt- und Variablennamen
- sichtbare Texte als Labels
- Captions und ToolTips sinnvoll gesetzt
- `ApplicationArea` gesetzt

### 3. Architektur

Prüfe:

- Businesslogik nicht unnötig in Pages
- Logik sinnvoll in Codeunits ausgelagert
- Tabellenvalidierung sinnvoll platziert
- keine unnötigen globalen Variablen
- keine unnötigen Abhängigkeiten
- keine versteckten Seiteneffekte
- keine unnötigen Refactorings

### 4. Datenbankzugriffe und Performance

Prüfe:

- Filter vor Schleifen gesetzt
- passende Keys verwendet
- `FindSet`, `FindFirst`, `IsEmpty` passend genutzt
- keine unnötigen `Modify()`-Aufrufe
- keine unnötigen FlowField-Berechnungen
- `SetLoadFields()` geprüft, wenn sinnvoll
- keine teuren Operationen in Page-Triggern
- Verhalten bei großen Tabellen berücksichtigt

### 5. Fehlerbehandlung

Prüfe:

- verständliche Fehlermeldungen
- Fehlertexte als Labels
- `Get()` bewusst verwendet
- bei optionalen Datensätzen `if not Get(...) then`
- keine technischen Fehlermeldungen für Anwender
- keine verschluckten Fehler

### 6. Buchungs- und Prozessrisiken

Besonders kritisch prüfen bei:

- Buchungslogik
- Preisen
- Rabatten
- Lager
- Artikelposten
- Wertposten
- Reservierungen
- Artikelverfolgung
- Lieferterminzusagen
- Reklamationen
- Montage/Fertigung
- Zahlungsprozessen
- Schnittstellen

Bei solchen Änderungen muss klar sein:

- welche Prozesse betroffen sind
- welche Tests durchgeführt wurden
- welche Risiken bestehen

### 7. Berechtigungen

Prüfe:

- neue Objekte in PermissionSets berücksichtigt?
- Zugriff fachlich korrekt?
- keine zu breiten Berechtigungen?
- indirekte Berechtigungen notwendig?
- Rollenmodell betroffen?

### 8. Tests

Prüfe:

- gibt es automatisierte Tests?
- gibt es manuelle Testhinweise?
- sind Randfälle beschrieben?
- wurde Regression berücksichtigt?
- wurde Build/Compile ausgeführt?
- wurden Diagnostics geprüft?

Wenn keine Tests vorhanden sind, muss das Review dies klar markieren.

### 9. Sicherheit

Prüfe:

- keine Secrets im Code
- keine Zugangsdaten
- keine produktiven Kundendaten
- keine Debug-Ausgaben mit sensiblen Daten
- keine unnötige Protokollierung personenbezogener Daten
- keine unsicheren Schnittstellenaufrufe

### 10. Dokumentation

Prüfe:

- PR-Beschreibung vorhanden?
- technische Änderung erklärt?
- Testhinweise vorhanden?
- Risiken genannt?
- ggf. Release Note vorhanden?
- ggf. Schulungs-/Anwenderhinweis notwendig?

## Review-Ausgabe

Reviews sollen diese Struktur nutzen:

```markdown
## Review-Ergebnis

Status: Freigabe / Änderungen notwendig / Blocker

## Zusammenfassung

...

## Blocker

- ...

## Verbesserungsvorschläge

- ...

## Testlücken

- ...

## Risiken

- ...

## Positiv aufgefallen

- ...

## Empfohlener PR-Kommentar

...
```

## Blocker

Blocker sind z. B.:

- Build schlägt fehl
- Code kompiliert nicht
- produktionskritisches Risiko ungeklärt
- Datenmigration ohne Review
- Berechtigungen massiv erweitert
- Secrets im Code
- fachliche Anforderung nicht erfüllt
- fehlende Tests bei kritischer Prozessänderung
- Änderung direkt auf `main`
- unklare Änderung an Buchungslogik

## Verbesserungsvorschläge

Verbesserungsvorschläge sind z. B.:

- bessere Benennung
- Logik aus Page in Codeunit verschieben
- Label statt hartcodiertem Text
- Filter vor Schleife setzen
- Testhinweis ergänzen
- PR-Beschreibung verbessern

## Freigabeempfehlung

Nutze:

```markdown
Status: Freigabe
```

nur, wenn keine Blocker vorhanden sind und die Änderung nachvollziehbar getestet oder testbar dokumentiert ist.

Nutze:

```markdown
Status: Änderungen notwendig
```

wenn die Änderung grundsätzlich richtig ist, aber nachgebessert werden sollte.

Nutze:

```markdown
Status: Blocker
```

wenn die Änderung nicht gemerged werden sollte.

## AI-Agent-Regeln

Wenn ein Agent reviewt:

- keine erfolgreichen Tests behaupten, die nicht ausgeführt wurden
- Buildstatus nicht erfinden
- Risiken klar benennen
- bei Unsicherheit konservativ bewerten
- keine Merge-Freigabe bei ungeklärten kritischen Prozessänderungen
- konkrete Verbesserungsvorschläge liefern
