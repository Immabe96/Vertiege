# Vertiege → React Native rebuild (from scratch)

**Decision:** 2026-09-18 — rebuild the Vertiege client **from scratch** in **React Native + Expo + TypeScript**.
**Scope:** everything is new — code, architecture, and **visual design**. No Flutter code, no Renewal theme carryover. The only things taken from the Flutter app are **keys and logins** (§3) and the **backend contract** (§4).
**Design note:** `DESIGN.md`, the prototypes, and the IA spec in `docs/design/s12-renewal/` are exploration history only — the new app's visuals are decided as it is built.

## 1. Strategy

- Fresh folder `app/` with a brand-new Expo project (scaffolded: `rn-new --nativewindui`, i.e. Expo Router + NativeWind + NativeWindUI + Reanimated on Expo SDK 56 / RN 0.85).
- The Flutter app keeps shipping the closed beta (Play + TestFlight) until the new app passes review on both stores; then it is archived as `legacy-flutter/`.
- Supabase/Firebase are the only shared runtime; backend tables, RLS, storage buckets, and edge functions are reused as-is.

## 2. Repo layout

```
Vertiege/
  lib/…                       # Flutter app — untouched until cutover (shipping beta)
  app/                        # NEW: fresh Expo app (Expo Router)
  supabase/                   # backend source of truth (migrations, functions) — unchanged
  docs/design/s12-renewal/    # design exploration history (not applied)
```

## 3. Stack (user choices + "Choosing the Right React Native Stack in 2026", Simon Grimm)

