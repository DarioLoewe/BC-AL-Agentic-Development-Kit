<#
.SYNOPSIS
    Phase 4 Verifikations-Skript — prüft alle HELP-01..04 Anforderungen.
.DESCRIPTION
    Überprüft ob alle Phase-4-Artefakte korrekt erstellt und aktualisiert wurden:
    - HELP-01: al-websearch.agent.md (Frontmatter, Verbote, Aufruf-Protokoll, Output-Header)
    - HELP-02: al-code-research.agent.md (Frontmatter, Verbote, Aufruf-Protokoll, Fallback)
    - HELP-03: Leaf-Node-Verifikation (kein ERGEBNIS-Block in Helpers)
    - HELP-04: Caller-Updates (al-architect, al-coder, main-agent, AGENTS.md)
.EXAMPLE
    cd C:\Users\dloewe\BC-AL-Agentic-Development-Kit
    .\.planning\04-helper-agents\verify-phase-4.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Repo-Root: zwei Ebenen über dem Skript-Verzeichnis
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$AgentsDir = Join-Path $RepoRoot ".github\agents"

$PassedChecks = [System.Collections.Generic.List[string]]::new()
$FailedChecks = [System.Collections.Generic.List[string]]::new()

function Assert-Check {
    param(
        [string]$RequirementId,
        [string]$Description,
        [bool]$Result
    )
    $label = "[$RequirementId] $Description"
    if ($Result) {
        $PassedChecks.Add($label)
        Write-Host "  PASS  $label" -ForegroundColor Green
    } else {
        $FailedChecks.Add($label)
        Write-Host "  FAIL  $label" -ForegroundColor Red
    }
}

Write-Host "`nPhase 4: Helper Agents — Verifikation" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# ──────────────────────────────────────────────────────────────
# HELP-01: al-websearch.agent.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-01] al-websearch.agent.md" -ForegroundColor Yellow

$wsPath = Join-Path $AgentsDir "al-websearch.agent.md"
$wsExists = Test-Path $wsPath
Assert-Check "HELP-01" "al-websearch.agent.md existiert" $wsExists

if ($wsExists) {
    $ws = Get-Content $wsPath -Raw -Encoding UTF8

    Assert-Check "HELP-01" "model: claude-sonnet-4-5" ($ws -match 'model:\s*claude-sonnet-4-5')
    Assert-Check "HELP-01" "tools enthaelt web_search" ($ws -match 'web_search')
    Assert-Check "HELP-01" 'tools enthaelt "read"' ($ws -match '"read"')
    Assert-Check "HELP-01" "Abschnitt ABSOLUTES VERBOT vorhanden" ($ws -match '##\s*ABSOLUTES VERBOT')
    Assert-Check "HELP-01" "Keinen ERGEBNIS-Block produzieren im Verbot" ($ws -match 'Keinen ERGEBNIS-Block produzieren')
    Assert-Check "HELP-01" "Abschnitt Aufruf-Protokoll vorhanden" ($ws -match '##\s*Aufruf-Protokoll')
    Assert-Check "HELP-01" "## Output Header vorhanden" ($ws -match '(?m)^##\s+Output\s*$')
    Assert-Check "HELP-01" "Pre-Flight web_search-Verfuegbarkeit dokumentiert" ($ws -match 'Pre-Flight')
    Assert-Check "HELP-01" "URL-Prioritaetsliste mit learn.microsoft.com" (
        $ws -match 'learn\.microsoft\.com.*dynamics365.*business-central'
    )
    Assert-Check "HELP-01" "Aufruf-Protokoll nennt al-architect als zugelassenen Caller" (
        $ws -match 'al-architect'
    )
    Assert-Check "HELP-01" "Aufruf-Protokoll nennt al-coder als zugelassenen Caller" (
        $ws -match 'al-coder'
    )
} else {
    @(
        "model: claude-sonnet-4-5",
        "tools enthaelt web_search",
        'tools enthaelt "read"',
        "Abschnitt ABSOLUTES VERBOT vorhanden",
        "Keinen ERGEBNIS-Block produzieren im Verbot",
        "Abschnitt Aufruf-Protokoll vorhanden",
        "## Output Header vorhanden",
        "Pre-Flight web_search-Verfuegbarkeit dokumentiert",
        "URL-Prioritaetsliste mit learn.microsoft.com",
        "Aufruf-Protokoll nennt al-architect als zugelassenen Caller",
        "Aufruf-Protokoll nennt al-coder als zugelassenen Caller"
    ) | ForEach-Object { Assert-Check "HELP-01" $_ $false }
}

