# Domain Pitfalls — BC AL Agentic Development Kit

**Domain:** Business Central AL Development with Human-in-the-Loop Agentic Orchestration
**Researched:** 2026-06-18
**Source basis:** Codebase audit (CONCERNS.md), agent-policy.md, PROJECT.md, codebase ARCHITECTURE + STACK maps
**Confidence:** HIGH — findings grounded in observed code, not generic AI advice

---

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, production incidents, or a collapsed pipeline.

---

### Pitfall C-1: Main-Agent Silent Bypass of Human Checkpoints

**What goes wrong:**
The Main-Agent orchestrates specialists sequentially. If the agent's instructions lack an explicit "stop and surface to user" step between each specialist delegation, it will proceed fire-and-forget — exactly the problem already present in `al-auto-dev`. The user sees only the final output, not the intermediate plan or review. A bad plan flows directly into bad code, and the user only discovers the mistake at the PR stage.

**Why it happens:**
LLM agents optimise for task completion. Without an explicit instruction to *pause and await approval*, they default to completing the full sequence. The current `al-auto-dev` is the evidence: it delegates all six sub-agents without surfacing intermediate results to the user.

**BC-specific consequences:**
- Architect-Agent creates a plan that adds fields to the wrong table (e.g., `Customer` instead of a TableExtension) → Coder-Agent implements it → build passes → Reviewer flags it → full rework required.
- Posting logic change (Buchungslogik) with `confidence = 0.72` gets implemented without user seeing the confidence warning. Policy requires block at `< 0.80` for critical paths.

**Warning signs:**
- Main-Agent responds with "Done — PR created" in a single turn without asking for approval at the Planning or Review stage.
- Specialist agent output does not appear in the conversation — only a summary does.
- User is surprised by what code was written.

**Prevention strategy:**
1. Every Main-Agent instruction file MUST contain an explicit template block after each delegation step:
   ```
   ## ⏸ CHECKPOINT — Warte auf Zustimmung
   Ich habe [Agent X] ausgeführt. Ergebnis:
   [ZUSAMMENFASSUNG]
   
   Soll ich mit [Agent Y] fortfahren? (ja / nein / ändern)
   ```
2. The Main-Agent markdown file must list "await user confirmation" as a named tool step or instruction, not as prose guidance.
3. Add a policy rule to `agent-policy.md`: "Main-Agent darf niemals zwei Spezialisten in derselben Turn-Sequenz starten."
4. Acceptance test: Run the full pipeline on a trivial task and verify the user sees at least 7 distinct checkpoint moments.

**Phase to address:** Main-Agent implementation phase (first new-functionality phase).

---

### Pitfall C-2: `runSubagent` Unavailability Causing Silent Pipeline Collapse

**What goes wrong:**
The entire orchestration chain depends on `runSubagent` (sub-agent spawning). When running in GitHub Copilot Chat (not the coding agent environment), this capability is absent. The orchestrator fails silently — it either errors out without a useful message or skips the delegation step and produces no output for that specialist.

**Why it happens:**
`al-auto-dev.agent.md` lists `agent` as a tool, which maps to `runSubagent`, but there is no fallback path documented. The Main-Agent will inherit this same dependency.

**BC-specific consequences:**
- If the Architect-Agent is not spawned, the Coder-Agent operates without a technical plan → generates structurally wrong AL code.
- If the Build-Tester is not spawned, code is never compiled → broken AL ships to draft PR.

**Warning signs:**
- Orchestrator turn completes very quickly (< 5 seconds) without specialist output.
- No "Starting al-planner..." or similar delegation message visible.
- Error message mentions "agent" or "runSubagent" tool not available.

**Prevention strategy:**
1. Add a pre-flight check to Main-Agent instructions:
   ```
   Prüfe zuerst: Ist das Tool `runSubagent` / `agent` verfügbar?
   Wenn NEIN: Gib dem Nutzer die manuelle Ausführungsreihenfolge aus und stoppe.
   ```
