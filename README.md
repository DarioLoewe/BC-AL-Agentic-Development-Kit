# BC AL Agentic Development Kit

> Agentic-AI-Framework für Business Central AL-Entwicklung — von der Anforderung bis zum Draft Pull Request.

---

## Was ist das?

Dieses Repository ist ein **internes Coding-Framework** für die Entwicklung von Microsoft Dynamics 365 Business Central Extensions mit AL.

Es enthält keine AL-Extensions, keine `.al`-Dateien und kein `src/`-Verzeichnis.

**Was es enthält:** Agents, Skills, Prompts, Policies und Instructions — alles, was nötig ist, um AL-Entwicklung strukturiert, nachvollziehbar und AI-gestützt abzuwickeln.

> **Business-Central-interne Copilot-Funktionen** innerhalb einer BC-App sind bewusst **nicht Bestandteil** dieses Setups.

---

## Grundprinzip

Ein Entwickler spricht ausschließlich mit dem **Main-Agent**.
Dieser orchestriert alle Spezialisten im Hintergrund — mit Human-in-the-Loop-Checkpoints nach jedem Delegationsschritt.

```
Entwickler
    ↓
main-agent  ←→  Checkpoint (Mensch bestätigt)
    ↓
al-devops-reader  →  al-architect  →  al-codebase-analyst
    →  al-coder  →  al-validator  →  al-reviewer  →  al-documenter
    ↓
Draft Pull Request
```

Der Mensch bleibt verantwortlich für:

- fachliche Prüfung
- Code Review
- Merge und Release
- produktive Veröffentlichung

---

## Entwicklungsablauf

```
Azure DevOps Work Item / Kundenanforderung
        ↓  al-devops-reader liest und parst das Ticket
        ↓  al-architect erstellt JSON Plan Contract + T-Shirt-Sizing
        ↓  al-codebase-analyst findet relevante Objekte und Events
        ↓  al-coder implementiert Code, führt Build aus, pflegt Objekt-IDs ein
        ↓  al-validator prüft Akzeptanzkriterien (5 Layer, max. 2 Korrekturrunden)
        ↓  al-reviewer bewertet Code nach BC-Konventionen
        ↓  al-documenter erstellt PR-Beschreibung und Testhinweise
        ↓
Draft Pull Request  →  Mensch reviewed und merged
```

---

## Repository-Struktur

```
BC-AL-Agentic-Development-Kit/         ← dieses Repo (kein AL-Code)
│
├── .github/
│   ├── copilot-instructions.md         ← Grundregeln für alle Agents
│   ├── policies/
│   │   └── agent-policy.md             ← verbindliche Sicherheits- und Ablaufregeln
│   ├── instructions/
│   │   ├── al-coding-standards.instructions.md
│   │   ├── al-testing.instructions.md
│   │   ├── al-review.instructions.md
│   │   ├── azure-devops.instructions.md
│   │   └── ergebnis-contract.instructions.md
│   ├── agents/
│   │   ├── main-agent.agent.md         ← einziger Gesprächspartner
│   │   ├── al-architect.agent.md
│   │   ├── al-coder.agent.md
│   │   ├── al-validator.agent.md
│   │   ├── al-reviewer.agent.md
│   │   └── ...                         ← weitere Agents (siehe unten)
│   ├── skills/
│   │   ├── al-build-validation/
│   │   ├── al-code-review/
│   │   ├── al-devops-workitem/
│   │   ├── al-object-analysis/
│   │   ├── al-test-design/
│   │   └── gsd-*/                      ← GSD-Workflow-Skills
│   └── prompts/                        ← Schnellstarter für häufige Tasks
│
├── docs/
│   └── model-switching.md              ← Modell-Zuordnung pro Agent
│
├── AGENTS.md                           ← Projektkontext für alle Agents
└── README.md
```

**AL-Extension-Projekte entstehen als Geschwister-Ordner:**

```
C:\Users\dloewe\
├── BC-AL-Agentic-Development-Kit\      ← Framework (dieses Repo)
├── {Kunde}\
│   └── {ExtensionName}\               ← AL-Projekt (eigenes Git-Repo)
└── ...
```

---

## Agents

### AL-Entwicklung

> Alle Agent-Dateien sind vorhanden. Aktuellen Implementierungsstand der Workflow-Phasen: siehe [`.planning/STATE.md`](.planning/STATE.md).

