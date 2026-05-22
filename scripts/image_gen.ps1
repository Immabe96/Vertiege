# Resumable image generation queue for Codex / manual runs.
# Usage: .\scripts\image_gen.ps1 next | status | mark | promote | init
param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'next', 'status', 'mark', 'promote', 'list', 'reset')]
    [string] $Command = 'status',

    [string] $Id,
    [ValidateSet('pending', 'generated', 'approved', 'failed')]
    [string] $Status,
    [string] $Notes,
    [switch] $All,
    [string] $FilterStatus = 'pending'
)

$ErrorActionPreference = 'Stop'
$Root = if (Test-Path (Join-Path $PSScriptRoot '..\pubspec.yaml')) {
    (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
} else { $PSScriptRoot }

$ManifestPath = Join-Path $Root 'docs\assets\image-manifest.json'
$StagingDir = Join-Path $Root 'assets\staging\generated'
$FinalDir = Join-Path $Root 'assets\generated'
$LogPath = Join-Path $Root 'docs\assets\generation-log.md'

$BannerNegative = @(
    'no text', 'no letters', 'no numbers', 'no words', 'no logos', 'no signage',
    'no neon signs with writing', 'no watermarks', 'no UI', 'no captions'
) -join ', '

$EmblemNegative = @(
    'no text', 'no letters', 'no numbers', 'no words', 'no labels', 'no monograms',
    'transparent background', 'isolated emblem only', 'no white square backdrop',
    'no drop shadow card'
) -join ', '

function Ensure-Dirs {
    foreach ($d in @($StagingDir, $FinalDir, (Split-Path $ManifestPath))) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
}

function Get-Manifest {
    if (-not (Test-Path $ManifestPath)) { return $null }
    Get-Content $ManifestPath -Raw | ConvertFrom-Json
}

function Save-Manifest($manifest) {
    $manifest.updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    $json = $manifest | ConvertTo-Json -Depth 8
    Set-Content -Path $ManifestPath -Value $json -Encoding UTF8
}

function New-ItemDef {
    param(
        [string] $Id,
        [string] $Filename,
        [string] $Category,
        [string] $Format,
        [bool] $Transparent,
        [string] $Size,
        [string] $Prompt,
        [string] $Negative
    )
    [PSCustomObject]@{
        id            = $Id
        filename      = $Filename
        category      = $Category
        format        = $Format
        transparent   = $Transparent
        size          = $Size
        noText        = $true
        status        = 'pending'
        prompt        = $Prompt
        negativePrompt = $Negative
        stagingPath   = "assets/staging/generated/$Filename"
        finalPath     = "assets/generated/$Filename"
        generatedAt   = $null
        approvedAt    = $null
        notes         = $null
    }
}

function Build-DefaultManifest {
    $items = [System.Collections.Generic.List[object]]::new()

    $worlds = @{
        'world-aetheria' = @{ theme = 'ethereal high society'; motif = 'floating terraces in mist, soft aurora' }
        'world-arts-pavilion' = @{ theme = 'creative elite'; motif = 'modern gallery at dusk, sculpture garden' }
        'world-aviation-heights' = @{ theme = 'aviation prestige'; motif = 'airport skyline, runway lights at dawn' }
        'world-azure-coast' = @{ theme = 'coastal luxury'; motif = 'cliff villas, turquoise water, golden hour' }
        'world-crimson-court' = @{ theme = 'power and ceremony'; motif = 'crimson-lit grand hall, velvet, chandeliers' }
        'world-crystal-shore' = @{ theme = 'serene wealth'; motif = 'crystal-clear bay, minimalist piers' }
        'world-financial-district' = @{ theme = 'finance capital'; motif = 'glass towers, night glow, no readable signs' }
        'world-golden-estate' = @{ theme = 'old money estate'; motif = 'manor drive, hedges, warm sunset' }
        'world-legal-plaza' = @{ theme = 'law and order'; motif = 'courthouse columns, marble, blue hour' }
        'world-medical-nexus' = @{ theme = 'medical excellence'; motif = 'futuristic hospital campus, white and violet' }
        'world-neon-district' = @{ theme = 'cyber nightlife'; motif = 'neon alley, rain reflections, glowing shapes only no readable signs' }
        'world-nova-station' = @{ theme = 'space research'; motif = 'orbital station window, nebula view' }
        'world-quantum-core' = @{ theme = 'tech science'; motif = 'particle accelerator aesthetic, blue energy' }
        'world-silver-page' = @{ theme = 'media publishing'; motif = 'abstract press room, paper stacks, no headlines' }
        'world-sovereign-city' = @{ theme = 'capital metropolis'; motif = 'panoramic city crown, citadel, no skyline text' }
        'world-tech-sprawl' = @{ theme = 'startup megacity'; motif = 'tech campus, holographic light shapes, no words on billboards' }
    }

    foreach ($kv in $worlds.GetEnumerator()) {
        $slug = $kv.Key -replace '^world-', ''
        $w = $kv.Value
        $prompt = @"
Cinematic wide establishing shot themed as $($w.theme). Visual only: $($w.motif).
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.
"@.Trim()
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).jpg" -Category 'world_banner' `
            -Format 'jpg' -Transparent $false -Size '1200x675' -Prompt $prompt -Negative $BannerNegative))
    }

    $badges = @{
        'badge-doctor' = 'medical emblem, stethoscope and caduceus motif, metallic'
        'badge-engineer' = 'engineering emblem, gear and blueprint motif, metallic'
        'badge-attorney' = 'legal emblem, scales of justice motif, metallic'
        'badge-finance' = 'finance emblem, rising chart motif, metallic'
        'badge-artist' = 'arts emblem, palette and brush motif, metallic'
        'badge-pilot' = 'aviation emblem, wings and compass motif, metallic'
        'badge-marathon' = 'running shoe and laurel wreath emblem, metallic'
        'badge-author' = 'quill and open book emblem, metallic'
        'badge-founder' = 'rocket launch emblem, metallic'
        'badge-explorer' = 'compass and mountain emblem, metallic'
        'badge-debtfree' = 'broken chain and coin emblem, metallic'
        'badge-leader' = 'crown and torch emblem, metallic'
        'badge-polyglot' = 'speech bubbles as abstract shapes only no letters, globe, metallic'
    }
    foreach ($kv in $badges.GetEnumerator()) {
        $p = "Single centered 3D metallic game emblem: $($kv.Value). Isolated icon, premium mobile UI asset."
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).png" -Category 'badge' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative $EmblemNegative))
    }

    $profs = @{
        'prof-doctor' = 'stethoscope emblem'
        'prof-engineer' = 'gear and blueprint emblem'
        'prof-attorney' = 'gavel emblem'
        'prof-finance' = 'coin stack and chart emblem'
        'prof-artist' = 'palette emblem'
        'prof-pilot' = 'wings emblem'
    }
    foreach ($kv in $profs.GetEnumerator()) {
        $p = "Profession icon emblem: $($kv.Value), 3D metallic, centered."
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).png" -Category 'profession' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative $EmblemNegative))
    }

    $ach = @{
        'ach-education' = 'stack of books'
        'ach-career' = 'briefcase'
        'ach-relationships' = 'interlocking hearts'
        'ach-health' = 'dumbbell'
        'ach-skills' = 'wrench and hammer'
        'ach-travel' = 'airplane'
        'ach-finance' = 'coins'
        'ach-community' = 'handshake'
        'ach-funny' = 'comedy mask'
        'ach-creative' = 'artist palette'
    }
    foreach ($kv in $ach.GetEnumerator()) {
        $p = "Achievement category icon: $($kv.Value), 3D metallic emblem, centered."
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).png" -Category 'achievement_category' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative $EmblemNegative))
    }

    $tiers = @{
        'tier-bronze' = 'bronze medal crest ornate'
        'tier-silver' = 'silver medal crest ornate'
        'tier-gold' = 'gold medal crest ornate'
        'tier-diamond' = 'diamond platinum medal crest ornate'
    }
    foreach ($kv in $tiers.GetEnumerator()) {
        $p = "Tier rank medallion: $($kv.Value), no engraved words, 3D metallic."
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).png" -Category 'tier' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative $EmblemNegative))
    }

    for ($i = 1; $i -le 6; $i++) {
        $id = "avatar-$i"
        $p = "Studio portrait bust, diverse appearance variant $i, violet rim light, transparent background, no text, 1:1."
        $items.Add((New-ItemDef -Id $id -Filename "$id.png" -Category 'avatar' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative ($EmblemNegative + ', soft vignette allowed')))
    }
    foreach ($name in @('marcus', 'elena', 'alistair')) {
        $id = "avatar-$name"
        $p = "Professional portrait bust, distinct person, violet rim light, transparent background, no text or name tag, 1:1."
        $items.Add((New-ItemDef -Id $id -Filename "$id.png" -Category 'avatar' `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $p -Negative $EmblemNegative))
    }

    $empties = @{
        'empty-feed' = 'minimal dark illustration, quiet social feed timeline, no text'
        'empty-chat' = 'minimal dark illustration, abstract speech bubbles, no text'
        'empty-worlds' = 'minimal dark illustration, portal gateways, no text'
        'empty-notifications' = 'minimal dark illustration, bell icon motif, no text'
        'bg-splash' = 'abstract black and violet gradient, premium app splash, no characters no text'
        'bg-onboarding' = 'abstract black violet blue gradient, welcoming atmosphere, no text'
    }
    foreach ($kv in $empties.GetEnumerator()) {
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).jpg" -Category 'background' `
            -Format 'jpg' -Transparent $false -Size '1080x1920' -Prompt $kv.Value -Negative $BannerNegative))
    }

    [PSCustomObject]@{
        version    = 1
        updatedAt  = (Get-Date).ToUniversalTime().ToString('o')
        stagingDir = 'assets/staging/generated'
        finalDir   = 'assets/generated'
        workflowDoc = 'docs/assets/CODEX_IMAGE_WORKFLOW.md'
        items      = $items
    }
}

