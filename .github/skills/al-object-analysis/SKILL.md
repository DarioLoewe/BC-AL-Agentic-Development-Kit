---
name: al-object-analysis
description: Analysiert AL-Repositories und findet relevante Tabellen, Pages, Codeunits, Reports, Events, Enums und Extensions.
---

# AL Object Analysis Skill

Nutze diesen Skill, wenn eine Änderung in einem Business-Central-AL-Repository geplant wird. Nicht direkt Code ändern.
Erst bestehende Patterns suchen — sowohl im eigenen Repository als auch in der Base Application.
Nicht nur Textsuche verwenden, wenn AL Symbolsuche/LSP verfügbar ist.

## Vorgehen

### Schritt 0 — Symbole herunterladen (PFLICHT)

Bevor irgendeine Analyse beginnt:
1. `al_downloadsymbols` ausführen, damit die Base Application und System Application im LSP bekannt sind.
2. Prüfen, ob `.alpackages/` vorhanden und nicht leer ist.
3. Ohne heruntergeladene Symbole ist keine vollständige Analyse möglich — Schritt nicht überspringen.

### Schritt 1 — Standard-BC-Objekte prüfen (vor eigener Implementierung)

Vor der Planung neuer Tabellen, Pages oder Codeunits:
- Prüfen ob ein Standard-BC-Äquivalent existiert (z. B. `Employee`, `Resource`, `Contact`, `Bank Account`).
- `semantic_search` und `grep_search` nutzen, um im Repository nach vorhandenen Verweisen auf Standard-Objekte zu suchen.
- LSP-Lookup (`vscode_listCodeUsages`) für bekannte Standard-Tabellen-Kandidaten nutzen.
- Wenn ein Standard-Äquivalent existiert: **TableExtension bevorzugen**, keine neue Tabelle erstellen.

**Häufige Standard-BC-Tabellen, die fälschlicherweise neu erstellt werden:**
| Fachlicher Begriff | Standard-BC-Tabelle |
|---|---|
| Mitarbeiter / Angestellter | `Employee` (Tabelle 5200) |
| Kontakt / Ansprechpartner | `Contact` (Tabelle 5050) |
| Ressource | `Resource` (Tabelle 156) |
| Bankkonto | `Bank Account` (Tabelle 270) |
| Währung | `Currency` (Tabelle 4) |
| Maßeinheit | `Unit of Measure` (Tabelle 204) |
| Lagerort | `Location` (Tabelle 14) |
| Abteilung / Kostenträger | `Dimension` + `Dimension Value` |
| Lieferant | `Vendor` (Tabelle 23) |
| Debitor | `Customer` (Tabelle 18) |
| Artikel | `Item` (Tabelle 27) |

### Schritt 2 — Eigenes Repository analysieren

1. Lies die fachliche Anforderung.
2. Suche relevante AL-Objekte im eigenen Repo.
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
