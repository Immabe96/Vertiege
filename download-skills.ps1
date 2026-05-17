# Download all Flutter, UI/UX, and Social Media skills
$ErrorActionPreference = "Continue"
$baseDir = ".opencode\skills"

function Download-Skill {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Name
    )
    
    try {
        $dir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec 30
        Write-Output "  [OK] $Name"
        return $true
    } catch {
        Write-Output "  [FAIL] $Name - $($_.Exception.Message)"
        return $false
    }
}

# ============================================
# FLUTTER SKILLS (Official Flutter Team)
# ============================================
Write-Output "`n=== Downloading Flutter Skills ==="

$flutterSkills = @(
    @{Name="flutter-adding-home-screen-widgets"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-adding-home-screen-widgets/SKILL.md"},
    @{Name="flutter-animating-apps"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-animating-apps/SKILL.md"},
    @{Name="flutter-architecting-apps"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-architecting-apps/SKILL.md"},
    @{Name="flutter-building-forms"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-building-forms/SKILL.md"},
    @{Name="flutter-building-layouts"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-building-layouts/SKILL.md"},
    @{Name="flutter-building-plugins"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-building-plugins/SKILL.md"},
    @{Name="flutter-caching-data"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-caching-data/SKILL.md"},
    @{Name="flutter-embedding-native-views"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-embedding-native-views/SKILL.md"},
    @{Name="flutter-handling-concurrency"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-handling-concurrency/SKILL.md"},
    @{Name="flutter-handling-http-and-json"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-handling-http-and-json/SKILL.md"},
    @{Name="flutter-implementing-navigation-and-routing"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-implementing-navigation-and-routing/SKILL.md"},
    @{Name="flutter-improving-accessibility"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-improving-accessibility/SKILL.md"},
    @{Name="flutter-interoperating-with-native-apis"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-interoperating-with-native-apis/SKILL.md"},
    @{Name="flutter-localizing-apps"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-localizing-apps/SKILL.md"},
    @{Name="flutter-managing-state"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-managing-state/SKILL.md"},
    @{Name="flutter-reducing-app-size"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-reducing-app-size/SKILL.md"},
    @{Name="flutter-setting-up-on-linux"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-setting-up-on-linux/SKILL.md"},
    @{Name="flutter-setting-up-on-macos"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-setting-up-on-macos/SKILL.md"},
    @{Name="flutter-setting-up-on-windows"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-setting-up-on-windows/SKILL.md"},
    @{Name="flutter-testing-apps"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-testing-apps/SKILL.md"},
    @{Name="flutter-theming-apps"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-theming-apps/SKILL.md"},
    @{Name="flutter-working-with-databases"; Url="https://raw.githubusercontent.com/flutter/skills/main/skills/flutter-working-with-databases/SKILL.md"}
)

$flutterOk = 0
$flutterFail = 0
foreach ($skill in $flutterSkills) {
    $outPath = Join-Path $baseDir "flutter\$($skill.Name)\SKILL.md"
    if (Download-Skill -Url $skill.Url -OutputPath $outPath -Name $skill.Name) {
        $flutterOk++
    } else {
        $flutterFail++
    }
}
Write-Output "Flutter: $flutterOk OK, $flutterFail Failed"

# ============================================
# UI/UX DESIGN SKILLS
# ============================================
Write-Output "`n=== Downloading UI/UX Design Skills ==="

$uiuxSkills = @(
    # Anthropic skills
    @{Name="frontend-design"; Url="https://raw.githubusercontent.com/anthropics/claude-code/main/skills/frontend-design/SKILL.md"; Category="ui-ux"},
    @{Name="canvas-design"; Url="https://raw.githubusercontent.com/anthropics/claude-code/main/skills/canvas-design/SKILL.md"; Category="ui-ux"},
    @{Name="theme-factory"; Url="https://raw.githubusercontent.com/anthropics/claude-code/main/skills/theme-factory/SKILL.md"; Category="ui-ux"},
    @{Name="brand-guidelines"; Url="https://raw.githubusercontent.com/anthropics/claude-code/main/skills/brand-guidelines/SKILL.md"; Category="ui-ux"},
    
    # Vercel skills
    @{Name="web-design-guidelines"; Url="https://raw.githubusercontent.com/vercel-labs/skills/main/skills/web-design-guidelines/SKILL.md"; Category="ui-ux"},
    
    # Microsoft skills
    @{Name="frontend-design-review"; Url="https://raw.githubusercontent.com/microsoft/skills/main/skills/frontend-design-review/SKILL.md"; Category="ui-ux"},
    
    # Google Labs (Stitch) skills
    @{Name="design-md"; Url="https://raw.githubusercontent.com/google-labs-code/stitch-mcp/main/skills/design-md/SKILL.md"; Category="ui-ux"},
    @{Name="enhance-prompt"; Url="https://raw.githubusercontent.com/google-labs-code/stitch-mcp/main/skills/enhance-prompt/SKILL.md"; Category="ui-ux"},
    @{Name="shadcn-ui"; Url="https://raw.githubusercontent.com/google-labs-code/stitch-mcp/main/skills/shadcn-ui/SKILL.md"; Category="ui-ux"},
    
    # Community UI/UX skills
    @{Name="ui-ux-pro-max"; Url="https://raw.githubusercontent.com/nextlevelbuilder/ui-ux-pro-max-skill/main/SKILL.md"; Category="ui-ux"},
    @{Name="ui-skills"; Url="https://raw.githubusercontent.com/ibelick/ui-skills/main/SKILL.md"; Category="ui-ux"},
    @{Name="platform-design-skills"; Url="https://raw.githubusercontent.com/ehmo/platform-design-skills/main/SKILL.md"; Category="ui-ux"},
    @{Name="taste-skill"; Url="https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/SKILL.md"; Category="ui-ux"},
    @{Name="apple-hig-skills"; Url="https://raw.githubusercontent.com/raintree-technology/apple-hig-skills/main/SKILL.md"; Category="ui-ux"},
    @{Name="color-expert"; Url="https://raw.githubusercontent.com/meodai/skill.color-expert/main/SKILL.md"; Category="ui-ux"},
    
    # Web quality/accessibility
    @{Name="accessibility"; Url="https://raw.githubusercontent.com/addyosmani/web-quality-skills/main/skills/accessibility/SKILL.md"; Category="ui-ux"},
    @{Name="web-quality-audit"; Url="https://raw.githubusercontent.com/addyosmani/web-quality-skills/main/skills/web-quality-audit/SKILL.md"; Category="ui-ux"}
)

$uiuxOk = 0
$uiuxFail = 0
foreach ($skill in $uiuxSkills) {
    $outPath = Join-Path $baseDir "$($skill.Category)\$($skill.Name)\SKILL.md"
    if (Download-Skill -Url $skill.Url -OutputPath $outPath -Name $skill.Name) {
        $uiuxOk++
    } else {
        $uiuxFail++
    }
}
Write-Output "UI/UX: $uiuxOk OK, $uiuxFail Failed"

# ============================================
# SOCIAL MEDIA SKILLS
# ============================================
Write-Output "`n=== Downloading Social Media Skills ==="

$socialSkills = @(
    # Twitter/X skills
    @{Name="typefully"; Url="https://raw.githubusercontent.com/typefully/skills/main/skills/typefully/SKILL.md"; Category="social-media"},
    @{Name="x-twitter-scraper"; Url="https://raw.githubusercontent.com/Xquik-dev/x-twitter-scraper/main/SKILL.md"; Category="social-media"},
    @{Name="tweetclaw"; Url="https://raw.githubusercontent.com/Xquik-dev/tweetclaw/main/SKILL.md"; Category="social-media"},
    @{Name="x-article-publisher"; Url="https://raw.githubusercontent.com/wshuyi/x-article-publisher-skill/main/SKILL.md"; Category="social-media"},
    @{Name="social-content"; Url="https://raw.githubusercontent.com/coreyhaines31/marketingskills/main/skills/social-content/SKILL.md"; Category="social-media"},
    
    # Multi-platform social media
    @{Name="postiz-agent"; Url="https://raw.githubusercontent.com/gitroomhq/postiz-agent/main/SKILL.md"; Category="social-media"},
    @{Name="wonda"; Url="https://raw.githubusercontent.com/degausai/wonda/main/SKILL.md"; Category="social-media"},
    
    # WhatsApp skills
    @{Name="integrate-whatsapp"; Url="https://raw.githubusercontent.com/gokapso/agent-skills/master/skills/integrate-whatsapp/SKILL.md"; Category="social-media"},
    @{Name="automate-whatsapp"; Url="https://raw.githubusercontent.com/gokapso/agent-skills/master/skills/automate-whatsapp/SKILL.md"; Category="social-media"},
    @{Name="observe-whatsapp"; Url="https://raw.githubusercontent.com/gokapso/agent-skills/master/skills/observe-whatsapp/SKILL.md"; Category="social-media"},
    
    # Research across social platforms
    @{Name="last30days-skill"; Url="https://raw.githubusercontent.com/mvanhorn/last30days-skill/main/SKILL.md"; Category="social-media"}
)

$socialOk = 0
$socialFail = 0
foreach ($skill in $socialSkills) {
    $outPath = Join-Path $baseDir "$($skill.Category)\$($skill.Name)\SKILL.md"
    if (Download-Skill -Url $skill.Url -OutputPath $outPath -Name $skill.Name) {
        $socialOk++
    } else {
        $socialFail++
    }
}
Write-Output "Social Media: $socialOk OK, $socialFail Failed"

# ============================================
# MOBILE/NATIVE SKILLS (Expo, React Native - useful reference)
# ============================================
Write-Output "`n=== Downloading Mobile/Native Skills ==="

$mobileSkills = @(
    # Sentry Flutter SDK
    @{Name="sentry-flutter-sdk"; Url="https://raw.githubusercontent.com/getsentry/sentry-skills/main/skills/sentry-flutter-sdk/SKILL.md"; Category="mobile"},
    
    # React Native (useful patterns)
    @{Name="react-native-best-practices"; Url="https://raw.githubusercontent.com/callstackincubator/skills/main/skills/react-native-best-practices/SKILL.md"; Category="mobile"},
    @{Name="react-native-skills"; Url="https://raw.githubusercontent.com/vercel-labs/skills/main/skills/react-native-skills/SKILL.md"; Category="mobile"},
    @{Name="upgrading-react-native"; Url="https://raw.githubusercontent.com/callstackincubator/skills/main/skills/upgrading-react-native/SKILL.md"; Category="mobile"},
    
    # Expo skills
    @{Name="building-native-ui"; Url="https://raw.githubusercontent.com/expo/skills/main/skills/building-native-ui/SKILL.md"; Category="mobile"},
    @{Name="expo-tailwind-setup"; Url="https://raw.githubusercontent.com/expo/skills/main/skills/expo-tailwind-setup/SKILL.md"; Category="mobile"},
    @{Name="native-data-fetching"; Url="https://raw.githubusercontent.com/expo/skills/main/skills/native-data-fetching/SKILL.md"; Category="mobile"}
)

$mobileOk = 0
$mobileFail = 0
foreach ($skill in $mobileSkills) {
    $outPath = Join-Path $baseDir "$($skill.Category)\$($skill.Name)\SKILL.md"
    if (Download-Skill -Url $skill.Url -OutputPath $outPath -Name $skill.Name) {
        $mobileOk++
    } else {
        $mobileFail++
    }
}
Write-Output "Mobile: $mobileOk OK, $mobileFail Failed"

# ============================================
# SUMMARY
# ============================================
$totalOk = $flutterOk + $uiuxOk + $socialOk + $mobileOk
$totalFail = $flutterFail + $uiuxFail + $socialFail + $mobileFail

Write-Output "`n========================================="
Write-Output "DOWNLOAD SUMMARY"
Write-Output "========================================="
Write-Output "Flutter:       $flutterOk OK, $flutterFail Failed"
Write-Output "UI/UX:         $uiuxOk OK, $uiuxFail Failed"
Write-Output "Social Media:  $socialOk OK, $socialFail Failed"
Write-Output "Mobile:        $mobileOk OK, $mobileFail Failed"
Write-Output "-----------------------------------------"
Write-Output "TOTAL:         $totalOk OK, $totalFail Failed"
Write-Output "========================================="
