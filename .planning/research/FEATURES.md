# Feature Landscape — BC AL Agentic Development Kit (Main-Agent Milestone)

**Domain:** Agentic coding framework for Business Central AL development
**Researched:** 2026-06-18
**Sources:** PROJECT.md, CONVENTIONS.md, agent-policy.md, existing agent/skill analysis

---

## Context

This milestone transitions the existing `al-auto-dev` fire-and-forget orchestrator into a
**conversational Main-Agent architecture** with Human-in-the-Loop (HitL) checkpoints. Every
feature below is evaluated against one question: *does this make the Main-Agent vision work, or
make it uniquely good for BC AL development?*

Existing validated capabilities (already built — not features to build):
- `al-auto-dev` orchestrator + 6 sub-agents (planner, analyst, implementer, build-tester, reviewer, documenter)
- AL build/diagnostics, code review, test design, object analysis skills
- GSD planning workflow (70+ skills)
- Policy-enforced agent behavior (confidence rules, stop rules, blocker behavior)
- Azure DevOps AI tag system

---

## Table Stakes

> Features the Main-Agent vision **cannot function without**. Missing any one of these and the
> product regresses to fire-and-forget or breaks the Human-in-the-Loop contract.

### TS-1: Main-Agent Single Conversational Interface

**What:** One agent file (`main-agent.agent.md`) that the developer always talks to. The Main-Agent
owns the conversation, delegates silently to specialists, and surfaces only one voice to the user.

**Why Expected:** The current `al-auto-dev` is a trigger, not a conversation partner. The developer
has no way to ask questions mid-workflow, course-correct, or negotiate scope. Without this, the
entire milestone goal collapses.

**Complexity:** Medium — requires new agent file + strict delegation rules + response shaping
conventions.

**BC Specifics:**
- Must understand BC work-item vocabulary (Work Item, Feature Branch, Draft PR, BC Version)
- Must know when to escalate to Architect vs. Coder vs. Reviewer based on intent
- Must carry customer context (Betzold / Hermes / Tröber) across conversation turns

---

### TS-2: Human-in-the-Loop Checkpoint Protocol

**What:** After each specialist completes its work, the Main-Agent presents a **structured
checkpoint summary** and waits for explicit developer approval (`ja`/`weiter`/`abbrechen`) before
delegating to the next specialist. No specialist is started without the previous checkpoint being
approved.

**Why Expected:** The explicit PROJECT.md constraint is "Kein Schritt ohne explizite
Nutzer-Zustimmung". Without this, the framework is architecturally identical to the rejected
fire-and-forget model.

**Checkpoint pattern that works for AL pipelines:**

```
┌─────────────────────────────────────────────────┐
│ Checkpoint: Architect-Agent abgeschlossen        │
│                                                   │
│ Geplante Objekte: tableextension 50100, page 50101│
│ Aufwand: ~3h                                      │
│ Risiken: Buchungslogik berührt → Confidence 0.65  │
│                                                   │
│ Weiter mit Coder-Agent? [ja / anpassen / stopp]  │
└─────────────────────────────────────────────────┘
```

**Required checkpoint positions:**
1. After DevOps-Reader reads the work item (before planning starts)
2. After Architect-Agent produces the object plan (before coding starts)
3. After Validator-Agent checks requirement coverage (before PR creation)
4. After Reviewer-Agent produces the review (before PR is submitted as Draft)
5. Any time confidence drops below 0.60 (policy-mandated escalation)

**Complexity:** Medium — requires checkpoint summary template + approval gate logic in Main-Agent.

---

### TS-3: Checkpoint Summary Format (Structured Handoff)

**What:** Every specialist produces a **checkpoint-ready output block** that the Main-Agent can
surface verbatim or condense. The summary must always include: what was done, what decisions were
made, what risks were identified, and what the next step is.

**Why Expected:** Without a consistent summary format, the Main-Agent cannot reliably extract
the key facts to present at each checkpoint. The developer would need to read raw agent output.

