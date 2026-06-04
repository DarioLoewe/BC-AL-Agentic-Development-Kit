---
name: al-build-validation
description: Führt AL Build/Compile, Symbol-Download und Diagnostics für Business-Central-Extensions aus.
---

# AL Build Validation Skill

Nutze diesen Skill nach jeder relevanten AL-Codeänderung. Bei Fehlern nicht raten. Erst Diagnostics auswerten. Keine produktive Veröffentlichung.

## Vorgehen

1. Prüfe, ob Symbole aktuell sind.
2. Lade Symbole bei Bedarf herunter.
3. Führe Build oder Compile aus.
4. Hole Diagnostics.
5. Fasse Fehler verständlich zusammen.
6. Schlage konkrete Korrekturen vor.

## Bevorzugte AL Tools

- al_downloadsymbols
- al_build
- al_compile
- al_getdiagnostics

## Output

```markdown
## Buildstatus

Erfolgreich / Fehlerhaft

## Diagnostics

| Datei | Zeile | Regel | Problem | Vorschlag |
| ----- | ----: | ----- | ------- | --------- |

## Nächste Schritte

- ...
```
