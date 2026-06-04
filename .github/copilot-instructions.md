# Copilot Instructions — Business Central AL Development

## Kontext

Dieses Repository ist das **BC AL Agentic Development Kit** — ein Framework aus Skills, Agents, Instructions und Policies für die automatisierte AL-Entwicklung.

Es enthält selbst **keine AL-Extensions**.
AL-Extension-Projekte für Kunden werden außerhalb dieses Repositories angelegt.

## Verzeichnisstruktur

Neue AL-Extensions werden als Geschwister-Ordner neben dem Kit angelegt:

```
C:\Users\dloewe\
├── BC-AL-Agentic-Development-Kit\   ← dieses Framework-Repo (kein AL-Code)
├── {Kunde}\                          ← Kunden-Ordner
│   └── {ExtensionName}\              ← AL-Extension-Projekt (eigenes Git-Repo)
└── ...
```

Beispiel:

```
C:\Users\dloewe\KundeXY\FahrzeugVerwaltung\
```

**Agents müssen neue AL-Extension-Projekte immer außerhalb von `BC-AL-Agentic-Development-Kit\` anlegen.**
Kein AL-Code, keine app.json, keine `.al`-Dateien direkt im Kit-Repository.

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