# ──────────────────────────────────────────────────────────────
# HELP-02: al-code-research.agent.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-02] al-code-research.agent.md" -ForegroundColor Yellow

$crPath = Join-Path $AgentsDir "al-code-research.agent.md"
$crExists = Test-Path $crPath
Assert-Check "HELP-02" "al-code-research.agent.md existiert" $crExists

if ($crExists) {
    $cr = Get-Content $crPath -Raw -Encoding UTF8

    Assert-Check "HELP-02" "model: claude-sonnet-4-5" ($cr -match 'model:\s*claude-sonnet-4-5')
    Assert-Check "HELP-02" 'tools enthaelt "read"' ($cr -match '"read"')
    Assert-Check "HELP-02" 'tools enthaelt "search"' ($cr -match '"search"')
    Assert-Check "HELP-02" "Abschnitt ABSOLUTES VERBOT vorhanden" ($cr -match '##\s*ABSOLUTES VERBOT')
    Assert-Check "HELP-02" "Keinen ERGEBNIS-Block produzieren im Verbot" ($cr -match 'Keinen ERGEBNIS-Block produzieren')
    Assert-Check "HELP-02" "Abschnitt Aufruf-Protokoll vorhanden" ($cr -match '##\s*Aufruf-Protokoll')
    Assert-Check "HELP-02" "## Output Header vorhanden" ($cr -match '(?m)^##\s+Output\s*$')
    Assert-Check "HELP-02" "vscode_listCodeUsages erwaehnt" ($cr -match 'vscode_listCodeUsages')
    Assert-Check "HELP-02" "vscode_listCodeUsages als optional dokumentiert" (
        $cr -match 'vscode_listCodeUsages' -and ($cr -match 'optional' -or $cr -match '[Ff]allback')
    )
    Assert-Check "HELP-02" "grep/search Fallback dokumentiert" ($cr -match 'grep')
    Assert-Check "HELP-02" "Nutze diese Skills (al-object-analysis) vorhanden" (
        $cr -match 'al-object-analysis'
    )
    Assert-Check "HELP-02" "Aufruf-Protokoll nennt al-architect als zugelassenen Caller" (
        $cr -match 'al-architect'
    )
    Assert-Check "HELP-02" "Aufruf-Protokoll nennt al-coder als zugelassenen Caller" (
        $cr -match 'al-coder'
    )
} else {
    @(
        "model: claude-sonnet-4-5",
        'tools enthaelt "read"',
        'tools enthaelt "search"',
        "Abschnitt ABSOLUTES VERBOT vorhanden",
        "Keinen ERGEBNIS-Block produzieren im Verbot",
        "Abschnitt Aufruf-Protokoll vorhanden",
        "## Output Header vorhanden",
        "vscode_listCodeUsages erwaehnt",
        "vscode_listCodeUsages als optional dokumentiert",
        "grep/search Fallback dokumentiert",
        "Nutze diese Skills (al-object-analysis) vorhanden",
        "Aufruf-Protokoll nennt al-architect als zugelassenen Caller",
        "Aufruf-Protokoll nennt al-coder als zugelassenen Caller"
    ) | ForEach-Object { Assert-Check "HELP-02" $_ $false }
}

# ──────────────────────────────────────────────────────────────
# HELP-03: Leaf-Node Verifikation (kein ERGEBNIS in Helpers)
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-03] Leaf-Node Verifikation" -ForegroundColor Yellow

