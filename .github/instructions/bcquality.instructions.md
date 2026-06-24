---
description: BCQuality — Pflichtquelle für BC-spezifisches Qualitätswissen bei Reviews und Code-Generierung
applyTo: "**/*.al"
---

# BCQuality Knowledge Base

**BCQuality** (https://github.com/microsoft/BCQuality) ist eine kuratierte Wissensdatenbank
für Business-Central-spezifische Qualitätsprobleme — ausschließlich Dinge, die ein LLM ohne
diese Basis falsch machen würde: falsche API-Semantik, nicht-offensichtliche Reihenfolgeregeln,
CodeCop-Regel-Nummern, BC-spezifische Performance-Footguns.

## Verfügbarkeit

| Modus | Pfad |
|-------|------|
| **Lokal (bevorzugt)** | `.bcquality/` — Git-Submodule, vollständig durchsuchbar |
| **Remote-Fallback** | `https://raw.githubusercontent.com/microsoft/BCQuality/main/` |

Submodule einrichten (einmalig):
```
git submodule add https://github.com/microsoft/BCQuality .bcquality
git submodule update --init --recursive
```

## Einstiegspunkt

Immer zuerst lesen: `.bcquality/skills/entry.md` (lokal) oder
`https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/entry.md`

Entry gibt einen Dispatch-Record zurück, der die zutreffenden Action-Skills benennt.

## Wichtigste Action-Skills

| Skill | Lokaler Pfad | Wann |
|-------|-------------|------|
| AL Code Review (Super-Skill) | `.bcquality/microsoft/skills/review/al-code-review.md` | Standard-Review |
| Performance | `.bcquality/microsoft/skills/review/al-performance-review.md` | Performance-Fokus |
| Security | `.bcquality/microsoft/skills/review/al-security-review.md` | Security-Fokus |
| Style | `.bcquality/microsoft/skills/review/al-style-review.md` | Code-Style |
| Upgrade | `.bcquality/microsoft/skills/review/al-upgrade-review.md` | Upgrade-Sicherheit |
| Error Handling | `.bcquality/microsoft/skills/review/al-error-handling-review.md` | Fehlerbehandlung |
| UI | `.bcquality/microsoft/skills/review/al-ui-review.md` | Pages/UI |
| Privacy | `.bcquality/microsoft/skills/review/al-privacy-review.md` | Datenschutz |

## Knowledge-Domänen (für direkte Suche)

```
.bcquality/microsoft/knowledge/performance/
.bcquality/microsoft/knowledge/security/
.bcquality/microsoft/knowledge/upgrade/
.bcquality/microsoft/knowledge/style/
.bcquality/microsoft/knowledge/error-handling/
.bcquality/microsoft/knowledge/ui/
.bcquality/microsoft/knowledge/testing/
.bcquality/microsoft/knowledge/privacy/
.bcquality/community/knowledge/   ← Community-Beiträge
.bcquality/custom/knowledge/      ← Projekt-spezifische Overrides (im Fork befüllen)
```

## Consumption-Pattern (4 Schritte)

```
1. SOURCE    — Knowledge-Ordner für die relevante Domäne bestimmen
2. RELEVANCE — Filtern nach bc-version, technologies, countries aus YAML-Frontmatter
3. WORKLIST  — Kandidaten auf die für den konkreten Code zutreffenden Artikel einschränken
4. ACTION    — Jede Regel gegen den Code prüfen → strukturiertes Finding mit Reference
```

## Finding-Format

Jedes BCQuality-Finding muss referenzieren:
```
- severity: error | warning | info
  message: "..."
  reference: ".bcquality/microsoft/knowledge/{domain}/{slug}.md"
  confidence: high | medium | low
```

## Wann BCQuality konsultieren

- **Code Review** — Immer. BCQuality ist Pflichtquelle für alle AL-Reviews.
- **Code-Generierung** — Bei Performance, Upgrade, Error-Handling, Security und API-Nutzung.
- **Neue Knowledge-Datei nötig?** — Wenn ein Agent ein BC-spezifisches Problem findet, für
  das kein Knowledge-File existiert → in `.bcquality/custom/knowledge/` ablegen
  (Format: YAML-Frontmatter + `## Description` + opt. `## Best Practice` + `## Anti Pattern`).