**Required sections in every specialist output:**
```markdown
## Ergebnis (1–2 Sätze)
## Entscheidungen & Annahmen
## Risiken (confidence-Bewertung)
## Nächster Schritt (Empfehlung)
```

**Complexity:** Low — documentation/convention change, no code logic.

---

### TS-4: Session State Persistence

**What:** The Main-Agent persists the current workflow state across conversation turns and
optionally across sessions:
- Current work item / ticket reference
- Which specialist was last run and its output
- Pending checkpoint (waiting for developer approval)
- Customer context (which customer project is active)
- Branch name currently being worked on

**Why Expected:** Without state persistence, every developer message requires re-explaining context
("which WI are we on?", "what did the architect plan?"). This destroys the conversational UX.

**Implementation:** Use `session_store_sql` tool (already declared in `al-auto-dev` toolset) or a
lightweight `.planning/sessions/` directory. State file is customer+WI scoped.

**Complexity:** Medium — requires state schema design + read/write at each checkpoint.

**State schema (minimum viable):**
```json
{
  "customer": "Betzold",
  "work_item_id": "12345",
  "branch": "feature/wi-12345-vendor-block",
  "current_step": "architect_approved",
  "last_checkpoint": "2026-06-18T09:00:00",
  "pending_approval": false,
  "specialist_outputs": { "architect": "...", "coder": null }
}
```

---

### TS-5: DevOps-Reader (Read-Only Work Item Access)

**What:** A specialist that reads GitHub Issues and Azure DevOps Work Items and returns structured
content (title, description, acceptance criteria, tags, linked PRs). **Read-only — no writes.**

**Why Expected:** The developer's entry point is a work item. Without this, they must paste the
full ticket text into every conversation. The Main-Agent can't proactively understand scope.

**What it must parse:**
- Work item title, description, acceptance criteria
- Existing `ai:*` tags (to know current state: `ai:auto`, `ai:blocked`, `ai:done`)
- Linked branches and PRs
- Related work items (parent feature, child tasks)
- Azure DevOps area path (maps to customer/project)

**Complexity:** Low-Medium — tool integration (ADO API / GitHub API), read-only, no AL logic.

**Hard constraint from policy:** Never write to ADO or GitHub from DevOps-Reader. Tag updates
(`ai:done`, `ai:blocked`) are proposed at checkpoint, applied only with explicit developer approval
via a separate write step.

---

### TS-6: Architect-Agent with BC-Specific Object Planning

**What:** Plans the full object structure for a BC AL change before any code is written. Produces
a concrete, reviewable plan at the checkpoint.

**What an Architect-Agent needs for BC-specific object planning:**

1. **AL Symbol Resolution** — must query `al_downloadsymbols` output or existing `.alpackages` to
   know what tables, pages, codeunits, and events already exist in base app + installed extensions.
   Without this, it cannot apply the extension-first principle.

2. **Standard BC Table Catalog** — must know the canonical standard tables
   (Customer/18, Vendor/23, Item/27, Employee/5200, etc.) to avoid creating duplicate tables.

3. **Object ID Range Awareness** — must know the customer's assigned PTE range (50000–99999 or a
   sub-range per customer agreement) and avoid ID collisions with already-used IDs in the repo.

4. **BC Architecture Patterns** — must enforce:
   - Business logic → Codeunits (Mgt./Impl.)
   - Validation → Table triggers or dedicated Codeunit
   - Events → lean subscribers delegating to Codeunit
   - Enum over Option for new fields

5. **Extension-First Validation** — before proposing `table 50XXX "New Table"`, must verify
   that no standard BC table can be extended instead.

6. **Effort Estimation Model** — lightweight: count planned objects × complexity tier
   (simple field extension = 0.5h, new codeunit with business logic = 2–4h, new page = 1–2h).

7. **Permission Set Implication Check** — for every new table or codeunit, flag whether a new
   PermissionSet or extension of an existing one is needed.

8. **Thin Requirement Handling** — when the requirement doesn't specify objects, the Architect
   must make explicit assumptions visible (not hidden), mark them with confidence score, and
   list them in the checkpoint summary for developer review.

