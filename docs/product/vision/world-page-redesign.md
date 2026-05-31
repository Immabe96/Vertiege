# World page redesign — product spec

**Status:** In progress (Release 1 shipped in app; Releases 2–5 phased)  
**Last updated:** 2026-05-25  
**Owners:** Product + mobile

## Problem

World detail feels like an admin console (Manage + long About) instead of a **Facebook Group / Page** visitors understand in seconds. Dominion types (Academy, Archive) multiply confusion without matching how users create worlds.

## Goals

1. **First-time clarity** — Public/Private, what this world is, who runs it, why join.
2. **Daily use** — Feed + Channels for members; Home for visitors.
3. **Low breakage** — Reorganize navigation before deleting data or enum values.

## Locked decisions (14-question interview)

| Topic | Decision |
|-------|----------|
| Positioning | Achievements/proof-led, mixed audience |
| Preset worlds | Keep **Wealth** + **Profession** presets |
| User-created worlds | **Sanctuary** + **Marketplace** only (create UI) |
| Academy | Concept merges into **Sanctuary** (legacy rows until Release 5) |
| Archive type | Drop as dominion type; **Vault** stays optional feature |
| Feed vs Channels | **Separate tabs** |
| Manage tab | **Remove** → **Shop** (marketplace only) + **··· tools drawer** |
| Layout | Same shell; **tab visibility + copy** differ by world kind |
| Social model | Hybrid **Group discussion** + **pinned admin announcements** |
| Visibility v1 | **Public / Private** on Home + join (from `constitution.admission`) |
| Onboarding order | Profile → join world → Nexus → achievements |
| App home | **Nexus first**; after join, prompt default world Feed (Release 3) |
| Feature visibility | **Reorganize only** — do not hide Alliances/Vault/Jobs/Polls |
| Ship order | IA → Home polish → onboarding → create 2 types → delete legacy DB |

## Plain language glossary (UI)

| Internal | User-facing |
|----------|-------------|
| Sovereign | Admin |
| Dominion (user-created) | Community / Shop world |
| Residents | Members |
| Rep / standing | Reputation |
| Prestige | World level |
| Decree | Announcement |

Implementation: `lib/config/world_page_ia.dart`.

## Information architecture (Release 1)

### Tabs (dynamic)

| Tab | Always | Notes |
|-----|--------|-------|
| **Home** | Yes | Visitor landing; visibility, admin line, join CTA, announcements preview |
| **Feed** | Yes | Member default; world-scoped posts |
| **Channels** | Yes | Chat channels |
| **Members** | Yes | Was “People” |
| **Shop** | Marketplace dominions only | Treasury + marketplace entry |

**Removed:** Manage, About (as primary tab).

### Default tab

- **Visitor** → Home  
- **Member** → Feed  
- **Deep link `?post=`** → Feed  

### Tools drawer (end)

Opened from hero **···** — polls, jobs, archive, treasury/marketplace (non-Shop worlds), settings (admins), share. **Realm guide** opens full `WorldRealmDossier` in a sheet (legacy depth, not lost).

### Shop tab

Only when `world.isMarketplace`. Wealth/Profession economy links live in the tools drawer.

## Releases

### Release 1 — IA & navigation ✅

- Dynamic tabs + defaults  
- `WorldHomeTab`, `WorldShopTab`, `WorldToolsDrawer`  
- Spec + `WorldPageIa` helpers  

### Release 2 — Home content ✅

- “About this group” card (members, visibility, admin line)  
- Prominent admin announcement card  
- Recent discussion previews; full dossier in sheet/drawer only  

### Release 3 — Onboarding ✅ (partial)

- Post-join Feed vs Home dialog + Settings toggle (`WorldNavPrefs`)  
- Explore intro copy (achievement / proof first)  
- Nexus default tab unchanged (app shell)  
- First-session checklist on Identity (`FirstStepsCard`)  
- Onboarding welcome step: Nexus / world / proof CTAs  

### Release 4 — Create world

- `DominionTypePicker` → Sanctuary + Marketplace only  
- Read-compat for academy/archive in app until Release 5  

### Release 5 — Data cleanup ✅ (migration ready)

- `20260526200000_retire_academy_archive_dominions.sql` — DELETE academy/archive worlds, scrub `joined_world_ids`, RPC guard  
- Client: create-world validation; legacy `academy`/`archive` parse as sanctuary  
- Apply on remote: `supabase db push` or `db query -f` (review row counts first)  

## Files

| Area | Path |
|------|------|
| IA helpers | `lib/config/world_page_ia.dart` |
| Screen | `lib/screens/world_detail_screen.dart` |
| Home | `lib/widgets/worlds/world_home_tab.dart` |
| Shop | `lib/widgets/worlds/world_shop_tab.dart` |
| Drawer | `lib/widgets/worlds/world_tools_drawer.dart` |
| Legacy depth | `lib/widgets/worlds/world_realm_dossier.dart` |

## Verification

- [ ] Visitor opens world → lands on **Home**  
- [ ] Member opens world → lands on **Feed**  
- [ ] Marketplace dominion shows **Shop**; Wealth world does not  
- [ ] **···** opens tools; realm guide sheet still shows dossier  
- [ ] `?post=id` opens **Feed** with highlight  
- [ ] `flutter test test/config/world_page_ia_test.dart`
