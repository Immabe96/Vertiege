# World realm dossier (G4)

**Screen:** `WorldDetailScreen` → **About** tab  
**Widget:** `lib/widgets/worlds/world_realm_dossier.dart`

## Purpose

Single Forui-forward “about this realm” experience: charter, standing, economy gates, knowledge link, live news, governance honesty.

## IA

| Tab | Role |
|-----|------|
| Feed | Social default for **joined** members |
| Channels | Room list |
| People | Roster |
| Manage | Economy actions (member-focused) |
| **About** | Realm dossier (default for **visitors**) |

Deep link `?post=` → **Feed** tab with highlight.

## Visitor vs member

| Block | Visitor | Member |
|-------|---------|--------|
| Charter | Teaser + “Join to read full charter” | Full premise, focus, culture |
| Standing | Ladder only | Ladder + your rep |
| Economy | Locked tiles + reasons | Unlocked per `WorldCapabilityMatrix` |
| News | Read previews | Same |
| Governance | Coming soon alert | + settings if council/sovereign |

## Type emphasis

- **Dominion** — `WorldGrowthCard` lead  
- **Wealth** — tier gate + prestige + sovereign  
- **Profession** — profession gate + sovereign  

## Feature flags

Economy tiles follow **Manage** tab: hidden when `FeatureFlags.marketplace` / `treasury` / etc. are off.

## Analytics

| Event | When |
|-------|------|
| `world_dossier_viewed` | About tab first paint |
| `world_dossier_charter_cta` | Join for full charter |
| `world_dossier_economy_tile` | Economy tile tap |
| `world_dossier_knowledge_link` | #info link |
| `world_dossier_governance_tap` | Settings from governance |
| `world_dossier_news_open` | News post tap |

## PR 2 (shipped)

- **Get started** — numbered orientation steps → `#info`, `#rules`, `#roles`, `#general`  
- **Leadership** — sovereign + council (5000+ rep) preview → resident profile / full roster  
- Removed unused `WorldInfoSheet` / `WorldInfoCards`  
- Analytics: `world_dossier_orientation_step`, `world_dossier_council_tap`  
