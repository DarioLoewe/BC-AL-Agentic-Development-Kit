# Coding Conventions

**Analysis Date:** 2026-06-18

## Overview

This is a **framework repository** — it contains agents, skills, instructions, policies, and prompts for AL development. It does NOT contain AL extension code. Conventions are split into two layers:

1. **Framework conventions** — how agents, skills, instructions, and prompts are structured inside this kit
2. **AL coding standards** — the rules the framework enforces on actual AL extension projects

---

## Framework File Naming Patterns

**Instructions:**
- Pattern: `{al-topic}.instructions.md`
- Location: `.github/instructions/`
- Examples: `al-coding-standards.instructions.md`, `al-testing.instructions.md`, `al-review.instructions.md`
- Frontmatter required: `description:` and `applyTo:` fields

**Agents:**
- Pattern: `{al-role}.agent.md` (BC-specific) or `gsd-{role}.agent.md` (GSD framework)
- Location: `.github/agents/`
- Examples: `al-auto-dev.agent.md`, `al-planner.agent.md`, `gsd-executor.agent.md`
- Frontmatter required: `name:`, `description:`, optional `tools:` and `agents:` arrays

**Skills:**
- Pattern: subdirectory `{al-skill}/SKILL.md` or `gsd-{command}/SKILL.md`
- Location: `.github/skills/`
- Examples: `al-build-validation/SKILL.md`, `al-test-design/SKILL.md`
- Frontmatter required: `name:`, `description:`

**Policies:**
- Pattern: `{topic}.md`
- Location: `.github/policies/`
- Example: `agent-policy.md`
- No frontmatter; plain Markdown with `#` heading

**Prompts:**
- Pattern: `{verb}-{al-topic}.prompt.md`
- Location: `.github/prompts/`
- Examples: `plan-al-change.prompt.md`, `review-al-pr.prompt.md`
- Frontmatter required: `description:`

## Framework Document Structure Conventions

**Instruction Files (`.github/instructions/`):**
```markdown
---
description: [Purpose in German]
applyTo: "**/*.al"
---

# [Topic] Instructions

[Body with ## headings for each rule area]
```

**Agent Files (`.github/agents/`):**
```markdown
---
name: al-{role}
description: [One-line purpose in German]
tools: ["read", "search", "edit", "terminal", ...]
agents:
  - al-subagent-name
---

# AL {Role} Agent

[Role description]

## Nutze diese Skills

- al-skill-name

## Regeln

- [Rule]

## Output

```markdown
## [Output section]
...
```
```

**Skill Files (`.github/skills/{name}/SKILL.md`):**
```markdown
---
name: al-{skill}
description: [One-line purpose in German]
---

# AL {Skill} Skill

## Vorgehen

1. [Step]

## Output

```markdown
## [Output section]
```
```

---

## Framework Naming Conventions

**Files:** kebab-case for all framework files (`al-coding-standards`, `al-build-tester`)

**Skill/agent names:** match the directory name exactly (e.g., directory `al-build-validation/` → `name: al-build-validation`)

**Language:** German for descriptions, rule texts, and output labels; English allowed in AL code examples and technical identifiers

---

## AL Object Naming Conventions

Defined in `.github/instructions/al-coding-standards.instructions.md`, enforced by all agents:

**One object per file.** File name must match the object name.

**Object naming examples:**
```al
tableextension 50100 "Customer Ext." extends Customer
pageextension 50101 "Customer Card Ext." extends "Customer Card"
codeunit 50102 "Sales Validation Mgt."
```

**Naming rules:**
- Use full, descriptive names — no cryptic abbreviations
- Follow existing naming conventions already present in the target repository
- Codeunit suffix: `Mgt.` for management, `Impl.` for implementation details
- Extensions: append `Ext.` to base object name
- No abbreviations that obscure meaning

**Variables:**
- Descriptive names (e.g., `Customer`, `SalesHeader`, `ExternalReference`)
- No single-letter or abbreviated variable names
- Record variables named after the table (e.g., `SalesLine` for `Sales Line`)

