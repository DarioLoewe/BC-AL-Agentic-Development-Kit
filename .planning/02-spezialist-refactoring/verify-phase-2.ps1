#!/usr/bin/env pwsh
# Phase 2: Spezialist-Refactoring — Verifikationsskript
# Prüft alle 11 Requirements: ARCH-01..04, VALID-01..03, TEST-01..02, CODER-01, CONTRACT-01
#
# Ausführung vom Repo-Root:
#   pwsh .planning\02-spezialist-refactoring\verify-phase-2.ps1
#
# Wichtig: Nutzt (?m)^ für multiline Regex (PowerShell-Bug ohne (?m): ^ matcht nur String-Anfang)

param(
    [string]$RepoRoot = ""
)

# Repo-Root ermitteln (2 Ebenen über dem Skript-Verzeichnis)
if ([string]::IsNullOrEmpty($RepoRoot)) {
    $RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
}
$RepoRoot = $RepoRoot.ToString().TrimEnd('\')

$ErrorCount = 0
$PassCount  = 0

function Check {
    param([string]$Req, [string]$Description, [bool]$Condition)
    if ($Condition) {
        Write-Host ("  PASS [{0}] {1}" -f $Req, $Description) -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host ("  FAIL [{0}] {1}" -f $Req, $Description) -ForegroundColor Red
        $script:ErrorCount++
    }
}

function Get-FileContent {
    param([string]$Path)
    if (Test-Path $Path) { return (Get-Content $Path -Raw) } else { return "" }
}

Write-Host ""
Write-Host "=== Phase 2: Spezialist-Refactoring — Verifikation ===" -ForegroundColor Cyan
Write-Host ("Repo: {0}" -f $RepoRoot)
Write-Host ("Datum: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm"))
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# ARCH-01..04: al-architect.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- ARCH: al-architect.agent.md ---" -ForegroundColor Yellow
$archPath = Join-Path $RepoRoot ".github\agents\al-architect.agent.md"
$archOK   = Test-Path $archPath
Check "ARCH-01" "al-architect.agent.md existiert" $archOK

