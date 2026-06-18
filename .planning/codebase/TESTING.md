# Testing Patterns

**Analysis Date:** 2026-06-18

## Overview

Testing in the BC AL Agentic Development Kit operates at two levels:

1. **AL automated tests** — test codeunits written in AL for the extension under development (in the customer AL project, outside this kit)
2. **Build & diagnostics validation** — mandatory compile/build checks executed by the `al-build-tester` agent after every code change

Test design is handled by the `al-test-design` skill (`.github/skills/al-test-design/SKILL.md`) and governed by `.github/instructions/al-testing.instructions.md`.

---

## Test Runner Configuration

**Location:** `.altestrunner/config.json`

```json
{
  "containerResultPath": "",
  "launchConfigName": "",
  "securePassword": "",
  "userName": "",
  "companyName": "",
  "testSuiteName": "",
  "vmUserName": "",
  "vmSecurePassword": "",
  "remoteContainerName": "",
  "dockerHost": "",
  "newPSSessionOptions": "",
  "testRunnerServiceUrl": "",
  "codeCoveragePath": ".altestrunner\\codecoverage.json",
  "culture": "en-US"
}
```

**Code coverage output:** `.altestrunner/codecoverage.json`

**AL build/test tools used:**
- `al_downloadsymbols` — download BC base and system application symbols
- `al_build` — build/compile the AL project
- `al_getdiagnostics` — retrieve compiler diagnostics

The runner configuration is populated per-project; connection credentials (username, password) are NEVER stored in files — entered through VS Code login dialog only.

---

## Build & Diagnostics — Mandatory After Every Change

Defined in `.github/policies/agent-policy.md` and `.github/instructions/al-testing.instructions.md`:

**Build rule (non-optional):**
1. Run `al_build` or compile
2. Run `al_getdiagnostics`
3. Fix all errors
4. Evaluate all warnings
5. Document result

Maximum **3 fix loops** are allowed before escalating as a blocker.

**Prerequisite:** `.vscode/launch.json` must exist with valid BC server configuration before `al_downloadsymbols` or build can run.

**Minimal `launch.json` for OnPrem:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "BC Server",
      "type": "al",
      "request": "launch",
      "environmentType": "OnPrem",
      "server": "http://<server>",
      "serverInstance": "<instanz>",
      "authentication": "UserPassword",
      "breakOnError": true
    }
  ]
}
```

If `launch.json` is missing or incomplete, the agent asks the user for server URL, instance, and authentication type — then generates the file. Credentials are NEVER written to files.

---

## AL Test Framework

**Test codeunit structure (Subtype = Test):**
```al
codeunit 50100 "Sales Validation Tests"
{
    Subtype = Test;

    [Test]
    procedure CustomerBlockedPreventsPosting()
    begin
        // [GIVEN] A blocked customer
        // [WHEN] A sales order is posted
        // [THEN] Posting is prevented
    end;
}
```

**Rules for automated AL tests** (from `.github/instructions/al-testing.instructions.md`):
- Write test code in dedicated Test Codeunits (`Subtype = Test`)
- Use descriptive test method names
- Create test data in a controlled way (no dependency on random existing data)
- Clearly formulate Assert statements
- Test both positive AND negative cases
- Keep setup logic reusable across tests

---

## GIVEN / WHEN / THEN Pattern

All tests and test hints follow this structure — both in AL code comments and in Markdown documentation:

**In AL test code:**
```al
[Test]
procedure CustomerBlockedPreventsPosting()
begin
    // [GIVEN] A blocked customer
    // [WHEN] A sales order is posted for that customer
    // [THEN] An error is raised and posting is prevented
end;
```

**In Markdown documentation:**
```markdown
### GIVEN

Ausgangssituation — what state is set up

### WHEN

Die Aktion — what the user or system does

### THEN

Erwartetes Ergebnis — what must happen
```

---

## Test Types

From `.github/instructions/al-testing.instructions.md`:

| Test type | Purpose |
|---|---|
| Fachlicher Test | Verifies the business requirement is fulfilled |
| Technischer Test | Verifies code paths, validation, and error cases |
| Regressionstest | Verifies existing processes still work |
| Berechtigungstest | Verifies role and access control behavior |
| Performancetest | Verifies behavior under larger data volumes |
| Integrationstest | Verifies interfaces and dependent modules |

---

## When Automated Tests Are Especially Important

Changes to the following areas require particularly thorough testing:

- Booking/posting logic (Buchungslogik)
- Purchase processes
- Sales processes
- Inventory processes
- Item ledger entries (Artikelposten)
- Value entries (Wertposten)
- Prices and discounts
- Reservations
- Item tracking (batch/serial numbers)
- Available-to-promise (Lieferterminzusagen)
- Returns/complaints (Reklamationen)
- Assembly/manufacturing
- Interfaces/integrations
- Permissions
- Data migrations

---

## Test Case Documentation Template

Each test case should be documented in this structure (from `.github/instructions/al-testing.instructions.md`):

```markdown
## Testfall: [Name]

### Ziel

Was soll geprüft werden?

### Voraussetzungen

Welche Stammdaten, Belege oder Einstellungen werden benötigt?

### Schritte

1. ...
2. ...
3. ...

### Erwartetes Ergebnis

Was muss passieren?

### Hinweise