if ($wsExists) {
    $ws = Get-Content $wsPath -Raw -Encoding UTF8
    $wsHasErgebnis = $ws -match '(?m)^##\s+ERGEBNIS'
    Assert-Check "HELP-03" "al-websearch hat keinen ## ERGEBNIS Abschnittstitel" (-not $wsHasErgebnis)

    $frontmatterMatch = [regex]::Match($ws, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-03" "al-websearch hat kein agents: im Frontmatter (Leaf-Node)" (-not ($fm -match '^agents:'))
        Assert-Check "HELP-03" "al-websearch hat kein skills: im Frontmatter (Leaf-Node)" (-not ($fm -match '^skills:'))
    } else {
        Assert-Check "HELP-03" "al-websearch hat kein agents: im Frontmatter (Leaf-Node)" $false
        Assert-Check "HELP-03" "al-websearch hat kein skills: im Frontmatter (Leaf-Node)" $false
    }
} else {
    Assert-Check "HELP-03" "al-websearch hat keinen ## ERGEBNIS Abschnittstitel" $false
    Assert-Check "HELP-03" "al-websearch hat kein agents: im Frontmatter (Leaf-Node)" $false
    Assert-Check "HELP-03" "al-websearch hat kein skills: im Frontmatter (Leaf-Node)" $false
}

if ($crExists) {
    $cr = Get-Content $crPath -Raw -Encoding UTF8
    $crHasErgebnis = $cr -match '(?m)^##\s+ERGEBNIS'
    Assert-Check "HELP-03" "al-code-research hat keinen ## ERGEBNIS Abschnittstitel" (-not $crHasErgebnis)

    $frontmatterMatch = [regex]::Match($cr, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-03" "al-code-research hat kein agents: im Frontmatter (Leaf-Node)" (-not ($fm -match '^agents:'))
        Assert-Check "HELP-03" "al-code-research hat kein skills: im Frontmatter (Leaf-Node)" (-not ($fm -match '^skills:'))
    } else {
        Assert-Check "HELP-03" "al-code-research hat kein agents: im Frontmatter (Leaf-Node)" $false
        Assert-Check "HELP-03" "al-code-research hat kein skills: im Frontmatter (Leaf-Node)" $false
    }
} else {
    Assert-Check "HELP-03" "al-code-research hat keinen ## ERGEBNIS Abschnittstitel" $false
    Assert-Check "HELP-03" "al-code-research hat kein agents: im Frontmatter (Leaf-Node)" $false
    Assert-Check "HELP-03" "al-code-research hat kein skills: im Frontmatter (Leaf-Node)" $false
}

# ──────────────────────────────────────────────────────────────
# HELP-04: Aufruf-Protokoll in Caller-Agents
# ──────────────────────────────────────────────────────────────
Write-Host "`n[HELP-04] Caller-Agent Updates" -ForegroundColor Yellow

$archPath = Join-Path $AgentsDir "al-architect.agent.md"
if (Test-Path $archPath) {
    $arch = Get-Content $archPath -Raw -Encoding UTF8
    Assert-Check "HELP-04" "al-architect agents: enthaelt al-websearch" ($arch -match 'agents:[\s\S]*?al-websearch')
    Assert-Check "HELP-04" "al-architect agents: enthaelt al-code-research" ($arch -match 'agents:[\s\S]*?al-code-research')
    Assert-Check "HELP-04" "al-architect agents: enthaelt noch al-codebase-analyst" ($arch -match 'al-codebase-analyst')
    Assert-Check "HELP-04" "al-architect Body enthaelt Helper-Aufruf Sektion" ($arch -match 'Helper-Aufruf')
    Assert-Check "HELP-04" "al-architect Helper-Aufruf ist On-Demand (nicht Default)" (
        $arch -match 'NICHT als Default'
    )
} else {
    Write-Host "  WARN  al-architect.agent.md nicht gefunden" -ForegroundColor DarkYellow
}

