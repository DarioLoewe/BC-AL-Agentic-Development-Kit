# Phase 2: Spezialist-Refactoring — Research

**Researched:** 2026-06-18
**Domain:** BC AL Agent Architecture — Specialist Agent Refactoring
**Confidence:** HIGH (all findings based on direct codebase analysis)

---

## Summary

Phase 2 refactors five specialist agents (Architect, Coder, Validator, Reviewer, Tester) into
dedicated, self-contained agents with machine-readable `## ERGEBNIS` output blocks. The primary
innovation is a **JSON Plan Contract** that flows from `al-architect` → `al-coder` → `al-validator`
without ambiguity. This eliminates the freetext gap between planning and implementation that the
current `al-planner` → `al-implementer` chain has.

**Key pre-existing assets that Phase 2 builds on:**
- `al-devops-reader.agent.md` (Phase 1) — canonical `## ERGEBNIS` block reference [VERIFIED: codebase]
- `agent-policy.md` — Confidence-Rubrik with AL-specific task examples [VERIFIED: codebase]
- `al-coding-standards.instructions.md` — 10 coding rule categories [VERIFIED: codebase]
- `al-testing.instructions.md` — GIVEN/WHEN/THEN pattern + testfall structure [VERIFIED: codebase]
- `al-review.instructions.md` — 10-section review criteria [VERIFIED: codebase]
- `main-agent.agent.md` — existing checkpoint/delegation protocol [VERIFIED: codebase]

**Primary recommendation:** Build all five specialist agents as new files; deprecate
`al-implementer` and `al-build-tester` in-place (add deprecation note to frontmatter). Do NOT
delete legacy agents until Phase 2 is validated end-to-end in main-agent workflow.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | `al-architect.agent.md` — plant BC-Objekte, Felder, Extensions | JSON Plan Contract schema (§4), T-shirt sizing rubric (§4.4) |
| ARCH-02 | Architect liest `app.json` und `.alpackages/` Symbole | BC-Version-Awareness protocol (§4.2) |
| ARCH-03 | Architect liefert Aufwandsschätzung | T-Shirt sizing rubric (§4.4) |
| ARCH-04 | Structured JSON Plan Contract — maschinenlesbar | Full JSON schema with examples (§4.3) |
| VALID-01 | `al-validator.agent.md` — prüft AC-Abdeckung | 5-Layer validation design (§6) |
| VALID-02 | 5-Layer-Prüfung: AC→Mapping, AL-Konventionen, Tests, Diff, Trigger | Layer-by-layer breakdown (§6.1) |
| VALID-03 | Validator: max. 2 Korrekturschleifen dann Blocker-Report | Escalation protocol (§6.2) |
| TEST-01 | `al-tester.agent.md` — nur auf explizite Anforderung | Isolation strategy (§7) |
| TEST-02 | Tester nutzt GIVEN/WHEN/THEN-Pattern | Pattern extraction from al-testing.instructions.md (§7.1) |
| CODER-01 | `al-coder.agent.md` konsolidiert al-implementer + Build-Logik | Consolidation analysis (§5) |
| CONTRACT-01 | Alle Spezialisten: strukturierte `## ERGEBNIS`-Blöcke | ERGEBNIS template per agent (§3) |

---

## 1. Existing Codebase Analysis

### 1.1 Current Agent Inventory (Phase 2 Scope)

| Agent File | Model | Tools | Output Format | Status |
|------------|-------|-------|---------------|--------|
| `al-planner.agent.md` | claude-opus-4 | read, search | Freetext markdown | → Replaced by al-architect |
| `al-implementer.agent.md` | claude-sonnet-4-5 | read, search, edit | Freetext markdown | → Absorbed into al-coder |
| `al-build-tester.agent.md` | claude-sonnet-4-5 | read, search, terminal | Freetext markdown | → Absorbed into al-coder |
| `al-reviewer.agent.md` | claude-sonnet-4-5 | read, search | Freetext markdown | → Enhanced with ERGEBNIS block |
| `al-codebase-analyst.agent.md` | claude-sonnet-4-5 | read, search | Freetext markdown | Unchanged in Phase 2 |

### 1.2 Gap Analysis: Why Freetext Fails

The current `al-planner` → `al-implementer` handoff is freetext:

```markdown
## Technischer Plan
1. Feld "External Reference" (Code[50]) zu Customer Ext. hinzufügen
2. Caption setzen: 'External Reference'
...
```

Problems this creates:
- al-implementer must re-parse intent from natural language
- Object IDs are not explicitly assigned — implementer guesses or asks
- No structured field metadata → DataClassification can be forgotten
- No machine-parseable list of objects → Main-Agent cannot checkpoint individual objects
- Freetext ambiguity leads to "assumed" implementations that drift from AC

The JSON Plan Contract fixes all of these.

### 1.3 What Already Works (Do Not Break)

- `agent-policy.md` Fix-Loop-Eskalation rule: max 3 loops → BLOCKER-REPORT.md [VERIFIED: codebase]
- `main-agent.agent.md` Checkpoint-Protokoll: `## ERGEBNIS` block is already expected [VERIFIED: codebase]
- `al-devops-reader.agent.md` ERGEBNIS format: canonical reference for all other ERGEBNIS blocks [VERIFIED: codebase]
- `al-coding-standards.instructions.md`: Referenced by all agents via `## Nutze diese Skills → al-code-review` [VERIFIED: codebase]
- Confidence-Rubrik in `agent-policy.md` with 12 concrete AL task examples [VERIFIED: codebase]

---

## 2. ERGEBNIS Block Standard (CONTRACT-01)

