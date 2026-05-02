# Vertiege — TODO

## Already Done
- [x] FadeIn widget (fade + slide-up, configurable delay/duration)
- [x] Staggered list animations — PostItem, WorldCard, AchievementCard
- [x] Hero: world icon (WorldCard → WorldDetailScreen)
- [x] Pull-to-refresh on all list screens
- [x] Swipe-to-dismiss on alerts
- [x] Haptic feedback on tab switches
- [x] Empty states for all screens
- [x] World creation flow
- [x] Chat provider + real-time + DM
- [x] Channel view + routing + messaging
- [x] Discovery, Invites, and World Settings
- [x] AchievementCard index + FadeIn + AchievementGrid refactor

## Animation & Polish (current)
- [ ] FadeIn entry animations on all screen content
  - [ ] NexusScreen — greeting header, PostInput
  - [ ] ExploreScreen — search bar, filter chips, empty states
  - [ ] IdentityScreen — avatar, name, badges, tiles
  - [ ] AlertsScreen — list tiles
  - [ ] ChatListScreen — room tiles
  - [ ] ResidentProfileScreen — avatar, name, bio, badges
  - [ ] SettingsScreen — list tiles
  - [ ] WorldDetailScreen — description, channels, residents
- [ ] Hero: avatar → profile (PostItem, IdentityScreen, ResidentProfileScreen)
- [ ] Run flutter analyze and fix all warnings
- [ ] Commit animation and polish

## Future
- [ ] Channels/rooms — topic-based sub-spaces
- [ ] Roles & permissions — Visitor→Council gates actions
- [ ] Member directory — see all residents
- [ ] Announcements — sovereign/admin broadcast posts
- [ ] Invite system — residents invite others (Patron+)
- [ ] Moderation tools — remove posts, mute, ban
- [ ] World events — scheduled happenings
- [ ] ParallaxScroll — wire up the existing unused widget
- [ ] AnimatedList for real-time post insertions