2. Document a "Manueller Modus" in the Main-Agent instructions: a numbered list of which agent to invoke manually and in what order, with the handoff prompt between each.
3. Add the same fallback to the existing `al-auto-dev.agent.md` (existing tech debt).
4. Never use wildcard or implicit tool dependencies — explicitly list `runSubagent` as a named dependency with an availability gate.

**Phase to address:** Main-Agent implementation phase; also backlog fix for `al-auto-dev`.

---

### Pitfall C-3: `ado/*` Wildcard Causing Unintended Azure DevOps Mutations

**What goes wrong:**
`al-auto-dev.agent.md` lists `"ado/*"` as a permitted tool — a wildcard that includes every Azure DevOps action including write operations. An agent reading a work item can trivially invoke `ado/work-items/update` and change state, assignee, or title without the user being aware.

**Why it happens:**
Wildcard tool grants are a convenience shorthand. They are not scoped to read-only operations. Any LLM reasoning error that concludes "I should mark this as In Progress" executes immediately against a live ADO instance.

**BC-specific consequences:**
- Work items accidentally marked as "Done" or "In Progress" before developer has reviewed.
- Comments added to tickets with incorrect information by an agent with wrong context.
- Work item title or story points changed by an agent guessing at values.
- DevOps-Reader is supposed to be read-only by design (PROJECT.md Decision), but `ado/*` wildcard violates that boundary.

**Warning signs:**
- Work item state changes that the developer did not request.
- ADO comment history shows changes made by the AI agent.
- Agent mentions "Ich habe das Work Item aktualisiert" without being asked.

**Prevention strategy:**
1. Replace `"ado/*"` in `al-auto-dev.agent.md` with an explicit allowlist immediately (existing tech debt):
   ```yaml
   tools:
     - ado/work-items/get
     - ado/work-items/list
     - ado/repos/get-pull-request
     - ado/repos/list-pull-requests
   ```
2. DevOps-Reader agent definition must only list the four read-only `ado/` tools above — never `ado/*/create`, `ado/*/update`, `ado/*/delete`.
3. Add to `agent-policy.md`: "ADO write operations (`ado/*/create`, `ado/*/update`) require explicit user instruction and Main-Agent confirmation checkpoint."
4. Document each permitted `ado/` tool with its scope in the agent file header.

**Phase to address:** DevOps-Reader agent phase; backlog fix for `al-auto-dev` must happen before Main-Agent goes live.

---

### Pitfall C-4: AL Symbol Download Failure Before Code Generation (Silent Wrong Code)

**What goes wrong:**
`al_downloadsymbols` can fail if the BC server is unreachable or authentication is stale. If the build validation skill proceeds without symbols, the agent generates AL code against an empty or stale symbol set. The code may reference non-existent procedures, wrong field names, or removed Base Application APIs. It compiles only if the missing references are caught at build time — and sometimes they are not (e.g., procedure names that exist but have changed signatures in a newer runtime).

**Why it happens:**
`al-build-validation` SKILL.md documents "Führe zuerst `al_downloadsymbols` aus" but does not include a hard stop if the download fails. Agents interpret soft instructions as best-effort.

**BC-specific consequences:**
- Code references `Customer.FindFirst()` with the wrong parameter signature for the target BC runtime version.
- `TableExtension` incorrectly extends a table that was renamed in the target BC version.
- `OnAfterPostSalesDoc` subscriber uses a signature that changed between runtime 8.0 and 12.0.
- Build appears to succeed locally against cached symbols but fails in the target customer environment.

**Warning signs:**
- `al_downloadsymbols` step completes in < 1 second (cached from a different session or project).
- Generated code references procedures not found in the BC documentation for the stated target version.
- Build passes with zero errors on first attempt on a complex change.

**Prevention strategy:**
1. Add a mandatory gate to `al-build-validation` SKILL.md:
   ```
   Schritt 0: Symbol-Download erzwingen
   Führe `al_downloadsymbols` aus.
   Wenn Fehler oder Exit-Code ≠ 0: SOFORT STOPPEN.
   Melde dem Nutzer: "Symbol-Download fehlgeschlagen. BC-Server erreichbar? Credentials aktuell?"
   Kein Code generieren oder bauen bis Symbole erfolgreich geladen sind.
   ```