if ($archOK) {
    $c = Get-FileContent $archPath
    Check "ARCH-01" "model: claude-opus-4 im Frontmatter" ($c -match 'model:\s*claude-opus-4')
    Check "ARCH-02" "Liest app.json (BC-Version-Awareness)" ($c -match 'app\.json')
    Check "ARCH-02" "Listet .alpackages Verzeichnis auf" ($c -match '\.alpackages')
    Check "ARCH-03" "T-Shirt-Sizing Rubrik vorhanden (XS..XL)" ($c -match '(?i)\bXS\b' -and $c -match '(?i)\bXL\b')
    Check "ARCH-04" "plan_contract_version im JSON-Schema" ($c -match 'plan_contract_version')
    Check "ARCH-04" "JSON-Schema hat objects-Array" ($c -match '"objects"')
    Check "ARCH-04" "JSON-Schema hat fields-Struktur" ($c -match '"fields"')
    Check "ARCH-04" "JSON-Schema hat proposed_id" ($c -match 'proposed_id')
    Check "ARCH-04" "JSON-Schema hat data_classification" ($c -match 'data_classification')
    Check "ARCH-04" "Contract-Pfad PLAN-CONTRACT referenziert" ($c -match 'PLAN-CONTRACT')
    Check "CONTRACT-01" "## ERGEBNIS — Architect Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat contract_path Feld" ($c -match 'contract_path')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# CODER-01: al-coder.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- CODER-01: al-coder.agent.md ---" -ForegroundColor Yellow
$coderPath = Join-Path $RepoRoot ".github\agents\al-coder.agent.md"
$coderOK   = Test-Path $coderPath
Check "CODER-01" "al-coder.agent.md existiert" $coderOK

if ($coderOK) {
    $c = Get-FileContent $coderPath
    Check "CODER-01" "model: claude-sonnet-4-5 im Frontmatter" ($c -match 'model:\s*claude-sonnet-4-5')
    Check "CODER-01" "tools: terminal im Frontmatter" ($c -match '"terminal"')
    Check "CODER-01" "tools: edit im Frontmatter" ($c -match '"edit"')
    Check "CODER-01" "Liest JSON Plan Contract (architect_contract_path)" ($c -match 'architect_contract_path')
    Check "CODER-01" "al_downloadsymbols vor Code-Schreiben" ($c -match 'al_downloadsymbols')
    Check "CODER-01" "Objekt-ID Vergabe (proposed_id)" ($c -match 'proposed_id')
    Check "CODER-01" "Uebersetzungseintraege (.xlf) behandelt" ($c -match '\.xlf')
    Check "CODER-01" "Max 3 Fix-Schleifen (aus policy)" ($c -match '3.*Schleife|Fix-Loop|max.*3')
    Check "CODER-01" "BLOCKER-REPORT.md Erstellung bei Eskalation" ($c -match 'BLOCKER-REPORT')
    Check "CODER-01" "Konsolidiert al-implementer (skills: al-object-analysis)" ($c -match 'al-object-analysis')
    Check "CODER-01" "Konsolidiert al-build-tester (skills: al-build-validation)" ($c -match 'al-build-validation')
    Check "CONTRACT-01" "## ERGEBNIS — Coder Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Build-Ergebnis / Build-Status" ($c -match 'Build-Ergebnis|Build-Status|Buildstatus')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# VALID-01..03: al-validator.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- VALID: al-validator.agent.md ---" -ForegroundColor Yellow
$validPath = Join-Path $RepoRoot ".github\agents\al-validator.agent.md"
$validOK   = Test-Path $validPath
Check "VALID-01" "al-validator.agent.md existiert" $validOK

if ($validOK) {
    $c = Get-FileContent $validPath
    Check "VALID-01" "model: claude-opus-4 im Frontmatter (reasoning-heavy task)" ($c -match 'model:\s*claude-opus-4')
    Check "VALID-01" "Kein edit-Tool (Validator schreibt keinen Code)" (-not ($c -match '"edit"'))
    Check "VALID-01" "Kein terminal-Tool" (-not ($c -match '"terminal"'))
    Check "VALID-02" "Layer 1: AC-Objekt-Mapping erwaehnt" ($c -match 'Layer 1|AC.*Mapping|AC.*Objekt')
    Check "VALID-02" "Layer 2: AL-Konventionen erwaehnt" ($c -match 'Layer 2|AL-Konventionen|Konventionen')
    Check "VALID-02" "Layer 3: Test-Coverage erwaehnt" ($c -match 'Layer 3|Test-Coverage|Testabdeckung')
    Check "VALID-02" "Layer 4: Diff-Verifikation erwaehnt" ($c -match 'Layer 4|Diff-Verifikation')
    Check "VALID-02" "Layer 5: Korrektur-Trigger erwaehnt" ($c -match 'Layer 5|Korrektur-Trigger')
    Check "VALID-03" "Max 2 Korrekturschleifen dokumentiert" ($c -match 'max.*2|2.*Schleife|2.*Korrektur')
    Check "VALID-03" "BLOCKER-REPORT.md Erstellung bei Eskalation" ($c -match 'BLOCKER-REPORT')
    Check "VALID-03" "validator_loop_count Tracking erwaehnt" ($c -match 'validator_loop_count|Schleifenzaehler|Korrekturschleifen')
    Check "CONTRACT-01" "## ERGEBNIS — Validator Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat 5-Layer Prueftabelle" ($c -match 'Layer.*Pruefpunkt|5-Layer|Layer.*Status')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# TEST-01..02: al-tester.agent.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- TEST: al-tester.agent.md ---" -ForegroundColor Yellow
$testerPath = Join-Path $RepoRoot ".github\agents\al-tester.agent.md"
$testerOK   = Test-Path $testerPath
Check "TEST-01" "al-tester.agent.md existiert" $testerOK

if ($testerOK) {
    $c = Get-FileContent $testerPath
    Check "TEST-01" "Explizit-Guard: tester_requested in SESSION.md" ($c -match 'tester_requested')
    Check "TEST-01" "Guard: NIEMALS automatisch aufgerufen" ($c -match '(?i)niemals automatisch|never.*automat')
    Check "TEST-01" "Guard am Anfang des Dokuments (vor Aufgabe)" (($c.IndexOf('tester_requested')) -lt ($c.IndexOf('## Aufgabe') + 1))
    Check "TEST-02" "GIVEN/WHEN/THEN Pattern vorhanden" ($c -match '\[GIVEN\]|\[WHEN\]|\[THEN\]|GIVEN.*WHEN.*THEN')
    Check "TEST-02" "Verweis auf al-testing.instructions.md" ($c -match 'al-testing\.instructions')
    Check "TEST-02" "Subtype = Test im AL-Beispiel" ($c -match 'Subtype\s*=\s*Test')
    Check "CONTRACT-01" "## ERGEBNIS — Tester Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Erstellte Tests Tabelle" ($c -match 'Erstellte Tests|tests_created|Testmethode')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# CONTRACT-01: al-reviewer.agent.md — ERGEBNIS-Block vorhanden
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- CONTRACT-01: al-reviewer.agent.md ---" -ForegroundColor Yellow
$reviewerPath = Join-Path $RepoRoot ".github\agents\al-reviewer.agent.md"
if (Test-Path $reviewerPath) {
    $c = Get-FileContent $reviewerPath
    Check "CONTRACT-01" "## ERGEBNIS — Reviewer Block vorhanden" ($c -match '(?m)^## ERGEBNIS')
    Check "CONTRACT-01" "ERGEBNIS hat Pruefergebnis Tabelle" ($c -match 'Pruefer?gebnis|Kriterium.*Status|Review-Status')
    Check "CONTRACT-01" "ERGEBNIS hat Interpretation fuer Main-Agent" ($c -match 'Interpretation.*Main-Agent')
} else {
    Check "CONTRACT-01" "al-reviewer.agent.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# SESSION.md: Phase-2-Felder
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- SESSION.md: Phase-2-Felder ---" -ForegroundColor Yellow
$sessionPath = Join-Path $RepoRoot ".planning\al-workflow\SESSION.md"
if (Test-Path $sessionPath) {
    $c = Get-FileContent $sessionPath
    Check "ARCH-04"  "SESSION.md: architect_contract_path Feld vorhanden" ($c -match 'architect_contract_path')
    Check "VALID-03" "SESSION.md: validator_loop_count Feld vorhanden" ($c -match 'validator_loop_count')
    Check "TEST-01"  "SESSION.md: tester_requested Feld vorhanden" ($c -match 'tester_requested')
} else {
    Check "ARCH-04"  "SESSION.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# Deprecation: Legacy-Agents
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- Deprecation: Legacy-Agents ---" -ForegroundColor Yellow
foreach ($agentName in @("al-planner", "al-implementer", "al-build-tester")) {
    $agentPath = Join-Path $RepoRoot ".github\agents\$agentName.agent.md"
    if (Test-Path $agentPath) {
        $c = Get-FileContent $agentPath
        Check "Compat" "$agentName hat [DEPRECATED] im Frontmatter" ($c -match '\[DEPRECATED')
    } else {
        Check "Compat" "$agentName.agent.md existiert noch (backward compat)" $false
    }
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# AGENTS.md: Phase-2-Roster
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- AGENTS.md: Roster-Update ---" -ForegroundColor Yellow
$agentsPath = Join-Path $RepoRoot "AGENTS.md"
if (Test-Path $agentsPath) {
    $c = Get-FileContent $agentsPath
    Check "Roster" "AGENTS.md erwaehnt al-architect" ($c -match 'al-architect')
    Check "Roster" "AGENTS.md erwaehnt al-coder" ($c -match 'al-coder')
    Check "Roster" "AGENTS.md erwaehnt al-validator" ($c -match 'al-validator')
    Check "Roster" "AGENTS.md erwaehnt al-tester" ($c -match 'al-tester')
} else {
    Check "Roster" "AGENTS.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# main-agent.agent.md: Phase-2-Updates
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- main-agent.agent.md: Phase-2-Updates ---" -ForegroundColor Yellow
$mainPath = Join-Path $RepoRoot ".github\agents\main-agent.agent.md"
if (Test-Path $mainPath) {
    $c = Get-FileContent $mainPath
    Check "Orchestr" "main-agent agents: enthaelt al-architect" ($c -match 'al-architect')
    Check "Orchestr" "main-agent agents: enthaelt al-coder" ($c -match 'al-coder')
    Check "Orchestr" "main-agent agents: enthaelt al-validator" ($c -match 'al-validator')
    Check "Orchestr" "main-agent agents: enthaelt al-tester" ($c -match 'al-tester')
    Check "TEST-01"  "main-agent hat tester_requested Guard" ($c -match 'tester_requested')
    Check "VALID-03" "main-agent hat validator_loop_count Referenz" ($c -match 'validator_loop_count')
    Check "ARCH-04"  "main-agent hat architect_contract_path Referenz" ($c -match 'architect_contract_path')
} else {
    Check "Orchestr" "main-agent.agent.md existiert" $false
}

Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# Zusammenfassung
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("  Bestanden:       {0}" -f $PassCount) -ForegroundColor Green
Write-Host ("  Fehlgeschlagen:  {0}" -f $ErrorCount) -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Host "  Alle Phase-2-Anforderungen erfuellt!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("  {0} Pruefung(en) fehlgeschlagen." -f $ErrorCount) -ForegroundColor Red
    Write-Host "  Bitte offene Punkte beheben und Skript erneut ausfuehren." -ForegroundColor Yellow
    exit 1
}