### 2.1 Canonical Reference: al-devops-reader Pattern

`al-devops-reader.agent.md` established the canonical ERGEBNIS block [VERIFIED: codebase]:

```markdown
## ERGEBNIS — DevOps-Reader

## Ticket-Summary: {WI/Issue-ID}
**Titel:** {Titel}
...
### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Offene Fragen: {Falls vorhanden, sonst "Keine"}
```

Key structural elements:
1. Header: `## ERGEBNIS — {Agent-Name}` (single H2, machine-findable)
2. Named sections with bold keys
3. Always ends with `### Interpretation für Main-Agent` containing `Confidence:` and next step hint

### 2.2 How main-agent Parses ERGEBNIS Blocks [VERIFIED: codebase]

From `main-agent.agent.md`:
```
1. Lies den Output-Block (`## Output` oder `## ERGEBNIS`) aus dem Subagent-Ergebnis
2. Schreibe SESSION.md: aktualisiere `current_step`, `current_agent`, `awaiting_checkpoint: true`
3. Trage den Schritt-Output als Zusammenfassung in SESSION.md ein
4. Präsentiere dem Entwickler den CHECKPOINT-Block
```

Parse strategy: Main-agent scans for `## ERGEBNIS` header, reads the block to end of agent output,
extracts: Confidence value, summary for Checkpoint-Block, next step hint, blocker flags.

### 2.3 ERGEBNIS Templates per Specialist

**Template: al-architect**
```markdown
## ERGEBNIS — Architect

**Ticket-ID:** {WI-ID}
**BC-Version:** {runtime + application aus app.json}
**Symbol-Status:** Geladen ✓ | Fehler: {Details}
**Aufwandsschätzung:** {XS|S|M|L|XL} — {Begründung in 1 Satz}

### JSON Plan Contract

```json
{ ... }  ← vollständiger Plan Contract (see §4.3 for schema)
```

### Annahmen
- {Annahme 1}

### Risiken
- {Risiko 1}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-coder — implementiert JSON Plan Contract
- Offene Fragen: {oder "Keine"}
```

**Template: al-coder**
```markdown
## ERGEBNIS — Coder

**Ticket-ID:** {WI-ID}
**Plan Contract Version:** {plan_contract_version aus Input}

### Implementierte Objekte
| Objekt | Typ | Aktion | Datei |
|--------|-----|--------|-------|
| {Name} | {tableextension|codeunit|...} | erstellt|erweitert | {Pfad} |

### Build-Ergebnis
- Status: ✓ Erfolgreich | ✗ Fehler
- Fix-Schleifen: {0|1|2|3}
- Diagnostics: {Warnungen / Fehler}

### Übersetzungseinträge
- {de-DE Einträge oder "Keine neuen"}

### Geänderte Dateien
- {Pfad 1}

### Offene Punkte
- {oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-validator — prüft AC-Abdeckung
- Offene Fragen: {oder "Keine"}
```

**Template: al-validator**
```markdown
## ERGEBNIS — Validator

**Ticket-ID:** {WI-ID}
**Korrekturschleifen:** {0|1|2} von max. 2

### 5-Layer Prüfung

| Layer | Prüfpunkt | Status | Detail |
|-------|-----------|--------|--------|
| 1 | AC→Objekt-Mapping | ✓ OK | Alle ACs abgedeckt |
| 2 | AL-Konventionen | ✓ OK | Labels, DataClassification gesetzt |
| 3 | Test-Coverage | ⚠ Lücke | Kein Test für AC-3 |
| 4 | Diff-Verifikation | ✓ OK | Alle Änderungen im Diff vorhanden |
| 5 | Korrektur-Trigger | — | Keine Lücken → kein Trigger |

### AC-Abdeckung
| AC | Objekt | Status |
|----|--------|--------|
| AC-1 | tableextension "Customer Ext." Feld "External Ref." | ✓ |
| AC-2 | pageextension "Customer Card Ext." | ✓ |

### Offene Lücken
- {oder "Keine"}

### Interpretation für Main-Agent
- Gesamtstatus: Freigabe | Korrektur erforderlich | BLOCKER
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer | al-coder (Korrektur) | ESKALATION
- Offene Fragen: {oder "Keine"}
```

**Template: al-reviewer (enhanced)**
```markdown
## ERGEBNIS — Reviewer

**Ticket-ID:** {WI-ID}
**Review-Status:** Freigabe | Änderungen notwendig | Blocker

### Prüfergebnis
| Kriterium | Status | Hinweis |
|-----------|--------|---------|
| Upgradefähigkeit | ✓ | Events genutzt |
| AL-Best-Practices | ✓ | Labels gesetzt |
| Performance | ⚠ | SetLoadFields prüfen |
| Fehlerbehandlung | ✓ | — |
| Testbarkeit | ✓ | — |
| Berechtigungen | ⚠ | PermissionSet fehlt |
| Labels | ✓ | — |
| Keine unnötigen COMMITs | ✓ | — |

### Blocker
- {oder "Keine"}

### Verbesserungsvorschläge
- {oder "Keine"}

### Testlücken
- {oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-documenter | Blocker → Entwickler
- Offene Fragen: {oder "Keine"}
```

