---
name: al-build-validation
description: Führt AL Build/Compile, Symbol-Download und Diagnostics für Business-Central-Extensions aus.
---

# AL Build Validation Skill

Nutze diesen Skill nach jeder relevanten AL-Codeänderung. Bei Fehlern nicht raten. Erst Diagnostics auswerten. Keine produktive Veröffentlichung.

## Vorgehen

1. Prüfe, ob `.vscode/launch.json` im Projektordner existiert und eine gültige BC-Server-Konfiguration enthält (`server`, `serverInstance`, `authentication`).
2. Falls `launch.json` fehlt oder unvollständig ist: Frage den Nutzer nach den fehlenden Verbindungsdaten (Server-URL, Instanz, Authentifizierungstyp). **Credentials (Benutzername, Passwort) niemals selbst speichern oder ausgeben** – den Nutzer auffordern, diese manuell in `launch.json` einzutragen oder über VS Code Secrets zu hinterlegen.
3. Lege `launch.json` mit den gelieferten Werten an, sobald alle Pflichtfelder vorliegen.
4. Führe `al_downloadsymbols` automatisch aus.
5. Führe Build oder Compile aus.
6. Hole Diagnostics.
7. Fasse Fehler verständlich zusammen.
8. Schlage konkrete Korrekturen vor.

## Pflichtfelder launch.json (BC OnPrem / SaaS)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "BC Server",
      "type": "al",
      "request": "launch",
      "environmentType": "OnPrem",
      "server": "http://<server>",
      "serverInstance": "<instanz>",
      "authentication": "UserPassword",
      "breakOnError": true
    }
  ]
}
```

Benutzername und Passwort werden NICHT in `launch.json` gespeichert – der Nutzer trägt diese beim ersten Symbol-Download in das VS Code-Anmeldedialog ein.

## Bevorzugte AL Tools

- al_downloadsymbols
- al_build
<!-- - al_compile -->
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
