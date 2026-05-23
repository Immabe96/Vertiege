# Resumable image generation queue for Codex / manual runs.
# Usage: .\scripts\image_gen.ps1 next | status | mark | promote | init
param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'next', 'status', 'mark', 'promote', 'list', 'reset', 'export-chatgpt', 'export-chatgpt-project', 'refresh-prompts', 'skip-category', 'pull', 'sync-tiers', 'resize-assets')]
    [string] $Command = 'status',

    [string] $Id,
    [ValidateSet('pending', 'generated', 'approved', 'failed', 'skipped')]
    [string] $Status,
    [string] $Category,
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
    'no drop shadow card', 'do not use generic shiny gold metal for every icon',
    'each icon must look visually distinct'
) -join ', '

$AvatarNegative = @(
    'no text', 'no letters', 'no numbers', 'no words', 'no labels', 'no monograms',
    'transparent background', 'no photorealistic face', 'no real person', 'no celebrity likeness',
    'no photographic portrait', 'no skin pores', 'no eyes nose mouth detail',
    'faceless silhouette or stylized illustration only', 'no white square backdrop'
) -join ', '

function Ensure-Dirs {
    foreach ($d in @($StagingDir, $FinalDir, (Split-Path $ManifestPath))) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
}

# ChatGPT image gen only exports PNG; JPG manifest entries are converted on pull/mark.
function Get-ChatGptFilename($item) {
    if ($item.format -eq 'jpg') {
        return [System.IO.Path]::ChangeExtension($item.filename, '.png')
    }
    return $item.filename
}

function Get-PixelSize($sizeString) {
    $parts = $sizeString -split 'x'
    if ($parts.Count -ne 2) {
        throw "Invalid size: $sizeString (expected WxH)"
    }
    return @{
        Width  = [int]$parts[0]
        Height = [int]$parts[1]
    }
}

function Resize-ImageAsset {
    param(
        [string] $SourcePath,
        [string] $DestPath,
        [int] $Width,
        [int] $Height,
        [string] $Format,
        [int] $JpegQuality = 88
    )
    Add-Type -AssemblyName System.Drawing
    $src = (Resolve-Path $SourcePath).Path
    $image = [System.Drawing.Image]::FromFile($src)
    $bmp = $null
    try {
        $destDir = Split-Path $DestPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $bmp = New-Object System.Drawing.Bitmap(
            $Width,
            $Height,
            ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb))
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            if ($Format -eq 'jpg') {
                $graphics.Clear([System.Drawing.Color]::FromArgb(255, 8, 6, 14))
            } else {
                $graphics.Clear([System.Drawing.Color]::Transparent)
            }
            $graphics.DrawImage($image, 0, 0, $Width, $Height)
        } finally {
            $graphics.Dispose()
        }

        $tempPath = "$DestPath.resize_tmp"
        if ($Format -eq 'jpg') {
            $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                Where-Object { $_.MimeType -eq 'image/jpeg' } |
                Select-Object -First 1
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
                [System.Drawing.Imaging.Encoder]::Quality, $JpegQuality)
            $bmp.Save($tempPath, $encoder, $encoderParams)
        } else {
            $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
    } finally {
        $image.Dispose()
        if ($bmp) { $bmp.Dispose() }
    }
    Move-Item -Path $tempPath -Destination $DestPath -Force
}

function Save-ImageAsJpeg {
    param(
        [string] $SourcePath,
        [string] $DestPath,
        [int] $Quality = 92
    )
    Add-Type -AssemblyName System.Drawing
    $src = (Resolve-Path $SourcePath).Path
    $image = [System.Drawing.Image]::FromFile($src)
    try {
        $destDir = Split-Path $DestPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
            Where-Object { $_.MimeType -eq 'image/jpeg' } |
            Select-Object -First 1
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, $Quality)
        $image.Save($DestPath, $encoder, $encoderParams)
    } finally {
        $image.Dispose()
    }
}

