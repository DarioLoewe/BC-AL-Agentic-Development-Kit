# Modell-Switching-Konzept

**BC AL Agentic Development Kit — Agent-Modell-Zuordnung**
**Erstellt:** Phase 1 (2026-06-18)

---

## Prinzip

Jeder Agent hat ein zugewiesenes Modell im `model:`-Frontmatter seiner `.agent.md`-Datei.
Die Zuordnung folgt einem zweigeteilten Prinzip:

| Kategorie | Modell | Kriterium |
|-----------|--------|-----------|
| Orchestrierung, Planung, Analyse | `claude-opus-4` | Tiefes Reasoning, Ambiguitätsauflösung, komplexe Entscheidungen |
| Ausführung, Parsing, strukturierte Tasks | `claude-sonnet-4-5` | Strukturierte Codegenerierung, Diagnostics, Template-Erstellung |

**Geschätzte Kosteneinsparung:** ~60 % gegenüber Opus-4 für alle Tasks.

---

## Agent-Modell-Tabelle (Phase 1)

| Agent-Datei | Modell | Begründung |
|-------------|--------|------------|
| `main-agent.agent.md` | `claude-opus-4` | HiTL-Orchestrierung, Routing, Ambiguitätsauflösung |
| `al-auto-dev.agent.md` | `claude-opus-4` | Orchestrator-Fallback (backward-compat) |
| `al-planner.agent.md` | `claude-opus-4` | Technische Planung — Architect-Ersatz bis Phase 2 |
| `al-devops-reader.agent.md` | `claude-sonnet-4-5` | Strukturiertes Parsen — kein tiefes Reasoning nötig |
| `al-codebase-analyst.agent.md` | `claude-sonnet-4-5` | Objekt-Suche, strukturierte Analyse |
| `al-implementer.agent.md` | `claude-sonnet-4-5` | Routine-AL-Codegenerierung |
| `al-build-tester.agent.md` | `claude-sonnet-4-5` | Diagnostics-Parsing, Fix-Schleifen |
| `al-reviewer.agent.md` | `claude-sonnet-4-5` | Checklisten-getriebenes Review |
| `al-documenter.agent.md` | `claude-sonnet-4-5` | Template-basierte Textgenerierung |

### Geplante Zuordnungen (Phase 2)

| Agent-Datei | Modell | Begründung |
|-------------|--------|------------|
| `al-architect.agent.md` | `claude-opus-4` | JSON Plan Contract, Objekt-Planung, Abhängigkeits-Analyse |
| `al-validator.agent.md` | `claude-opus-4` | Semantische 5-Layer Anforderungsdeckungsprüfung |
| `al-coder.agent.md` | `claude-sonnet-4-5` | Code-Generierung, Build-Integration, Objekt-IDs |

---

## Technische Hinweise

### VS Code Copilot

Das `model:`-Frontmatter wird von VS Code Copilot als **Empfehlung** interpretiert.

**Einschränkung:** Das Modell kann nicht mid-Conversation automatisch gewechselt werden.
Der Main-Agent gibt im Checkpoint einen expliziten Wechsel-Hinweis:

> 💡 Für diesen Analyse-Schritt ist `claude-opus-4` empfohlen — wechsle im Chat-Header,
> falls noch nicht auf Opus.

**Enterprise-Tenants:** In Umgebungen mit fixem Mandanten-Modell wird `model:` möglicherweise
ignoriert. Das Framework funktioniert auch mit einem einzigen Modell — die Zuordnung ist eine
Kosten-Qualitäts-Empfehlung, kein hartes Requirement.

### Claude Code

Per-Subagent-Modell-Selektion ist über `--model`-Flag beim `runSubagent`-Aufruf möglich.
Das `model:`-Frontmatter wird direkt von Claude Code's Agent-Runner gelesen und erzwingt
das angegebene Modell pro Subagent-Aufruf.

### Annahmen (Assumptions Log)

| # | Annahme | Risiko wenn falsch |
|---|---------|-------------------|
| A1 | `model:`-Syntax (`claude-opus-4`, `claude-sonnet-4-5`) ist korrekt für aktuelle Copilot-Version | Model wird nicht erkannt — Fallback auf Default |
| A2 | VS Code Copilot wertet `model:` in `.agent.md` als Empfehlung aus | Frontmatter hat keinen Effekt — nur als Dokumentation funktional |
| A3 | Enterprise-Tenants können `model:` durch Tenant-Policy überschreiben | Erwartete Modell-Qualität nicht immer erreichbar |

---

## Änderungshistorie

| Datum | Phase | Änderung |
|-------|-------|----------|
| 2026-06-18 | Phase 1 | Initial erstellt — 9 Agents mit model:-Frontmatter |
