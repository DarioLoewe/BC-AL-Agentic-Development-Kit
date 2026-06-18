---
description: ERGEBNIS-Block-Standard für alle BC AL Agentic Development Kit Agents
applyTo: ".github/agents/*.agent.md"
---

# ERGEBNIS-Block-Standard

## 1. Zweck

Alle Agents im BC AL Agentic Development Kit MÜSSEN ihre Ausgabe mit einem strukturierten
`## ERGEBNIS — {Agent-Name}` Block abschließen. Main-Agent scannt für diesen Header und
baut daraus den Checkpoint-Block. Abweichende Casing, fehlende Leerzeichen oder falsche
Bindestrichzeichen brechen das Parsing.

## 2. Header-Regel (verbindlich)

Der Header MUSS exakt sein:

```
## ERGEBNIS — {Agent-Name}
```

- **H2** (zwei Hash-Zeichen)
- **Gedankenstrich** (em dash `—`, nicht Bindestrich `-`)
- **Leerzeichen** vor und nach dem Gedankenstrich
- **Agent-Name** entspricht genau dem `name:` im Frontmatter

Korrekte Beispiele:
```
## ERGEBNIS — Architect
## ERGEBNIS — Coder
## ERGEBNIS — Validator
## ERGEBNIS — Reviewer
## ERGEBNIS — Tester
## ERGEBNIS — DevOps-Reader
```

Falsch (bricht Main-Agent-Parsing):
- `##ERGEBNIS — Architect` (kein Leerzeichen nach `##`)
- `## Ergebnis — Architect` (falsche Großschreibung)
- `## ERGEBNIS - Architect` (Bindestrich statt Gedankenstrich)
- `## ERGEBNIS — ` (ohne Agent-Name)
- `## ERGEBNIS` (ohne Gedankenstrich und Name)

## 3. Pflicht-Footer für alle Agents

Jeder ERGEBNIS-Block MUSS mit diesem Footer enden:

```markdown
### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: {Agent-Name} — {1 Satz was er tun wird}
- Offene Fragen: {oder "Keine"}
```

## 4. Templates pro Agent

### Template: al-architect

```markdown
## ERGEBNIS — Architect

**Ticket-ID:** {WI-ID}
**BC-Version:** {runtime + application aus app.json}
**Symbol-Status:** Geladen ✓ | Fehler: {Details}
**Aufwandsschätzung:** {XS|S|M|L|XL} — {Begründung in 1 Satz}
**contract_path:** `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json`

### JSON Plan Contract
```json
{ ... vollständiger Contract ... }
```

### Annahmen
- {Annahme 1 oder "Keine"}

### Risiken
- {Risiko 1 oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-coder — implementiert JSON Plan Contract
- Offene Fragen: {oder "Keine"}
```

### Template: al-coder

```markdown
## ERGEBNIS — Coder

**Ticket-ID:** {WI-ID}
**Plan Contract Version:** {plan_contract_version aus Contract}

### Implementierte Objekte
| Objekt | Typ | Aktion | Datei |
|--------|-----|--------|-------|
| {Name} | {tableextension|page|codeunit|...} | erstellt|erweitert | {Pfad} |

### Build-Ergebnis
- Status: ✓ Erfolgreich | ✗ Fehler | 🚨 BLOCKER
- Fix-Schleifen: {0|1|2|3}
- Diagnostics: {Anzahl Warnungen / Fehler oder "Keine"}

### Übersetzungseinträge
- {de-DE Einträge oder "Keine neuen"}

### Geänderte Dateien
- {Vollständiger Pfad 1}

### Offene Punkte
- {oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-validator — prüft AC-Abdeckung
- Offene Fragen: {oder "Keine"}
```

### Template: al-validator

```markdown
## ERGEBNIS — Validator

**Ticket-ID:** {WI-ID}
**Korrekturschleifen:** {0|1|2} von max. 2

### 5-Layer Prüfung
| Layer | Prüfpunkt | Status | Detail |
|-------|-----------|--------|--------|
| 1 | AC→Objekt-Mapping | ✓ OK / ✗ Lücke | {Detail} |
| 2 | AL-Konventionen | ✓ OK / ✗ Lücke | {Detail} |
| 3 | Test-Coverage | ✓ OK / ⚠ Warnung / ✗ Lücke | {Detail} |
| 4 | Diff-Verifikation | ✓ OK / ✗ Lücke | {Detail} |
| 5 | Korrektur-Trigger | — Kein Trigger / ⚡ Trigger | {Detail} |

### AC-Abdeckung
| AC | Objekt/Feld | Status |
|----|------------|--------|
| AC-1 | {Objekt.Feld} | ✓ |

### Offene Lücken
- {Lücke 1 oder "Keine"}

### Interpretation für Main-Agent
- Gesamtstatus: Freigabe | Korrektur erforderlich | BLOCKER
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer | al-coder (Korrektur) | ESKALATION
- Offene Fragen: {oder "Keine"}
```

### Template: al-reviewer

```markdown
## ERGEBNIS — Reviewer

**Ticket-ID:** {WI-ID}
**Review-Status:** Freigabe | Änderungen notwendig | Blocker

### Prüfergebnis
| Kriterium | Status | Hinweis |
|-----------|--------|---------|
| Upgradefähigkeit | ✓ / ⚠ / ✗ | {Detail} |
| AL-Best-Practices | ✓ / ⚠ / ✗ | {Detail} |
| Performance | ✓ / ⚠ / ✗ | {Detail} |
| Fehlerbehandlung | ✓ / ⚠ / ✗ | {Detail} |
| Testbarkeit | ✓ / ⚠ / ✗ | {Detail} |
| Berechtigungen | ✓ / ⚠ / ✗ | {Detail} |
| Labels | ✓ / ⚠ / ✗ | {Detail} |
| Keine unnötigen COMMITs | ✓ / ⚠ / ✗ | {Detail} |

### Blocker
- {oder "Keine"}

### Verbesserungsvorschläge
- {oder "Keine"}

### Testlücken
- {oder "Keine"}

### PR-Kommentar (Kurzfassung)
{2–3 Sätze für PR-Beschreibung}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-documenter | Blocker → Entwickler-Entscheidung
- Offene Fragen: {oder "Keine"}
```

### Template: al-tester

```markdown
## ERGEBNIS — Tester

**Ticket-ID:** {WI-ID}
**Test-Modus:** AL-Test-Codeunit | Manuelle Testhinweise | Beides

### Erstellte Tests
| Testmethode | Typ | Abgedecktes AC |
|-------------|-----|----------------|
| {DescriptiveName} | Automatisiert | AC-{N} |

### Test-Datei
- Pfad: {src/Tests/...Test.al}

### GIVEN/WHEN/THEN Zusammenfassung
{Für jeden Test ein Kurzblock:}
**{Testmethode}**
- [GIVEN] {Vorbedingung}
- [WHEN] {Aktion}
- [THEN] {Erwartetes Ergebnis}

### Nicht abdeckbare Testfälle
- {und Begründung, oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer (falls noch nicht erfolgt)
- Offene Fragen: {oder "Keine"}
```