**Template: al-tester**
```markdown
## ERGEBNIS — Tester

**Ticket-ID:** {WI-ID}
**Test-Modus:** AL-Test-Codeunit | Manuelle Testhinweise | Beides

### Erstellte Tests
| Testmethode | Typ | Abgedecktes AC |
|-------------|-----|----------------|
| CustomerBlockedPreventsPosting | Automatisiert | AC-1 |
| ExternalRefMandatory | Automatisiert | AC-2 |

### Test-Datei
- Pfad: {src/Tests/...Test.al}

### GIVEN/WHEN/THEN Zusammenfassung
{Für jeden Test ein Kurzblock}

### Nicht abdeckbare Testfälle
- {und Begründung, oder "Keine"}

### Interpretation für Main-Agent
- Confidence: {0.00–1.00}
- Nächster Schritt: al-reviewer (falls noch nicht erfolgt)
- Offene Fragen: {oder "Keine"}
```

---

## 3. JSON Plan Contract Schema (ARCH-04)

### 3.1 Design Principles

The JSON Plan Contract is the machine-readable output of `al-architect`, consumed directly by
`al-coder` without re-parsing. It must be:
- **Complete**: al-coder needs zero assumptions from the ticket text to start coding
- **Unambiguous**: explicit object IDs, field types, lengths — no "Code[50] or whatever fits"
- **Verifiable**: al-validator can check each contract item against implemented code
- **Minimal**: no prose commentary inside the contract — that goes in the ERGEBNIS block

### 3.2 BC Object Types Covered [ASSUMED — based on AL language spec knowledge]

| AL Object Type | Contract Action Values |
|----------------|----------------------|
| `table` | `create` |
| `tableextension` | `create`, extending named base table |
| `page` | `create` |
| `pageextension` | `create`, extending named base page |
| `codeunit` | `create`, `modify` |
| `report` | `create` |
| `reportextension` | `create` |
| `enum` | `create` |
| `enumextension` | `create` |
| `permissionset` | `create`, `modify` |
| `permissionsetextension` | `create` |

### 3.3 JSON Plan Contract Schema

```json
{
  "plan_contract_version": "1.0",
  "ticket_id": "WI-1234",
  "ticket_title": "Lieferantensperre im Verkaufsauftrag anzeigen",
  "bc_version": {
    "runtime": "12.0",
    "application": "23.0.0.0",
    "platform": "23.0.0.0"
  },
  "effort": {
    "size": "S",
    "hours_estimate": "2-4h",
    "rationale": "PageExtension + 1 Feld in TableExtension, kein Buchungsfluss"
  },
  "confidence": 0.85,
  "objects": [
    {
      "id": "contract_obj_1",
      "type": "tableextension",
      "proposed_id": 50100,
      "name": "Vendor Ext.",
      "extends": "Vendor",
      "file_path": "src/TableExtensions/VendorExt.TableExt.al",
      "action": "create",
      "fields": [
        {
          "id": 50100,
          "name": "Delivery Blocked",
          "type": "Boolean",
          "caption": "Lieferantensperre",
          "data_classification": "CustomerContent",
          "tooltip": "Gibt an, ob dieser Kreditor für Lieferungen gesperrt ist."
        }
      ],
      "keys": [],
      "triggers": []
    },
    {
      "id": "contract_obj_2",
      "type": "pageextension",
      "proposed_id": 50101,
      "name": "Sales Order Ext.",
      "extends": "Sales Order",
      "file_path": "src/PageExtensions/SalesOrderExt.PageExt.al",
      "action": "create",
      "controls": [
        {
          "action": "addlast",
          "group": "General",
          "field_name": "Delivery Blocked",
          "source_table_field": "Vendor.Delivery Blocked",
          "application_area": "All",
          "editable": false,
          "tooltip": "Gibt an, ob der Kreditor des Artikels für Lieferungen gesperrt ist."
        }
      ],
      "methods": []
    }
  ],
  "codeunits": [],
  "enums": [],
  "permission_sets": [
    {
      "action": "note",
      "note": "Neue Tabellenfelder müssen in bestehende PermissionSets aufgenommen werden — manuell prüfen"
    }
  ],
  "translations": [
    {
      "language": "de-DE",
      "entries": [
        "tableextension 50100 Vendor Ext. Feld 50100 Caption = Lieferantensperre"
      ]
    }
  ],
  "dependencies": [
    {
      "type": "base_object_read",
      "object": "Vendor",
      "reason": "TableExtension extends Vendor — Symbole müssen geladen sein"
    }
  ],
  "assumptions": [
    "Objekt-ID-Bereich 50100-50199 ist im Kundenprojekt für diese Extension reserviert"
  ],
  "risks": [
    "Feld 'Delivery Blocked' zeigt nur einen statischen Wert — keine Buchungsblock-Logik"
  ],
  "out_of_scope": [
    "Änderung der Einkaufsbuchungslogik",
    "Automatische Sperrung von Bestellungen"
  ]
}
```

### 3.4 ID Range Handling

**Problem** [ASSUMED]: AL object IDs must be in the customer-specific reserved range (typically
50000–99999 for per-tenant extensions). The architect must propose an ID from a range. The coder
must then verify no conflict exists in the project.

**Approach:**
1. Architect reads `app.json` → extracts `"idRanges"` array if present
2. Architect scans existing `.al` files in the project → finds highest used ID per type
3. Architect proposes `proposed_id` = highest_used + 1 (within range)
4. Coder verifies ID is not taken before creating file
5. If `idRanges` is absent in `app.json`: architect notes as assumption, proposes 50100+ default

### 3.5 T-Shirt Sizing Rubric (ARCH-03)

Based on the Confidence-Rubrik in `agent-policy.md` [VERIFIED: codebase], mapped to effort:

