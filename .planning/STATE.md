# Project State

**Project:** BC AL Agentic Development Kit
**Milestone:** v1 — Main-Agent Architecture
**Phase:** Pre-Phase (not started)
**Updated:** 2026-06-18

---

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-18)

**Core value:** Der Entwickler beschreibt eine Anforderung — der Main-Agent holt alle nötigen Infos, plant, baut, testet und dokumentiert, mit Checkpoint-Zustimmung bei jedem Übergang.
**Current focus:** Pre-Phase — Foundations Cleanup

---

## Phase Status

| Phase | Name | Status | Blocker |
|-------|------|--------|---------|
| Pre | Foundations Cleanup | Not Started | — |
| 1 | Main-Agent + Session State + DevOps-Reader | Not Started | — |
| 2 | Spezialist-Refactoring | Not Started | — |
| 3 | Customer Docs Pipeline | Not Started | ⚠️ Hermes/Tröber Stil-Input fehlt |
| 4 | Helper Agents | Not Started | — |

---

## Current Position

```
Milestone : v1 — Main-Agent Architecture
Phase     : Pre-Phase
Plan      : none (not started)
Status    : Not started
Progress  : [░░░░░░░░░░░░░░░░░░░░] 0%
```

---

## Open Blockers

- **Phase 3 (Customer Docs):** Hermes- und Tröber-Dokumentationsstil, PR-Sprache und README-Konventionen müssen vom Entwickler vor Beginn der Phase-3-Planung bereitgestellt werden.
  - Benötigt: Je ein Beispiel-PR-Text für Hermes und Tröber mit Stil-Anmerkungen
  - Betroffen: DOCS-04 (`al-docs-hermes.agent.md`), DOCS-05 (`al-docs-troeber.agent.md`)
  - Einzige unblockierte Docs-Arbeit: DOCS-01, DOCS-02, DOCS-03, DOCS-06 (Betzold + Base)

---

## Accumulated Context

### Key Decisions

| Decision | Rationale | Phase |
|----------|-----------|-------|
| Pre-Phase zuerst | `ado/*` Wildcard ist sicherheitskritisch — muss vor Main-Agent-Build behoben sein | Pre |
| SESSION.md in `.planning/al-workflow/` | Durable State über VS Code-Neustarts — identisches Pattern zu GSD STATE.md | 1 |
| Checkpoint-Logik lebt nur im Main-Agent | Spezialisten geben strukturierten Output zurück; Main-Agent kontrolliert Flow | 1 |
| JSON Plan Contract (ARCH-04) | Maschinenlesbarer Handoff Architect→Coder — kein Fließtext-Parsing | 2 |
| Kunden-Docs-Agents lesen Stil aus `.github/instructions/docs-{kunde}.md` | Stateless, kein Session-State-Coupling, expliziter Stil-Override möglich | 3 |
| Helper-Agents als Leaf-Nodes | Nie direkt vom Nutzer aufrufbar, keine Checkpoint-Pflicht | 4 |

### Architecture Notes

- Framework-Repo: `C:\Users\dloewe\BC-AL-Agentic-Development-Kit\`
- AL-Extensions (Kunden): `C:\Users\dloewe\{Kunde}\{ExtensionName}\` (Geschwister-Verzeichnisse, nie im Framework-Repo)
- Vorhandene Basis: `al-auto-dev` als fire-and-forget Orchestrator mit 6 Unter-Agenten — wird zu `main-agent` refactored
- Neue Agent-Layer: 7 neue Agents (main-agent, al-devops-reader, al-architect, al-coder, al-validator, al-tester) + 4 Docs-Agents + 2 Helpers
- Neue Layer: `.planning/session/` (durable SESSION state), `.github/skills/al-docs-base/` (neue Skill-Layer)
- Modell-Strategie: Opus 4.x → Main-Agent, Architect, Validator | Sonnet 4.x → Coder, Reviewer, Docs, DevOps-Reader, Helpers

### Pitfalls to Watch

| ID | Pitfall | Phase | Mitigation |
|----|---------|-------|-----------|
| C-1 | Main-Agent bypass checkpoints silent | 1 | Named Checkpoint-Blöcke mandatory; policy rule "nie zwei Spezialisten in einer Turn-Sequenz" |
| C-2 | `runSubagent` unavailable in Chat mode | 1 | Pre-flight check + Manueller-Modus Fallback dokumentieren |
| C-3 | `ado/*` Wildcard ADO mutations | Pre | Erster Task der Pre-Phase |
| C-4 | AL symbol download failure | 2 | Hard stop in `al-build-validation` wenn `al_downloadsymbols` scheitert |
| C-5 | BC runtime version mismatch | 2 | `app.json` lesen als erster Pflicht-Schritt im Architect-Agent |

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases total | 5 (Pre + 4) |
| Requirements mapped | 43/43 |
| Plans created | 0 |
| Plans complete | 0 |
| Phases complete | 0 |

---

## Session Continuity

**Last session:** 2026-06-18 — Project initialized, roadmap created
**Next action:** `/gsd-plan-phase Pre-Phase` — Plan the Foundations Cleanup phase

**Context for next session:**
- Pre-Phase has 8 requirements (FOUND-01..08); all are small, independent file-level changes
- Start with FOUND-01 (`ado/*` wildcard) — highest security priority
- FOUND-06 (`debug.log` removal) + FOUND-05 (`.gitignore`) can be done in a single plan
- No external dependencies for Pre-Phase — all work is self-contained in framework repo

---
*State initialized: 2026-06-18*
*Last updated: 2026-06-18 after roadmap creation*
