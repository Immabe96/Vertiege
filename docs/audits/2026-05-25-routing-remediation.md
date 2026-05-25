# Routing remediation (2026-05-25)

## Summary

Centralized in-app path construction and fixed high-severity routing bugs found in the routing audit. All targeted router tests pass (151 total suite at time of commit).

## Changes

### Central modules

- `lib/router/world_navigation.dart` — encoded explore/world/channel/resident/DM/campfire/audit paths
- `lib/router/notification_navigation.dart` — `routeForNotification()`, `notificationDeepLinkPath()`
- `docs/vision/world-channel-routing.md` — reserved sub-routes vs channel names

### P0 fixes

| Issue | Fix |
|-------|-----|
| `/resident/:id` in dossier | `residentProfilePath()` |
| `/league` in Nexus shortcuts | `leaguesPath()` → `/leagues` |

### Router

- `WorldArchiveScreen` at `/explore/:worldId/archive`
- `archive` added to `kReservedWorldSubRoutes`
- Notification deep links fall back to `/notifications` when payload is incomplete
- FCM `routeFromRemoteMessage()` uses navigation helpers

### UI migration

Widgets and screens now call `world_navigation` helpers instead of string interpolation (explore, members, polls, treasury, marketplace, jobs, channels, profiles, DMs, campfire).

### Archive entry points

- World dossier Quick links (joined members)
- World detail Manage tab
- World settings

### Tests

- `test/router/notification_navigation_test.dart` (new)
- `test/widgets/world_channel_shortcuts_test.dart` — import from router
- `test/widgets/world_feed_chat_teaser_test.dart` — import from router
- `test/router/world_route_redirects_test.dart` — covers `archive` reserved segment

## Intentionally unchanged

- Shell routes `context.push/go('/explore')` for Explore tab root (not a world id)
- GoRouter route declarations in `app_router.dart` (path patterns, not builders)

## Follow-up (optional)

- Literal-path guard script in CI
- Re-run Understand-Anything `/understand lib` after merge for graph refresh
