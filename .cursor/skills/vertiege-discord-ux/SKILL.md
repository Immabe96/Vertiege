---
name: vertiege-discord-ux
description: >-
  Vertiege Commune UX — 3-tab shell with Vertiege lexicon (worlds, residents,
  achievements). Use for DCX-* changes. Borrow layout patterns only; never
  Discord product naming.
---

# Vertiege Commune UX

## Three-tab product thesis (authoritative)

| Tab | Analog | Job | Vertiege rule |
|-----|--------|-----|----------------|
| **Nexus** | LinkedIn | Public standing feed — verified wins, progression, announcements | Proof moments, not hot takes. FAB compose for milestone posts. |
| **Chat** | Discord | Fast comms — worlds, channels, DMs, Campfire | Borrow Discord density; tier locks + constitution stay visible. |
| **Identity** | *Only Vertiege* | **Passport / national ID → verified tick.** Honour wall, tier truth. | **Verify identity above the fold.** Achievement proof is separate (`/achievements/submit`). |

**One line:** LinkedIn shows what you claim. Chat lets you talk. **Identity proves you are a real resident** (government ID tick) — achievements prove what you've done.

### Live shell (code truth)

- **Tabs:** Nexus `/` · Chat `/chat` · Identity `/identity`
- **Hidden branch 3:** `/explore` + world/channel routes (no tab; highlights Chat)
- **Legacy redirects:** `/you` → `/identity`, `/more` → `/identity`
- **`CommuneHomeScreen` / `commune_home_provider`:** deleted — NOT routed; do not restore unless DCX reopened

## Lexicon (mandatory in all UI copy, docs, comments)

| Use | Do not use |
|-----|------------|
| World | server |
| Resident | member |
| Achievement / verified | generic “badge” alone |
| World channel | server channel |
| Nexus | “feed” alone in nav labels |
| Campfire | voice channel (user-facing) |

Achievements, tiers, governance, and economy are **first-class** — not demoted behind chat.

## When to use

- Redesigning navigation, chat, worlds, theme
- Implementing `DCX-xxx` from [discord-redesign-changes.json](../../../docs/archive/planning/discord-redesign-changes.json) (archived)
- Active engineering work: [PLAN.md](../../../PLAN.md) (SOC-* waves)
- Reviewing UI against [DESIGN.md](../../../docs/reference/DESIGN.md)
- Any feature that touches proof, standing, or world governance

## Read first

1. [gamification-and-worlds.md](../../../docs/product/vision/gamification-and-worlds.md) — north star
2. [PLAN.md](../../../PLAN.md) — active social stack plan
3. [discord-redesign-master-plan.md](../../../docs/archive/planning/discord-redesign-master-plan.md) — archived DCX context
3. [vertiege-forui-ui](../vertiege-forui-ui/SKILL.md)

## Non-negotiables

- **Vertiege features stay:** tier gating, worlds, channels, DMs, threads, Campfire, Nexus, achievements, governance, economy, season/league, verifier tools.
- **Borrow patterns, not vocabulary:** panels, hidden nav, dark ladder — not “servers” or “members”.
- **Two proof types:** (1) **Identity** = passport/ID → tick on Identity tab. (2) **Achievement** = catalog evidence → XP/honour wall. Never merge copy or CTAs.
- **Achievement loop:** verify achievement → toast with **Share to Nexus** → optional channel cross-post.
- **Primary nav:** 3 tabs — Nexus · Chat · Identity (never restore 5-tab or unrouted Commune Home rail without explicit approval).
- **Hide bottom nav** in world channel, DM, Campfire.
- **Forui** for tab chrome and sheets (`VTabPage`, `showVSheet`, `VButton`).
- **URLs stable** unless explicitly approved.

## Key files

| Area | Path |
|------|------|
| Nexus tab | `lib/screens/tabs/nexus_screen.dart` |
| Nexus moment sheet | `lib/widgets/nexus/nexus_moment_sheet.dart` |
| Chat tab | `lib/screens/tabs/chat_list_screen.dart` |
| Identity tab | `lib/screens/tabs/you_screen.dart` |
| Identity verification | `lib/widgets/identity/identity_verification_card.dart` |
| Achievement proof | `lib/screens/achievements/submit_achievement.dart` |
| Tab shell | `lib/screens/tabs/tab_layout.dart` |
| Channel chat | `lib/screens/world_channel_screen.dart` |
| Proof submit | `lib/screens/achievements/submit_achievement.dart` |
| Theme | `lib/theme/v_commune_colors.dart` |

## Smoke test

1. Identity → **Verify with passport or ID** (government ID, not achievements)
2. Achievements hub → submit **achievement proof** (separate flow)
3. After achievement verify → toast **Nexus** action → post moment on feed
3. Chat → world → channel → message (≤3 taps)
4. Tier-locked channel shows lock + tier requirement
5. Bottom nav hidden in channel; returns on back

## Better-than-Discord checklist (PR gate)

Every UX PR should strengthen at least one:

- [ ] Proof submit or queue visibility (Identity)
- [ ] Verified moment on Nexus feed
- [ ] Standing/tier visible in chat or worlds
- [ ] Achievement-native social (badge reactions, attachments, cross-post)

Do **not** add Discord-parity features (bots, embeds) before the proof loop is obvious in all three tabs.
