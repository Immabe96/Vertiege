# Commune UX wave status

**Live shell (Vertiege 3-tab):** Nexus `/` · Chat `/chat` · Identity `/identity` — worlds/channels via `/explore` (shell branch **3**, no tab). Commune Home rail is **retired** from routing.

| Tab | Analog | Focus |
|-----|--------|--------|
| Nexus | LinkedIn | Verified moments, progression, announcements |
| Chat | Discord | Worlds, channels, DMs, Campfire |
| Identity | Vertiege moat | Proof submit, queue, honour wall, tier |

| Wave | Name | Status | Done | Total |
|------|------|--------|------|-------|
| 0 | Planning & foundations | **done** | 5 | 5 |
| 1 | IA & navigation | **done** | 24 | 24 |
| 2 | Commune theme | **done** | 18 | 18 |
| 3 | Chat & messaging | **done** | 26 | 26 |
| 4 | World UI | **done** | 18 | 18 |
| 5 | Nexus / feed | **done** | 12 | 12 |
| 6 | You / identity | **done** | 12 | 12 |
| 7 | Components & polish | **done** | 14 | 14 |
| 8 | Performance & a11y | **done** | 10 | 10 |
| 9 | Vertiege differentiators | **done** | 10 | 10 |

**Changes DB:** **144 / 144** marked `done` in [discord-redesign-changes.json](discord-redesign-changes.json)

## Wave 4 shipped

- [x] DCX-069: Channels-first world detail tabs via `WorldPageIa`
- [x] DCX-070: Channel categories collapsible on Home
- [x] DCX-071: `WorldCompactHeader` on Home channel panel
- [x] DCX-072–075, DCX-080–081, DCX-086: rail unread, invite, tier lock, tooltips
- [x] DCX-076: Shop/jobs demoted to `WorldToolsPanel` overflow
- [x] DCX-077: Optional feed tab (`hasFeedTab`)
- [x] DCX-078: 48dp circular world icons on rail
- [x] DCX-079: `BoostedWorldsRow` on Explore screen
- [x] DCX-082–083: Governance, treasury, academy in world tools menu
- [x] DCX-085: Inline create-channel row on channel list
- [x] DCX-084: `showWorldWelcomeFlow` on first join — rules + quick channel picks

## Wave 5 shipped

- [x] DCX-087–092: Flat feed, shortcuts, context chips, comment push
- [x] DCX-088: `InlineReactionBar` under posts
- [x] DCX-089: Sticky `PostInput` atop Nexus feed body
- [x] DCX-093: `VFeedback.showAchievementUnlock` toast + app listener
- [x] DCX-094: Season banner removed from Nexus; chip on You tab
- [x] DCX-095: Full-bleed post images
- [x] DCX-097: Mute world from post overflow menu
- [x] DCX-096: Cross-post achievement to world channel via `CrossPostAchievementSheet`
- [x] DCX-098: Unified `ShimmerPostCard` / `ShimmerChatTile` in `ScreenLoading`

## Wave 6 shipped

- [x] DCX-099–100: You profile card + allies row
- [x] DCX-101: Settings entry from You tab
- [x] DCX-102: Collapsible progression section
- [x] DCX-105: `status_picker.dart` on profile card
- [x] DCX-108: Coin balance on You profile card
- [x] DCX-109: Featured achievements horizontal strip
- [x] DCX-103: Denser trophy grid + detail sheet on tap
- [x] DCX-104: Minimal profile hero (avatar + name focus)
- [x] DCX-106: Edit profile via `showVSheet`
- [x] DCX-107: Tier ring on `VAvatar`
- [x] DCX-110: Full-width Message CTA on resident profile

## Wave 7 shipped

- [x] DCX-111: `VChannelTile`
- [x] DCX-112: `VAvatar` presence dot
- [x] DCX-119: Reaction haptics (`Haptics.light` on inline + action bar)
- [x] DCX-113: `VSearchBar` + `VSearchFilterChip`
- [x] DCX-114: `VContextMenu` unified long-press menus
- [x] DCX-115: `VIconButton` tooltips + semantics
- [x] DCX-116: `EmptyStateIllustration` commune art on `AppEmptyState`
- [x] DCX-117: `showVSideSheet` side panel variant
- [x] DCX-118: Migrated `showModalBottomSheet` → `showVSheet`
- [x] DCX-120: `panelSlide` transitions for `/chat` routes
- [x] DCX-121: Campfire full-bleed `VCommuneColors` dark ladder
- [x] DCX-122: Auth screens commune dark ladder
- [x] DCX-123: Onboarding 3-step (identity → gate → worlds)
- [x] DCX-124: Achievement categories open in hub sheets

## Wave 9 shipped

- [x] DCX-135: Tier-gated channels show lock + tier requirement on row
- [x] DCX-136: Achievement share attachments + badge reactions in chat
- [x] DCX-137: `WorldTreasuryGlance` in world tools menu
- [x] DCX-138: Season progress chip on You tab with days remaining
- [x] DCX-139: Verifier queue count on Settings → Staff review
- [x] DCX-140: `AiProofPreviewPanel` on achievement submit
- [x] DCX-141: Cross-world Message CTA in unified search
- [x] DCX-142: Campfire text split bar (`_CampfireTextSplitBar`)
- [x] DCX-143: `VMemberCard` on resident list tap
- [x] DCX-144: Constitution pinned in #rules + rules markdown

## Wave 2 shipped

- [x] DCX-025–042: `VCommuneColors` ladder, accent discipline, chat tokens, Forui bridge, `DESIGN.md` commune spec

## Wave 3 shipped

- [x] DCX-043–068: `VMessageBubble`, markdown/spoilers/mentions, attachments, slash commands, pins, search, resident list, system messages, Campfire mini bar

## Wave 8 shipped

- [x] DCX-125–134: ListView perf, `RepaintBoundary` on bubbles, cache extent, image `cacheWidth`, selective Riverpod watches, semantics, 44dp rail targets, `VMotion` reduce-motion, high-contrast toggle, panel focus order

## Prior waves (still shipped)

- [x] Wave 1: Overlapping panels, world switcher, discover slide-over, last-channel resume

## Audit (2026-05-30)

- **144 / 144** `done` in [discord-redesign-changes.json](discord-redesign-changes.json) — file-existence pass; 2 stale path entries corrected (DCX-019, DCX-047).
- **Retired:** `commune_home_screen.dart`, `commune_home_provider.dart` (3-tab shell; deep links via `app_router` + `world_admin_breadcrumb`).
- **~70 untracked lib/test/migration files** on branch — implementation artifacts referenced by modified screens; stage when ready to commit.
- **Backlog (post-DCX):** DM → channel cross-post; profile standing pagination ✅; `ref` cleanup in channel/DM `deactivate()` ✅.
