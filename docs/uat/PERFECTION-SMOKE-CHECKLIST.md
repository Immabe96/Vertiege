# Perfection pass — quick device smoke (Waves 0–5)

**Build:** `flutter build apk --release` from `develop`  
**Install:** `adb install -r build/app/outputs/flutter-apk/app-release.apk`  
**Record:** device, OS, commit SHA, date, tester

## Core tabs

- [ ] **Nexus:** Feed loads or shows error/retry (not blank gray); partial sync shows yellow banner when posts exist
- [ ] **Nexus:** Comment sheet — send button not hidden under compose FAB
- [ ] **Discover:** Worlds load; yellow banner if sync failed with cache
- [ ] **Identity:** Profile loads; achievement sync warning if applicable; Wall of Honour scrolls without giant gray box
- [ ] **Chat:** DM list error + retry; world channels error + retry; open DM and channel

## World detail

- [ ] **Channels / Members:** No grey void below lists; Residents has no grey loading card (see [UAT-ISSUE-LOG.md](./UAT-ISSUE-LOG.md) #2)
- [ ] **Back:** Returns to Explore (not blank Nexus)
- [ ] **Tools (⋯):** Opens bottom sheet; treasury/marketplace links work; close dismisses
- [ ] **Join / tabs / feed:** Hero, stats, tab bar scroll correctly
- [ ] **Sync warning:** If shown, retry refreshes world list

## Hub screens (Forui shell)

- [ ] **Search:** Forui header with inline search; back works
- [ ] **Create post:** Close + PUBLISH in header; publish returns to feed
- [ ] **League / Challenges / Daily quests:** Load or error state with retry
- [ ] **Thread:** Back to channel; replies load or error + retry
- [ ] **World channel:** Back to world (not blank); messages load
- [ ] **Campfire / voice (Wave 7):** World tools → Lounge / Campfire; channel list shows `# lounge` + Campfire icon; voice opens Campfire (not text screen); locked resident sees gate reason; mini-bar while connected; back leaves room

## Security (spot)

- [ ] Signed-out: cannot hit privileged flows without login
- [ ] Rep milestone / XP: only affects signed-in user (no cross-user XP via tampered RPC)

## Sign-off

| Result | Notes |
|--------|-------|
| Pass / Fail | |
