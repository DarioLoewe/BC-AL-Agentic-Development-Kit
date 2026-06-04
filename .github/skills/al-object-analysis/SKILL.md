---
name: al-object-analysis
description: Analysiert AL-Repositories und findet relevante Tabellen, Pages, Codeunits, Reports, Events, Enums und Extensions.
---

# AL Object Analysis Skill

Nutze diesen Skill, wenn eine Änderung in einem Business-Central-AL-Repository geplant wird. Nicht direkt Code ändern.
Erst bestehende Patterns suchen.
Nicht nur Textsuche verwenden, wenn AL Symbolsuche/LSP verfügbar ist

## Vorgehen

1. Lies die fachliche Anforderung.
2. Suche relevante AL-Objekte.
3. Prüfe bestehende Events, Subscriber, Interfaces und Enums.
4. Identifiziere vorhandene Patterns im Repository.
5. Erstelle eine Liste betroffener Objekte.

## Output

```markdown
## Betroffene Objekte

- ...

## Relevante bestehende Logik

- ...

## Mögliche Erweiterungspunkte

- ...

## Risiken

- ...
```