| Agent                 | Rolle                                                                       | Modell            |
| --------------------- | --------------------------------------------------------------------------- | ----------------- |
| `main-agent`          | Einziger Gesprächspartner, Orchestrator mit HiTL-Checkpoints                | claude-opus-4     |
| `al-devops-reader`    | Azure DevOps / GitHub — read-only Ticket-Parser                             | claude-sonnet-4-5 |
| `al-architect`        | JSON Plan Contract, Objekt-Planung, T-Shirt-Sizing, BC-Symbole              | claude-opus-4     |
| `al-codebase-analyst` | AL-Objekte, Events und Abhängigkeiten im Repo finden                        | claude-sonnet-4-5 |
| `al-coder`            | Code generieren, Build ausführen, Objekt-IDs pflegen, Übersetzungen anlegen | claude-sonnet-4-5 |
| `al-validator`        | 5-Layer-Akzeptanzkriterien-Prüfung, max. 2 Korrekturrunden, BLOCKER-Report  | claude-opus-4     |
| `al-reviewer`         | Code-Review nach BC-Konventionen                                            | claude-sonnet-4-5 |
| `al-tester`           | AL-Tests (GIVEN/WHEN/THEN) — **nur auf explizite Anforderung**              | claude-sonnet-4-5 |
| `al-documenter`       | PR-Beschreibung, Release Notes, Testhinweise                                | claude-sonnet-4-5 |
| `al-websearch`        | MS Learn / Web-Suche — Leaf-Node für al-architect + al-coder                | claude-sonnet-4-5 |
| `al-code-research`    | AL-Symbole und Code-Usages — Leaf-Node für al-architect + al-coder          | claude-sonnet-4-5 |

> `al-websearch` und `al-code-research` werden nie direkt aufgerufen — sie sind interne Hilfsagents.

### GSD-Workflow-Agents

Zusätzlich sind alle Standard-GSD-Agents vorhanden (`gsd-planner`, `gsd-executor`, `gsd-verifier` usw.).
Diese werden über GSD-Befehle aufgerufen, nicht direkt.

---

## Skills

Skills sind wiederverwendbare Fähigkeiten, die mehrere Agents nutzen.

| Skill                 | Zweck                                                                   |
| --------------------- | ----------------------------------------------------------------------- |
| `al-object-analysis`  | Tables, Pages, Codeunits, Reports, Enums und Erweiterungspunkte finden  |
| `al-build-validation` | Build/Compile, Symbol-Download, Diagnostics                             |
| `al-code-review`      | Qualität, Upgradefähigkeit, Testbarkeit, BC-Best-Practices              |
| `al-devops-workitem`  | Work-Item analysieren, Akzeptanzkriterien ableiten, Tasks strukturieren |
| `al-test-design`      | Testfälle entwerfen (fachlich und technisch)                            |

---

## Instructions

Instructions enthalten thematische Regeln, die automatisch auf passende Dateitypen angewendet werden.

| Datei                                 | Gilt für                    | Inhalt                                                 |
| ------------------------------------- | --------------------------- | ------------------------------------------------------ |
| `al-coding-standards.instructions.md` | `**/*.al`                   | Naming, Patterns, Events, Performance, Labels          |
| `al-testing.instructions.md`          | `**/*.al`                   | GIVEN/WHEN/THEN, Build-Regeln, Testdokumentation       |
| `al-review.instructions.md`           | `**/*.al`                   | Review-Kriterien, Risiken, Buchungslogik, Sicherheit   |
| `azure-devops.instructions.md`        | `**/*`                      | Work Items, Branches, PRs, AI-Tags, Definition of Done |
| `ergebnis-contract.instructions.md`   | `.github/agents/*.agent.md` | ERGEBNIS-Block-Standard für Agent-Ausgaben             |

---

## Policy

Die zentrale Agent Policy liegt in:

```
.github/policies/agent-policy.md
```

Sie hat **Vorrang** vor allen anderen Instructions, Skills und Agent-Beschreibungen.

### Was Agents dürfen

- Anforderungen analysieren und planen
- AL-Code lesen und schreiben
- Build und Diagnostics ausführen
- Reviews und Dokumentation erstellen
- Draft Pull Requests vorbereiten

### Was Agents nicht dürfen

- Direkt auf `main` committen oder automatisch mergen
- Produktiv veröffentlichen
- Secrets lesen oder ausgeben
- Produktive Kundendaten in Prompts verwenden
- Datenmigrationen ohne Review anlegen
- Buchungs- oder Lagerlogik ohne explizite Bestätigung ändern

### Confidence-Regel