function Import-AssetFromDownloads($item) {
    Ensure-Dirs
    $staging = Join-Path $Root ($item.stagingPath -replace '/', '\')
    $base = [System.IO.Path]::GetFileNameWithoutExtension($item.filename)
    $dl = Join-Path $env:USERPROFILE 'Downloads'
    $names = @(
        (Get-ChatGptFilename $item),
        "$base.png",
        "$base.PNG",
        $item.filename
    ) | Select-Object -Unique
    foreach ($name in $names) {
        $src = Join-Path $dl $name
        if (-not (Test-Path $src)) { continue }
        $ext = [System.IO.Path]::GetExtension($src).ToLowerInvariant()
        if ($item.format -eq 'jpg' -and $ext -eq '.png') {
            Save-ImageAsJpeg -SourcePath $src -DestPath $staging
            Write-Host "Converted PNG to JPG: $($item.stagingPath)"
        } else {
            Copy-Item $src $staging -Force
            Write-Host "Copied to staging: $($item.stagingPath)"
        }
        return $true
    }
    $false
}

function Test-StagingReady($item) {
    $staging = Join-Path $Root ($item.stagingPath -replace '/', '\')
    if (Test-Path $staging) { return $true }
    $pngStaging = [System.IO.Path]::ChangeExtension($staging, '.png')
    if ($item.format -eq 'jpg' -and (Test-Path $pngStaging)) {
        Save-ImageAsJpeg -SourcePath $pngStaging -DestPath $staging
        Write-Host "Converted staging PNG to JPG: $($item.stagingPath)"
        return $true
    }
    $false
}

function Ensure-StagingFile($item) {
    if (Test-StagingReady $item) { return $true }
    Import-AssetFromDownloads $item
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

    $unique = Get-UniqueItemPrompts
    foreach ($kv in $unique.GetEnumerator()) {
        $neg = $EmblemNegative
        if ($kv.Key.StartsWith('badge-')) {
            $cat = 'badge'
        } elseif ($kv.Key.StartsWith('prof-')) {
            $cat = 'profession'
        } elseif ($kv.Key.StartsWith('ach-')) {
            $cat = 'achievement_category'
        } elseif ($kv.Key.StartsWith('tier-')) {
            $cat = 'tier'
        } elseif ($kv.Key.StartsWith('avatar-')) {
            $cat = 'avatar'
            $neg = $AvatarNegative
        } else { continue }
        $items.Add((New-ItemDef -Id $kv.Key -Filename "$($kv.Key).png" -Category $cat `
            -Format 'png' -Transparent $true -Size '512x512' -Prompt $kv.Value -Negative $neg))
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
        if ($item.status -in @('approved', 'skipped')) { continue }
        if (Test-StagingReady $item) {
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

function Get-AspectLine($item) {
    if ($item.size -eq '1080x1920') { return 'Aspect: 9:16 portrait (phone wallpaper).' }
    if ($item.category -eq 'world_banner') { return 'Aspect: 16:9 landscape.' }
    if ($item.size -eq '512x512') { return 'Aspect: 1:1 square.' }
    return "Aspect: match $($item.size) exactly."
}

function Get-FormatLine($item) {
    if ($item.transparent) { return 'Format: PNG with transparent background (alpha).' }
    if ($item.format -eq 'jpg') { return 'Format: PNG from ChatGPT; repo converts to JPG on import.' }
    return "Format: $($item.format.ToUpper()) opaque, no transparency."
}

function Build-ChatGptPromptBlock($item) {
    $chatgptFile = Get-ChatGptFilename $item
    $lines = @(
        'Vertiege premium mobile game asset.',
        "Asset ID: $($item.id)",
        "File name when saving: $chatgptFile"
    )
    if ($chatgptFile -ne $item.filename) {
        $lines += "Final app file: $($item.filename)"
    }
    $lines += @(
        "Dimensions: $($item.size) pixels (generate at this exact size).",
        (Get-FormatLine $item),
        (Get-AspectLine $item),
        '',
        $item.prompt.Trim(),
        '',
        "Avoid: $($item.negativePrompt)",
        'No text, letters, numbers, logos, watermarks, or UI.'
    )
    $lines -join "`n"
}

function Sort-QueueItems($items) {
    $tierOrder = @{
        'tier-hustler'      = 1
        'tier-high-roller'  = 2
        'tier-elite'        = 3
        'tier-old-money'    = 4
        'tier-apex'         = 5
    }
    $items | Sort-Object {
        if ($tierOrder.ContainsKey($_.id)) { 'tier-{0:D2}' -f $tierOrder[$_.id] }
        else { $_.id }
    }
}

function Get-NextItem($manifest) {
    $order = @('pending', 'failed', 'generated')
    foreach ($st in $order) {
        $found = Sort-QueueItems ($manifest.items | Where-Object { $_.status -eq $st }) | Select-Object -First 1
        if ($found) { return $found }
    }
    return $null
}

# Distinct art direction per asset — avoid generic gold metallic look.
function Get-UniqueItemPrompts {
    $ach = @{
        'ach-education'     = 'Achievement category icon: stack of books with deep navy blue enamel and ivory pages, scholastic art-deco crest shape, subtle gold trim only on spine edges, flat premium UI icon.'
        'ach-finance'       = 'Achievement category icon: stacked coins in emerald green crystal and cool silver, geometric low-poly style, no yellow gold, finance app icon.'
        'ach-relationships' = 'Achievement category icon: interlocking hearts in rose quartz pink and soft coral enamel, gentle inner glow, romantic pin-badge style, not metallic gold.'
        'ach-funny'         = 'Achievement category icon: comedy and tragedy masks in glossy playful plastic, hot pink and teal accents, cartoon game UI icon, bold and fun.'
        'ach-health'        = 'Achievement category icon: dumbbell in matte charcoal rubber with neon green energy ring, modern fitness app icon, sporty and clean.'
        'ach-skills'        = 'Achievement category icon: crossed wrench and hammer in forged dark iron with orange spark accents, industrial trades badge, rugged not shiny gold.'
        'ach-travel'        = 'Achievement category icon: airplane in sky-blue enamel with white contrail, vintage travel sticker aesthetic, wanderlust vibe.'
        'ach-community'     = 'Achievement category icon: handshake silhouette in warm copper and terracotta on dark slate circle, community patch style, human and welcoming.'
        'ach-creative'      = 'Achievement category icon: artist palette with rainbow paint splashes, iridescent holographic foil highlights, creative and colorful, not gold metal.'
        'ach-career'        = 'Achievement category icon: leather briefcase in rich burgundy with small brass clasp detail only, executive flat icon, professional not golden.'
    }
    $badges = @{
        'badge-doctor'    = 'Game badge medallion: elegant stethoscope arc forming a subtle heart curve on deep teal enamel shield, brushed silver rim, soft violet accent glow, premium mobile RPG pin illustration with gentle depth and polish, not flat clipart or a plain white hospital disc.'
        'badge-engineer'  = 'Game badge: copper gear over cyan blueprint grid lines, technical blueprint medallion, steampunk-lite.'
        'badge-attorney'  = 'Game badge: scales of justice in brushed steel and dark mahogany wood frame, solemn legal crest.'
        'badge-finance'     = 'Game badge: ascending bar chart in emerald and silver chrome, sharp corporate icon, no gold.'
        'badge-artist'      = 'Game badge: paint palette with vivid paint blobs, watercolor texture edges, artsy and colorful.'
        'badge-pilot'       = 'Game badge: silver wings and navy compass rose, aviation insignia enamel pin style.'
        'badge-marathon'    = 'Game badge: running shoe and laurel in oxidized bronze and lime accent, athletic medal.'
        'badge-author'      = 'Game badge: quill pen and parchment scroll in sepia ink and cream paper, literary wax-seal mood.'
        'badge-founder'     = 'Game badge: minimalist rocket silhouette in electric violet gradient flame, startup tech icon.'
        'badge-explorer'    = 'Game badge: mountain peak and compass in forest green and sandstone, outdoor expedition patch.'
        'badge-debtfree'    = 'Game badge: broken chain links turning into butterflies, silver and mint green, hopeful symbolism.'
        'badge-leader'      = 'Game badge: torch and laurel crown in royal purple and flame orange, leadership crest not gold.'
        'badge-polyglot'    = 'Game badge: abstract speech bubble shapes around a globe, multicolor enamel dots, no letters or words.'
    }
    $profs = @{
        'prof-doctor'    = 'Profession icon medallion: elegant stethoscope arc on deep teal enamel disc with brushed silver rim and soft violet glow, premium mobile UI pin, subtle depth and polish, not a plain white hospital circle or flat clipart cross.'
        'prof-engineer'  = 'Profession icon: orange gear with graphite blueprint corner, engineering flat icon.'
        'prof-attorney'  = 'Profession icon: dark gavel on burgundy round seal, legal profession stamp style.'
        'prof-finance'   = 'Profession icon medallion: emerald enamel shield with stylized ascending bars and silver chrome trim, premium fintech pin, subtle depth, cool green and graphite palette, no gold coins clipart or cheesy up-arrow sticker.'
        'prof-artist'    = 'Profession icon: painter palette with primary color dabs, playful creative flat icon.'
        'prof-pilot'     = 'Profession icon medallion: silver pilot wings arc over midnight navy enamel disc, subtle compass rose engraving, single small brass star accent, vintage aviation insignia pin with gentle depth, not flat clipart wings or oversized gold stars.'
    }
    # Match lib/config/tiers.dart + ResidentTier: 1 Hustler, 2 High Roller, 3 Elite, 4 Old Money, 5 Apex
    $tiers = @{
        'tier-hustler'      = 'Vertiege tier 1 Hustler medallion: copper and crimson street-grind emblem, gritty ambition energy, weathered metal with warm rust patina, humble starter rank pin, no text or numbers.'
        'tier-high-roller'  = 'Vertiege tier 2 High Roller medallion: neon magenta and champagne gold casino flair, dice and chip motifs abstracted, flashy nightlife prestige pin, bold and playful, no text.'
        'tier-elite'        = 'Vertiege tier 3 Elite medallion: hexagonal violet enamel crest with interlocking silver chevrons and a subtle crown silhouette, jewel-tone depth and brushed metal rim, prestigious but not police-badge clipart, no text.'
        'tier-old-money'    = 'Vertiege tier 4 Old Money medallion: deep burgundy enamel disc with muted antique gold rim, small abstract legacy knot in center, quiet old-world prestige pin, flat front-facing game icon like tier 1-3 style, no text.'
        'tier-apex'         = 'Vertiege tier 5 Apex medallion: platinum ring around faceted violet-white crystal core, soft prismatic edge glow, sovereign apex rank pin, flat front-facing game icon like tier 1-3 style, no text.'
    }
    $avatars = @{
        'avatar-1'        = 'Default player avatar: faceless bust silhouette in deep violet gradient, smooth organic shoulders, premium game UI, abstract citizen icon not a real person.'
        'avatar-2'        = 'Default player avatar: minimal teal line-art illustrated head and shoulders, geometric shapes only, no facial features, modern flat design.'
        'avatar-3'        = 'Default player avatar: coral and magenta paper-cut layered silhouette bust, craft illustration style, no face detail.'
        'avatar-4'        = 'Default player avatar: amber holographic outline figure, glowing edge light only, sci-fi citizen silhouette, no realistic skin.'
        'avatar-5'        = 'Default player avatar: cool blue watercolor wash silhouette in three-quarter view, soft painted edges, artistic not photographic.'
        'avatar-6'        = 'Default player avatar: mint and charcoal flat vector icon bust, rounded shoulders badge style, bold simple shapes.'
        'avatar-marcus'   = 'Named preset avatar: angular bold silhouette bust in royal purple and black, heroic game character shape language, faceless archetype not a real man.'
        'avatar-elena'    = 'Named preset avatar: soft curved silhouette bust in rose gold and blush gradient, elegant illustrated citizen, faceless archetype not a real woman.'
        'avatar-alistair' = 'Named preset avatar: silver wireframe bust illustration on dark navy, subtle cyan nodes, futuristic faceless avatar icon.'
    }
    $merged = @{}
    foreach ($h in @($ach, $badges, $profs, $tiers, $avatars)) {
        foreach ($k in $h.Keys) { $merged[$k] = $h[$k] }
    }
    return $merged
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
        $chatgptFile = Get-ChatGptFilename $item
        $formatHint = if ($item.transparent) {
            'PNG transparent (ChatGPT export)'
        } elseif ($item.format -eq 'jpg') {
            'PNG from ChatGPT, then auto-convert to JPG on pull/mark'
        } else {
            "$($item.format.ToUpper()) opaque"
        }
        $out = [ordered]@{
            done            = $false
            id              = $item.id
            filename        = $item.filename
            renameAs        = $chatgptFile
            finalFilename   = $item.filename
            category        = $item.category
            format          = $item.format
            transparent     = $item.transparent
            size            = $item.size
            stagingPath     = $item.stagingPath
            finalPath       = $item.finalPath
            status          = $item.status
            prompt          = $item.prompt
            negativePrompt  = $item.negativePrompt
            chatgptPrompt   = @"
Vertiege premium mobile game asset.
Asset ID: $($item.id)
File name when saving: $chatgptFile
Final app file: $($item.filename)
Dimensions: $($item.size) pixels (exact).
Format: $formatHint
$($item.prompt.Trim())
Avoid: $($item.negativePrompt)
No text, letters, numbers, logos, watermarks, or UI.
"@
            codexInstruction = @"
Generate ONE image at $($item.size). Save ChatGPT PNG as $chatgptFile in Downloads, then:
.\scripts\image_gen.ps1 mark -Id $($item.id) -Status generated
(or: pull -Id $($item.id) then mark)
If rate limited: mark -Status failed -Notes 'daily limit'
"@
        }
        $out | ConvertTo-Json -Depth 5
        Write-Host ''
        Write-Host '--- Rename in Downloads (copy filename only) ---'
        Write-Host $chatgptFile
        if ($chatgptFile -ne $item.filename) {
            Write-Host "--- converts to: $($item.filename) on pull/mark ---"
        }
        Write-Host '--- staging path ---'
        Write-Host $item.stagingPath
        Write-Host ''
    }

    'list' {
        $m = Get-Manifest
        if (-not $m) { exit 1 }
        $m.items | Where-Object { $_.status -eq $FilterStatus } | ForEach-Object {
            Write-Host "$($_.id) [$($_.status)] -> $($_.stagingPath)"
        }
    }

    'pull' {
        if (-not $Id) { Write-Error 'Usage: pull -Id <id>' }
        $m = Get-Manifest
        $item = $m.items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
        if (-not $item) { Write-Error "Unknown id: $Id" }
        if (-not (Import-AssetFromDownloads $item)) {
            Write-Host "No file found in Downloads. Save ChatGPT output as: $(Get-ChatGptFilename $item)"
            exit 1
        }
    }

    'mark' {
        if (-not $Id -or -not $Status) {
            Write-Error 'Usage: mark -Id <id> -Status pending|generated|approved|failed|skipped [-Notes text]'
        }
        $m = Get-Manifest
        $item = $m.items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
        if (-not $item) { Write-Error "Unknown id: $Id" }
        if ($Status -eq 'generated') {
            $null = Ensure-StagingFile $item
        }
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

    'sync-tiers' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run init first.'; exit 1 }
        $unique = Get-UniqueItemPrompts
        $legacy = @('tier-bronze', 'tier-silver', 'tier-gold', 'tier-diamond')
        $named = @('tier-hustler', 'tier-high-roller', 'tier-elite', 'tier-old-money', 'tier-apex')
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $m.items) {
            if ($item.id -in $legacy) {
                if ($item.status -eq 'pending') {
                    $item.status = 'skipped'
                    $item.notes = 'replaced by named tiers (Hustler..Apex)'
                }
                $list.Add($item)
                continue
            }
            $list.Add($item)
        }
        foreach ($tierId in $named) {
            $existing = $list | Where-Object { $_.id -eq $tierId } | Select-Object -First 1
            if ($existing) {
                $existing.prompt = $unique[$tierId]
                $existing.negativePrompt = $EmblemNegative
                continue
            }
            $list.Add((New-ItemDef -Id $tierId -Filename "$tierId.png" -Category 'tier' `
                -Format 'png' -Transparent $true -Size '512x512' `
                -Prompt $unique[$tierId] -Negative $EmblemNegative))
        }
        $m.items = @($list)
        Save-Manifest $m
        Write-Host 'Synced 5 named tier assets (Hustler, High Roller, Elite, Old Money, Apex).'
        Write-Host 'Legacy tier-bronze/silver/gold/diamond pending rows marked skipped.'
        Write-Host 'Update lib/utils/world_assets.dart _tierImagePaths if not already done.'
    }

    'skip-category' {
        if (-not $Category) {
            Write-Error 'Usage: skip-category -Category avatar [-Notes "deferred"]'
        }
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run init first.'; exit 1 }
        $note = if ($Notes) { $Notes } else { 'skipped for now' }
        $n = 0
        foreach ($item in $m.items) {
            if ($item.category -ne $Category) { continue }
            if ($item.status -ne 'pending') { continue }
            $item.status = 'skipped'
            $item.notes = $note
            $n++
        }
        Save-Manifest $m
        Write-LogLine "skip-category $Category - $n items - $note"
        Write-Host "Skipped $n pending item(s) in category '$Category'. Resume later: mark -Id {id} -Status pending"
    }

    'refresh-prompts' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run init first.'; exit 1 }
        $unique = Get-UniqueItemPrompts
        $n = 0
        foreach ($item in $m.items) {
            if ($unique.ContainsKey($item.id)) {
                $item.prompt = $unique[$item.id]
                $item.negativePrompt = if ($item.category -eq 'avatar') {
                    $AvatarNegative
                } else {
                    $EmblemNegative
                }
                $n++
            }
        }
        Save-Manifest $m
        Write-Host "Updated prompts for $n assets (ach/badge/prof/tier/avatar). Status unchanged."
        Write-Host "Regenerate ChatGPT doc: .\scripts\image_gen.ps1 export-chatgpt"
    }

    'export-chatgpt' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run: .\scripts\image_gen.ps1 init'; exit 1 }
        $pending = $m.items | Where-Object { $_.status -in @('pending', 'failed') } | Sort-Object id
        $outPath = Join-Path $Root 'docs\assets\chatgpt-pending-prompts.md'
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('# ChatGPT batch — pending Vertiege assets')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm') | Count: $($pending.Count)")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Use one ChatGPT image generation per section. Save to **stagingPath**, then `mark -Status generated`.')
        [void]$sb.AppendLine('')
        $n = 0
        foreach ($item in $pending) {
            $n++
            $sizeSpec = $item.size
            $formatLine = if ($item.transparent) {
                'Format: PNG with transparent background (alpha).'
            } elseif ($item.format -eq 'jpg') {
                'Format: PNG from ChatGPT; auto-converts to JPG on pull/mark.'
            } else {
                "Format: $($item.format.ToUpper()) opaque, no transparency."
            }
            $aspectLine = if ($item.size -eq '1080x1920') {
                'Aspect: 9:16 portrait (phone wallpaper).'
            } elseif ($item.category -eq 'world_banner') {
                'Aspect: 16:9 landscape.'
            } elseif ($item.size -eq '512x512') {
                'Aspect: 1:1 square.'
            } else {
                "Aspect: match $($item.size) exactly."
            }
            [void]$sb.AppendLine("## $n. $($item.id)")
            [void]$sb.AppendLine('')
            $chatgptFile = Get-ChatGptFilename $item
            [void]$sb.AppendLine('**Rename in Downloads — copy filename only (ChatGPT exports PNG):**')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('```text')
            [void]$sb.AppendLine($chatgptFile)
            [void]$sb.AppendLine('```')
            if ($chatgptFile -ne $item.filename) {
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine("Auto-converts to ``$($item.filename)`` via ``pull`` or ``mark -Status generated``.")
            }
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("- Staging: ``$($item.stagingPath)``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('**ChatGPT prompt (copy all lines in the box):**')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('```text')
            [void]$sb.AppendLine('Vertiege premium mobile game asset.')
            [void]$sb.AppendLine("Asset ID: $($item.id)")
            [void]$sb.AppendLine("File name when saving: $chatgptFile")
            if ($chatgptFile -ne $item.filename) {
                [void]$sb.AppendLine("Final app file: $($item.filename)")
            }
            [void]$sb.AppendLine("Dimensions: $sizeSpec pixels (generate at this exact size).")
            [void]$sb.AppendLine($formatLine)
            [void]$sb.AppendLine($aspectLine)
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('Subject:')
            [void]$sb.AppendLine($item.prompt.Trim())
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("Avoid: $($item.negativePrompt)")
            [void]$sb.AppendLine('No text, letters, numbers, logos, watermarks, or UI.')
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('**After download:**')
            [void]$sb.AppendLine('```powershell')
            [void]$sb.AppendLine(".\\scripts\\image_gen.ps1 mark -Id $($item.id) -Status generated")
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('---')
            [void]$sb.AppendLine('')
        }
        Set-Content -Path $outPath -Value $sb.ToString() -Encoding UTF8
        Write-Host "Wrote $outPath - $($pending.Count) items"
    }

    'export-chatgpt-project' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run: .\scripts\image_gen.ps1 init'; exit 1 }
        $pending = Sort-QueueItems ($m.items | Where-Object { $_.status -in @('pending', 'failed') })
        $outPath = Join-Path $Root 'docs\assets\chatgpt-project-batch.md'
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine('# Vertiege - ChatGPT Project batch file')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm') | Pending assets: $($pending.Count)")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Upload this file to a **ChatGPT Project** (Project files / knowledge). Use the custom instructions block below in Project settings.')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('---')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Custom instructions (paste into ChatGPT Project)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('```text')
        [void]$sb.AppendLine('You generate Vertiege mobile game art from the batch manifest in this file.')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Rules for every image:')
        [void]$sb.AppendLine('- Follow each asset PROMPT block exactly; one asset per generation unless user asks for the next numbered item.')
        [void]$sb.AppendLine('- Use the exact SAVE_AS filename (ChatGPT only exports PNG).')
        [void]$sb.AppendLine('- Match DIMENSIONS and ASPECT; world banners are 1200x675 landscape 16:9.')
        [void]$sb.AppendLine('- No text, letters, numbers, logos, signage, or watermarks in the image.')
        [void]$sb.AppendLine('- After each image, tell the user: SAVE_AS filename and ASSET_ID for renaming in Downloads.')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('When user says "batch" or "run the list", generate assets in manifest order (1, 2, 3...), one image per message, and stop if rate-limited.')
        [void]$sb.AppendLine('```')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Local workflow (after ChatGPT)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('1. Download each image and rename to **SAVE_AS** (see each asset).')
        [void]$sb.AppendLine('2. Put files in `%USERPROFILE%\\Downloads` with that exact name.')
        [void]$sb.AppendLine('3. In repo: `.\scripts\image_gen.ps1 mark -Id <ASSET_ID> -Status generated` (pulls from Downloads, converts JPG if needed).')
        [void]$sb.AppendLine('4. When all done: `.\scripts\image_gen.ps1 promote -All` then rebuild APK.')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Manifest index')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| # | ASSET_ID | SAVE_AS | SIZE | NOTES |')
        [void]$sb.AppendLine('|---|----------|---------|------|-------|')
        $n = 0
        foreach ($item in $pending) {
            $n++
            $saveAs = Get-ChatGptFilename $item
            $notes = if ($saveAs -ne $item.filename) { "-> $($item.filename)" } else { '' }
            [void]$sb.AppendLine("| $n | $($item.id) | $saveAs | $($item.size) | $notes |")
        }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Kickoff prompts (try in Project chat)')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('- `Generate asset #1 from the manifest. Use its PROMPT block exactly.`')
        [void]$sb.AppendLine('- `Batch mode: generate assets #1 through #16 in order, one per reply. Confirm SAVE_AS after each.`')
        [void]$sb.AppendLine('- `Continue from asset #5.`')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('---')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Asset prompts')
        [void]$sb.AppendLine('')
        $n = 0
        foreach ($item in $pending) {
            $n++
            $saveAs = Get-ChatGptFilename $item
            [void]$sb.AppendLine("### $n. $($item.id)")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("| Field | Value |")
            [void]$sb.AppendLine("|-------|-------|")
            [void]$sb.AppendLine("| ASSET_ID | ``$($item.id)`` |")
            [void]$sb.AppendLine("| SAVE_AS | ``$saveAs`` |")
            if ($saveAs -ne $item.filename) {
                [void]$sb.AppendLine("| FINAL_FILE | ``$($item.filename)`` |")
            }
            [void]$sb.AppendLine("| DIMENSIONS | $($item.size) |")
            [void]$sb.AppendLine("| CATEGORY | $($item.category) |")
            [void]$sb.AppendLine("| STAGING | ``$($item.stagingPath)`` |")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('**PROMPT (copy for image generation):**')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('```text')
            [void]$sb.AppendLine((Build-ChatGptPromptBlock $item))
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('---')
            [void]$sb.AppendLine('')
        }
        Set-Content -Path $outPath -Value $sb.ToString() -Encoding UTF8
        Write-Host "Wrote $outPath - $($pending.Count) items for ChatGPT Project"
    }

    'resize-assets' {
        $m = Get-Manifest
        if (-not $m) { Write-Host 'Run init first.'; exit 1 }
        $n = 0
        foreach ($item in $m.items) {
            $px = Get-PixelSize $item.size
            foreach ($rel in @($item.stagingPath, $item.finalPath)) {
                $path = Join-Path $Root ($rel -replace '/', '\')
                if (-not (Test-Path $path)) { continue }
                $before = (Get-Item $path).Length
                Resize-ImageAsset -SourcePath $path -DestPath $path `
                    -Width $px.Width -Height $px.Height -Format $item.format
                $after = (Get-Item $path).Length
                $n++
                Write-Host "Resized $($item.id) -> $($item.size) ($([math]::Round($before/1KB))KB -> $([math]::Round($after/1KB))KB) [$rel]"
            }
        }
        Write-Host "Resized $n file(s). Rebuild APK to see sharper, smaller assets."
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
