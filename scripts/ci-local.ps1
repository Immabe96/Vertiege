# Mirror GitHub Actions CI verify + build-apk locally.
# Requires JDK 21 for Gradle (JDK 26 breaks Kotlin DSL — same as CI uses Java 21).

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Find-Java21 {
    $candidates = @(
        $env:JAVA_HOME,
        "C:\Program Files\Eclipse Adoptium\jdk-21*",
        "C:\Program Files\Java\jdk-21*",
        "C:\Program Files\Microsoft\jdk-21*"
    )
    foreach ($pattern in $candidates) {
        if (-not $pattern) { continue }
        $resolved = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved -and (Test-Path "$($resolved.FullName)\bin\java.exe")) {
            return $resolved.FullName
        }
    }
    return $null
}

Write-Host "== flutter test (CI verify) =="
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$java21 = Find-Java21
if (-not $java21) {
    Write-Host ""
    Write-Host "ERROR: JDK 21 not found. CI uses Java 21; JDK 26 fails Gradle with: IllegalArgumentException: 26.0.1"
    Write-Host "Install: https://adoptium.net/temurin/releases/?version=21"
    Write-Host "Then set JAVA_HOME to the JDK 21 folder and re-run: .\scripts\ci-local.ps1"
    exit 1
}

$env:JAVA_HOME = $java21
$env:Path = "$java21\bin;" + $env:Path
Write-Host "Using JAVA_HOME=$java21"

if (-not (Test-Path .env)) {
    Write-Host "WARNING: .env missing — APK will launch offline (CI uses SUPABASE_URL / SUPABASE_ANON_KEY secrets)"
}

Write-Host ""
Write-Host "== flutter build apk --release (CI build-apk) =="
flutter build apk --release --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    $info = Get-Item $apk
    Write-Host ""
    Write-Host "OK: $($info.FullName) ($([math]::Round($info.Length / 1MB, 2)) MB)"
}
