# Validates that every asset referenced in WorldAssets / cosmetics exists on disk.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $root "pubspec.yaml"))) {
    $root = Split-Path -Parent $PSScriptRoot
}

$generated = Join-Path $root "assets\generated"
$missing = @()

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
        $missing += $rel
    }
}

$extra = Get-ChildItem $generated -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin ($paths | ForEach-Object { Split-Path $_ -Leaf }) }

Write-Host "Referenced assets: $($paths.Count)"
if ($missing.Count -gt 0) {
    Write-Host "MISSING ($($missing.Count)):" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "All referenced assets present." -ForegroundColor Green
if ($extra) {
    Write-Host "Unreferenced files in assets/generated/ ($($extra.Count)):" -ForegroundColor Yellow
    $extra | Select-Object -First 10 | ForEach-Object { Write-Host "  $($_.Name)" }
}
exit 0