**Complexity:** High — requires AL symbol access, BC table knowledge, ID management logic,
effort estimation model.

**Output (checkpoint-ready):**
```markdown
## Geplante Objekte
| Objekt | Typ | Basis-Objekt | ID | Neu/Erweiterung |
|--------|-----|--------------|-----|-----------------|
| ...    | ... | ...          | ... | ...             |

## Aufwandsschätzung: ~Xh

## Annahmen
- ...

## Risiken (Confidence: X.XX)
- ...

## PermissionSet-Bedarf: ja/nein
```

---

### TS-7: Validator-Agent — Requirement Coverage Verification

**What:** After the Coder-Agent finishes, the Validator-Agent checks that every acceptance
criterion from the plan is actually covered by the implemented AL code. If gaps are found, it
triggers a correction loop back to the Coder-Agent (with specific remediation instructions).

**How a Validator-Agent verifies requirement coverage against AL code:**

1. **Acceptance Criteria → Object/Procedure Mapping**
   Each AC from the Architect's plan is mapped to a concrete AL object or procedure:
   - "Field X must appear on the Customer Card" → check for `pageextension` with `addlast` for
     field X
   - "Error Y must be raised when Z" → check for `Error(YErr, ...)` call in codeunit
   - "Event E must be raised" → check for `OnAfterXxx` event in codeunit

2. **AL Convention Compliance as Coverage Signal**
   - Every visible text is a Label (no hardcoded strings) → if missing, AC for user-facing error
     is only partially covered
   - Business logic in Codeunit, not Page → if logic is in page trigger, architecture AC fails
   - Build passes with 0 errors → if build fails, no AC is considered covered

3. **Test Coverage Check**
   For each AC, verify: does at least one test procedure in the test codeunit reference the
   relevant object/procedure? If not, flag as "untested AC".

4. **Diff-Based Verification**
   The Validator reads the git diff for the feature branch and maps changed files to planned
   objects. Any planned object not changed → flag as "planned but not implemented".