| Size | Hours | Typical AL Task | Confidence Anchor |
|------|-------|-----------------|-------------------|
| XS | < 1h | Caption/Label-Text ändern | 0.95 |
| S | 1-4h | Feld zu TableExtension hinzufügen, PageControl hinzufügen | 0.85-0.90 |
| M | 4-8h | FlowField/FlowFilter, neues Objekt ohne Buchungslogik | 0.75-0.80 |
| L | 8-16h | Neue Tabelle, komplexe Codeunit, Schnittstelle (API/Webservice) | 0.40-0.70 |
| XL | > 16h | Buchungslogik, Datenmigration, Berechtigungen komplex | 0.25-0.39 |

**Rule**: If `confidence < 0.60` → forced escalation to developer before al-coder is called
(CP-5 in main-agent). Architect must annotate the contract accordingly.

---

## 4. al-architect vs al-planner (ARCH-01..04)

### 4.1 Current al-planner Gaps

`al-planner.agent.md` [VERIFIED: codebase]:
- Tools: `read`, `search` only — **cannot download symbols**
- Output: freetext markdown (6 sections: Zusammenfassung, ACs, Technischer Plan, Objekte, Tests, Risiken)
- No BC-version awareness — no `app.json` read
- No structured object/field definitions
- No effort estimate
- No `## ERGEBNIS` block (just plain output format)

### 4.2 BC-Version-Awareness Protocol (ARCH-02)

**Step 1: Read app.json** (customer project path from SESSION.md `customer_path`)
```json
{
  "runtime": "12.0",
  "application": "23.0.0.0",
  "platform": "23.0.0.0",
  "idRanges": [{ "from": 50100, "to": 50149 }]
}
```
Extracted: `runtime`, `application`, `platform`, `idRanges`

**Step 2: Symbol download via `al-build-validation` skill**
- Skill: `al-build-validation` → calls `al_downloadsymbols`
- Prerequisite: `.vscode/launch.json` must exist with valid server config
- **Hard stop if symbols not downloadable**: architect cannot know base object structure
  → note in ERGEBNIS block: "Symbol-Status: Fehler — Architect hat ohne vollständige Symbolkenntnis geplant"

**Step 3: Query relevant base objects**
- Use `search` to find existing `.al` files in the project
- Check `.alpackages/` for base app symbols
- Determine: does an equivalent base object exist? (e.g., `Vendor` table has the field already?)

### 4.3 al-architect Frontmatter

```yaml
---
name: al-architect
model: claude-opus-4
description: >
  Plant BC-Objekte, Felder, Extensions und Beziehungen auf Basis von Ticket + BC-Symbolen.
  Gibt einen maschinenlesbaren JSON Plan Contract zurück.
tools: ["read", "search"]
agents:
  - al-codebase-analyst
skills:
  - al-object-analysis
  - al-devops-workitem
  - al-build-validation
---
```

Note: `terminal` is NOT in al-architect's tools — symbol download is orchestrated via the
`al-build-validation` skill, not direct terminal access.

---

## 5. al-coder Consolidation (CODER-01)

### 5.1 What to Merge

**From al-implementer** [VERIFIED: codebase]:
- Policy: only make changes listed in the plan
- Policy: document all assumptions
- Policy: no extra refactorings
- Skills: `al-object-analysis`, `al-build-validation`
- Tools: `read`, `search`, `edit`

**From al-build-tester** [VERIFIED: codebase]:
- Tools: `terminal` (required for AL tool execution)
- AL Tools: `al_downloadsymbols`, `al_build`, `al_getdiagnostics`
- Policy: max 3 fix loops → BLOCKER-REPORT.md (identical to agent-policy.md Fix-Loop-Eskalation)
- Policy: launch.json check before symbol download
- Policy: never write credentials

**New additions for al-coder**:
- Accepts JSON Plan Contract as structured input (not freetext)
- Manages object ID assignment (verify proposed_id is not taken)
- Creates translation entries (`.xlf` or inline label management)
- Reports per-object implementation status in ERGEBNIS block

### 5.2 al-coder Frontmatter

```yaml
---
name: al-coder
model: claude-sonnet-4-5
description: >
  Implementiert AL-Code auf Basis eines JSON Plan Contracts. Konsolidiert al-implementer
  und al-build-tester. Schreibt Code, verwaltet Objekt-IDs, führt Build durch,
  erstellt Übersetzungseinträge.
tools: ["read", "search", "edit", "terminal"]
skills:
  - al-object-analysis
  - al-build-validation
---
```

### 5.3 Build Loop Protocol in al-coder

Max 3 fix loops (from `agent-policy.md § Fix-Loop-Eskalation`) [VERIFIED: codebase]:

```
Loop 1-3:
  1. edit code
  2. al_build → al_getdiagnostics
  3. if errors → analyze → fix → goto 2

After loop 3 with remaining errors:
  1. STOP — no more code changes
  2. Create .planning/al-workflow/BLOCKER-REPORT.md
  3. Return ERGEBNIS with Confidence = 0.00, Status = BLOCKER
  4. main-agent presents BUILD-ESKALATION block to developer
```

### 5.4 Translation Handling

[ASSUMED — based on BC AL xliff translation knowledge]

BC AL projects use `.xlf` files for translations. al-coder must:
1. Check if project has `translations/` folder and `*.g.xlf` file
2. After build: scan generated `.g.xlf` for new entries from added labels
3. Copy entries to target language `.xlf` (e.g., `de-DE.xlf`) with DE translations
4. Document new entries in ERGEBNIS block `### Übersetzungseinträge`

If no `.xlf` infrastructure exists in customer project: note in ERGEBNIS, do not create
infrastructure without explicit ask.

### 5.5 Backward Compatibility: al-implementer + al-build-tester

**Strategy: Deprecate in-place, do NOT delete**