2. Add BC version and runtime version to session state: `{ "bcVersion": "23.x", "alRuntime": "12.0" }` — agents must confirm this matches `app.json` before generating code.
3. Document the OnPrem vs SaaS symbol download difference (different auth flows) in the skill.

**Phase to address:** Build validation hardening (can be a quick fix phase or bundled into Coder-Agent phase).

---

### Pitfall C-5: BC Runtime Version Mismatch in Generated Code

**What goes wrong:**
No BC version or AL runtime version constraint is documented in the framework. The Coder-Agent will generate code based on the BC patterns it learned during training — which may be a different runtime version than the actual customer project. Customers Betzold, Hermes, and Tröber may run different BC versions.

**Why it happens:**
`agent-policy.md` has no version constraint. `al-coding-standards.instructions.md` has no `runtime` field guidance. There is no session state that carries `{ "customer": "Betzold", "bcRuntime": "11.0" }`.

**BC-specific consequences:**
- Generating `EnumExtension` syntax when the customer is on a runtime that uses `Option` fields.
- Using `Rec.SystemId` (runtime 4.0+) on a runtime 3.x project.
- Generating `procedure SetRange(FieldNo: Integer; ...)` overloads that didn't exist in older runtimes.
- Using `IsNullOrEmpty` on `Text` (added in a specific BC version) vs. `= ''` check.

**Warning signs:**
- Build errors referencing "member not found" or "syntax error" on valid-looking AL.
- Reviewer flags modern AL patterns in a project with old `app.json` `runtime` value.
- `app.json` in the customer AL project shows `"runtime": "8.0"` but generated code uses runtime 12.0 patterns.

**Prevention strategy:**
1. Make reading `app.json` mandatory as the first step in any Coder-Agent or Architect-Agent session:
   ```
   Lies immer zuerst die app.json des AL-Projekts.
   Extrahiere: "runtime", "application", "platform" und "target".
   Speichere als Session-Kontext: { runtimeVersion, applicationVersion, target }.
   Generiere Code nur für diese Versionsschranken.
   ```
2. Add version-specific code examples to `al-coding-standards.instructions.md` with `// runtime ≥ X.x required` annotations.
3. Add a compatibility check to `agent-policy.md`: "Wenn runtime < 10.0 und moderner Syntax verwendet wird → Blocker dokumentieren."

**Phase to address:** Coder-Agent and Architect-Agent implementation phases.

---

### Pitfall C-6: AL Extension Files Created Inside the Framework Repository

**What goes wrong:**
Agents executing in the framework repository context may create `.al` files, `app.json`, or `src/` directories inside `BC-AL-Agentic-Development-Kit/`. This violates the directory policy and pollutes the framework repo with extension code that belongs in a sibling directory.

**Why it happens:**
The working directory when an agent runs is typically the repo root. Any agent instructed to "create the file" without an explicit path defaults to the current working directory. The `applyTo: "**/*.al"` glob in instruction files activates if any `.al` file lands in the framework repo.

**BC-specific consequences:**
- Framework repo grows `.al`, `app.json`, `launch.json` artifacts that are tracked by git.
- `al-coding-standards.instructions.md` fires its rules on framework maintenance tasks, not AL development.
- `launch.json` with credentials gets committed to the framework repo (already happened with `.altestrunner/config.json`).

**Warning signs:**
- Agent says "Ich habe `src/CustomerExtension.al` erstellt" without specifying an absolute path.
- `git status` shows `.al` files in the framework repo root or any subdirectory.
- Build validation skill triggers inside the framework repo.

