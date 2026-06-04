# Quiet UX principles

Vertiege quality work should **not** add visible chrome by default. Use these rules when shipping features from the roadmap and perfection backlog.

## Do

- **One home per job** — e.g. world economy and social features live under **Manage & participate**; the world tools sheet stays a short overflow menu.
- **Progressive disclosure** — collapsed Nexus shortcuts, expansion for council post options, expansion for council queue details.
- **One-line gate reasons** — show on the row (`detail` on `VSectionTile`), not a permanent banner.
- **Toasts for outcomes** — success/error after an action; avoid SnackBars and duplicate banners on the same screen.
- **Low-pressure mode** — Settings → Progression (leaderboard opt-out); no nag screens.

## Don’t

- Duplicate the same link on Nexus, Identity, and More.
- Show lock copy **and** a yellow banner **and** a toast for the same gate.
- Add onboarding tooltips on every screen; teach once in Gate or empty states.
- Surface raw IDs, Postgrest codes, or JSON in council or error UI.

## Patterns

| Pattern | Widget / API |
|--------|----------------|
| Locked row | `QuietGateTile.section(gate: reason, onOpen: …)` |
| World overflow | `WorldToolsPanel` → **Manage & participate** |
| Global people search | `ResidentSearchService` + local world members |
| Council review | `ExpansionTile` — title + one line; actions inside |

## Wave 12 batches

**Forui:** create world (`FTextFormField`, collapsed channels), shop (`FCard` + `FButton`), settings (`VThemeSchemePicker`).

**Deep links & voice & season:**

- Post/notification targets: `PostNotifier.ensurePostVisible` + feed scroll highlight
- Campfire: `CampfireMiniBar` (connecting / connected / mute / leave) — no extra screens
- Season: collapsed “How this season works”; low-pressure note only when opted in

See also: [wave-status.md](../product/planning/wave-status.md), [perfection-backlog.md](../product/planning/perfection-backlog.md).
