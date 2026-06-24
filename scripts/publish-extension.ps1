# publish-extension.ps1
# Synct AL-Dateien aus dem Kit in die Extension und veröffentlicht auf dem VS Code Marketplace.
# Aufruf: .\scripts\publish-extension.ps1 [-VersionBump patch|minor|major] [-PackageOnly]

param(
    [ValidateSet("patch", "minor", "major")]
    [string]$VersionBump = "patch",

    [switch]$PackageOnly   # Nur VSIX bauen, nicht publishen
)

$ErrorActionPreference = "Stop"

$kitRoot = $PSScriptRoot | Split-Path -Parent
$extRoot = "C:\Users\dloewe\bc-al-agents-extension"

Write-Host "=== BC AL Agent Hub — Extension Build ===" -ForegroundColor Cyan

# 1. AL-Agents kopieren (al-* + main-agent)
Write-Host "Kopiere Agents..." -ForegroundColor Yellow
Get-ChildItem "$kitRoot\.github\agents" -Filter "al-*.agent.md" |
    Copy-Item -Destination "$extRoot\agents\" -Force
Copy-Item "$kitRoot\.github\agents\main-agent.agent.md" "$extRoot\agents\" -Force

# 2. Instructions kopieren
Write-Host "Kopiere Instructions..." -ForegroundColor Yellow
Get-ChildItem "$kitRoot\.github\instructions" -Filter "*.instructions.md" |
    Copy-Item -Destination "$extRoot\instructions\" -Force

# 3. Skills kopieren
Write-Host "Kopiere Skills..." -ForegroundColor Yellow
$skills = @("al-build-validation","al-code-review","al-devops-workitem","al-object-analysis","al-test-design")
foreach ($s in $skills) {
    Copy-Item "$kitRoot\.github\skills\$s\SKILL.md" "$extRoot\skills\$s\SKILL.md" -Force
}

# 4. Version in package.json hochzählen
Write-Host "Bumpe Version ($VersionBump)..." -ForegroundColor Yellow
Set-Location $extRoot
npx @vscode/vsce version $VersionBump --no-git-tag-version 2>&1 | Out-Null
$version = (Get-Content "$extRoot\package.json" | ConvertFrom-Json).version
Write-Host "Neue Version: $version" -ForegroundColor Green

# 5. Paketieren
Write-Host "Paketiere VSIX..." -ForegroundColor Yellow
npx @vscode/vsce package --no-dependencies 2>&1

if ($PackageOnly) {
    Write-Host "=== DONE: VSIX erstellt (kein Publish) ===" -ForegroundColor Green
    Write-Host "Datei: $extRoot\al-agent-hub-$version.vsix"
    exit 0
}

# 6. Publishen
Write-Host "Publishe auf Marketplace..." -ForegroundColor Yellow
npx @vscode/vsce publish --no-dependencies 2>&1

Write-Host "=== DONE: al-agent-hub v$version veröffentlicht ===" -ForegroundColor Green
Write-Host "URL: https://marketplace.visualstudio.com/items?itemName=ALDevelopmentTools.al-agent-hub"
