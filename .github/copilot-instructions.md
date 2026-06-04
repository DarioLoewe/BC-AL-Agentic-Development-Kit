# Copilot Instructions — Business Central AL Development

## Kontext

Dieses Repository enthält Microsoft Dynamics 365 Business Central AL-Extensions.

## Grundregeln

- Schreibe upgradefähigen AL-Code.
- Bevorzuge Events, Interfaces und Erweiterungspunkte gegenüber invasiven Änderungen.
- Ändere nur Dateien, die für die Aufgabe notwendig sind.
- Führe nach Codeänderungen immer Build/Compile und Diagnostics aus.
- Keine direkten Änderungen auf main.
- Keine produktiven Veröffentlichungen.
- Keine Secrets, Kundendaten oder Zugangsdaten ausgeben.
- Sichtbare Texte als Labels definieren.
- Businesslogik nicht unnötig in Pages platzieren.
- Performance bei großen Tabellen beachten.
- Keine unnötigen COMMITs.
- Keine ungeprüften GETs ohne Fehlerbehandlung.
- Keine Schreibvorgänge in TryFunctions
- Keine ungetesteten Änderungen pushen.
- Keine Änderungen ohne Code Review.
- Keine Änderungen ohne Tests.
- Keine Änderungen ohne Dokumentation.

## Agent Policy

Für alle agentischen Workflows gilt zusätzlich:

`.github/policies/agent-policy.md`

Diese Policy definiert Sicherheitsregeln, Thin-Requirement-Verhalten, Confidence-Regeln, Build-Regeln und Stop-Regeln.