$coderPath = Join-Path $AgentsDir "al-coder.agent.md"
if (Test-Path $coderPath) {
    $coder = Get-Content $coderPath -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($coder, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "HELP-04" "al-coder hat agents: Frontmatter-Feld (neu)" ($fm -match '(?m)^agents:')
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-code-research" ($fm -match 'al-code-research')
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-websearch" ($fm -match 'al-websearch')
    } else {
        Assert-Check "HELP-04" "al-coder hat agents: Frontmatter-Feld (neu)" $false
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-code-research" $false
        Assert-Check "HELP-04" "al-coder agents: enthaelt al-websearch" $false
    }
    Assert-Check "HELP-04" "al-coder Body enthaelt Helper-Aufruf Sektion" ($coder -match 'Helper-Aufruf')
    Assert-Check "HELP-04" "al-coder Helper-Aufruf ist On-Demand (nicht Default)" (
        $coder -match 'NICHT als Default'
    )
} else {
    Write-Host "  WARN  al-coder.agent.md nicht gefunden" -ForegroundColor DarkYellow
}

# ──────────────────────────────────────────────────────────────
# Roster: main-agent.agent.md + AGENTS.md
# ──────────────────────────────────────────────────────────────
Write-Host "`n[Roster] main-agent.agent.md + AGENTS.md" -ForegroundColor Yellow

$mainPath = Join-Path $AgentsDir "main-agent.agent.md"
if (Test-Path $mainPath) {
    $main = Get-Content $mainPath -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($main, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $fm = $frontmatterMatch.Groups[1].Value
        Assert-Check "Roster" "main-agent agents: enthaelt al-websearch" ($fm -match 'al-websearch')
        Assert-Check "Roster" "main-agent agents: enthaelt al-code-research" ($fm -match 'al-code-research')
    } else {
        Assert-Check "Roster" "main-agent agents: enthaelt al-websearch" $false
        Assert-Check "Roster" "main-agent agents: enthaelt al-code-research" $false
    }
    Assert-Check "Roster" "main-agent Body enthaelt Helper-Agents Infrastruktur-Hinweis" (
        $main -match 'Helper-Agents'
    )
} else {
    Write-Host "  WARN  main-agent.agent.md nicht gefunden" -ForegroundColor DarkYellow
}

$agentsMdPath = Join-Path $RepoRoot "AGENTS.md"
if (Test-Path $agentsMdPath) {
    $agentsMd = Get-Content $agentsMdPath -Raw -Encoding UTF8

    Assert-Check "Roster" "AGENTS.md: al-websearch in Aktuelle Agents Tabelle" (
        $agentsMd -match 'al-websearch.*Aktiv'
    )
    Assert-Check "Roster" "AGENTS.md: al-code-research in Aktuelle Agents Tabelle" (
        $agentsMd -match 'al-code-research.*Aktiv'
    )

    $geplantBlock = [regex]::Match($agentsMd, '(?s)### Geplante Agents.*?(?=###|\z)')
    if ($geplantBlock.Success) {
        $geplant = $geplantBlock.Value
        Assert-Check "Roster" "AGENTS.md: al-websearch nicht mehr in Geplante Agents" (
            -not ($geplant -match 'al-websearch\.agent\.md.*Phase 4')
        )
        Assert-Check "Roster" "AGENTS.md: al-code-research nicht mehr in Geplante Agents" (
            -not ($geplant -match 'al-code-research\.agent\.md.*Phase 4')
        )
    }
} else {
    Write-Host "  WARN  AGENTS.md nicht gefunden" -ForegroundColor DarkYellow
}

# ──────────────────────────────────────────────────────────────
# Zusammenfassung
# ──────────────────────────────────────────────────────────────
Write-Host ("`n" + ("=" * 50)) -ForegroundColor Cyan
Write-Host "Ergebnis Phase 4 Verifikation" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "  Bestanden: $($PassedChecks.Count)" -ForegroundColor Green
Write-Host "  Fehler:    $($FailedChecks.Count)" -ForegroundColor $(if ($FailedChecks.Count -eq 0) { "Green" } else { "Red" })

if ($FailedChecks.Count -gt 0) {
    Write-Host "`nFehlgeschlagene Pruefungen:" -ForegroundColor Red
    $FailedChecks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host "`nAlle Phase-4-Anforderungen erfuellt. Phase 4 ist abgeschlossen." -ForegroundColor Green
    exit 0
}