`al-implementer.agent.md` → add to frontmatter description:
```yaml
description: >
  [DEPRECATED — Phase 2] Verwende al-coder.agent.md.
  al-implementer bleibt für Rückwärtskompatibilität mit al-auto-dev erhalten.
```

`al-build-tester.agent.md` → same approach:
```yaml
description: >
  [DEPRECATED — Phase 2] Build-Logik ist in al-coder.agent.md integriert.
  al-build-tester bleibt für Standalone-Build-Diagnosen erhalten.
```

**Rationale**: `al-auto-dev.agent.md` (legacy orchestrator) still references `al-implementer` and
`al-build-tester`. Deleting them breaks `al-auto-dev`. Since `al-auto-dev` is itself being
superseded by `main-agent` (Phase 1), and it may still be used during the transition, keep the
old agents alive.

---

## 6. 5-Layer Validation (VALID-01..03)

### 6.1 Layer-by-Layer Design

**Layer 1: AC → Objekt-Mapping**
- Input: Akzeptanzkriterien from DevOps-Reader ERGEBNIS (SESSION.md)
- Input: JSON Plan Contract from Architect ERGEBNIS (SESSION.md)
- Check: For each AC item — is there a concrete object/field/method in the plan contract that implements it?
- Evidence: grep the diff/changed files for the object name + field name listed in contract
- Pass: All ACs have ≥1 implementing object/field/method in the diff
- Fail: AC without any matching code change → Layer 5 trigger

**Layer 2: AL-Konventionen**
- Source: `al-coding-standards.instructions.md` [VERIFIED: codebase]
- Rules checked (auto-verifiable by al-validator reading files):
  - Labels set for visible texts (search for hardcoded string literals in `Error()`, `Message()`)
  - Caption set on all new fields (field block has `Caption = '...';`)
  - DataClassification set on all new table fields
  - ApplicationArea set on page controls
  - No `COMMIT` without justification
  - Business logic not in page triggers (check OnValidate, OnAfterGetRecord in page extensions)
  - One object per file (verify file count matches object count in contract)
- Pass: All rules satisfied
- Fail: Any rule violated → annotate, Layer 5 trigger

**Layer 3: Test-Coverage**
- Source: `al-testing.instructions.md` [VERIFIED: codebase]
- Check: Is there a test codeunit OR manual test hints in ERGEBNIS block?
- Critical check: If task touches Buchungslogik, Preise, Lager, Berechtigungen → test is MANDATORY
  (from al-testing.instructions.md: "Wenn möglich, Änderungen testbar gestalten")
- Pass: Test or manual hints exist
- Warning (not fail): No tests for non-critical changes — noted in ERGEBNIS
- Fail (only for risk areas): No tests at all on Buchungslogik/Schnittstellen change → Layer 5 trigger

**Layer 4: Diff-Verifikation**
- Check: Every object listed in JSON Plan Contract → file exists in expected path
- Check: Every field listed in contract → actually present in the file (grep)
- Check: No "phantom" claims — implementer cannot claim AC covered without actual code
- Pass: All contract items have matching file+content evidence
- Fail: Discrepancy between contract and actual files → Layer 5 trigger

**Layer 5: Korrektur-Trigger**
- If any Layer 1-4 fails:
  - Max 2 correction loops with al-coder
  - Loop: Validator sends specific gap description → al-coder fixes → Validator re-runs all 5 layers
  - After 2 loops with remaining gaps:
    - Create `.planning/al-workflow/BLOCKER-REPORT.md`
    - ERGEBNIS: Gesamtstatus = BLOCKER
    - main-agent escalates to developer

### 6.2 Escalation Protocol (VALID-03)

```
Korrekturschleife 1:
  al-validator → al-coder: "Layer 2: DataClassification fehlt auf Feld 'External Reference'"
  al-coder: fixes → build → ERGEBNIS
  al-validator: re-runs 5 layers

Korrekturschleife 2 (if still failing):
  al-validator → al-coder: "Layer 1: AC-3 hat kein implementierendes Objekt im Diff"
  al-coder: fixes → build → ERGEBNIS
  al-validator: re-runs 5 layers

Nach 2 Schleifen ohne Vollabdeckung:
  al-validator: erstellt BLOCKER-REPORT.md
  ERGEBNIS: Confidence = 0.00, Gesamtstatus = BLOCKER
  main-agent: BUILD-ESKALATION Block an Entwickler
```

**What triggers a BLOCKER vs a Korrektur-Schleife:**
| Situation | Response |
|-----------|----------|
| AC not covered by any code | Korrektur-Schleife (up to 2) |
| Label missing | Korrektur-Schleife |
| DataClassification missing | Korrektur-Schleife |
| Build fails | → al-coder handles, not al-validator |
| Booking logic unverifiable | SOFORT BLOCKER (Confidence < 0.39 by policy) |
| Security risk (no auth check on API endpoint) | SOFORT BLOCKER |
| File exists but contract says "created" | BLOCKER (phantom claim) |

---

## 7. Tester Isolation (TEST-01..02)

### 7.1 When al-tester Runs

`al-tester` runs ONLY when:
- Developer explicitly says: "erstelle Tests", "schreibe AL-Tests", "automate the tests"
- main-agent receives a task that includes test creation as explicit requirement
- Developer says "ja" to a test-creation offer from main-agent at a specific checkpoint

`al-tester` does NOT run:
- Automatically after al-coder
- Automatically after al-validator
- As part of the standard 7-step workflow [VERIFIED: codebase — workflow table has no tester step]

### 7.2 main-agent Signaling Protocol

Current main-agent workflow table (Phase 1) has steps 1-7 [VERIFIED: codebase]. al-tester is NOT
in this table. The signal mechanism:

Option A (recommended): main-agent adds an optional step 4.5 that is only shown when developer
requests it. The step-table comment notes: `al-tester: nur auf explizite Anforderung`.

Option B: al-tester is listed in the `agents:` frontmatter of main-agent but the orchestration
instruction says: "Delegiere al-tester NUR wenn Entwickler explizit 'Tests' anfordert".

**Decision**: Use Option B — keep agent in registry but add explicit guard in delegation rules.

### 7.3 GIVEN/WHEN/THEN Pattern [VERIFIED: codebase]

From `al-testing.instructions.md`, the AL test structure:

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

al-tester rules:
- Test codeunit ID in customer-reserved range (from JSON Plan Contract `idRanges`)
- Test method names: descriptive verb phrases (`CustomerBlockedPreventsPosting`)
- No dependency on random existing data — create controlled test data in `// [GIVEN]`
- Positive AND negative test cases per AC
- Assert with `Assert.AreEqual`, `Assert.IsTrue`, or `Error` on unexpected state

### 7.4 al-tester Input Requirements

al-tester receives from main-agent (via SESSION.md):
- `ticket_id` — for test naming
- AC list from DevOps-Reader ERGEBNIS
- JSON Plan Contract from Architect ERGEBNIS (object names, IDs for test setup)
- Changed files list from Coder ERGEBNIS

### 7.5 al-tester Frontmatter

```yaml
---
name: al-tester
model: claude-sonnet-4-5
description: >
  Erstellt und führt AL-Tests durch — ausschließlich auf explizite Anforderung.
  Niemals automatisch als Teil des Standard-Workflows.
  Nutzt GIVEN/WHEN/THEN-Pattern aus al-testing.instructions.md.
tools: ["read", "search", "edit", "terminal"]
skills:
  - al-build-validation
  - al-test-design
---
```

---

## 8. Agent Chaining via main-agent (Phase 2 Update)

### 8.1 Workflow Table Changes Required

Current Phase 1 workflow [VERIFIED: codebase]:
| Schritt | Agent | Checkpoint |
|---------|-------|-----------|
| 2 | al-planner | CP-2 |
| 4 | al-implementer | Nach Bedarf |
| 5 | al-build-tester | Bei Fehlern |
| 6 | al-reviewer | CP-3 + CP-4 |

Phase 2 target workflow:
| Schritt | Agent | Checkpoint |
|---------|-------|-----------|
| 2 | **al-architect** | **CP-2** (unchanged position) |
| 3 | al-codebase-analyst | Nach Bedarf (unchanged) |
| 4 | **al-coder** | Bei Fehlern (absorbs implementer+build-tester) |
| 5 | **al-validator** | **CP-3** (new mandatory checkpoint) |
| 6 | al-reviewer | **CP-4** (was CP-3) |
| 7 | al-documenter | CP-Ende (unchanged) |
| (opt) | **al-tester** | Nur auf Anforderung |

### 8.2 Checkpoint Position Renaming

Phase 1 had a note: `*CP-2 = nach al-planner; CP-3 = nach al-reviewer (kombinierter Review + Validator-Schritt, da al-validator erst in Phase 2 kommt)*`

Phase 2 resolves this: al-validator gets CP-3, al-reviewer gets CP-4. The comment should be
removed when main-agent is updated.

### 8.3 main-agent `agents:` Frontmatter Update

Phase 2 replaces in main-agent.agent.md:
```yaml
# BEFORE (Phase 1):
agents:
  - al-devops-reader
  - al-planner          # → replace with al-architect
  - al-codebase-analyst
  - al-implementer      # → remove (absorbed by al-coder)
  - al-build-tester     # → remove (absorbed by al-coder)
  - al-reviewer
  - al-documenter

# AFTER (Phase 2):
agents:
  - al-devops-reader
  - al-architect        # NEW — replaces al-planner
  - al-codebase-analyst
  - al-coder            # NEW — absorbs al-implementer + al-build-tester
  - al-validator        # NEW
  - al-reviewer
  - al-documenter
  - al-tester           # NEW — optional, explicit request only
```

### 8.4 SESSION.md Schema Extensions

Phase 2 adds fields to SESSION.md to track new agent outputs:

```yaml
# Existing (Phase 1):
ticket_id: ""
current_step: 0
awaiting_checkpoint: false
approved_steps: []
build_fix_loop_count: 0
customer_path: ""

# New (Phase 2):
architect_contract_path: ""    # path to persisted JSON Plan Contract
validator_loop_count: 0        # tracks al-validator correction loops (max 2)
tester_requested: false        # flag: has developer explicitly requested tests?
```

**Why persist the contract path**: al-coder and al-validator both need the JSON Plan Contract.
Rather than passing it inline (potentially huge), persist it to disk and pass the path.

---

## 9. Pitfalls to Avoid

### Pitfall 1: ERGEBNIS Block Parsing Fragility
**What goes wrong**: If the `## ERGEBNIS` header uses different casing/spacing, main-agent fails
to find the block and presents an empty checkpoint summary.
**Root cause**: No enforced schema — each agent writes freestyle.
**Avoidance**: All ERGEBNIS templates in this research are exact copy-paste templates the planner
must include in each agent file. The header MUST be `## ERGEBNIS — {Agent-Name}` (no exceptions).
**Detection**: In main-agent code review — verify the header pattern is consistent across all
6 agents in Phase 2.

