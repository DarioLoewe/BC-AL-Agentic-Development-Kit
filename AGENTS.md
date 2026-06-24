<!-- GSD Configuration — managed by gsd-core installer -->
# Instructions for GSD

- Use the gsd-core skill when the user asks for GSD or uses a `gsd-*` command.
- Treat `/gsd-...` or `gsd-...` as command invocations and load the matching file from `.github/skills/gsd-*`.
- When a command says to spawn a subagent, prefer a matching custom agent from `.github/agents`.
- Do not apply GSD workflows unless the user explicitly asks for them.
- After completing any `gsd-*` command (or any deliverable it triggers: feature, bug fix, tests, docs, etc.), ALWAYS: (1) offer the user the next step by prompting via `ask_user`; repeat this feedback loop until the user explicitly indicates they are done.
<!-- /GSD Configuration -->

> **Hinweis:** GSD ist eine optionale Workflow-Integration. Das BC AL Kit ist ohne GSD vollständig nutzbar. GSD-Befehle (`gsd-*`) werden nur verarbeitet, wenn der Entwickler sie explizit aufruft.

---

# BC AL Agentic Development Kit — Projektkontext

## Was ist dieses Repository?

Ein agentic Coding-Framework für Business Central AL-Entwicklung. Der Entwickler spricht
ausschließlich mit einem **Main-Agent**, der als Orchestrator fungiert und alle Spezialisten im
Hintergrund koordiniert — mit Human-in-the-Loop-Checkpoints nach jedem Delegationsschritt.

**Wichtig — Repository-Scope:** Dieses Repo enthält ausschließlich Framework-Dateien (Agents,
Skills, Prompts, Policies, Instructions). Keine AL-Extensions, keine `.al`-Dateien, kein
`src/`-Verzeichnis. AL-Projekte entstehen als Geschwister-Ordner:
`C:\Users\dloewe\{Kunde}\{ExtensionName}\`

## Verbindliche Policy (gilt für alle Agents in diesem Repository)

**`.github/policies/agent-policy.md`** ist die alleinige Policy-Quelle.

Sie regelt: Confidence-Regeln, Stop-Rules, Blocker-Verhalten, Fix-Loop-Eskalation, erlaubte und
nicht erlaubte Aktionen. Diese Policy hat Vorrang vor allen anderen Anweisungen.

## Agent-Rollen

### Aktuelle Agents (vorhanden)

| Agent-Datei | Rolle | Status |
|-------------|-------|--------|
| `.github/agents/main-agent.agent.md` | Einziger Gesprächspartner, Orchestrator mit Checkpoints | Aktiv |
| `.github/agents/al-devops-reader.agent.md` | ADO/GitHub read-only Ticket-Reader | Aktiv |
| `.github/agents/al-architect.agent.md` | JSON Plan Contract, BC-Symbole, T-Shirt-Sizing, Objekt-Planung | Aktiv |
| `.github/agents/al-codebase-analyst.agent.md` | AL-Objekte, Events, Abhängigkeiten im Repo finden | Aktiv |
| `.github/agents/al-coder.agent.md` | Code + Build + Objekt-IDs + Übersetzungen | Aktiv |
| `.github/agents/al-validator.agent.md` | 5-Layer AC-Prüfung, max. 2 Korrekturschleifen, BLOCKER-Report | Aktiv |
| `.github/agents/al-reviewer.agent.md` | Code-Review nach BC-Konventionen | Aktiv |
| `.github/agents/al-tester.agent.md` | AL-Tests (GIVEN/WHEN/THEN), nur auf explizite Anforderung | Aktiv |
| `.github/agents/al-documenter.agent.md` | PR-Beschreibung, Release Notes, Testhinweise | Aktiv |
| `.github/agents/al-websearch.agent.md` | MS Learn / Web-Suche — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv |
| `.github/agents/al-code-research.agent.md` | AL-Symbole, Code-Usages — Leaf-Node-Hilfsagent für al-architect + al-coder | Aktiv |

### Geplante Agents (noch nicht implementiert)

| Agent-Datei | Rolle | Phase |
|-------------|-------|-------|
| `al-docs-coordinator.agent.md` | Kunden-Doku-Routing nach Projektpfad | Phase 3 |
| `al-docs-betzold/hermes/troeber.agent.md` | Kunden-spezifische Doku-Agents | Phase 3 |

## Skills und Prompts

- **Skills** (`.github/skills/al-*/`): AL-spezifische Skill-Definitionen — Build-Validation,
  Code-Review, Test-Design, DevOps-Workitem, Object-Analysis
- **Prompts** (`.github/prompts/`): Entry-Point-Prompts für häufige Tasks —
  `plan-al-change`, `review-al-pr`, `analyze-work-item`, `explain-build-error`
- **Instructions** (`.github/instructions/`): AL-Coding-Standards, Testing, Review, Azure DevOps

## Weiterführende Dokumente

- **Phasen und Anforderungen:** `.planning/ROADMAP.md`
- **Aktueller Status:** `.planning/STATE.md`
- **Projektkontext:** `.planning/PROJECT.md`
- **Policy (verbindlich):** `.github/policies/agent-policy.md`

## GSD-Framework-Agents

Die folgenden Agents im Verzeichnis `.github/agents/` gehören zum separaten **GSD (Guided Software Development) Framework** und sind nicht Teil des BC AL Workflows:

| Präfix | Beispiel-Agents | Aufruf über |
|--------|----------------|------------|
| `gsd-*` | `gsd-planner`, `gsd-executor`, `gsd-verifier`, `gsd-code-reviewer`, ... | `gsd-*`-Befehle |

Diese Agents werden vom Main-Agent **nicht** direkt aufgerufen. Sie sind nur aktiv, wenn der Entwickler einen `gsd-*`-Befehl eingibt.

