# World detail scroll contract

Prevents **grey void** regressions on Channels / Members tabs (Wave 6 UAT).

## Rule: one vertical scroll owner per tab body

| Region | Scroll owner | Notes |
|--------|--------------|--------|
| World home | `NestedScrollView` on [world_detail_screen.dart](../../lib/screens/world_detail_screen.dart) | Header slivers + pinned tab bar |
| Feed tab | Inner list inside tab — **no** nested `RefreshIndicator` on child | Pull-to-refresh on outer `NestedScrollView` only |
| Channels tab | Single `ListView` / column of channel rows | No `Expanded` + inner `ListView` without bounded height |
| Members tab | Single scrollable list | Do not wrap in `VLoadingCard` that steals flex |
| Manage / governance | `VHubPage` body = one `ListView` | Standard hub pattern |

## Do not

- Put `ListView` inside `Column` without `Expanded` or fixed height.
- Add a second `RefreshIndicator` on tab content when the parent already refreshes.
- Use shimmer `VLoadingCard` as the **only** child of a tab (shows empty grey).

## Smoke after changes

1. Open a joined world → Channels → scroll full list.  
2. Members tab → scroll; tap a resident.  
3. Rotate device / large text → tabs still scroll.

See also: [deep-link-matrix.md](../operations/deep-link-matrix.md), [quiet-ux-principles.md](quiet-ux-principles.md).
