# Vertiege Feature Roadmap — Beyond Vision

**Date:** 2026-05-06
**Source:** Swarm audit (gap analysis + Stitch comparison + beyond-vision ideation)
**Status:** Prioritized

## Phase A: Foundation Fixes (Now)

Critical schema and logic gaps before any new features:

| # | Fix | Effort | Impact |
|---|-----|--------|--------|
| A1 | Add missing Supabase columns: `activity_score`, `boost_count`, `last_boost_month`, `constitution` to `worlds` table | Low | Unblocks world leveling, boost, constitution in prod |
| A2 | Create `verification_submissions` table in Supabase | Low | Unblocks verification pipeline |
| A3 | Wire `lastSeenAt` to Supabase (not just local StorageService) | Low | Unblocks council inactivity ejection in prod |
| A4 | Exempt dominion/custom worlds from council governance | Low | Vision compliance |
| A5 | Enable `StoreService.isEnabled` for production | Low | Unblocks IAP payments |
| A6 | Fix `channel_messages` insert — add `world_id` and `sender_name` | Low | Unblocks proper channel message routing |
| A7 | Gate custom world creation behind resident level check | Low | Vision compliance |
| A8 | Add image picker to achievement proof submission | Low | Unblocks real proof uploads |
| A9 | Add auto-verified in-app achievement triggers (post count, streak, etc.) | Medium | Unblocks "1000s of achievements" vision |

## Phase B: Stitch Gap Closure (Next)

Wire existing widgets to screens and fill missing Stitch design elements:

| # | Feature | Effort | 
|---|---------|--------|
| B1 | Wire `GlowBorder` + `SovereignCard` to WorldCard based on world tier | Low |
| B2 | World Showcase bento grid layout with grid/tier toggle | Medium |
| B3 | Tier-differentiated world hero (Apex gold / Elite violet / Hustler orange) | Low |
| B4 | Live chat panel on world detail screen | Medium |
| B5 | Resource vault widget for world detail | Medium |
| B6 | World invite Accept/Decline cards in Nexus feed | Low |
| B7 | Individual achievement badge bento grid | Medium |
| B8 | Locked achievement states with blur overlay | Low |
| B9 | Protocol logs section for error states | Low |
| B10 | Ghost inputs on world settings screen | Low |

## Phase C: Must-Have Features (This Month)

Highest impact, lowest effort — the retention + growth backbone:

| # | Feature | Effort | Why |
|---|---------|--------|-----|
| C1 | **Streak Engine** — daily login/posting/reaction streaks with escalating rewards | Medium | #1 retention mechanic in consumer apps |
| C2 | **Daily Resonance Reward** — randomized daily drop with variable reward | Medium | Pairs with streaks for habit formation |
| C3 | **Realm Mentions & Hashtags** — `@user` tags + `#topic` discovery | Low | Social fabric, cross-world discovery |
| C4 | **Polls & Consensus** — structured polls in posts with animated results | Low | Highest engagement-per-post mechanic |
| C5 | **Luminary Nameplates** — animated name gradients by tier (plain→gold glow) | Medium | Makes prestige VISIBLE in every interaction |
| C6 | **Share Card Engine** — glassmorphism-styled share images with QR codes | Low | Organic growth, already scaffolded |
| C7 | **The Sentinel (AI Moderation)** — pre-publish content classifier | Medium | Safety at scale |
| C8 | **The Vault (Subscription)** — 3-tier: Resident/Patrician/Sovereign Elite | Medium | Recurring revenue |
| C9 | **The Archivist (AI Verification)** — auto-verify achievement proof via AI | High | Scale the achievement pipeline |
| C10 | **The Gate (Onboarding Rite)** — guided 3-min onboarding with world quiz | High | Day 1/7 retention |

## Phase D: Should-Have Features (Next Quarter)

| # | Feature | Effort | Why |
|---|---------|--------|-----|
| D1 | **Sovereign Seasons** — 4-week world-vs-world competitions | High | Recurring engagement waves |
| D2 | **Title Forge** — earnable + purchasable display name titles | Medium | Identity expression + monetization |
| D3 | **World Embassy (Alliances)** — cross-world alliances, shared channels | Medium | Network effects between worlds |
| D4 | **Resident Referral Nexus** — invite codes with rewards + leaderboard | Low | Organic growth loops |
| D5 | **Realm Events** — scheduled AMAs, challenges with RSVP + live chat | Medium | Calendar-anchored returns |
| D6 | **Sovereign Regalia (Cosmetics Shop)** — frames, colors, backgrounds | Medium | Premium cosmetic monetization |
| D7 | **World Boost Marketplace** — paid visibility boosts in Discover | Low | World Sovereign monetization |
| D8 | **The Herald (AI Banners)** — AI-generated world banners/icons | Medium | Visual quality, reduces friction |
| D9 | **FOMO Pulse Notifications** — context-rich push with deep links | Low | Re-engagement |
| D10 | **Hall of Ascension** — multi-dimensional global leaderboards | Medium | Prestige driver |
| D11 | **Sovereign's Court** — council-exclusive perks + cross-world lounge | Low | Governance incentive |
| D12 | **Chronicle Studio** — rich text composer with preview | Medium | Content quality |
| D13 | **Sovereign Decrees** — gold-bordered world announcements | Low | Sovereign tools |
| D14 | **World Legacy System** — age + prestige based legacy tiers | Medium | World permanence |
| D15 | **Trending & Rising Worlds** — velocity-based discovery | Low | Fair discovery |
| D16 | **Glass Caching** — instant resume from cache | Medium | Premium feel |
| D17 | **Haptic Identity** — curated haptic feedback map | Low | Tactile excellence |

## Phase E: Could-Have (Future)

| # | Feature | Effort |
|---|---------|--------|
| E1 | Council Tournament Mode — bracket-style world competitions | High |
| E2 | Tribute System — P2P micro-tipping (70/30 split) | Medium |
| E3 | The Chronicler — AI-personalized Nexus feed | High |
| E4 | Flash Events — random 24-hour challenges | Low |
| E5 | Post Analytics Dashboard — views, reactions, reach | Medium |
| E6 | World Rituals — recurring auto-posted threads | Low |
| E7 | Realm Connect — offline-first mode with sync queue | High |

## Total: 51 features across 5 phases

- **Phase A:** 9 fixes (now)
- **Phase B:** 10 Stitch gaps (next)
- **Phase C:** 10 must-haves (this month)
- **Phase D:** 17 should-haves (next quarter)
- **Phase E:** 7 could-haves (future)
