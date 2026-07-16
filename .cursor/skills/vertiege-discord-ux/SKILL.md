---
name: vertiege-discord-ux
description: >-
  Vertiege Commune UX — 4-tab shell (Nexus · Worlds · Chat · You) with Vertiege
  lexicon. Use for DCX-* / IA changes. Borrow layout patterns only; never
  Discord product naming.
---

# Vertiege Commune UX

## Four-tab product thesis (authoritative)

| Tab | Job | Vertiege rule |
|-----|-----|----------------|
| **Nexus** | Public standing feed — verified wins, announcements | Proof moments. FAB compose. |
| **Worlds** | Discover, join, open realm home | Worlds are first-class — not buried under Chat. |
| **Chat** | Worlds channels, DMs, Campfire | Density + belonging after you join. |
| **You** | Passport tick, honour wall, tier; Achievements + Progress hubs | Identity ≠ achievement proof. |

**One line:** Nexus shows standing. Worlds is where you belong. Chat is how you talk. You proves who you are and what you've earned.

### Live shell (code truth)

- **Tabs:** Nexus `/` · Worlds `/worlds` · Chat `/chat` · You `/identity`
- **Hubs (push):** Achievements `/achievements`, Progress `/progress`, world detail `/explore/:id`
- **Legacy redirects:** `/you` → `/identity`, `/more` → `/identity`, bare `/explore` → `/worlds`
- **Activation path:** Join world → Open Chat → Submit proof

## Lexicon (mandatory in all UI copy, docs, comments)

| Use | Do not use |
|-----|------------|
| World | server |
| Resident | member (except world “members” list) |
| Achievement / verified | generic “badge” alone |
| World channel | server channel |
| Nexus | “feed” alone in nav labels |
| Campfire | voice channel (user-facing) |
| Tier / XP / Streak | lead with prestige/ascension/league in v1 copy |

Achievements, tiers, and worlds are **first-class** — economy modules stay flag-gated in closed beta.

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