**Prevention strategy:**
1. Every agent that touches files MUST include this path guard in its instructions:
   ```
   Vor jeder Datei-Erstellungs-Operation:
   Prüfe: Befindet sich der Zielpfad außerhalb von BC-AL-Agentic-Development-Kit/?
   Wenn NEIN: Stoppe. Frage den Nutzer nach dem korrekten Pfad.
   Format: C:\Users\dloewe\{Kunde}\{ExtensionName}\
   ```
2. Add to `.gitignore`: `*.al`, `app.json` (in framework repo only — via `!/github/**` exclusion).
3. Main-Agent must confirm the target AL project path in the opening checkpoint before any specialist is delegated.

**Phase to address:** Main-Agent implementation phase (path confirmation as mandatory first checkpoint).

---

## Moderate Pitfalls

Mistakes that cause quality degradation, rework, or inconsistency — recoverable but costly.

---

### Pitfall M-1: Model Switching Quality Degradation (Opus Analysis → Sonnet Execution)

**What goes wrong:**
Opus produces a nuanced technical plan in rich prose. Sonnet receives that plan and must execute it faithfully. If the plan contains ambiguity, Sonnet will fill gaps with its own assumptions — which may be at a lower reasoning quality level than Opus. The structural plan is correct; the implementation detail is subtly wrong.

**BC-specific examples:**
- Opus plan: "Add a FlowField to the Customer table extension that calculates open invoice amounts." Sonnet interprets "open" as `Status = Open` instead of the correct BC pattern `Remaining Amount > 0 AND Open = true`.
- Opus plan: "Subscribe to OnAfterReleaseSalesDoc." Sonnet subscribes to the wrong event signature, passing `var SalesHeader` as value not reference.
- Opus plan recommends an `EventSubscriber` isolation pattern. Sonnet creates the subscriber in the same codeunit as posting logic (violating the standard).

**Why it happens:**
Handoff is done via free-form prose summary. The Sonnet-tier model receives ambiguous natural-language instructions and must resolve them.

**Warning signs:**
- Reviewer-Agent raises issues that were explicitly addressed in the Architect-Agent plan.
- Sonnet-generated code differs structurally from the Opus plan in ways the user didn't approve.
- Build passes but Validator-Agent finds requirements not covered by the implementation.

**Prevention strategy:**
1. Enforce a **structured handoff contract** between Opus planning and Sonnet execution. Opus must output a machine-readable plan, not free prose:
   ```json
   {
     "objects": [{ "type": "TableExtension", "extends": "Customer (18)", "fields": [...] }],
     "events": [{ "subscribe": "OnAfterReleaseSalesDocumentCode", "publisher": "Release Sales Document (414)" }],
     "codeunits": [{ "name": "Betzold Customer Calc", "methods": [...] }],
     "assumptions": ["Open invoice = Remaining Amount > 0 AND Open = true"]
   }
   ```
2. Architect-Agent must output this JSON block at the end of every plan.
3. Coder-Agent must reference the JSON block, not the prose narrative.
4. Checkpoint: user must confirm the JSON plan before Sonnet execution begins.

**Phase to address:** Architect-Agent + Coder-Agent implementation phases.

---

### Pitfall M-2: Confidence Score Miscalibration for BC-Specific Task Types

**What goes wrong:**
The confidence thresholds (0.80/0.60/0.40) are defined but have no calibration rubric for BC-specific tasks. Two agents rating the same task may reach 0.72 and 0.55 and take different actions (cautious implementation vs. technical preparation only). More critically, an agent may self-rate a complex posting logic change at 0.82 because it has seen similar AL code — when the correct rating should be 0.35 (insufficient acceptance criteria for a financial impact area).

**Why it happens:**
`agent-policy.md` defines the thresholds but not the measurement methodology. Each agent estimates confidence based on its own reasoning, with no anchor examples.

**BC-specific consequences:**
- Buchungslogik (posting logic) change implemented at confidence 0.75 → no blocker raised → wrong posting created → financial data integrity issue.
- Lager (inventory) change at 0.65 → "vorsichtig implementieren" → silent assumptions about warehouse setup → wrong result in non-standard warehousing.