| Concern | Choice | Notes |
|---------|--------|-------|
| Framework | Expo SDK 56 + TypeScript + Expo Router | scaffolded; typed routes on |
| Styling | **NativeWind v4 + NativeWindUI** (user choice) | video suggests UniWind as the Tailwind option — user's call stands |
| Animation/gesture | Reanimated 4 + Gesture Handler (worklets plugin) | must-have per video; installed |
| Client state | Zustand | persists via MMKV |
| Server state | TanStack Query | HTTP + cache layer over supabase-js |
| Local data | expo-sqlite + Drizzle (schema in TS, Drizzle Studio) | offline cache/read-heavy data |
| Key-value | MMKV (not AsyncStorage) | needs dev-client (already installed) — never Expo Go |
| Forms | React Hook Form + Zod | typed, validated forms |
| Lists | FlashList | installed |
| Backend | Supabase (Postgres + Auth + Realtime + Storage + Edge Functions) | existing project reused |
| Auth | **Supabase Auth** (deviation from video's Clerk) | backend contract: RLS uses `auth.uid()`; keeps existing logins + `vertiege://auth/callback` working |
| Build/ship | EAS (build, submit, updates) | |
| Monitoring | Sentry | install at hardening phase |
| IAP | RevenueCat (when IAP unpauses; S10.21 keeps it paused) | |
| Analytics | PostHog | install at hardening phase |

## 4. Keys & logins (extracted from the Flutter app)

| Item | Value | New home |
|------|-------|----------|
| Supabase URL | `https://wjaphoaxalvgjnrwqjwe.supabase.co` | `app/.env` → `EXPO_PUBLIC_SUPABASE_URL` ✅ |
| Supabase anon key | from Flutter `.env` (public, RLS-protected) | `app/.env` → `EXPO_PUBLIC_SUPABASE_ANON_KEY` ✅ |
| App identity | name Vertiege, scheme `vertiege`, android `com.vertiege`, iOS `com.vertiege` | `app/app.json` ✅ |
| OAuth redirect | `vertiege://auth/callback` | Supabase Auth config (unchanged) + Expo scheme |
| Firebase project | `veritage` · sender `92526224561` | `app/config/firebase.ts` (when Firebase services land) |
| Firebase Android | apiKey `AIzaSyBZTPAlGRd_kMw743Fe0qJkVHNeeJySU80`, appId `1:92526224561:android:7b7a9f6f448f61ca7cae90` | `app/config/firebase.ts` |
| Firebase iOS | apiKey `AIzaSyDlrYB-KZskQuktszLXHMZ5NGLpp2fJQIY`, appId `1:92526224561:ios:29b2459028dca5757cae90` | `app/config/firebase.ts` |
| Google OAuth clients | android `92526224561-d4q4ecq0b6v1kfd4sh2l8im2t27pedce…`, ios `92526224561-oq7m8j0fgqmbqadcluhvc1h6lqvq7709…` | expo-auth-session config (when wired) |
| Supabase project id | `wjaphoaxalvgjnrwqjwe` | — (encoded in URL) |
| Storage buckets | avatars, post-media, world-banners, world-icons, marketplace-media, chat-attachments, verification-proofs (private) | backend, unchanged |

`.env` is gitignored; `EXPO_PUBLIC_*` values are build-time embedded (anon key is public by design — security is RLS).

## 5. Backend contract (unchanged, reused as-is)

- **Supabase:** auth (email + Google + Apple, redirect `vertiege://auth/callback`), Postgres + RLS (source of truth), Realtime, Storage buckets above, Edge Functions: `send-push`, `livekit-token`, `verify-subscription-purchase`.
- **Firebase:** FCM push (via `send-push` webhook), Crashlytics, Analytics, Remote Config, App Check.
- **Rules:** no `service_role` or Firebase service-account JSON in the client, ever.

## 6. Product pillars (what the fresh app implements)

Built from scratch as the product evolves — visuals decided during the build:

1. **Home feed** — moments/feed with streak, quests, tier visibility.
2. **Worlds** — discovery and world detail with channels.
3. **Chat** — DMs, world channels, threads, reactions, typing, presence, voice.
4. **Profile/You** — identity, stats, tier progress, achievements, connections, settings.
5. **Progression & economy** — quests, season, leagues, streaks, shop, subscription (IAP paused per S10.21).

Backend tables/RLS not used by a pillar simply stay dormant.

## 7. Build phases

| Phase | Scope | Exit |
|-------|-------|------|
| **F0 — Foundation** | Scaffold `app/` ✅, NativeWind+UI+Reanimated ✅, app identity ✅, keys in `.env` ✅, Supabase client + secure-store session, Zustand + TanStack Query + MMKV + sqlite/Drizzle wiring, auth boot (email + Google + Apple via Supabase) | App boots, sign-in loop works, `tsc --noEmit` + eslint clean |
| **F1 — Core loop** | Home feed + composer, worlds + channels, DM/chat with presence/typing, post detail/comments/reactions | Core loop usable end-to-end |
| **F2 — Identity & progression** | Profile, achievements + proof upload, quests/season/league, streak | Progression loop complete |
| **F3 — Notifications & retention** | Unified inbox, FCM push, quiet hours, notification prefs | Push + inbox live |
| **F4 — Hardening & launch** | Reanimated polish (reduced-motion), a11y, empty/error states, Sentry + PostHog + Crashlytics/Remote Config/App Check, RevenueCat (if IAP unpaused), EAS build config, store beta review | Both stores green → cutover |

Each phase lands with `tsc --noEmit` + eslint + jest (jest-expo).

## 8. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Firebase native modules (push/crashlytics) need config | `@react-native-firebase/*` via config plugins + dev-client from day one |
| Supabase Realtime edge cases | Port behavior at the contract level (RLS + channels), not code level |
| Secrets in client | Security gate script for `app/` (scan for `service_role`) |
| Expo Go can't run MMKV/dev-client features | dev-client is the single dev target from the start |

## 9. Conventions (RN side)

- Clean Expo structure: `app/` routes, `components/` UI, `lib/` services/state, `db/` Drizzle schema.
- Feature screens never import `nativewindui` internals beyond `components/ui/` primitives.
- Lexicon: world, resident, achievement, Campfire, Nexus, Identity, Ally, tier.
