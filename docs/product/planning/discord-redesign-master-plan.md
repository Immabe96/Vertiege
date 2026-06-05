# Vertiege Commune UX — Master Plan

**Status:** Wave 1 in progress  
**Branch:** `feature/discord-ux-redesign` · [PR #33](https://github.com/Immabe96/Vertiege/pull/33)  
**Goal:** Borrow **chat-native navigation and density** from modern community apps — without renaming Vertiege or diluting what makes it unique.

---

## Vertiege lexicon (non-negotiable)

| Always say | Never substitute |
|------------|------------------|
| **World** | server |
| **Resident** | member, user (in product copy) |
| **Achievement** / verified milestone | generic badge only |
| **Tier** / ascension | rank (unless league context) |
| **Nexus** | generic feed |
| **Campfire** | voice channel (user-facing) |
| **World channel** | #server-channel |

**Product thesis:** Vertiege is not a Discord clone. It is a **tier-gated social world** with proof-based achievements, governance, economy, and seasons — delivered through a **fast, chat-first shell** people already know how to use.

Research references (Discord mobile blogs, dark UI patterns) inform **layout and motion only**, not vocabulary or feature priority.

---

## What we borrow vs what we keep

| Borrow (UX patterns) | Keep (Vertiege identity) |
|----------------------|---------------------------|
| Unified Home: worlds + DMs in one place | Worlds, not “servers” |
| Overlapping panels: world rail → channels → chat | Tier-locked channels visible |
| Bottom nav hides in active channel/DM | Achievements prominent in Home + You |
| Dark surface ladder, dense lists | Gold/violet prestige accents on milestones |
| Swipe-to-reply, grouped messages | Proof submit, verifier, trophy wall |
| Tap channel name for details | Governance, treasury, academy (world tools) |

**Tagline:** *Discord-fast. Vertiege-true.*

---

## Research summary (layout only)

| Principle | Application in Vertiege terms |
|-----------|-------------------------------|
| One primary bottom nav + panels | Home shows **world rail** + **channels** + content |
| Nav hides in immersive chat | Hide bar in world channel, DM, Campfire |
| Home → channels → chat hierarchy | `VOverlappingPanels` |
| Dark elevation ladder | `VCommuneColors` |
| Accent on interactive only | `VColors.brand` for tier/achievement moments |

Sources: [Discord Android panels blog](https://discord.com/blog/how-discord-made-android-in-app-navigation-easier), [mobile layout support](https://support.discord.com/hc/en-us/articles/12654190110999) — cited for IA, not branding.

---

## Deliverables

| Artifact | Path |
|----------|------|
| **144 change database** | [discord-redesign-changes.json](discord-redesign-changes.json) |
| **50-asset manifest** | [discord-redesign-asset-manifest.json](../../assets/discord-redesign-asset-manifest.json) |
| **Wave tracker** | [discord-redesign-wave-status.md](discord-redesign-wave-status.md) |
| **Design spec** | [DESIGN.md](../../reference/DESIGN.md) |
| **Agent skill** | [.cursor/skills/vertiege-discord-ux/SKILL.md](../../../.cursor/skills/vertiege-discord-ux/SKILL.md) |

---

## Wave roadmap

| Wave | Focus | Exit criteria |
|------|-------|---------------|
| **0** | Planning, tokens, lexicon | DB + `VCommuneColors` + lexicon doc |
| **1** | IA & navigation | 3-tab shell + `VWorldRail` + Home |
| **2** | Commune theme | Chat surfaces use surface ladder |
| **3** | Chat rewrite | Shared `VMessageBubble` |
| **4** | World UI | Channels-first world home |
| **5** | Nexus / feed | Flatter feed inside Home |
| **6** | You / profile | Resident profile + progression |
| **7–9** | Components, perf, differentiators | Tier locks, achievement share, treasury glance |

---

## Success metrics

- **3 taps** to send a message in a world channel from cold start.
- User says: *“This is as fast as Discord — but I still feel my tier and achievements.”*
- Zero user-facing copy uses “server” or “member” for worlds/residents.