**Warning signs:**
- Agent says "Confidence: 0.82" for a change to codeunit 80 (Sales-Post) without mentioning risks.
- No assumptions documented for a change that touches posting, prices, or permissions.
- Fix-loop exhausts all 3 attempts at confidence 0.78 — should have been blocked at planning.

**Prevention strategy:**
1. Add a calibration rubric to `agent-policy.md`:
   ```markdown
   ## Confidence Rubric (BC-spezifisch)
   
   | Task Type | Base Confidence | Modifier |
   |-----------|-----------------|----------|
   | Neues Feld in TableExtension (kein Pflichtfeld) | 0.90 | — |
   | Neue Seite (Page Extension mit Filter) | 0.85 | — |
   | Neuer EventSubscriber (kein Posting-Bezug) | 0.80 | — |
   | Bestehende Prozedur erweitern | 0.70 | −0.20 wenn Posting-Bezug |
   | Buchungslogik (Sales-Post, Purch-Post, etc.) | 0.35 | Basis — immer Blocker-Kandidat |
   | Datenmigration / Upgrade-Codeunit | 0.25 | Immer Blocker ohne explizite ACs |
   | Berechtigungsänderung | 0.30 | Immer explizite Zustimmung nötig |
   ```
2. Require that any confidence score below 0.80 on a Buchungslogik-touching task AUTOMATICALLY triggers a blocker, regardless of the raw score.

**Phase to address:** agent-policy.md hardening (can be a quick fix before Main-Agent launch).

---

### Pitfall M-3: Fix-Loop Exhaustion With No Escalation Path

**What goes wrong:**
`al-build-tester` runs up to 3 fix loops and then… stops. The policy says "maximal 3 Fix-Schleifen" but gives no instruction for what comes next. The agent silently halts, leaves broken code in the branch, and produces no escalation report. The developer has no structured information about what failed, what was tried, and what human intervention is needed.

**Why it happens:**
The stop rule is defined (`agent-policy.md`, `al-build-tester.agent.md`) but the escalation action is not.

**BC-specific consequences:**
- Build fails on AL compiler error `AL0468` (ambiguous function call) — agent tries 3 fixes, all wrong, stops. Developer opens the project to find 3 rounds of incremental changes that made things worse.
- Symbol-resolution error (missing extension dependency) cannot be fixed by code changes alone — requires `app.json` update or dependency install. Loop wastes 3 attempts without identifying this as the real cause.

**Warning signs:**
- Agent says "3 Versuche erschöpft" or similar without producing a structured failure report.
- Branch has 3–4 commits that all show build failures in diagnostics.
- No blocker ticket, no summary of what was tried, no next-step recommendation.

**Prevention strategy:**
1. Add to `agent-policy.md` and `al-build-tester.agent.md`:
   ```markdown
   ## Nach 3 Fehlgeschlagenen Fix-Schleifen
   
   1. Erstelle eine BLOCKER-REPORT.md im Projektverzeichnis mit:
      - Fehler-Code (z.B. AL0468, AL0132)
      - Fehler-Ursache (kurze Erklärung)
      - Versuchte Fixes (Loop 1, 2, 3 — was geändert, warum)
      - Benötigte Informationen vom Entwickler
      - Empfehlung: [Symbol fehlt | Abhängigkeit fehlt | Logik unklar | Anderes]
   2. Markiere den Branch mit einem Draft-PR-Kommentar: "⛔ Build fehlgeschlagen nach 3 Versuchen — BLOCKER-REPORT.md beachten"
   3. Stoppe. Kein weiterer automatischer Versuch.
   ```
2. The Main-Agent must surface the BLOCKER-REPORT.md content to the user at the next checkpoint.

**Phase to address:** Build validation hardening; also backport to `al-build-tester.agent.md`.

---

### Pitfall M-4: Session State Stale or Incorrect Context

**What goes wrong:**
The `session_store_sql` tool (used in `al-auto-dev`) enables persistent state across sessions. If state becomes stale (e.g., records "Planning complete" when the plan was rejected), the Main-Agent resumes from the wrong step. It may skip replanning, skip a checkpoint, or apply an old plan to a modified requirement.

