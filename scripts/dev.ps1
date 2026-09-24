param(
    [string[]]$WowAddOnsPath
)

$ErrorActionPreference = 'Stop'

$addonName = 'ProEnchanters'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Personal machine paths never live in source control. Provide yours via:
#  - the -WowAddOnsPath parameter (one or more paths),
#  - the PE_WOW_ADDONS_PATH environment variable (';'-separated), or
#  - a local scripts\dev.local.ps1 file (gitignored) that sets $WowAddOnsPaths
#    (array) or $WowAddOnsPath (single string).
$targets = @()
if ($WowAddOnsPath) { $targets = @($WowAddOnsPath) }

if (-not $targets) {
    $localOverride = Join-Path $PSScriptRoot 'dev.local.ps1'
    if (Test-Path -LiteralPath $localOverride) {
        . $localOverride
        if ($WowAddOnsPaths) { $targets = @($WowAddOnsPaths) }
        elseif ($WowAddOnsPath) { $targets = @($WowAddOnsPath) }
    }
}

if (-not $targets -and $env:PE_WOW_ADDONS_PATH) {
    $targets = $env:PE_WOW_ADDONS_PATH -split ';' | Where-Object { $_ }
}

if (-not $targets) {
    throw "No WoW AddOns folder configured. Pass -WowAddOnsPath, set PE_WOW_ADDONS_PATH, or create scripts\dev.local.ps1 setting `$WowAddOnsPaths."
}

# The repository root is the addon folder. Everything that is not part of the
# shipped addon (git metadata, dev tooling, source spreadsheets) stays behind.
$excludeDirs = @('.git', '.github', '.vscode', 'scripts', 'tools')
$excludeFiles = @('.gitignore', '.gitattributes', '*.xlsx', '*.zip', '*.log')

# Dev-only companion addons shipped from tools\ (each folder holds its own .toc)
$companions = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "$($_.Name).toc") })

# Only ever deploy into a real WoW AddOns folder, whatever the flavour.
$flavourPattern = 'World of Warcraft\\_[^\\]+_\\Interface\\AddOns$'
$deployed = 0

function Invoke-Mirror([string]$source, [string]$destination, [string[]]$extraArgs) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    robocopy $source $destination /MIR /NFL /NDL /NJH /NJS /NP @extraArgs | Out-Host
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE (target: $destination)"
    }
}

foreach ($path in $targets) {
    if (-not $path) { continue }
    if (-not (Test-Path -LiteralPath $path)) {
        throw "AddOns folder not found: $path"
    }

    $resolved = (Resolve-Path -LiteralPath $path).Path.TrimEnd('\')
    if ($resolved -notmatch $flavourPattern) {
        throw "Refusing to deploy outside a WoW AddOns folder: $resolved"
    }

    Invoke-Mirror $projectRoot (Join-Path $resolved $addonName) (@('/XD') + $excludeDirs + @('/XF') + $excludeFiles)
    Write-Host "DEV deploy complete -> $(Join-Path $resolved $addonName)"

    foreach ($companion in $companions) {
        Invoke-Mirror $companion.FullName (Join-Path $resolved $companion.Name) @()
        Write-Host "DEV deploy complete -> $(Join-Path $resolved $companion.Name)"
    }
    $deployed++
}

Write-Host "Deployed to $deployed folder(s). Reload WoW with /reload to test (a new addon folder needs a client restart)."
exit 0
