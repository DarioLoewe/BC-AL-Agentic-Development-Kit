---
name: al-code-review
description: Prüft AL-Codeänderungen auf Qualität, Upgradefähigkeit, Testbarkeit und Business-Central-Best-Practices.
---

# AL Code Review Skill

## Prüfkriterien

- Upgradefähigkeit
- Event-/Extension-Pattern
- Keine unnötige Businesslogik in Pages
- Labels für sichtbare Texte
- Berechtigungssätze berücksichtigt
- Tests oder Testhinweise vorhanden
- Performance bei großen Tabellen
- Saubere Fehlerbehandlung
- Keine Secrets
- Keine produktionskritischen Aktionen

## Output

```markdown
## Review-Zusammenfassung

...

## Kritische Punkte

- ...

## Verbesserungsvorschläge

- ...

## Freigabeempfehlung

Freigeben / Nicht freigeben / Mit Änderungen freigeben
```