**Why it happens:**
SQL-backed session state is written optimistically. If the user rejects a plan mid-session and closes the conversation, the state may record "plan approved" because the approval step was attempted but the rejection wasn't written back.

**BC-specific consequences:**
- Session state says "Coder-Agent completed for ticket BC-1042" but the user changed the requirement after the session. Main-Agent skips to Reviewer-Agent, reviewing stale code.
- Session state records the wrong customer context (`customer: "Hermes"` for a `Betzold` ticket) → wrong Kunden-Doku-Agent is invoked → wrong PR template used.
- Context window overflow: after 10+ tool calls with large AL diagnostics output, the session state includes stale file contents that contradict the current state of the AL project.

**Warning signs:**
- Main-Agent says "Ich setze bei Schritt 4 fort" when the user is starting a fresh request.
- Main-Agent references a ticket number or requirement the user did not mention in this session.
- Kunden-Doku-Agent produces output in the wrong language or style for the actual customer.

**Prevention strategy:**
1. Session state must include a `lastConfirmedStep` and a `userConfirmedAt` timestamp. On session start, Main-Agent must surface:
   ```
   Ich finde einen offenen Workflow-Stand: Ticket {X}, letzter bestätigter Schritt: {Y} ({timestamp}).
   Ist das noch aktuell? (ja / nein — neu starten)
   ```
2. State schema must include `{ ticketId, customer, alProjectPath, bcRuntime, lastStep, userConfirmedAt }` — all fields required.
3. State older than 48 hours must be flagged as potentially stale and re-confirmed before use.
4. Document `session_store_sql` tool scope in `agent-policy.md` — specifically that it must never write production customer data.

**Phase to address:** Session persistence phase; `session_store_sql` documentation is a prerequisite.

---

### Pitfall M-5: Customer-Docs-Agent Style Drift and Wrong Customer Injection

**What goes wrong:**
Three Kunden-Doku-Agents (Betzold, Hermes, Tröber) maintain customer-specific PR descriptions, README language, and documentation style. Over time, or when the wrong agent is invoked, style blends across customers. The most severe variant: Hermes ADO Work Item number cited in a Betzold PR, or vice versa.

**Why it happens:**
Each customer agent reads its style guide from a static file. If the style guide is not regularly updated and the agent fills gaps from its general training, generic patterns dominate. If session state has the wrong `customer` field, the wrong agent is invoked.

**BC-specific consequences:**
- Betzold PR description contains Hermes-specific field names or reference numbers.
- Release notes written in English for a customer who expects German.
- PR title uses Hermes ticket format `#1234` when Betzold uses `BETZ-1234`.
- AL caption language mismatch: captions in English in a German-language customer project.

**Warning signs:**
- PR description mentions fields, objects, or terminology that doesn't match the actual AL project.
- Language in documentation changes mid-document (German intro, English body).
- Reviewer-Agent flags PR description as referencing wrong ticket ID.
- `customer` field in session state differs from the customer directory in the AL project path.

**Prevention strategy:**
1. Each Kunden-Doku-Agent must start with a hard-coded customer identity assertion:
   ```
   Du bist der Betzold-Doku-Agent.
   Schreibe AUSSCHLIESSLICH für Kundenprojekte unter C:\Users\dloewe\Betzold\.
   Wenn der aktuelle AL-Projekts-Pfad NICHT mit C:\Users\dloewe\Betzold\ beginnt:
   STOPPE und melde dem Nutzer den Konflikt.
   ```