| Confidence  | Aktion                                            |
| :---------: | ------------------------------------------------- |
| 0.80 – 1.00 | implementieren                                    |
| 0.60 – 0.79 | vorsichtig implementieren, Annahmen dokumentieren |
| 0.40 – 0.59 | nur technische Vorbereitung / Spike               |
| 0.00 – 0.39 | nicht implementieren, Blocker dokumentieren       |

### Thin-Requirement-Verhalten

Wenn eine Anforderung knapp formuliert ist:

- kleinste sichere Umsetzung wählen
- Annahmen sichtbar dokumentieren
- bei mehreren fachlichen Interpretationen: blocken und Rückfrage im Work-Item-Kommentar

---

## Azure DevOps — AI-Tags

Work Items steuern, was ein Agent tun darf:

| Tag              | Bedeutung                            |
| ---------------- | ------------------------------------ |
| `ai:auto`        | vollautomatisch verarbeiten          |
| `ai:plan-only`   | nur Analyse und Plan                 |
| `ai:implement`   | Umsetzung erlaubt                    |
| `ai:review-only` | nur Review                           |
| `ai:blocked`     | Agent konnte nicht sicher fortfahren |
| `ai:done`        | Agentenlauf abgeschlossen            |
| `bc-al`          | Business-Central-AL-Bezug            |

**Branch-Namensschema:**

```
feature/wi-{id}-kurzer-titel
bugfix/wi-{id}-kurzer-titel
ai/wi-{id}-kurzer-titel
```

**Commit-Format:**

```
WI #{id}: kurze Beschreibung
```

---

## Modell-Switching

Jeder Agent hat ein zugewiesenes Modell im `model:`-Frontmatter seiner `.agent.md`-Datei.

| Kategorie                        | Modell              | Einsatz                                               |
| -------------------------------- | ------------------- | ----------------------------------------------------- |
| Orchestrierung, Planung, Analyse | `claude-opus-4`     | Tiefes Reasoning, Ambiguität, komplexe Entscheidungen |
| Ausführung, Parsing, Code        | `claude-sonnet-4-5` | Strukturierte Codegenerierung, Diagnostics, Templates |

Geschätzte Kosteneinsparung gegenüber Opus-4 für alle Tasks: **~60 %**.

Details: [docs/model-switching.md](docs/model-switching.md)

> In VS Code Copilot ist `model:` eine Empfehlung, kein hartes Requirement. In Enterprise-Tenants mit fixem Mandanten-Modell wird das Frontmatter ggf. ignoriert — das Framework funktioniert auch mit einem einzigen Modell.

---

## Einstieg

### Vollautomatischer Ablauf

Öffne GitHub Copilot Chat, wähle den Agenten-Modus und starte mit:

```
Analysiere Work Item #12345 und setze es um.
```

Der Main-Agent übernimmt die Orchestrierung und fragt an den Checkpoints nach.

### Einzelne Tasks via Prompts

Prompts in `.github/prompts/` sind Schnellstarter für häufige Aufgaben:

| Prompt                | Wann nutzen                                           |
| --------------------- | ----------------------------------------------------- |
| `analyze-work-item`   | Work Item verstehen, ohne sofort umzusetzen           |
| `plan-al-change`      | technischen Plan für eine Anforderung erstellen       |
| `review-al-pr`        | Pull Request reviewen                                 |
| `explain-build-error` | Compilerfehler erklären und Lösungsvorschlag erhalten |

### GSD-Workflow-Befehle

Das Framework integriert das GSD-Workflow-System. Befehle beginnen mit `gsd-`:

| Befehl              | Zweck                                                |
| ------------------- | ---------------------------------------------------- |
| `gsd-progress`      | aktuellen Stand prüfen, nächsten Schritt vorschlagen |
| `gsd-plan-phase`    | Phase planen                                         |
| `gsd-execute-phase` | Phase ausführen                                      |
| `gsd-code-review`   | Code reviewen                                        |
| `gsd-debug`         | systematisches Debugging                             |

---

## Weiterführende Dokumente

| Dokument                                           | Inhalt                                        |
| -------------------------------------------------- | --------------------------------------------- |
| [AGENTS.md](AGENTS.md)                             | Vollständiger Projektkontext für alle Agents  |
| [docs/model-switching.md](docs/model-switching.md) | Modell-Zuordnung, Kosten, technische Hinweise |
| `.github/policies/agent-policy.md`                 | Verbindliche Sicherheits- und Ablaufregeln    |
| `.planning/ROADMAP.md`                             | Phasen und Anforderungen                      |
| `.planning/STATE.md`                               | Aktueller Projektstatus                       |