Besondere Randfälle oder Risiken.
```

---

## Manual Test Hints Template

When automated tests cannot be created, document at minimum:

```markdown
## Manuelle Testhinweise

### Vorbereitung

- ...

### Testschritte

1. ...
2. ...
3. ...

### Erwartetes Ergebnis

- ...

### Regression

Zusätzlich prüfen:

- ...
```

**Insufficient test documentation** — these phrases are NOT accepted:
- "sollte funktionieren" (should work)
- "nicht getestet" (not tested)
- "nur kleine Änderung" (just a small change)
- "Build nicht nötig" (no build needed)
- "keine Tests erforderlich" (no tests required)

If testing genuinely cannot be done, the reason must be stated explicitly.

---

## Edge Cases — Always Check

For every change, evaluate whether these edge cases are relevant:

- Empty values
- Blocked customers/vendors/items
- Missing master data
- Multiple lines
- Multiple companies (Mandanten)
- Different document types
- Different currencies
- Different locations (Lagerorte)
- Different units of measure (Einheiten)
- Variants (Varianten)
- Batch numbers / serial numbers (Chargen/Seriennummern)
- Already posted documents
- Canceled or corrected documents

---

## Regression Checklist

When modifying existing processes, always verify:

- [ ] Standard process still functions correctly
- [ ] Existing extensions still work
- [ ] No impact on Reports
- [ ] No impact on Interfaces
- [ ] No impact on Postings
- [ ] No impact on Permissions

---

## PR Test Documentation Checklist

Every Pull Request must include a test section:

```markdown
## Tests

Durchgeführt:

- [ ] Build/Compile
- [ ] Diagnostics geprüft
- [ ] manueller Test
- [ ] automatisierter Test
- [ ] Regression geprüft

Testhinweise:

- ...

Nicht getestet:

- ...
```

---

## al-test-design Skill

**Location:** `.github/skills/al-test-design/SKILL.md`

**Used by:** `al-build-tester` agent, `al-reviewer` agent, `al-planner` agent, `al-documenter` agent

**Procedure:**
1. Read requirement and change
2. Derive business (fachliche) test cases
3. Derive technical AL test cases
4. Check edge cases
5. Describe required test data

**Output format:**
```markdown
## Fachliche Tests

- ...

## Technische Tests

- ...

## Randfälle

- ...

## Benötigte Testdaten

- ...
```

---

## al-build-validation Skill

**Location:** `.github/skills/al-build-validation/SKILL.md`

**Used by:** `al-implementer` agent, `al-build-tester` agent

**Procedure:**
1. Verify `.vscode/launch.json` exists with valid BC server config
2. If missing/incomplete — ask user for server URL, instance, auth type; generate file
3. Run `al_downloadsymbols`
4. Run `al_build`
5. Run `al_getdiagnostics`
6. Summarize errors clearly
7. Propose concrete corrections

**Output format:**
```markdown
## Buildstatus

Erfolgreich / Fehlerhaft

## Diagnostics

| Datei | Zeile | Regel | Problem | Vorschlag |
| ----- | ----: | ----- | ------- | --------- |

## Nächste Schritte

- ...
```

---

## al-build-tester Agent

**Location:** `.github/agents/al-build-tester.agent.md`

**Tools:** `read`, `search`, `terminal`

**Responsibilities:**
- Validate `.vscode/launch.json` before any symbol download
- Run `al_downloadsymbols`, `al_build`, `al_getdiagnostics`
- Group errors clearly with file/line/rule reference
- Return concrete fix suggestions to `al-implementer` via orchestrator
- Maximum 3 correction loops in automated (`al-auto-dev`) pipeline
- Never redesign functionality or make large code changes

**Output format:**
```markdown
## Buildstatus

...

## Fehler

...

## Warnungen

...

## Testempfehlung

...

## Nächste Korrekturen

...
```

---

## Test Design Integration in Workflow

The `al-test-design` skill is used at multiple points in the automated workflow:

| Workflow step | Agent | Test-related action |
|---|---|---|
| Planning | `al-planner` | Derives test cases from requirements; lists risks |
| Build/Test | `al-build-tester` | Runs build/diagnostics; generates test recommendations |
| Review | `al-reviewer` | Identifies test gaps; evaluates test coverage |
| Documentation | `al-documenter` | Writes test hints for PR and Work Item comment |

---

## Error Analysis Pattern

When a test or build fails:

1. Reproduce the error
2. Describe the cause
3. Name the affected objects
4. Propose concrete correction
5. Document re-test result

---

## AI Agent Testing Rules

From `.github/instructions/al-testing.instructions.md`:

- **Never hide test gaps** — all untested areas must be declared
- **Never claim successful tests that weren't executed** — only report as successful if actually run
- **Build/diagnostics success is only reportable if actually achieved** — no assumption-based reporting
- **Document all assumptions** clearly
- **When test environment is unavailable** — generate manual test hints instead of skipping

---

## Symbol Download Prerequisite

Before any analysis or implementation in a BC AL project:

1. Run `al_downloadsymbols` (mandatory, not optional)
2. Verify `.alpackages/` directory is present and non-empty
3. Without downloaded symbols → analysis is incomplete; document limitations
4. If symbols cannot be downloaded → ask user if `launch.json` can be provided; otherwise continue with restricted analysis and document assumptions

This ensures the Base Application and System Application are known to the AL Language Server before any object lookups.

---

*Testing analysis: 2026-06-18*
