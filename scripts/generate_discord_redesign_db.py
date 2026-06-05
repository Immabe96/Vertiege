#!/usr/bin/env python3
"""Generate discord-redesign-changes.json with 120+ tracked UX changes."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/product/planning/discord-redesign-changes.json"

def c(id_, wave, cat, pri, title, desc, files=None, discord_ref=""):
    return {
        "id": id_,
        "wave": wave,
        "category": cat,
        "priority": pri,
        "title": title,
        "description": desc,
        "files": files or [],
        "discord_ref": discord_ref,
        "status": "planned",
    }

changes = []

# WAVE 1 — IA & navigation (24)
nav = [
    ("DCX-001", "Unify Home: worlds + DMs in one tab", "Merge Explore chat modes and world rail into Chat-native Home with overlapping panels", ["lib/screens/tabs/tab_layout.dart", "lib/screens/tabs/chat_list_screen.dart"], "Home tab servers + Messages"),
    ("DCX-002", "Collapse bottom nav inside active channel", "Hide tab bar when user is in world channel or DM; show on back", ["lib/screens/tabs/tab_layout.dart", "lib/router/app_router.dart"], "Navbar disappears in server"),
    ("DCX-003", "OverlappingPanelsLayout for world→channel", "Custom panel: world list | channel list | chat (Material easing, no drawer+tabs)", ["lib/ui/shell/v_overlapping_panels.dart"], "Android panels blog"),
    ("DCX-004", "Rename Identity tab to You", "Profile, status, friends, settings entry — Reference app You tab pattern", ["lib/screens/tabs/identity_screen.dart", "lib/ui/navigation/v_bottom_nav.dart"], "You tab"),
    ("DCX-005", "Fold More into You tab", "Remove 5th hub tab; relocate links to You settings groups", ["lib/screens/tabs/more_screen.dart", "lib/screens/tabs/identity_screen.dart"], "You tab settings"),
    ("DCX-006", "Reduce primary tabs to 3", "Home | Notifications | You (Nexus feed becomes Home sub-view)", ["lib/router/app_router.dart"], "3-tab mobile layout"),
    ("DCX-007", "Nexus feed as Home default center panel", "Feed remains first-class inside Home, not separate mental model", ["lib/screens/tabs/nexus_screen.dart"], "Activity/home blend"),
    ("DCX-008", "World discovery via Home search", "Global + in-world search with inline filter chips", ["lib/screens/search_screen.dart"], "Search filters"),
    ("DCX-009", "Eliminate dual DM routes", "Single /chat/:roomId; fix white-screen pushes from search/profile", ["lib/router/app_router.dart"], "Consistent DM routing"),
    ("DCX-010", "Channel header tap opens details sheet", "Members, pins, media, threads — not swipe-from-right", ["lib/screens/world_channel_screen.dart"], "Tap channel name"),
    ("DCX-011", "Swipe-to-reply on messages", "Right-to-left gesture on bubble triggers reply composer", ["lib/widgets/chat/"], "Mobile reply gesture"),
    ("DCX-012", "Favorite channels per world", "Pin channels to top of list with star affordance", ["lib/widgets/worlds/world_channel_list.dart"], "Favorite channels"),
    ("DCX-013", "Server (world) icon rail", "Fixed left rail of circular world icons with unread badges", ["lib/ui/navigation/v_world_rail.dart"], "World list rail"),
    ("DCX-014", "Unread pill on world icons", "White pill count on server icon; suppress when muted", ["lib/utils/chat_unread.dart"], "Unread badges"),
    ("DCX-015", "Back stack: Home→Channels→Chat hierarchy", "Panels animate with fixed duration; no ambiguous drawer overlay", ["lib/ui/shell/v_overlapping_panels.dart"], "Home→Channels→Chat"),
    ("DCX-016", "Deep links preserve panel state", "World/channel deep links open correct panel without blank tab", ["lib/router/app_router.dart"], "Deep link parity"),
    ("DCX-017", "Campfire entry from voice row in channel list", "Voice channels grouped; tap joins voice UI full-screen", ["lib/widgets/worlds/world_channel_list.dart"], "Voice channels"),
    ("DCX-018", "Thread preview inline in channel", "Thread summary row under parent message", ["lib/screens/world_channel_screen.dart"], "Threads in channel"),
    ("DCX-019", "Breadcrumb in nested world admin", "Secondary routes show world name + section; back to channel list", ["lib/screens/world_*_screen.dart"], "Wayfinding"),
    ("DCX-020", "Quick switcher between worlds", "Long-press world rail or search to jump worlds", ["lib/ui/navigation/v_world_rail.dart"], "Quick server switch"),
    ("DCX-021", "Persist last channel per world", "Resume where user left off on re-enter", ["lib/state/chat_provider.dart"], "Resume channel"),
    ("DCX-022", "Notifications tab or sheet", "Alerts accessible without leaving chat context", ["lib/screens/tabs/alerts_screen.dart"], "Notification center"),
    ("DCX-023", "Remove FAB on Nexus; composer in feed header", "Chat-native inline compose, not floating +", ["lib/screens/tabs/tab_layout.dart"], "Inline compose"),
    ("DCX-024", "Explore worlds as Home panel slide", "Discover worlds without dedicated bottom tab", ["lib/screens/tabs/explore_screen.dart"], "Discovery in Home"),
]
for i, (id_, title, desc, files, ref) in enumerate(nav, 1):
    changes.append(c(id_, 1, "navigation", "P0", title, desc, files, ref))

# WAVE 2 — Theme & design system (18)
theme = [
    ("DCX-025", "Commune dark surface ladder", "Add Discord-like elevation tokens: primary/secondary/tertiary/floating", ["lib/theme/v_colors.dart"], "#313338 ladder"),
    ("DCX-026", "Vertiege accent on interactive only", "Gold/violet reserved for CTAs, mentions, active states — not backgrounds", ["lib/theme/v_colors.dart"], "Blurple accent discipline"),
    ("DCX-027", "Message text tokens", "text-normal, text-muted, header-primary for chat typography", ["lib/theme/v_tokens.dart", "lib/theme/v_fonts.dart"], "Text roles"),
    ("DCX-028", "Modifier hover/active/selected rgba", "List row states without hard borders", ["lib/theme/v_colors.dart"], "background-modifier-*"),
    ("DCX-029", "8px card radius; pill buttons", "Commune radii across VCard/VButton", ["lib/theme/v_tokens.dart"], "8px radius"),
    ("DCX-030", "Remove gold wash on chat surfaces", "Chat areas use neutral dark only; prestige accents in headers", ["lib/screens/world_channel_screen.dart"], "Neutral chat bg"),
    ("DCX-031", "Elevation via lightness not shadow", "Dark theme depth without drop shadows on lists", ["lib/ui/cards/v_surface_card.dart"], "Surface elevation"),
    ("DCX-032", "Desaturated body text on dark", "Avoid pure white body; #dbdee1 equivalent", ["lib/theme/v_colors.dart"], "text-normal"),
    ("DCX-033", "Status color system", "Online/idle/dnd/offline dots unified", ["lib/utils/presence_utils.dart"], "Status colors"),
    ("DCX-034", "Mention and link colors", "Distinct link blue for URLs; accent for @mentions", ["lib/widgets/chat/"], "text-link"),
    ("DCX-035", "Theme scheme picker: Commune default", "New default dark preset; keep Prestige as optional", ["lib/widgets/core/v_theme_scheme_picker.dart"], "Theme options"),
    ("DCX-036", "Saturation/contrast accessibility sliders", "Chat-native a11y theme controls in Settings", ["lib/screens/settings_screen.dart"], "A11y sliders"),
    ("DCX-037", "Sync Forui theme to Commune ladder", "VertiegeForuiTheme maps new surface tokens", ["lib/theme/forui_theme.dart"], "Forui bridge"),
    ("DCX-038", "Icon size scale for dense lists", "20/16/14 icon steps for channel rows", ["lib/theme/v_tokens.dart"], "Dense icons"),
    ("DCX-039", "Divider tokens — subtle 1px", "channel-group separators at 10% white", ["lib/theme/v_colors.dart"], "Subtle dividers"),
    ("DCX-040", "Blur/glass removal in chat shell", "Solid surfaces in messaging; glass only for modals", ["lib/widgets/core/glass_panel.dart"], "Solid chat chrome"),
    ("DCX-041", "Light mode Commune variant", "Optional light theme with same IA", ["lib/theme/v_theme.dart"], "Light parity"),
    ("DCX-042", "DESIGN.md commune spec", "Living design doc for agents", ["docs/reference/DESIGN.md"], "design-md skill"),
]
for id_, title, desc, files, ref in theme:
    changes.append(c(id_, 2, "theme", "P0", title, desc, files, ref))

# WAVE 3 — Chat & messaging (26)
chat = [
    ("DCX-043", "Extract VMessageBubble widget", "Single shared bubble for DM + world channel", ["lib/widgets/chat/v_message_bubble.dart"], "Unified bubbles"),
    ("DCX-044", "Group consecutive messages by author", "Avatar only on first in group; tighter vertical rhythm", ["lib/widgets/chat/chat_message_grouper.dart"], "Message grouping"),
    ("DCX-045", "Compact message density option", "Settings toggle: cozy vs compact", ["lib/screens/settings_screen.dart"], "Density toggle"),
    ("DCX-046", "Username + timestamp inline header", "header-primary name, muted time on same row", ["lib/widgets/chat/v_message_bubble.dart"], "Message header"),
    ("DCX-047", "Reaction row on long-press", "Emoji picker overlay on message", ["lib/widgets/chat/v_message_reactions.dart"], "Reactions"),
    ("DCX-048", "Reply quote block in composer", "Quoted message preview above input", ["lib/widgets/chat/chat_input_bar.dart"], "Reply UI"),
    ("DCX-049", "Thread indicator chip on messages", "N replies · tap opens thread", ["lib/widgets/chat/v_message_bubble.dart"], "Threads"),
    ("DCX-050", "Markdown rendering parity", "Bold, italic, code blocks, spoilers in chat", ["lib/widgets/chat/v_message_content.dart"], "Markdown"),
    ("DCX-051", "Link embed preview cards", "URL unfurl below message when available", ["lib/widgets/chat/v_link_embed.dart"], "Embeds"),
    ("DCX-052", "Image grid in messages", "1/2/3+ image layouts chat-native media", ["lib/widgets/chat/chat_image.dart"], "Media grid"),
    ("DCX-053", "GIF/sticker picker sheet", "Bottom sheet picker; tier-gated stickers preserved", ["lib/widgets/chat/v_media_picker.dart"], "GIF picker"),
    ("DCX-054", "Typing indicator in channel list", "X is typing… on channel row", ["lib/screens/tabs/chat_list_screen.dart"], "Typing in list"),
    ("DCX-055", "Jump to present FAB", "Show when scrolled up; badge for new messages", ["lib/widgets/chat/scroll_fab.dart"], "Jump to present"),
    ("DCX-056", "Date separator style", "Floating pill dividers between days", ["lib/widgets/chat/chat_date_separator.dart"], "Date separators"),
    ("DCX-057", "New messages divider", "Red line / pill for unread boundary", ["lib/widgets/chat/new_since_visit_divider.dart"], "Unread divider"),
    ("DCX-058", "Composer grows multi-line", "Shift+enter newline; max height cap", ["lib/widgets/chat/chat_input_bar.dart"], "Multiline input"),
    ("DCX-059", "Attachment tray", "+ button: image, file, achievement share", ["lib/widgets/chat/chat_input_bar.dart"], "Attachments"),
    ("DCX-060", "Slash command hint bar", "/pin /thread /tier for power users", ["lib/widgets/chat/v_slash_commands.dart"], "Slash commands"),
    ("DCX-061", "Message actions context menu", "Copy, reply, react, report, delete (role-gated)", ["lib/widgets/chat/v_message_actions.dart"], "Context menu"),
    ("DCX-062", "Pin message banner", "Pinned messages accessible from channel header", ["lib/screens/world_channel_screen.dart"], "Pins"),
    ("DCX-063", "Search in channel", "Header search opens in:channel filter UI", ["lib/screens/search_screen.dart"], "In-channel search"),
    ("DCX-064", "Resident list sidebar sheet", "Avatars + roles; tap to DM", ["lib/widgets/chat/v_member_list_sheet.dart"], "Resident list"),
    ("DCX-065", "Role color on usernames", "World roles tint display names in chat", ["lib/widgets/chat/v_message_bubble.dart"], "Role colors"),
    ("DCX-066", "System message style", "Centered muted pills for joins/leaves/tier ups", ["lib/widgets/chat/v_system_message.dart"], "System messages"),
    ("DCX-067", "Voice connected bar", "Green bar when in Campfire; tap return", ["lib/widgets/voice/campfire_mini_bar.dart"], "Voice connected"),
    ("DCX-068", "Eliminate duplicate _MessageBubble code", "Delete private classes from channel/DM screens", ["lib/screens/chat_room_screen.dart", "lib/screens/world_channel_screen.dart"], "DRY chat"),
]
for id_, title, desc, files, ref in chat:
    changes.append(c(id_, 3, "chat", "P0", title, desc, files, ref))

# WAVE 4 — World UI (18)
world = [
    ("DCX-069", "Rewrite world_detail as world home", "Channels-first layout; tabs demoted to overflow", ["lib/screens/world_detail_screen.dart"], "World layout"),
    ("DCX-070", "Channel list categories collapsible", "Text / Voice / Announcement groups", ["lib/widgets/worlds/world_channel_list.dart"], "Channel categories"),
    ("DCX-071", "World header compact", "Icon + name + chevron; no hero banner on chat path", ["lib/widgets/worlds/world_profile_header.dart"], "Compact world header"),
    ("DCX-072", "Member count in channel header", "Online/total in subtitle", ["lib/screens/world_channel_screen.dart"], "Member count"),
    ("DCX-073", "World settings gear in rail context menu", "Long-press world icon for settings/mute/leave", ["lib/ui/navigation/v_world_rail.dart"], "World menu"),
    ("DCX-074", "Invite button in channel list header", "Prominent invite friends CTA", ["lib/widgets/worlds/world_channel_list.dart"], "Invite"),
    ("DCX-075", "World unread state on rail", "Bold white dot vs number pill", ["lib/ui/navigation/v_world_rail.dart"], "Unread world"),
    ("DCX-076", "Demote marketplace/jobs to world menu", "Keep features; not primary tabs", ["lib/config/world_page_ia.dart"], "Feature discoverability"),
    ("DCX-077", "Feed tab optional per world", "Worlds with feed enable tab; default off for chat-first", ["lib/widgets/worlds/world_feed_tab.dart"], "Optional feed"),
    ("DCX-078", "World icon 48dp circle", "Consistent world icon in rail and headers", ["lib/widgets/worlds/world_icon.dart"], "World icons"),
    ("DCX-079", "Boost/featured worlds row in discover panel", "Horizontal scroll discovery", ["lib/widgets/explore/boosted_worlds_row.dart"], "Discovery"),
    ("DCX-080", "Create world CTA at rail bottom", "+ icon chat-native add server", ["lib/ui/navigation/v_world_rail.dart"], "Discover worlds"),
    ("DCX-081", "World tooltips on long press", "Name + resident count preview", ["lib/ui/navigation/v_world_rail.dart"], "World tooltip"),
    ("DCX-082", "Governance behind mod tools", "Keep governance; access via settings > moderation", ["lib/screens/world_governance_screen.dart"], "Mod tools"),
    ("DCX-083", "Treasury/academy as server submenu", "Preserve RPG features without tab clutter", ["lib/screens/world_treasury_screen.dart"], "Server submenu"),
    ("DCX-084", "World welcome modal on first join", "Quick channel picks + rules", ["lib/widgets/worlds/world_welcome_flow.dart"], "Welcome flow"),
    ("DCX-085", "Channel create inline", "+ channel row at category bottom", ["lib/widgets/worlds/world_settings_channels.dart"], "Create channel"),
    ("DCX-086", "Slow mode / tier gate indicators on channel row", "Preserve tier gating visibly on row", ["lib/widgets/worlds/world_channel_list.dart"], "Channel metadata"),
]
for id_, title, desc, files, ref in world:
    changes.append(c(id_, 4, "world", "P1", title, desc, files, ref))

# WAVE 5 — Nexus / feed (12)
feed = [
    ("DCX-087", "Feed cards flatter — less bento chrome", "Discord-activity style rows not heavy cards", ["lib/widgets/nexus/bento_grid.dart"], "Activity feed"),
    ("DCX-088", "Inline reactions on posts", "Emoji bar under post without sheet", ["lib/widgets/feed/reaction_bar.dart"], "Inline reactions"),
    ("DCX-089", "Post composer sticky top", "Single-line expand chat-native status/post", ["lib/widgets/feed/post_input.dart"], "Composer"),
    ("DCX-090", "Reduce Nexus shortcuts grid", "3 primary shortcuts; rest in overflow", ["lib/widgets/nexus/nexus_shortcuts_section.dart"], "Shortcuts"),
    ("DCX-091", "Context strip as horizontal chips", "World/season context as filter chips", ["lib/widgets/nexus/nexus_context_strip.dart"], "Filter chips"),
    ("DCX-092", "Comment thread sheet → full screen push", "Comments feel like thread channel", ["lib/widgets/feed/comment_sheet.dart"], "Thread UX"),
    ("DCX-093", "Achievement unlock toast Chat-native", "Bottom toast with badge art, not modal", ["lib/widgets/core/v_feedback.dart"], "Toast notifications"),
    ("DCX-094", "Merge season/league into You progression", "Feed focuses social; progression in profile", ["lib/screens/tabs/nexus_screen.dart"], "Progression relocation"),
    ("DCX-095", "Media grid in posts — edge to edge", "Full-bleed images in feed", ["lib/widgets/feed/media_grid.dart"], "Media feed"),
    ("DCX-096", "Share achievement to channel from feed", "Cross-post achievement to world channel", ["lib/widgets/feed/post_action_bar.dart"], "Cross-post"),
    ("DCX-097", "Mute world from feed card menu", "Notification controls per world", ["lib/widgets/feed/post_item.dart"], "Mute controls"),
    ("DCX-098", "Skeleton loaders match chat list", "Unified shimmer components", ["lib/widgets/core/shimmer.dart"], "Loading parity"),
]
for id_, title, desc, files, ref in feed:
    changes.append(c(id_, 5, "feed", "P1", title, desc, files, ref))

# WAVE 6 — You / identity / profile (12)
profile = [
    ("DCX-099", "You tab: profile card top", "Avatar, display name, status picker, custom status", ["lib/screens/tabs/identity_screen.dart"], "You profile"),
    ("DCX-100", "Friends / allies list section", "Horizontal online friends row", ["lib/screens/connections_screen.dart"], "Friends list"),
    ("DCX-101", "Settings entry from You only", "Gear opens settings; no duplicate in More", ["lib/screens/settings_screen.dart"], "Settings in You"),
    ("DCX-102", "Progression as collapsible section", "XP, tier, achievements — expandable, not wall", ["lib/screens/tabs/identity_screen.dart"], "Progression section"),
    ("DCX-103", "Trophy wall grid denser", "Smaller cells; tap for detail sheet", ["lib/widgets/profile/achievement_trophy_wall.dart"], "Trophy grid"),
    ("DCX-104", "Profile banner optional/minimal", "Reduce hero height; focus avatar + name", ["lib/screens/resident_profile_screen.dart"], "Profile layout"),
    ("DCX-105", "Status: online/idle/dnd/custom", "Presence picker chat-native", ["lib/widgets/profile/status_picker.dart"], "Custom status"),
    ("DCX-106", "Edit profile inline sheet", "Not full-screen form", ["lib/widgets/profile/edit_profile_sheet.dart"], "Edit profile"),
    ("DCX-107", "Tier badge on avatar ring", "Preserve tier gating visually on avatar", ["lib/ui/media/v_avatar.dart"], "Tier ring"),
    ("DCX-108", "Coin balance in You wallet row", "Economy visible but not dominant", ["lib/screens/tabs/identity_screen.dart"], "Wallet row"),
    ("DCX-109", "Featured achievements showcase strip", "Horizontal scroll under profile", ["lib/widgets/profile/profile_achievement_showcase.dart"], "Featured badges"),
    ("DCX-110", "DM user from profile primary action", "Message button prominent", ["lib/screens/resident_profile_screen.dart"], "Message CTA"),
]
for id_, title, desc, files, ref in profile:
    changes.append(c(id_, 6, "profile", "P1", title, desc, files, ref))

# WAVE 7 — Components & polish (14)
comp = [
    ("DCX-111", "VListTile dense variant", "Channel row component: icon, name, badge, mute", ["lib/ui/lists/v_channel_tile.dart"], "Channel row"),
    ("DCX-112", "VAvatar with status dot", "Bottom-right presence indicator", ["lib/ui/media/v_avatar.dart"], "Avatar status"),
    ("DCX-113", "VSearchBar with filter chips", "Search component for global/in-world", ["lib/ui/inputs/v_search_bar.dart"], "Search bar"),
    ("DCX-114", "VContextMenu", "Long-press menus unified", ["lib/ui/overlays/v_context_menu.dart"], "Context menus"),
    ("DCX-115", "VTooltip for icon buttons", "Accessibility labels + tooltips", ["lib/ui/buttons/v_icon_button.dart"], "Tooltips"),
    ("DCX-116", "VEmptyState commune illustrations", "Use new empty state art", ["lib/widgets/core/empty_state.dart"], "Empty states"),
    ("DCX-117", "VSheet → side panel variant", "Resident list as side sheet on tablet", ["lib/ui/overlays/v_sheet.dart"], "Side panels"),
    ("DCX-118", "Remove showModalBottomSheet usages", "Migrate 12 files to VSheet", ["lib/widgets/core/glass_sheet.dart"], "Sheet migration"),
    ("DCX-119", "Haptic on reaction add", "Light impact on emoji select", ["lib/utils/haptics.dart"], "Micro haptics"),
    ("DCX-120", "Page transitions: panel slide not fade", "Chat navigation uses horizontal slide", ["lib/router/v_page_transitions.dart"], "Panel transitions"),
    ("DCX-121", "Voice Campfire full-bleed UI", "Rewrite campfire_screen commune dark", ["lib/screens/campfire_screen.dart"], "Voice UI"),
    ("DCX-122", "Auth screens commune theme", "Login/signup match new dark ladder", ["lib/screens/auth/"], "Auth polish"),
    ("DCX-123", "Onboarding 3-step max", "Gate → pick worlds → done", ["lib/screens/onboarding/"], "Onboarding"),
    ("DCX-124", "Achievement flows use hub sheets not hubs", "Category list as settings-style rows", ["lib/screens/achievements/"], "Achievement IA"),
]
for id_, title, desc, files, ref in comp:
    changes.append(c(id_, 7, "components", "P1", title, desc, files, ref))

# WAVE 8 — Performance & a11y (10)
perf = [
    ("DCX-125", "ListView.builder everywhere in chat", "No shrinkWrap nested scroll in channels", ["lib/screens/world_channel_screen.dart"], "List perf"),
    ("DCX-126", "RepaintBoundary on message bubbles", "Reduce jank on scroll", ["lib/widgets/chat/v_message_bubble.dart"], "Scroll perf"),
    ("DCX-127", "Channel list cache extent", "Prefetch off-screen rows", ["lib/widgets/worlds/world_channel_list.dart"], "List cache"),
    ("DCX-128", "Image cache width discipline", "Consistent cacheWidth in chat images", ["lib/widgets/chat/chat_image.dart"], "Image perf"),
    ("DCX-129", "Reduce rebuild scope in chat providers", "Selective Riverpod watches", ["lib/state/chat_provider.dart"], "State perf"),
    ("DCX-130", "Semantics on all icon-only buttons", "aria labels for screen readers", ["lib/ui/buttons/v_icon_button.dart"], "A11y"),
    ("DCX-131", "44dp min touch targets on rail", "World icons meet touch guidelines", ["lib/ui/navigation/v_world_rail.dart"], "Touch targets"),
    ("DCX-132", "Reduce motion setting", "Respect system reduce motion", ["lib/theme/v_animation.dart"], "Reduce motion"),
    ("DCX-133", "High contrast mode", "Toggle increases text contrast", ["lib/screens/settings_screen.dart"], "High contrast"),
    ("DCX-134", "Focus order in panels", "Keyboard/tab order for panels", ["lib/ui/shell/v_overlapping_panels.dart"], "Focus order"),
]
for id_, title, desc, files, ref in perf:
    changes.append(c(id_, 8, "performance", "P2", title, desc, files, ref))

# Vertiege differentiators (10) — Vertiege differentiators
plus = [
    ("DCX-135", "Tier-gated channels visible but locked", "Show lock + tier requirement on row", ["lib/widgets/worlds/world_channel_list.dart"], "Vertiege tier UX"),
    ("DCX-136", "Achievement reactions in chat", "Share verified badge as rich attachment", ["lib/widgets/chat/"], "Achievement share"),
    ("DCX-137", "World treasury widget in world menu", "RPG economy glance without leaving chat", ["lib/screens/world_treasury_screen.dart"], "Treasury glance"),
    ("DCX-138", "Season progress chip in You tab", "Competitive season without cluttering chat", ["lib/screens/season_screen.dart"], "Season chip"),
    ("DCX-139", "Verifier queue in staff section", "Staff tools grouped; not public nav", ["lib/screens/verification_review_screen.dart"], "Staff tools"),
    ("DCX-140", "AI achievement proof in thread UI", "Proof review inline in achievement submit", ["lib/screens/achievements/submit_achievement.dart"], "Proof flow"),
    ("DCX-141", "Cross-world DM from unified search", "Search residents + messages + worlds", ["lib/screens/search_screen.dart"], "Unified search"),
    ("DCX-142", "Campfire + text channel split view", "Voice while reading text (picture-in-picture bar)", ["lib/screens/campfire_screen.dart"], "Voice+text"),
    ("DCX-143", "Reputation/tier on resident hover card", "Rich member card on tap in list", ["lib/widgets/chat/v_member_card.dart"], "Resident card"),
    ("DCX-144", "World constitution pinned in rules channel", "Governance as first-class rules message", ["lib/widgets/worlds/constitution_editor.dart"], "Rules channel"),
]
for id_, title, desc, files, ref in plus:
    changes.append(c(id_, 9, "differentiator", "P1", title, desc, files, ref))

doc = {
    "schema_version": "1.0.0",
    "project": "Vertiege Commune UX (Commune UX)",
    "created": "2026-06-05",
    "research_sources": [
        "https://discord.com/blog/how-discord-made-android-in-app-navigation-easier",
        "https://support.discord.com/hc/en-us/articles/12654190110999",
        "https://github.com/Khalidabdi1/design-ai/blob/main/design-md/discord/DESIGN.md",
    ],
    "core_features_preserved": [
        "tier_gating",
        "worlds_and_channels",
        "dms_threads_campfire",
        "nexus_feed",
        "achievements_xp",
        "governance_marketplace_jobs",
        "season_league",
        "verifier_staff_tools",
        "cosmetics_economy",
    ],
    "waves": [
        {"id": 1, "name": "IA & navigation", "changes": 24},
        {"id": 2, "name": "Commune theme", "changes": 18},
        {"id": 3, "name": "Chat & messaging", "changes": 26},
        {"id": 4, "name": "World UI", "changes": 18},
        {"id": 5, "name": "Nexus / feed", "changes": 12},
        {"id": 6, "name": "You / identity", "changes": 12},
        {"id": 7, "name": "Components & polish", "changes": 14},
        {"id": 8, "name": "Performance & a11y", "changes": 10},
        {"id": 9, "name": "Vertiege differentiators", "changes": 10},
    ],
    "total_changes": len(changes),
    "changes": changes,
}

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(doc, indent=2) + "\n")
print(f"Wrote {len(changes)} changes to {OUT}")
