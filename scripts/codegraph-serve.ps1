# MCP entrypoint for Cursor on Windows (avoids npx spawnSync EINVAL).
$ErrorActionPreference = 'Stop'
$env:CI = 'true'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$bundled = Join-Path $env:APPDATA 'npm\node_modules\@colbymchenry\codegraph-win32-x64\bin\codegraph.cmd'
if (-not (Test-Path $bundled)) {
    Write-Error "CodeGraph not installed. Run: npm install -g @colbymchenry/codegraph-win32-x64"
    exit 1
}

& $bundled serve --mcp --path $root