### Pitfall 2: JSON Plan Contract Silently Missing Fields
**What goes wrong**: Architect produces a partial JSON (no `data_classification`, no `caption`)
→ al-coder creates code without those fields → validator fails Layer 2 → correction loop triggered.
**Root cause**: No schema validation at contract-write time.
**Avoidance**: al-architect's agent instructions must enumerate all MANDATORY fields and mark them
as required. Use a checklist within the agent instructions.

### Pitfall 3: al-coder Builds Without Symbol Download
**What goes wrong**: al-coder runs `al_build` without first running `al_downloadsymbols` → build
fails on missing base object references → wasted fix loop.
**Root cause**: Symbol download is a prerequisite that's easy to skip.
**Avoidance**: al-coder MUST run `al_downloadsymbols` as step 0 before writing any code. Hard rule
in agent instructions: "Schritt 0: Symbole herunterladen. Bei Fehler: STOPP, ERGEBNIS mit Blocker."

### Pitfall 4: Validator Triggers Correction Loop for Build Errors
**What goes wrong**: al-validator's Layer 4 finds a file that doesn't compile but the validator
is not a build agent → confusion about who fixes what.
**Root cause**: Validator's job is AC-coverage, not build health. Build health is al-coder's job.
**Avoidance**: al-validator explicitly states: "Build-Fehler sind NICHT Teil der 5-Layer-Prüfung.
Build muss bereits erfolgreich sein wenn al-validator aufgerufen wird." If al-coder's ERGEBNIS
shows build failure → main-agent does NOT call al-validator. It escalates build failure directly.

### Pitfall 5: al-tester Called Automatically
**What goes wrong**: Developer says "ja" to continue → main-agent calls al-tester automatically
between al-coder and al-reviewer → developer didn't want it.
**Root cause**: al-tester in agents list could be accidentally triggered.
**Avoidance**: main-agent instruction must have explicit guard: "al-tester wird NIEMALS automatisch
aufgerufen. Nur wenn `tester_requested: true` in SESSION.md."

### Pitfall 6: JSON Contract Not Persisted to Disk
**What goes wrong**: JSON Plan Contract is large (multi-object plans). Passing it through
`runSubagent` task string truncates it. al-coder receives partial contract.
**Root cause**: Large inline payloads in agent orchestration.
**Avoidance**: al-architect writes contract to `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json`.
Passes the path, not the content. al-coder reads the file. al-validator reads the file.
main-agent stores `architect_contract_path` in SESSION.md.

### Pitfall 7: BC-Version Mismatch — Wrong Base Object Assumption
**What goes wrong**: Architect assumes base object fields from BC 21 but customer runs BC 23 →
proposed extensions are for fields that don't exist in that version.
**Root cause**: Missing version-aware symbol lookup.
**Avoidance**: ARCH-02 is mandatory — `app.json` read is step 0 of architect. If `runtime` is
< 10.0 (NAV 2018), halt with BLOCKER: "BC-Version zu alt für Agentic-Workflow".

---

## 10. Backward Compatibility Summary

| Existing Agent | Phase 2 Action | Reference Held By |
|----------------|----------------|-------------------|
| `al-planner.agent.md` | Add deprecation note in description | al-auto-dev (legacy) |
| `al-implementer.agent.md` | Add deprecation note in description | al-auto-dev (legacy) |
| `al-build-tester.agent.md` | Add deprecation note in description | al-auto-dev (legacy) |
| `al-auto-dev.agent.md` | Keep as-is (already legacy per Phase 1) | — |
| `al-reviewer.agent.md` | Enhance with ERGEBNIS block — NO BREAKING CHANGE | main-agent, al-auto-dev |

**Files to CREATE (new, no conflicts):**
- `.github/agents/al-architect.agent.md`
- `.github/agents/al-coder.agent.md`
- `.github/agents/al-validator.agent.md`
- `.github/agents/al-tester.agent.md`

**Files to MODIFY:**
- `.github/agents/main-agent.agent.md` — update agents list, workflow table, SESSION.md schema
- `.github/agents/al-reviewer.agent.md` — add ERGEBNIS block to output section
- `.github/agents/al-planner.agent.md` — add deprecation note
- `.github/agents/al-implementer.agent.md` — add deprecation note
- `.github/agents/al-build-tester.agent.md` — add deprecation note
- `.planning/al-workflow/SESSION.md` — add new Phase 2 fields (or update template)

---

## 11. Open Questions / Assumptions Log (RESOLVED)

| # | Claim | Section | Risk if Wrong | Status |
|---|-------|---------|---------------|--------|
| A1 | T-shirt sizing hours are approximate (XS < 1h, S 1-4h, M 4-8h, L 8-16h, XL > 16h) | §4.4 | Wrong sizing leads to expectation mismatch with developer | RESOLVED: Rubrik in al-architect Schritt 5; developer can override |
| A2 | `.xlf` translation files exist in customer AL projects | §5.4 | al-coder creates translation entries that can't be placed anywhere | RESOLVED: al-coder does xlf-check at Schritt 5; skips gracefully if not found |
| A3 | `idRanges` in app.json is the source of truth for ID reservation | §4.4 | ID conflicts between agents/developers | RESOLVED: al-architect reads idRanges at Schritt 0; documented as required field |
| A4 | `runSubagent` passes JSON Plan Contract path, not inline JSON | §9 Pitfall 6 | If path-passing not supported, contract must be inlined (size limit risk) | RESOLVED: Contract written to disk as PLAN-CONTRACT-{id}.json; path in SESSION.md |
| A5 | al-architect does NOT have `terminal` tool — uses `al-build-validation` skill | §4.3 | If skill doesn't expose symbol download, architect cannot verify base objects | RESOLVED: al-architect uses `read` + `search` tools only; skill listed in frontmatter |
| A6 | validator_loop_count field added to SESSION.md schema | §8.4 | Validator loses loop count tracking across calls | RESOLVED: T8 adds `validator_loop_count` to SESSION.md template |
| A7 | BC runtime < 10.0 should trigger immediate BLOCKER in architect | §9 Pitfall 7 | Unlikely (NAV 2018 not in scope) but architecturally safer to guard | RESOLVED: al-architect Schritt 0 includes version guard; BLOCKER if < 10.0 |

