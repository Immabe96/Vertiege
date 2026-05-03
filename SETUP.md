# Vertiege — Windows Setup Guide

## Prerequisites

1. **Install Flutter SDK** (3.x stable)
   - Download: https://docs.flutter.dev/get-started/install/windows
   - Extract to `C:\flutter` or `%USERPROFILE%\flutter`
   - Add `C:\flutter\bin` to PATH

2. **Install Android Studio**
   - Download: https://developer.android.com/studio
   - Install Android SDK (API 34+) and NDK
   - Set `ANDROID_HOME` to `%USERPROFILE%\AppData\Local\Android\Sdk`

3. **Install Git**: https://git-scm.com/download/win

4. **Install VS Code**: https://code.visualstudio.com/
   - Extensions: Flutter, Dart, Expo Tools

5. **Install Node.js** (v25+): https://nodejs.org/

6. **Java JDK 17**: https://adoptium.net/

## Clone & Setup

```powershell
# Clone the Flutter app
git clone https://github.com/Immabe96/social-app-flutter.git %USERPROFILE%\Projects\social-app-flutter
cd %USERPROFILE%\Projects\social-app-flutter

# Install Flutter dependencies
flutter pub get

# Clone the Expo app (for reference / nanobanana image gen)
git clone https://github.com/Immabe96/social-app.git %USERPROFILE%\Projects\social-app
cd %USERPROFILE%\Projects\social-app
npm install
```

## Restore Config Files

### Claude Code Settings

Copy from `.config-backup/claude/` to the correct locations:

```powershell
# Global Claude settings
copy .config-backup\claude\settings.json %USERPROFILE%\.claude\settings.json

# Project-specific Claude settings
copy .config-backup\claude\settings.local.json .claude\settings.local.json

# Claude memory (persistent context)
copy .config-backup\memory\*.md %USERPROFILE%\.claude\projects\-home-imma-social-app-flutter\memory\
```

### MCP Server Configs

```powershell
# VS Code MCP config
copy .config-backup\mcp\mcp.json .vscode\mcp.json

# VS Code global MCP (if needed)
copy .config-backup\vscode\global-mcp.json %APPDATA%\Code\User\mcp.json
```

### Environment Variables

Set these in System Environment Variables or `%USERPROFILE%\.env`:

```powershell
# Supabase (publishable key — safe to share)
$env:EXPO_PUBLIC_SUPABASE_URL = "https://wjaphoaxalvgjnrwqjwe.supabase.co"
$env:EXPO_PUBLIC_SUPABASE_ANON_KEY = "sb_publishable_CpEQsbLTf2ql-xwhPjHOkA_SSpXkJ49"

# Gemini API Key (for nanobanana image generation)
# Get key from: https://aistudio.google.com/app/apikey
$env:GEMINI_API_KEY = "YOUR_KEY_HERE"
```

### Android SDK Path

```powershell
# Set in gradle.properties or local.properties
# Already in: android/local.properties
sdk.dir=C\:\\Users\\<USERNAME>\\AppData\\Local\\Android\\Sdk
```

## Verify Setup

```powershell
flutter doctor
flutter devices
flutter analyze          # Should show 0 issues
flutter build apk --debug  # Build debug APK
```

## Project Structure (Key Files)

```
social-app-flutter/
├── lib/
│   ├── app.dart                    # Root widget, splash, provider init
│   ├── main.dart                   # Entry point, Supabase init
│   ├── config/                     # Static data (tiers, cosmetics, achievements)
│   ├── models/                     # Data classes (json_serializable)
│   ├── router/                     # GoRouter with auth guards
│   ├── screens/                    # Full-screen pages
│   │   ├── tabs/                   # 5 tab screens
│   │   ├── auth/                   # Login, signup, callback
│   │   ├── onboarding/             # First-launch flow
│   │   └── achievements/           # Achievement CRUD
│   ├── services/                   # Business logic (Supabase, permissions)
│   ├── state/                      # Riverpod providers
│   ├── theme/                      # Design tokens + ThemeData
│   ├── utils/                      # Helpers (date, time_ago, string)
│   └── widgets/                    # Reusable UI components
│       ├── core/                   # Primitives (FadeIn, Shimmer, StatusDot, etc.)
│       ├── feed/                   # PostItem, PostInput, ReactionBar
│       ├── profile/                # CosmeticAvatar, Badge, ShareCard
│       ├── worlds/                 # WorldCard, WorldBanner, WorldIcon
│       ├── shared/                 # Cross-cutting widgets
│       └── achievements/           # AchievementCard, AchievementGrid
├── .claude/
│   ├── figma-rules.md             # Figma-to-Flutter integration rules
│   └── settings.local.json        # Project permissions
├── .config-backup/                # Portable config backup
│   ├── claude/                    # Claude settings
│   ├── mcp/                       # MCP server configs
│   ├── vscode/                    # VS Code configs
│   └── memory/                    # Claude persistent memory
├── CLAUDE.md                      # Project instructions for AI agents
├── SETUP.md                       # This file
├── AUDIT.md                       # Full audit report
└── TODO.md                        # Task tracking
```

## Image Generation (Nanobanana)

The Expo app at `%USERPROFILE%\Projects\social-app` contains the `opencode-nanobanana` package for AI image generation via Google Gemini.

```powershell
cd %USERPROFILE%\Projects\social-app
node -e "import('./node_modules/opencode-nanobanana/dist/index.js').then(async m => { const r = await m.default({}); console.log(Object.keys(r.tool)); })"
# Lists all 16 tools: generate_image, edit_image, restore_image, etc.
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Gradle cache corruption | `rm -rf %USERPROFILE%\.gradle\caches` then `flutter clean` |
| AGP 9+ DSL error | Already set `android.newDsl=false` in `android/gradle.properties` |
| NDK not found | Install NDK via Android Studio SDK Manager |
| Flutter doctor shows issues | Run `flutter doctor --android-licenses` |
