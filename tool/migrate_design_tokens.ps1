# Migrates design_system.dart imports and token aliases to v_tokens.dart
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Where-Object {
    (Get-Content $_.FullName -Raw) -match "design_system\.dart"
}

function Migrate-File($path) {
    $c = Get-Content $path -Raw -Encoding UTF8

    # Skip if already no design_system
    if ($c -notmatch "design_system\.dart") { return $false }

    # Replace imports (various relative depths)
    $c = $c -replace "import\s+'([^']*)theme/design_system\.dart';", "import '`$1theme/v_tokens.dart';"
    $c = $c -replace 'import\s+"([^"]*)theme/design_system\.dart";', 'import "`$1theme/v_tokens.dart";'

    # Spacing specials (before Spacing.)
    $c = $c -replace 'Spacing\.marginMobile', 'VSpacing.lg'
    $c = $c -replace 'Spacing\.marginDesktop', 'VSpacing.xxl'
    $c = $c -replace 'Spacing\.section', 'VSpacing.xxl'
    $c = $c -replace 'Spacing\.gutter', 'VSpacing.md'

    # Radius specials (before RadiusTokens.)
    $c = $c -replace 'RadiusTokens\.cardFeatured', 'VRadius.md'
    $c = $c -replace 'RadiusTokens\.card\b', 'VRadius.lg'
    $c = $c -replace 'RadiusTokens\.input', 'VRadius.md'
    $c = $c -replace 'RadiusTokens\.chip', 'VRadius.sm'
    $c = $c -replace 'RadiusTokens\.full', 'VRadius.pill'

    # FontSizes specials
    $c = $c -replace 'FontSizes\.displayHero', 'VFontSize.displayXl'
    $c = $c -replace 'FontSizes\.headingCard', 'VFontSize.headlineMd'
    $c = $c -replace 'FontSizes\.micro\b', 'VFontSize.labelSm'
    $c = $c -replace 'FontSizes\.caption\b', 'VFontSize.labelMd'
    $c = $c -replace 'FontSizes\.body\b', 'VFontSize.bodyMd'

    # LetterSpacing -> 0
    $c = $c -replace 'letterSpacing:\s*LetterSpacing\.\w+', 'letterSpacing: 0'
    $c = $c -replace 'LetterSpacing\.\w+', '0'

    # AnimCurves specials (AnimCurves.easeOut etc. are on Curves not VAnimation)
    $c = $c -replace 'AnimCurves\.easeOut', 'Curves.easeOutCubic'
    $c = $c -replace 'AnimCurves\.easeInOut', 'Curves.easeInOutCubic'
    $c = $c -replace 'AnimCurves\.bouncy', 'Curves.elasticOut'
    $c = $c -replace 'AnimCurves\.', 'VAnimation.'

    # Bulk aliases (only if not already V-prefixed)
    $c = $c -replace '(?<![V])Spacing\.', 'VSpacing.'
    $c = $c -replace 'RadiusTokens\.', 'VRadius.'
    $c = $c -replace '(?<![V])IconSizes\.', 'VIconSize.'
    $c = $c -replace 'FontSizes\.', 'VFontSize.'
    $c = $c -replace 'FontWeights\.', 'VFontWeight.'
    $c = $c -replace 'TouchTargets\.', 'VTouchTarget.'
    $c = $c -replace 'AnimDurations\.', 'VAnimation.'
    $c = $c -replace 'AppFont\.', 'VFont.'
    $c = $c -replace 'LineHeight\.', 'VLineHeight.'

    # Fix double-prefix mistakes
    $c = $c -replace 'VVVSpacing\.', 'VSpacing.'
    $c = $c -replace 'VVSpacing\.', 'VSpacing.'
    $c = $c -replace 'VVRadius\.', 'VRadius.'
    $c = $c -replace 'VVIconSize\.', 'VIconSize.'
    $c = $c -replace 'VVFontSize\.', 'VFontSize.'
    $c = $c -replace 'VVFontWeight\.', 'VFontWeight.'
    $c = $c -replace 'LetterVSpacing\.\w+', '0'
    $c = $c -replace 'VFontSize\.bodyMdMd', 'VFontSize.bodyMd'

    # Invalid VRadius aliases from bulk replace
    $c = $c -replace 'VRadius\.cardFeatured', 'VRadius.md'
    $c = $c -replace 'VRadius\.card\b', 'VRadius.lg'
    $c = $c -replace 'VRadius\.input', 'VRadius.md'
    $c = $c -replace 'VRadius\.chip', 'VRadius.sm'
    $c = $c -replace 'VRadius\.full', 'VRadius.pill'

    Set-Content -Path $path -Value $c -Encoding UTF8 -NoNewline
    return $true
}

$count = 0
foreach ($f in $files) {
    if (Migrate-File $f.FullName) { $count++ ; Write-Host "Migrated $($f.FullName)" }
}
Write-Host "Done: $count files"