function Sync-StatusFromDisk($manifest) {
    # Only staging folder drives progress. Production files are not auto-approved.
    foreach ($item in $manifest.items) {
        if ($item.status -eq 'approved') { continue }
        $staging = Join-Path $Root ($item.stagingPath -replace '/', '\')
        if (Test-Path $staging) {
            if ($item.status -in @('pending', 'failed')) {
                $item.status = 'generated'
            }
            if (-not $item.generatedAt) {
                $item.generatedAt = (Get-Date).ToUniversalTime().ToString('o')
            }
        }
    }
    $manifest
}

function Get-NextItem($manifest) {
    $order = @('pending', 'failed', 'generated')
    foreach ($st in $order) {
        $found = $manifest.items | Where-Object { $_.status -eq $st } | Sort-Object id | Select-Object -First 1
        if ($found) { return $found }
    }
    return $null
}

function Write-LogLine($line) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $entry = "- **$ts** - $line"
    if (-not (Test-Path $LogPath)) {
        Set-Content $LogPath "# Image generation log`n`n$entry" -Encoding UTF8
    } else {
        Add-Content $LogPath $entry -Encoding UTF8
    }
}

Ensure-Dirs

switch ($Command) {
    'init' {
        if (Test-Path $ManifestPath) {
            Write-Warning "Manifest already exists. Use: .\scripts\image_gen.ps1 reset"
            exit 1
        }
        $m = Build-DefaultManifest
        Save-Manifest $m
        Write-Host "Created $ManifestPath with $($m.items.Count) items (all pending)."
    }

    'reset' {
        if (-not (Test-Path $ManifestPath)) {
            Write-Host 'Run init first.'
            exit 1
        }
        $m = Get-Manifest
        foreach ($item in $m.items) {
            $item.status = 'pending'
            $item.generatedAt = $null
            $item.approvedAt = $null
            $item.notes = $null
        }
        Save-Manifest $m
        Write-Host "Reset $($m.items.Count) items to pending (prompts unchanged)."
    }

    'status' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run: .\scripts\image_gen.ps1 init'; exit 1 }
        $m = Sync-StatusFromDisk $m
        Save-Manifest $m
        $groups = $m.items | Group-Object status
        Write-Host "Image queue: $($m.items.Count) items"
        foreach ($g in $groups) { Write-Host "  $($g.Name): $($g.Count)" }
        $next = Get-NextItem $m
        if ($next) {
            Write-Host "`nNext up: $($next.id) -> $($next.stagingPath)"
        } else {
            Write-Host "`nQueue complete (all approved or generated)."
        }
    }

    'next' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run: .\scripts\image_gen.ps1 init'; exit 1 }
        $m = Sync-StatusFromDisk $m
        Save-Manifest $m
        $item = Get-NextItem $m
        if (-not $item) {
            Write-Host '{"done":true,"message":"No pending or failed items."}'
            exit 0
        }
        $out = [ordered]@{
            done            = $false
            id              = $item.id
            filename        = $item.filename
            category        = $item.category
            format          = $item.format
            transparent     = $item.transparent
            size            = $item.size
            stagingPath     = $item.stagingPath
            finalPath       = $item.finalPath
            status          = $item.status
            prompt          = $item.prompt
            negativePrompt  = $item.negativePrompt
            codexInstruction = @"
Generate ONE image. Save file to exactly: $($item.stagingPath)
Then run: .\scripts\image_gen.ps1 mark -Id $($item.id) -Status generated
Commit manifest + staging file. If rate limited: mark -Status failed -Notes 'daily limit'
"@
        }
        $out | ConvertTo-Json -Depth 5
    }

    'list' {
        $m = Get-Manifest
        if (-not $m) { exit 1 }
        $m.items | Where-Object { $_.status -eq $FilterStatus } | ForEach-Object {
            Write-Host "$($_.id) [$($_.status)] -> $($_.stagingPath)"
        }
    }

    'mark' {
        if (-not $Id -or -not $Status) {
            Write-Error 'Usage: mark -Id <id> -Status pending|generated|approved|failed [-Notes text]'
        }
        $m = Get-Manifest
        $item = $m.items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
        if (-not $item) { Write-Error "Unknown id: $Id" }
        $item.status = $Status
        if ($Status -eq 'generated') {
            $item.generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        }
        if ($Status -eq 'approved') {
            $item.approvedAt = (Get-Date).ToUniversalTime().ToString('o')
        }
        if ($Notes) { $item.notes = $Notes }
        Save-Manifest $m
        Write-LogLine "$Id -> $Status $(if ($Notes) { "($Notes)" })"
        Write-Host "Marked $Id as $Status"
    }

    'promote' {
        $m = Get-Manifest
        $targets = if ($All) {
            $m.items | Where-Object { $_.status -eq 'generated' }
        } else {
            if (-not $Id) { Write-Error 'Usage: promote -Id <id> OR promote -All' }
            @($m.items | Where-Object { $_.id -eq $Id })
        }
        foreach ($item in $targets) {
            $src = Join-Path $Root ($item.stagingPath -replace '/', '\')
            $dst = Join-Path $Root ($item.finalPath -replace '/', '\')
            if (-not (Test-Path $src)) {
                Write-Warning "Skip $($item.id): staging missing $src"
                continue
            }
            Copy-Item $src $dst -Force
            $item.status = 'approved'
            $item.approvedAt = (Get-Date).ToUniversalTime().ToString('o')
            Write-Host "Promoted $($item.id) -> $($item.finalPath)"
        }
        Save-Manifest $m
    }
}