---

## 12. File Creation Plan Summary

This table gives the planner the full picture of what Phase 2 produces:

| Action | File | Requirement | Notes |
|--------|------|-------------|-------|
| CREATE | `.github/agents/al-architect.agent.md` | ARCH-01..04 | Opus 4, JSON output, T-shirt sizing |
| CREATE | `.github/agents/al-coder.agent.md` | CODER-01 | Sonnet 4, terminal, absorbs implementer+builder |
| CREATE | `.github/agents/al-validator.agent.md` | VALID-01..03 | Opus 4, 5-layer, max 2 loops |
| CREATE | `.github/agents/al-tester.agent.md` | TEST-01..02 | Sonnet 4, GIVEN/WHEN/THEN, explicit-only |
| MODIFY | `.github/agents/main-agent.agent.md` | All (chaining) | Update agents list, workflow table, CP positions |
| MODIFY | `.github/agents/al-reviewer.agent.md` | CONTRACT-01 | Add ERGEBNIS block to output section |
| MODIFY | `.github/agents/al-planner.agent.md` | — | Add deprecation note only |
| MODIFY | `.github/agents/al-implementer.agent.md` | — | Add deprecation note only |
| MODIFY | `.github/agents/al-build-tester.agent.md` | — | Add deprecation note only |
| MODIFY | `.planning/al-workflow/SESSION.md` | ARCH-04, VALID-03 | Add architect_contract_path, validator_loop_count, tester_requested |

---

## Sources

### Primary (verified from codebase — HIGH confidence)
- `.github/agents/al-devops-reader.agent.md` — ERGEBNIS block canonical reference
- `.github/agents/main-agent.agent.md` — Checkpoint protocol, delegation syntax, workflow table
- `.github/agents/al-planner.agent.md` — Current planner gaps
- `.github/agents/al-implementer.agent.md` — Implementer tool set + policies
- `.github/agents/al-build-tester.agent.md` — Build loop protocol, fix loop max 3
- `.github/agents/al-reviewer.agent.md` — Review output format
- `.github/policies/agent-policy.md` — Confidence rubrik, Fix-Loop-Eskalation, T-shirt size basis
- `.github/instructions/al-coding-standards.instructions.md` — 10 coding rule categories for Layer 2
- `.github/instructions/al-testing.instructions.md` — GIVEN/WHEN/THEN pattern, test structure
- `.github/instructions/al-review.instructions.md` — 10 review criteria for reviewer enhancement
- `.planning/REQUIREMENTS.md` — Phase 2 requirement IDs
- `.planning/ROADMAP.md` — Success criteria, phase dependencies
- `.planning/STATE.md` — Key decisions, architecture notes, pitfalls already identified

### Assumed (LOW confidence — needs validation)
- AL object type list (complete list of BC AL object types) — assumed from training knowledge
- `.xlf` translation infrastructure in customer projects
- T-shirt sizing hour estimates
- `idRanges` as primary ID source in `app.json`

---

## RESEARCH COMPLETE

**Phase:** 2 — Spezialist-Refactoring
**Confidence:** HIGH

### Key Findings

1. **ERGEBNIS block is already a standard** — `al-devops-reader` established the canonical pattern
   in Phase 1. All Phase 2 agents must follow the same `## ERGEBNIS — {Name}` header + `### Interpretation für Main-Agent` footer pattern.

2. **JSON Plan Contract path**: Write to `.planning/al-workflow/PLAN-CONTRACT-{ticket_id}.json`
   and pass the path (not inline JSON) to avoid truncation in `runSubagent` calls.

3. **5-Layer Validation is concrete and implementable**: Each layer maps to specific file-level
   checks that al-validator can automate via `read`+`search` tools. No ambiguous "review"
   steps — each layer has pass/fail criteria.

4. **al-coder is a straight merge**: `al-implementer` tools + `al-build-tester` tools combined,
   with JSON Plan Contract as structured input instead of freetext. The fix-loop limit stays at 3
   (from policy) but al-coder owns the full loop.

5. **al-tester is a leaf-node**: Explicit `tester_requested: true` flag in SESSION.md is the
   guard. It never runs automatically. The planner should add a SESSION.md schema note.

6. **Backward compat is safe**: No existing files need to be deleted. Deprecation notes in
   frontmatter descriptions are the only change to legacy agents.

7. **main-agent update is scoped**: 4 changes: (1) agents list, (2) workflow table step 2/4/5,
   (3) CP-3/CP-4 position renaming, (4) SESSION.md schema extensions.

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| ERGEBNIS Block Templates | HIGH | Derived directly from al-devops-reader canonical pattern |
| JSON Plan Contract Schema | HIGH | Derived from AL object types + existing coding standards |
| 5-Layer Validation Design | HIGH | Derived from existing review/testing instructions files |
| al-coder Consolidation | HIGH | Direct analysis of both source agent files |
| T-shirt Sizing | MEDIUM | Mapped from existing Confidence-Rubrik — hour estimates assumed |
| Translation (.xlf) Handling | LOW | Assumed — customer projects not inspected |

### Ready for Planning
Research complete. Planner can now create PLAN.md for Phase 2.
