# Build or refresh the CodeGraph index for Vertiege (Dart/Flutter).
# Requires Node/npm for npx. Uses CodeGraph's bundled Node when the shim runs.
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$env:CI = 'true'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Get-CodeGraphCmd {
    # Prefer the platform bundle; npm's codegraph.cmd shim hits spawnSync EINVAL on Windows.
    $bundled = Join-Path $env:APPDATA 'npm\node_modules\@colbymchenry\codegraph-win32-x64\bin\codegraph.cmd'
    if (Test-Path $bundled) { return $bundled }

    $npxBundled = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA 'npm-cache\_npx') -Filter 'codegraph.cmd' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match 'codegraph-win32-x64\\bin\\codegraph\.cmd$' } |
        Select-Object -First 1
    if ($npxBundled) { return $npxBundled.FullName }

    return $null
}

function Invoke-CodeGraph {
    param([string[]]$CliArgs)
    $cmd = Get-CodeGraphCmd
    if ($cmd) {
        & $cmd @CliArgs 2>&1 | ForEach-Object { $_ | Out-Host }
        $exit = $LASTEXITCODE
        if ($null -eq $exit) { return [int](-not $?) }
        return $exit
    }
    npx -y @colbymchenry/codegraph@latest @CliArgs 2>&1 | ForEach-Object { $_ | Out-Host }
    $exit = $LASTEXITCODE
    if ($null -eq $exit) { return [int](-not $?) }
    return $exit
}

$initArgs = @('init')
if (-not (Test-Path '.codegraph\config.json')) {
    $initArgs += '-i'
} elseif ($Force) {
    Write-Host 'Force: full re-index...'
    exit (Invoke-CodeGraph -CliArgs 'index', '--force')
} else {
    Write-Host 'Updating index (sync)...'
    $code = Invoke-CodeGraph -CliArgs 'sync'
    if ($code -eq 0) { exit 0 }
    Write-Host 'Sync failed or no index; running init -i...'
    $initArgs = @('init', '-i')
}

exit (Invoke-CodeGraph -CliArgs $initArgs)