---

## AL Field and Label Naming

**Field definition pattern:**
```al
field(50100; "External Reference"; Code[50])
{
    Caption = 'External Reference';
    DataClassification = CustomerContent;
}
```

**Error label naming:** suffix `Err` appended to a descriptive name
```al
EmptyReferenceErr: Label 'External Reference must not be empty.';
CustomerNotFoundErr: Label 'Customer %1 not found.';
CustomerBlockedErr: Label 'Customer %1 is blocked.';
```

**Label usage — required pattern:**
```al
// Wrong:
Error('Customer is blocked.');

// Correct:
CustomerBlockedErr: Label 'Customer %1 is blocked.';
Error(CustomerBlockedErr, Customer."No.");
```

All visible text — error messages, captions, tooltips — MUST be defined as Labels or Captions. Never hardcode strings.

---

## AL Code Style

**Procedure design:**
- Use `local procedure` for private logic
- Small, focused procedures with one clear responsibility
- Descriptive procedure names (e.g., `ValidateExternalReference`, `CheckCustomerBlocked`)
- No unnecessary global variables
- No side effects without documentation

**Page field pattern:**
```al
addlast(General)
{
    field("External Reference"; Rec."External Reference")
    {
        ApplicationArea = All;
        ToolTip = 'Specifies the external reference for this record.';
    }
}
```

**Event subscriber pattern:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
begin
    // Delegate to codeunit — keep subscriber lean
end;
```

---

## AL Architecture Conventions

**Business logic placement:**
- Business logic → Codeunits (not Pages or Page Extensions)
- Validation → Table triggers or dedicated Codeunits
- Page triggers → only UI interaction, no complex logic
- Event subscribers → kept lean; delegate to separate Codeunit when logic is non-trivial

**Extension-first approach:**
1. Before creating a new table: run `al_downloadsymbols`, check if a standard BC table exists
2. If standard equivalent exists → create `tableextension`, never a new table
3. Prefer Events and extension points over invasive modifications

**Common standard BC tables (do not duplicate):**

| Business concept | Standard BC table |
|---|---|
| Employee/Staff | `Employee` (Table 5200) |
| Contact | `Contact` (Table 5050) |
| Resource | `Resource` (Table 156) |
| Bank Account | `Bank Account` (Table 270) |
| Vendor | `Vendor` (Table 23) |
| Customer | `Customer` (Table 18) |
| Item | `Item` (Table 27) |
| Location | `Location` (Table 14) |

**Event subscribers:**
- Set `SkipOnMissingLicense` and `SkipOnMissingPermission` consciously
- No unnecessary database changes in high-frequency events

**Enums preferred over Option fields** for new code.

---

## AL Error Handling Conventions

**Required pattern:**
```al
// Wrong — blind Get():
Customer.Get(CustomerNo);

// Correct:
if not Customer.Get(CustomerNo) then
    Error(CustomerNotFoundErr, CustomerNo);
```

**Rules:**
- Error texts always as Labels — never inline strings
- Write understandable business-level error messages
- Do not expose technical details to end users
- No swallowed errors
- `Get()` only when a missing record SHOULD cause an error

---

## AL Performance Conventions

**Filter before loop — required pattern:**
```al
SalesLine.SetRange("Document Type", SalesHeader."Document Type");
SalesLine.SetRange("Document No.", SalesHeader."No.");

if SalesLine.FindSet() then
    repeat
        // Logic
    until SalesLine.Next() = 0;