2. Extract customer identity from the AL project path (`C:\Users\dloewe\{Kunde}\`) — never from session state alone.
3. Create a style invariant checklist for each customer agent (language, ticket format, PR title pattern, label language) that is verified before output is produced.
4. Main-Agent must derive customer from path, not from user input: `customer = path.split('\\')[4]`.

**Phase to address:** Kunden-Doku-Agents phase.

---

## Minor Pitfalls

Mistakes that cause confusion or inefficiency — low impact but worth preventing.

---

### Pitfall m-1: Missing Entry-Point Prompts Break Onboarding

**What goes wrong:**
`README.md` lists `analyze-work-item.prompt.md` and `explain-build-error.prompt.md` as key entry points. Neither file exists. The most common developer tasks — "analyze this ADO ticket" and "explain this build error" — have no prompt scaffolding, forcing the developer to write freeform requests that miss context.

**Warning signs:**
- New session started without the two prompts producing structured output.
- Developer copy-pastes raw error output without the structured template.

**Prevention strategy:**
Create both prompts with YAML front-matter matching `plan-al-change.prompt.md` and `review-al-pr.prompt.md`. They should capture: ticket URL / error text + AL project path + BC version + customer name.

**Phase to address:** Quick fix — can be done in a standalone "missing foundations" phase before Main-Agent work begins.

---

### Pitfall m-2: `AGENTS.md` Provides No Framework Context to New Agent Sessions

**What goes wrong:**
`AGENTS.md` (the file AI agents read for project context at session start) contains only GSD boilerplate. A fresh agent session has no knowledge of the BC AL Agentic Development Kit, its agents, policies, or structure.

**Warning signs:**
- Agent asks "What is this project about?" when given context from `AGENTS.md`.
- Agent invokes GSD commands for a BC task that doesn't need them.

**Prevention strategy:**
Add a project context block to `AGENTS.md` above the GSD boilerplate: project name, purpose, key agent files, link to `agent-policy.md`, link to `README.md`, and the directory policy.

**Phase to address:** Pre-Main-Agent foundations phase.

---

### Pitfall m-3: Duplicate Policy Rules Creating Silent Drift

**What goes wrong:**
Security and policy rules are repeated in `agent-policy.md`, `copilot-instructions.md`, `al-coding-standards.instructions.md`, and individual agent files. When policy evolves (e.g., max fix loops changes from 3 to 5), only the primary file is updated. Agents loading only a secondary file apply the old rule.

**Warning signs:**
- Fix-loop limit set to 3 in `agent-policy.md` but an individual agent file says "try until success."
- Confidence thresholds differ between `agent-policy.md` and a copied block in an agent file.

**Prevention strategy:**
Replace all duplicate policy blocks with: `Lies und befolge: .github/policies/agent-policy.md` — this is already the recommended fix in CONCERNS.md and must be completed before the Main-Agent is built (the Main-Agent will load all specialist instructions and inherit contradictions).

**Phase to address:** Pre-Main-Agent foundations phase.

---

### Pitfall m-4: AL Label and Caption Language Policy Undefined

**What goes wrong:**
All framework documentation is German. Code examples in `al-coding-standards.instructions.md` use English captions. No rule specifies whether customer AL code should use German or English labels. Agents will produce mixed-language output.

**Warning signs:**
- Generated AL fields have English captions in a German-language customer project.
- Different agents produce labels in different languages for the same object.

**Prevention strategy:**
Add to `al-coding-standards.instructions.md`: "Captions und Labels folgen der Sprache des Kundenprojekts. Standard ist Deutsch, außer ein bestehendes Objekt verwendet ausschließlich Englisch — dann konsistent bleiben."

**Phase to address:** al-coding-standards update (quick fix, can bundle with m-1 and m-2).

---

### Pitfall m-5: No AL Extension Project Scaffold Causing Inconsistent Structure

**What goes wrong:**
The policy mandates that AL extensions live at `C:\Users\dloewe\{Kunde}\{ExtensionName}\`, but no `app.json` template or startup checklist exists. Agents must guess the initial structure, leading to inconsistency across Betzold, Hermes, and Tröber projects.

**Warning signs:**
- New AL project has incorrect `publisher`, `version`, or `runtime` in `app.json`.
- Project directory structure differs from what the build validation skill expects.
- Architect-Agent generates a plan that references a non-existent `src/` subdirectory.

**Prevention strategy:**
Create a project scaffold template for each customer: `app.json` with correct `publisher`, `version`, `runtime`, `dependencies`; `.vscode/launch.json` stub; `src/` directory structure. The Main-Agent should use this scaffold when a new AL extension is requested.

**Phase to address:** Project scaffold phase (can be parallel to or bundled with Coder-Agent phase).

---

## Phase-Specific Warnings

| Milestone Phase | Likely Pitfall | Priority | Mitigation |
|-----------------|---------------|----------|------------|
| Pre-foundations cleanup | m-1: Missing prompts | HIGH | Create `analyze-work-item`, `explain-build-error` prompts before any new agent work |
| Pre-foundations cleanup | m-2: Empty AGENTS.md | HIGH | Update AGENTS.md with project context block |
| Pre-foundations cleanup | m-3: Duplicate policy rules | HIGH | Single-source all policy to `agent-policy.md`; add `Lies: agent-policy.md` to all agents |
| Main-Agent design | C-1: Checkpoint bypass | CRITICAL | Explicit checkpoint template in every Main-Agent instruction transition |
| Main-Agent design | C-2: runSubagent no fallback | CRITICAL | Pre-flight check + documented manual mode |
| Main-Agent design | M-4: Stale session state | HIGH | State schema with `userConfirmedAt`; stale state confirmation on session start |
| Main-Agent design | C-6: Wrong directory for AL files | HIGH | Path guard in every file-creating specialist |
| DevOps-Reader agent | C-3: ADO wildcard mutation | CRITICAL | Replace `ado/*` with explicit read-only allowlist before this agent goes live |
| Architect-Agent | M-1: Model switching degradation | HIGH | Structured JSON plan handoff contract (not prose) |
| Architect-Agent | C-5: BC version mismatch | HIGH | Read `app.json` first; carry `{ runtimeVersion }` in session state |
| Coder-Agent | C-4: Symbol download failure | HIGH | Hard stop if `al_downloadsymbols` fails; no code generation without symbols |
| Coder-Agent | m-4: AL label language | MEDIUM | Language policy in `al-coding-standards.instructions.md` |
| Build validation | M-3: Fix-loop no escalation | HIGH | BLOCKER-REPORT.md template after 3 failures |
| Build validation | C-4: Symbol failure silent | HIGH | Exit-code gate on `al_downloadsymbols` |
| Reviewer-Agent | M-2: Confidence miscalibration | HIGH | BC-specific confidence rubric in `agent-policy.md` |
| Kunden-Doku-Agents | M-5: Style drift / wrong customer | HIGH | Path-derived customer identity; style invariant checklist |
| Kunden-Doku-Agents | M-5: Wrong customer injection | CRITICAL | Hard-coded path guard: wrong path = stop, do not produce output |
| Validator-Agent | M-1: Model quality gap | MEDIUM | Validator must compare against Opus JSON plan, not prose summary |
| Project scaffold | m-5: No AL project template | MEDIUM | Create per-customer `app.json` + launch.json template before Coder-Agent phase |
| GSD update cycle | (ongoing) | MEDIUM | Verify `classification: "user-owned"` agents not overwritten; pre-update review step |

---

## Sources

| Source | Type | Confidence |
|--------|------|------------|
| `.planning/codebase/CONCERNS.md` (codebase audit 2026-06-18) | Internal audit | HIGH |
| `.github/policies/agent-policy.md` | Project source | HIGH |
| `.planning/PROJECT.md` | Project source | HIGH |
| `.planning/codebase/ARCHITECTURE.md` | Internal codebase map | HIGH |
| `.planning/codebase/STACK.md` | Internal codebase map | HIGH |
| BC AL development patterns (embedded domain knowledge — runtime versioning, posting logic sensitivity, symbol management) | Domain knowledge | HIGH |
| Agentic framework design patterns (checkpoint enforcement, model switching handoff, session state management) | Domain knowledge | MEDIUM |

---

*Pitfalls research: 2026-06-18 — grounded in observed codebase issues, not generic AI advice*
