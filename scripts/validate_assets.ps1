# Validates Dart-referenced assets and approved manifest entries exist on disk.
# Usage: ./scripts/validate_assets.ps1 [-StrictUnreferenced]
param(
    [switch]$StrictUnreferenced
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root "pubspec.yaml"))) {
    Write-Error "Run from repo root (pubspec.yaml not found at $root)"
}

$generated = Join-Path $root "assets\generated"
$missing = [System.Collections.Generic.List[string]]::new()
$manifestMissing = [System.Collections.Generic.List[string]]::new()

# ── Code references (world_assets.dart, cosmetics.dart) ─────────────────
$patterns = @(
    (Join-Path $root "lib\utils\world_assets.dart"),
    (Join-Path $root "lib\config\cosmetics.dart")
)

$paths = [System.Collections.Generic.HashSet[string]]::new()
foreach ($file in $patterns) {
    if (-not (Test-Path $file)) { continue }
    $content = Get-Content $file -Raw
    [regex]::Matches($content, "assets/generated/[a-z0-9._-]+") | ForEach-Object {
        [void]$paths.Add($_.Value.Replace("/", "\"))
    }
}

foreach ($rel in ($paths | Sort-Object)) {
    $full = Join-Path $root ($rel -replace "/", "\")
    if (-not (Test-Path $full)) {
        $missing.Add($rel.Replace("\", "/"))
    }
}

# ── Manifest approved → finalPath on disk ────────────────────────────────
$manifestPath = Join-Path $root "docs\assets\image-manifest.json"
$manifestApproved = 0
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    foreach ($item in $manifest.items) {
        if ($item.status -ne "approved") { continue }
        if (-not $item.finalPath) { continue }
        $manifestApproved++
        $rel = ($item.finalPath -replace "/", "\")
        $full = Join-Path $root $rel
        if (-not (Test-Path $full)) {
            $manifestMissing.Add($item.finalPath)
        }
    }
}

# ── Core achievement badge PNGs (Wave 20 CI gate) ─────────────────────────
$coreIdsPath = Join-Path $root "lib\config\core_achievement_badge_ids.dart"
$worldAssetsPath = Join-Path $root "lib\utils\world_assets.dart"
$coreBadgeMissing = [System.Collections.Generic.List[string]]::new()
if ((Test-Path $coreIdsPath) -and (Test-Path $worldAssetsPath)) {
    $coreContent = Get-Content $coreIdsPath -Raw
    $worldAssetsContent = Get-Content $worldAssetsPath -Raw
    $badgeMap = @{}
    [regex]::Matches($worldAssetsContent, "'([^']+)': 'assets/generated/([^']+)'") | ForEach-Object {
        $badgeMap[$_.Groups[1].Value] = $_.Groups[2].Value
    }
    [regex]::Matches($coreContent, "'([a-z0-9-]+)'") | ForEach-Object {
        $id = $_.Groups[1].Value
        if ($id.Length -lt 3) { return }
        $rel = if ($badgeMap.ContainsKey($id)) {
            "assets/generated/$($badgeMap[$id])"
        } else {
            "assets/generated/achievements/$id.png"
        }
        $full = Join-Path $root ($rel -replace "/", "\")
        if (-not (Test-Path $full)) {
            $coreBadgeMissing.Add($rel.Replace("\", "/"))
        }
    }
}

# ── Unreferenced files (warn; optional strict) ───────────────────────────
$allowUnreferenced = @(
    "bg-onboarding.jpg",
    "bg-splash.jpg",
    "empty-chat.jpg",
    "empty-feed.jpg",
    "empty-notifications.jpg",
    "empty-worlds.jpg",
    "tier-bronze.png",
    "tier-diamond.png",
    "tier-gold.png",
    "tier-silver.png"
)

$referencedNames = $paths | ForEach-Object { Split-Path $_ -Leaf }
$extra = Get-ChildItem $generated -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -notin $referencedNames -and $_.Name -notin $allowUnreferenced
    }

Write-Host "Referenced in Dart: $($paths.Count)"
Write-Host "Manifest approved entries: $manifestApproved"

$failed = $false

if ($missing.Count -gt 0) {
    $failed = $true
    Write-Host "MISSING — referenced in code ($($missing.Count)):" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" }
}

if ($manifestMissing.Count -gt 0) {
    $failed = $true
    Write-Host "MISSING — manifest approved finalPath ($($manifestMissing.Count)):" -ForegroundColor Red
    $manifestMissing | ForEach-Object { Write-Host "  $_" }
}

if ($coreBadgeMissing.Count -gt 0) {
    $failed = $true
    Write-Host "MISSING — core achievement badges ($($coreBadgeMissing.Count)):" -ForegroundColor Red
    $coreBadgeMissing | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    if ($coreBadgeMissing.Count -gt 20) {
        Write-Host "  ... and $($coreBadgeMissing.Count - 20) more"
    }
}

if (-not $failed) {
    Write-Host "All referenced and manifest-approved assets present." -ForegroundColor Green
}

if ($extra.Count -gt 0) {
    $color = if ($StrictUnreferenced) { "Red" } else { "Yellow" }
    Write-Host "Unreferenced in assets/generated/ ($($extra.Count)):" -ForegroundColor $color
    $extra | Select-Object -First 15 | ForEach-Object { Write-Host "  $($_.Name)" }
    if ($StrictUnreferenced) { $failed = $true }
}

if ($failed) { exit 1 }
exit 0