5. **Correction Loop Trigger**
   If coverage gaps found:
   - Generate a specific remediation task for Coder-Agent (not a vague "fix it")
   - Assign confidence reduction to the gap (missing Label = minor, missing core logic = critical)
   - Present gap list at checkpoint before triggering correction
   - Maximum 2 correction loops (mirrors build-rule's 3-loop cap)

**Complexity:** High — requires AC parser, object mapper, diff reader, test coverage analysis.

**Coverage Report (checkpoint-ready):**
```markdown
## Abdeckung: X/Y Akzeptanzkriterien erfüllt

| AC | Status | Belege | Lücke |
|----|--------|--------|-------|
| Feld X auf Customer Card | ✅ | pageextension 50101 | — |
| Error bei leerem Feld    | ❌ | — | Kein Error-Call gefunden |

## Korrektur-Aufgaben für Coder-Agent
1. ...

## Empfehlung: [weiter / Korrekturschleife]
```

---

### TS-8: Coder-Agent (Evolution of al-implementer)

**What:** Evolution of the existing `al-implementer` — adds HitL-awareness so it can be called
by the Main-Agent (not just by al-auto-dev fire-and-forget). Must accept correction tasks from
the Validator-Agent.

**Delta from existing al-implementer:**
- Accept structured correction tasks from Validator-Agent (not just initial plan)
- Report build result in checkpoint-ready format
- Support ID assignment from Architect's plan (avoid ID collisions)
- Explicitly handle translation files (`.xlf`) when captions/labels are added

**Complexity:** Low — mostly convention changes to existing agent.

---

### TS-9: Policy Enforcement at Every Layer

**What:** The `agent-policy.md` confidence rules, thin-requirement rules, and blocker rules must
be enforced by **every specialist**, not just by the orchestrator. The Main-Agent cannot be the
single enforcement point — if a specialist runs without policy awareness, the whole system is
unsafe.

**Specifically:**
- Every specialist must read `agent-policy.md` at the start of its system prompt
- Every specialist must emit a confidence score in its output
- Any specialist that hits confidence < 0.40 must halt and produce a blocker report
- The Main-Agent must route blocker reports to the checkpoint immediately (not continue)
- Booking logic / pricing / inventory / permissions / data migration → auto-block regardless of
  confidence (policy hard rules)

**Complexity:** Low — instruction file change + convention enforcement.

---

## Differentiators

> Features that make this framework specifically excellent for BC AL development. Not expected by
> generic agentic frameworks, but highly valued here.

### D-1: Customer-Specific Documentation Agents (Betzold, Hermes, Tröber)

**Value:** Each customer project has its own PR style, README language, comment tone, and
terminology. A single generic docs agent produces generic output.

**What customer-specific Doku-Agents need to know and store:**

| Knowledge Category | Examples |
|--------------------|----------|
| **AL Object Prefix/Namespace** | Betzold uses "BEZ", Hermes uses "HER", Tröber uses "TRO" |
| **PR Description Language** | Betzold: German formal; Hermes: German informal; Tröber: German technical |
| **Branch Naming Convention** | Standard `feature/wi-{id}-*` but customer may add prefix |
| **Work Item Comment Style** | Does customer expect bullet points, prose, or table format? |
| **README Structure** | Existing section order, heading style, version format |
| **Domain Vocabulary** | Customer-specific business terms (e.g., "Artikel-Klasse" vs. "Produktgruppe") |
| **Contact/Stakeholder Context** | Who is the product owner? What's their technical level? |
| **Feature History** | What was previously built for this customer (avoid re-explaining context) |
| **ID Range per Customer** | Which object ID sub-ranges are allocated to each customer's PTE |
| **AL Extension Path** | `C:\Users\dloewe\{Kunde}\{ExtensionName}\` — agent must know the path |

**Storage pattern:** One instruction file per customer:
`.github/instructions/customer-betzold.instructions.md` (style guide)
`.github/instructions/customer-hermes.instructions.md`
`.github/instructions/customer-troeber.instructions.md`

**Hard constraint:** Code conventions are framework-wide and uniform — Doku-Agents never change
code style, only documentation style.

**Complexity:** Low (per agent) — structured instruction files with style rules.

---

### D-2: BC-Aware Code-Research Helper

**Value:** Generic web search doesn't understand AL syntax, BC table names, or BC events.
A Code-Research helper that queries MS Learn, BC symbol tables, and GitHub examples
drastically reduces Architect and Coder hallucination risk.

**What it searches:**
- AL system codeunits (e.g., "how does `Sales-Post` codeunit raise events?")
- MS Learn BC developer docs ("how to create a PageExtension for Journal Lines")
- GitHub microsoft/BCApps examples
- Base application symbol resolution (table fields, event signatures)

**Complexity:** Medium — requires search tool integration + BC-specific query shaping.

---

### D-3: Model Switching (Opus for Planning, Sonnet for Execution)

**Value:** Planning (Architect) and validation (Validator) require deep reasoning. Code generation
(Coder) is pattern-heavy. Using Opus only where needed reduces cost without sacrificing quality.

**Switching logic:**
- `al-main-agent`: Opus (orchestration, checkpoint reasoning)
- `al-architect`: Opus (complex BC object planning, effort estimation)
- `al-validator`: Opus (requirement coverage reasoning)
- `al-coder`: Sonnet (code generation, mechanical)
- `al-reviewer`: Sonnet (pattern matching against conventions)
- `al-build-tester`: Sonnet (deterministic build runner)
- `al-docs-agent`: Sonnet (template filling)
- `al-devops-reader`: Sonnet (structured data extraction)

**Complexity:** Low — model selection in agent frontmatter or system prompt header.

---

### D-4: Azure DevOps AI Tag Integration

**Value:** The `ai:*` tag system (already designed) allows the framework to mark work items
with `ai:done`, `ai:blocked`, `ai:auto` etc. This creates a two-way integration between
the agent workflow and the DevOps backlog visible to the whole team.

**Tag write flow (HitL-safe):**
1. DevOps-Reader reads current tags
2. Workflow runs
3. At final checkpoint: Main-Agent proposes tag update (e.g., `ai:done`)
4. Developer approves → write step (separate from DevOps-Reader)
5. Never auto-written

**Complexity:** Low — API call at final checkpoint only.

---

### D-5: Thin Requirement Auto-Handling (BC-Specific Risk Stratification)

**Value:** BC development has high-risk areas (booking logic, pricing, inventory, permissions,
data migration) where thin requirements are dangerous. The framework can automatically stratify
risk and handle thin requirements differently depending on the BC domain.

**Risk tiers:**
| BC Domain | Thin Requirement Behavior |
|-----------|--------------------------|
| UI only (page extensions, captions) | Implement with assumptions documented |
| New fields (non-critical tables) | Implement minimal, note assumptions |
| Business logic (Codeunits) | Spike only, checkpoint before implement |
| Booking / Pricing / Inventory | Auto-block, generate clarification questions |
| Permissions / DataClassification | Auto-block, never expand without explicit AC |
| Data Migration | Auto-block, require explicit review checklist |

**Complexity:** Low — rule table in policy file, routing logic in Main-Agent.

---

### D-6: Tester-Agent (On-Demand AL + AI Tests)

**Value:** Test generation is expensive if always run. On-demand trigger (developer says "auch
Tests schreiben") keeps the workflow fast for simple changes.

**What it generates:**
- AL test codeunits with `[Test]` procedures mapped to ACs
- Test data helper procedures
- AI-assisted test scenarios (edge cases, negative tests)
- Integration with existing `al-test-design` skill

**Complexity:** Medium — builds on existing `al-test-design` skill, adds on-demand trigger.

---

### D-7: WebSearch Helper (MS Learn / BC Documentation)

**Value:** BC documentation evolves with each release. Real-time search prevents reliance on
stale training data for BC-specific syntax and APIs.

**Query scope:**
- Microsoft Learn BC developer reference
- BC release notes (what changed in target BC version)
- Stack Overflow / BC community forum for known issues
- GitHub microsoft/BCApps for event signatures

**Complexity:** Low — web search tool integration + BC-specific query templates.

---

## Anti-Features

> Things to **deliberately NOT build**, with explicit reasoning. Each anti-feature represents a
> rejected design decision — not a backlog item.

### AF-1: Autonomous End-to-End Execution Without Checkpoints

**What this would be:** A mode where the developer triggers the pipeline and receives a Draft PR
with no intermediate interaction (the existing `al-auto-dev` model extended further).

**Why to avoid:**
- Explicitly excluded in PROJECT.md: "Vollautomatische Pipeline ohne Nutzer-Checkpoints — verstößt
  gegen Human-in-the-Loop-Philosophie"
- High-confidence correctness is not achievable for BC business logic without domain expert review
- A wrong architectural decision (wrong table, wrong event) compounds through all subsequent steps
- Destroys trust: developer cannot explain/defend AI-generated code they never reviewed

**What to do instead:** Sequential checkpoints with minimal friction (one-word approval: "ja").

---

### AF-2: Parallel Specialist Execution Without Sequential Checkpoints

**What this would be:** Running Architect + Coder in parallel to save time.

**Why to avoid:**
- Coder depends on Architect output — parallel execution produces race conditions
- Policy: "Parallele Agent-Ausführung ohne Zustimmung" is Out of Scope
- Developer cannot review two specialist outputs simultaneously

**What to do instead:** Sequential pipeline with checkpoint gates. Speed comes from
model switching (Sonnet for fast execution steps), not from parallelism.

---

### AF-3: Auto-Merge or Auto-Publish

**What this would be:** Automatically merging the Draft PR to main after the review passes.

**Why to avoid:**
- Hard policy: "direkt auf main committen" and "automatisch mergen" are explicitly prohibited
- Production deployments must always involve human review and explicit trigger
- AppSource / ISV requirements (if ever applicable) require human sign-off

**What to do instead:** Always end with a Draft PR. Developer clicks "Ready for review" manually.

---

### AF-4: Writing to Azure DevOps / GitHub Without Explicit Approval

**What this would be:** DevOps-Reader that also writes — adding comments, changing tags,
creating work items automatically.

**Why to avoid:**
- Read-only is a hard architectural decision in PROJECT.md
- Writing to DevOps modifies the team's shared backlog — has side effects visible to others
- Tag state (ai:done, ai:blocked) must reflect reality; agent writing stale tags is worse than
  no tags

**What to do instead:** DevOps-Reader is strictly read-only. Tag updates are proposed at
checkpoint and applied only with developer approval via a separate, explicit write step.

---

### AF-5: Customer Data in Prompts or Outputs

**What this would be:** Including production customer data (actual Business Central records,
customer master data, real prices, real orders) in agent context to improve response accuracy.

**Why to avoid:**
- Policy: "produktive Kundendaten in Prompts verwenden" is explicitly prohibited
- Privacy / confidentiality risk for Betzold, Hermes, Tröber as real business customers
- AI provider terms of service typically prohibit production PII in prompt context

**What to do instead:** Use anonymized example data in test procedures. Never pull live BC data
into agent context.

---

### AF-6: Large-Scale Autonomous Refactoring

**What this would be:** Agent decides to restructure code beyond the scope of the current WI
(e.g., moving business logic from page triggers to codeunits across the whole extension).

**Why to avoid:**
- Policy: "große Refactorings ohne explizite Anforderung" is prohibited
- Scope creep destroys the WI → PR traceability
- Refactoring without tests creates hidden regressions

**What to do instead:** Scope each agent run to the current WI. Flag refactoring opportunities
in the review as suggestions, never auto-apply them.

---

### AF-7: Cross-Customer Context Leakage in Doku-Agents

**What this would be:** A shared Doku-Agent that learns from all customer projects and applies
learnings across customers (e.g., terminology from Betzold appearing in Hermes PRs).

**Why to avoid:**
- Business confidentiality: customer-specific feature names, terms, and roadmap details must
  stay siloed
- Different customers may have conflicting naming conventions

**What to do instead:** Three separate, stateless Doku-Agents. Each reads only its own
customer instruction file and the current WI context.

---

### AF-8: Secrets or Credential Management

**What this would be:** Storing or passing ADO tokens, BC API keys, or client secrets through
agent context.

**Why to avoid:**
- Policy: "Secrets lesen oder ausgeben" is explicitly prohibited
- Any credential in a prompt is a credential in the model provider's logs

**What to do instead:** Credentials live in environment variables or system keychain, accessed
only by tool integrations, never surfaced in agent text.

---

### AF-9: AppSource / ISV Compliance Automation

**What this would be:** Automatically enforcing `DataClassification` on all fields,
enforcing `Access` property rules, generating AppSource submission manifests.

**Why to avoid:**
- Explicitly Out of Scope in PROJECT.md: "AppSource / ISV-spezifische Anforderungen"
- Adds policy complexity that conflicts with the internal-development focus
- AppSource rules change per BC version; automated enforcement creates false confidence

**What to do instead:** Document AppSource requirements in a separate instruction file if ever
needed. Never enforce automatically.

---

### AF-10: Bypassing Confidence Rules via "Force" Flags

**What this would be:** A developer command like "just do it, ignore confidence" that overrides
the policy-mandated confidence thresholds.

**Why to avoid:**
- The confidence rules exist specifically for high-risk BC domains (booking, pricing, permissions)
- Providing an override creates liability: agent writes dangerous code, developer approved the
  override without understanding the risk
- Erodes trust in the confidence system over time

**What to do instead:** At low confidence, the agent produces a detailed blocker report and
a list of questions the developer can answer to raise confidence. Resolution goes through
normal checkpoint flow, not a force flag.

---

## Feature Dependencies

```
DevOps-Reader (TS-5)
    └── Main-Agent (TS-1)
            ├── Checkpoint Protocol (TS-2)
            │       └── Checkpoint Summary Format (TS-3)
            ├── Session State Persistence (TS-4)
            ├── Architect-Agent (TS-6)
            │       ├── Code-Research Helper (D-2)
            │       └── WebSearch Helper (D-7)
            ├── Coder-Agent (TS-8)
            │       └── [builds on existing al-implementer]
            ├── Validator-Agent (TS-7)
            │       └── [depends on Architect output + Coder output]
            ├── Tester-Agent (D-6)
            │       └── [on-demand, depends on Validator gap report]
            ├── Customer Doku-Agents (D-1)
            │       └── [depends on Coder + Reviewer output]
            └── Policy Enforcement (TS-9)
                    └── [applies to ALL specialists]

Model Switching (D-3) ← applies to all specialists, no dependency
ADO Tag Integration (D-4) ← depends on DevOps-Reader + final checkpoint
Thin Requirement Stratification (D-5) ← depends on Architect-Agent
```

**Critical path for MVP:**
`TS-1 → TS-2 → TS-3 → TS-4 → TS-5 → TS-6 → TS-8 → TS-7`

Tester-Agent (D-6), Doku-Agents (D-1), Model Switching (D-3), and ADO Tag Integration (D-4) can
be added in subsequent iterations without breaking the core HitL loop.

---

## MVP Recommendation

**Phase 1 — Core HitL Loop (must ship first):**
1. TS-1 Main-Agent agent file + delegation rules
2. TS-2 Checkpoint protocol (summary format + approval gate)
3. TS-3 Checkpoint summary format (standardized output template)
4. TS-5 DevOps-Reader (read-only ADO/GitHub)
5. TS-6 Architect-Agent (object planning, BC symbol awareness, effort estimation)
6. TS-8 Coder-Agent (evolution of al-implementer with HitL awareness)
7. TS-7 Validator-Agent (requirement coverage check + 2-loop correction)
8. TS-9 Policy enforcement in all new agents

**Phase 2 — Session Continuity:**
9. TS-4 Session state persistence

**Phase 3 — Customer Value:**
10. D-1 Customer Doku-Agents (Betzold, Hermes, Tröber)
11. D-3 Model switching
12. D-5 Thin requirement stratification

**Phase 4 — Research & Quality:**
13. D-2 Code-Research Helper
14. D-7 WebSearch Helper
15. D-6 Tester-Agent (on-demand)
16. D-4 ADO Tag Integration

**Defer indefinitely:**
- AF-1 through AF-10 — anti-features, never build

---

## Complexity Summary

| Feature ID | Feature | Complexity | Phase |
|-----------|---------|-----------|-------|
| TS-1 | Main-Agent single interface | Medium | 1 |
| TS-2 | HitL checkpoint protocol | Medium | 1 |
| TS-3 | Checkpoint summary format | Low | 1 |
| TS-4 | Session state persistence | Medium | 2 |
| TS-5 | DevOps-Reader (read-only) | Low–Medium | 1 |
| TS-6 | Architect-Agent (BC object planning) | High | 1 |
| TS-7 | Validator-Agent (requirement coverage) | High | 1 |
| TS-8 | Coder-Agent (HitL-aware implementer) | Low | 1 |
| TS-9 | Policy enforcement at all layers | Low | 1 |
| D-1 | Customer Doku-Agents ×3 | Low per agent | 3 |
| D-2 | Code-Research Helper | Medium | 4 |
| D-3 | Model switching | Low | 3 |
| D-4 | ADO Tag Integration | Low | 4 |
| D-5 | Thin requirement stratification | Low | 3 |
| D-6 | Tester-Agent (on-demand) | Medium | 4 |
| D-7 | WebSearch Helper | Low | 4 |

---

## Sources

- `C:\Users\dloewe\BC-AL-Agentic-Development-Kit\.planning\PROJECT.md` — requirements, constraints, out-of-scope
- `C:\Users\dloewe\BC-AL-Agentic-Development-Kit\.planning\codebase\CONVENTIONS.md` — AL + framework conventions
- `C:\Users\dloewe\BC-AL-Agentic-Development-Kit\.github\policies\agent-policy.md` — confidence rules, blocker rules
- Existing agent analysis: `al-auto-dev`, `al-planner`, `al-implementer`, `al-reviewer`, `al-documenter`
- BC AL architecture patterns (extension-first, codeunit delegation, enum over option)