```

**Rules:**
- Always use appropriate Keys
- Set filters before loops — never iterate full tables
- Use `FindSet()` deliberately; use `FindFirst()` or `IsEmpty()` where appropriate
- No unnecessary `Modify()` calls
- No expensive calculations in Page triggers
- Calculate FlowFields only when needed
- Use `SetLoadFields()` when only a few fields are required from a large table

---

## AL Permissions Convention

When adding new objects or data access:
- Evaluate whether a new PermissionSet is needed
- Consider extending existing PermissionSets
- Check if indirect permissions are required
- Verify access is correct for target roles
- Never expand permissions without review

---

## Prohibited Practices (AL + Framework)

**AL code:**
- No hardcoded strings as visible text (use Labels)
- No business logic in Page triggers
- No unnecessary `COMMIT`s
- No write operations in TryFunctions
- No `Get()` without error handling where record may be absent
- No cryptic abbreviations in identifiers
- No secrets or credentials in code
- No undocumented assumptions

**Framework/agents:**
- No direct commits to `main`, `master`, `release/*`, `production/*`
- No automatic merges
- No production deployments
- No secrets in prompts or outputs
- No productive customer data in prompt context
- No data migrations without explicit review
- No large refactorings without explicit requirement
- No unreviewed permission expansions
- No AL extension code placed inside the Kit repository (`BC-AL-Agentic-Development-Kit/`)

---

## Agent Behaviour Conventions

**Orchestrator pattern (al-auto-dev):**
- Orchestrator delegates ALL work to sub-agents via `runSubagent`
- Orchestrator never implements, analyzes, or reviews directly
- Sub-agents receive output of previous step as input
- Sequential execution: wait for each step before proceeding

**Confidence rule** (from `.github/policies/agent-policy.md`):

| Confidence | Action |
|---:|---|
| 0.80 – 1.00 | Implement |
| 0.60 – 0.79 | Implement cautiously, document assumptions |
| 0.40 – 0.59 | Technical preparation only / spike |
| 0.00 – 0.39 | Do not implement, document blocker |

**Thin requirement rule:** When a requirement is sparse but safe implementation is evident — implement the minimal safe change, document assumptions, add test hints, mark PR as Draft.

**Blocker rule:** When requirement is ambiguous with multiple risky interpretations, or affects booking logic, pricing, inventory, permissions, or data migration without sufficient acceptance criteria — block and document.

**Build rule:** After every code change: build → check diagnostics → fix errors → max 3 fix loops → document result.

---

## Output Format Conventions

Each skill and agent defines a standard output template in Markdown. Required sections vary by role:

**al-build-validation output:**
```markdown
## Buildstatus
## Diagnostics  (table: Datei | Zeile | Regel | Problem | Vorschlag)
## Nächste Schritte
```

**al-code-review output:**
```markdown
## Review-Zusammenfassung
## Kritische Punkte
## Verbesserungsvorschläge
## Freigabeempfehlung
```

**al-reviewer agent output:**
```markdown
## Review-Ergebnis  (Freigabe / Änderungen notwendig / Blocker)
## Blocker
## Verbesserungsvorschläge
## Testlücken
## PR-Kommentar
```

**al-implementer output:**
```markdown
## Geänderte Dateien
## Umsetzung
## Build/Diagnostics
## Offene Punkte
```

**al-planner output:**
```markdown
## Zusammenfassung
## Akzeptanzkriterien
## Technischer Plan
## Betroffene Objekte
## Tests
## Risiken
```

---

## Azure DevOps Conventions

**Branch naming:**
```
feature/wi-{id}-kurzer-titel
bugfix/wi-{id}-kurzer-titel
ai/wi-{id}-kurzer-titel
```

**Commit message format:**
```
WI #{id}: kurze Beschreibung
```
Example: `WI #12345: Show vendor block status on sales order`

Forbidden commit messages: `fix`, `test`, `changes`, `wip`, `asdf` (non-descriptive)

**AI tags for Work Items:**

| Tag | Meaning |
|---|---|
| `ai:auto` | May be processed by auto-agent |
| `ai:plan-only` | Analysis and plan only |
| `ai:implement` | Implementation allowed |
| `ai:review-only` | Review only |
| `ai:blocked` | Agent could not proceed safely |
| `ai:done` | Agent run completed |
| `bc-al` | Business Central AL scope |

---

*Convention analysis: 2026-06-18*
