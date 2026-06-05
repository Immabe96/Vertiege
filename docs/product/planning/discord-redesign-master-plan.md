# Vertiege Commune UX — Discord++ Master Plan

**Status:** Wave 0 — planning & foundations  
**Branch:** `feature/discord-ux-redesign`  
**Goal:** Make Vertiege feel as fast, dense, and chat-native as Discord — while keeping tier gating, worlds, achievements, governance, and economy as **differentiators**.

---

## Research summary (2024–2025 Discord mobile)

| Principle | Source | Vertiege application |
|-----------|--------|----------------------|
| **One primary nav** — bottom tabs only; no drawer + tabs together | [Discord Android nav blog](https://discord.com/blog/how-discord-made-android-in-app-navigation-easier) | Replace 5-tab + nested drawers with **3 tabs** + **overlapping panels** inside Home |
| **Home = servers + DMs unified** | [Mobile layout support](https://support.discord.com/hc/en-us/articles/12654190110999) | Merge Explore chat modes + world rail into **Home** |
| **Navbar hides in active chat** | [App Fuel teardown](https://theappfuel.com/examples/discord_navigation) | Collapse bottom nav in channel/DM routes |
| **Home → Channels → Chat hierarchy** | Android panels post | `VOverlappingPanels`: rail \| channels \| content |
| **Tap channel name for details** | Mobile layout update | Sheet: members, pins, media, threads |
| **Swipe to reply** | Discord mobile feedback | Gesture on `VMessageBubble` |
| **Dark surface ladder** | [Discord DESIGN.md](https://github.com/Khalidabdi1/design-ai/blob/main/design-md/discord/DESIGN.md) | `VCommuneColors` tokens (#313338 → #1e1f22) |
| **Accent only on interactive** | Refero / DESIGN.md | Gold/violet = mentions, CTAs, tier — not chat backgrounds |
| **List performance** | [Supercharging mobile](https://discord.com/blog/supercharging-discord-mobile-our-journey-to-a-faster-app) | `ListView.builder`, repaint boundaries, no nested shrinkWrap |

---

## Vertiege → Discord mental model

| Vertiege today | Commune target | Core feature preserved |
|----------------|----------------|------------------------|
| Worlds | Servers | ✅ Tier-gated communities |
| Text channels | Text channels | ✅ `#channel` routes |
| Campfire | Voice channels | ✅ LiveKit voice |
| DMs | DMs | ✅ `/chat/:roomId` |
| Threads | Threads | ✅ `ThreadScreen` |
| Nexus feed | Home activity strip | ✅ Social feed, not removed |
| Explore tab | Home discover panel | ✅ World discovery |
| Identity tab | **You** tab | ✅ Profile, XP, achievements |
| More tab | Folded into You | ✅ All links retained |
| Achievements | You → progression + chat share | ✅ Proof, verifier, badges |
| Governance / treasury / jobs | Server ⋮ menu | ✅ RPG admin, demoted not deleted |
| Season / league | You → competitive | ✅ Rankings |
| Verifier tools | You → staff (gated) | ✅ Staff review |

**Tagline:** *Discord's speed and clarity. Vertiege's progression and stakes.*

---

## Deliverables

| Artifact | Path |
|----------|------|
| **144 change database** | [discord-redesign-changes.json](discord-redesign-changes.json) |
| **50-asset manifest** | [discord-redesign-asset-manifest.json](../../assets/discord-redesign-asset-manifest.json) |
| **Wave tracker** | [discord-redesign-wave-status.md](discord-redesign-wave-status.md) |
| **Design spec** | [DESIGN.md](../../reference/DESIGN.md) (Commune section) |
| **Agent skill** | [.cursor/skills/vertiege-discord-ux/SKILL.md](../../../.cursor/skills/vertiege-discord-ux/SKILL.md) |
| **Generator** | `scripts/generate_discord_redesign_db.py` |
| **Asset validator** | `scripts/validate_discord_redesign_assets.sh` |

Regenerate changes DB after edits:

```bash
python3 scripts/generate_discord_redesign_db.py
```

---

## Wave roadmap

| Wave | Focus | Changes | Exit criteria |
|------|-------|---------|---------------|
| **0** | Planning, tokens, skill, branch | — | DB + manifest + `VCommuneColors` landed |
| **1** | IA & navigation | DCX-001–024 | 3-tab shell + panels prototype on emulator |
| **2** | Commune theme | DCX-025–042 | Chat + lists use surface ladder |
| **3** | Chat rewrite | DCX-043–068 | Single `VMessageBubble`; DM + channel parity |
| **4** | World / server UI | DCX-069–086 | Channels-first world home |
| **5** | Nexus / feed | DCX-087–098 | Flatter feed inside Home |
| **6** | You / identity | DCX-099–110 | More tab removed; settings unified |
| **7** | Components | DCX-111–124 | New `VChannelTile`, sheets, auth |
| **8** | Perf & a11y | DCX-125–134 | 60fps scroll on $50 Android target |
| **9** | Differentiators | DCX-135–144 | Tier locks, achievement share, treasury glance |

---

## Architecture decisions

1. **Keep `go_router` URLs** — panel state is UI-layer; deep links unchanged.
2. **Keep Forui behind `lib/ui/*`** — Commune theme maps through `VertiegeForuiTheme`.
3. **Rewrite screens freely** — `chat_room_screen.dart`, `world_channel_screen.dart`, `tab_layout.dart` are first rewrite targets.
4. **No feature deletion** — demote to menus/sheets, don't remove routes.
5. **Asset pipeline** — manifest IDs (`DRA-xxx`) tracked like achievement badges.

---

## Agent workflow

1. Read **vertiege-discord-ux** skill + change ID from JSON.
2. Implement change; update `"status": "done"` in JSON (or wave-status.md).
3. Run `flutter test` + emulator smoke on Home → world → channel → DM.
4. Mark assets `generated` in manifest when added.

---

## Success metrics

- Time to first message in a world channel **< 3 taps** from cold start.
- Bottom nav visible **only** at Home root and You/Notifications roots.
- Chat scroll **no blank frames** on emulator API 30.
- User test: *"This feels like Discord but I still see my tier/achievements."*
