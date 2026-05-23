# Wave 4 — Device UAT checklist

Milestone pass after **Waves 1–4** (UX states, VHub, tokens/assets CI, marketplace/DM, world IA, glass/cards, treasury/polls/challenges, identity sections, **Wave 4 motion + a11y + hero**).

**Build:** CI artifact from `develop` ([DEVICE_UAT.md](../DEVICE_UAT.md) install steps)  
**Record:** device model, OS version, APK commit SHA, tester, date

---

## Install & environment

- [ ] **Android:** `adb uninstall com.vertiege` (or legacy package) then `adb install -r` APK
- [ ] **iOS:** TestFlight or local release build per team process
- [ ] **Desktop (optional):** `flutter run -d windows` or macOS — smoke only for layout/motion
- [ ] Sign in with a test account that has joined at least one world

---

## World — join & detail hero

- [ ] **Explore → world:** Open a world you have **not** joined — hero shows tier badge, name, **Join**
- [ ] **Join world:** Tap join — member count/stats update; Feed tab usable
- [ ] **Collapsible hero:** Pull down on hero (overscroll) — banner stretches; release
- [ ] **Sticky header:** Scroll feed — hero collapses to **world name** in top bar + back/share (+ compact Join/Leave when collapsed)
- [ ] **Leave world:** Leave from hero — confirmation dialog; channels/feed gated appropriately
- [ ] **Settings (council/sovereign):** Gear visible only when permitted; opens world settings

---

## World feed — post deep link

- [ ] Open world URL/query with `?post=<id>` or `?highlight=<id>` — lands on **Feed** tab, scrolls to post
- [ ] **Highlight flash:** Brief primary border/glow on target post (not excessively long)
- [ ] Missing post — snackbar “no longer available”, highlight clears
- [ ] **Reduced motion (optional):** OS “Remove animations” / Reduce motion ON — highlight is static border, no flash pulse; stat counters jump to final values

---

## Channels — unread divider

- [ ] Open a channel with messages since last visit — **“New since last visit”** divider appears once
- [ ] Send/receive while in channel — divider behavior still sane; read mark on exit
- [ ] **Back:** App bar back returns to world (not Nexus white screen)

---

## Marketplace — contact DM draft

- [ ] World **Manage → Marketplace** (member world with marketplace enabled)
- [ ] Open listing → **Contact Seller** — opens DM with prefilled draft mentioning listing title
- [ ] **Empty state:** No listings — copy + create CTA for members
- [ ] **Category chips:** Filter updates grid; chips easy to tap (~48dp)

---

## Manage — treasury / polls / challenges

- [ ] **Treasury** (prestige-gated): Empty vs loaded states; no layout overflow
- [ ] **Polls:** Empty state for non-council; create visible for sovereign/council
- [ ] **Challenges:** Empty/active lists readable; actions reachable

---

## Identity (Wall of Honour)

- [ ] **Sections visible:** Standing, Today, Trophy case, worlds, perks — no hunting
- [ ] **Header:** Refresh + Settings icons have tooltips / screen reader labels
- [ ] **Honour chips:** Achievements / Worlds / REP tappable where wired
- [ ] **Edit profile / share** still work from hero area

---

## DM chat room

- [ ] Open DM from marketplace or Nexus — header back labeled; no kick to wrong tab
- [ ] **Unread divider** in long threads (if applicable)
- [ ] Send text message — delivers, scroll FAB when scrolled up

---

## Motion spot check (Wave 4)

- [ ] Tab switch on world detail (Feed / Channels / …) feels smooth
- [ ] Empty states fade in (feed, marketplace) without jank
- [ ] Sheet open (listing detail, share world) — standard Material motion
- [ ] With **reduced motion ON:** animations minimized; content still fully usable

---

## Accessibility spot check

- [ ] **TalkBack / VoiceOver:** World hero Join/Leave, marketplace Contact Seller, identity refresh — announced sensibly
- [ ] **Icon-only actions:** Share, settings, create listing — tooltips on long-press (Android) or accessibility label
- [ ] **Contrast:** Primary CTAs (Join, Contact Seller) readable on light and dark theme

---

## Regression (quick)

- [ ] Nexus feed, explore rail, notifications tab open
- [ ] Search → profile → Message — no white screen
- [ ] Achievements proof upload path unchanged
- [ ] Sign out / sign in

---

## Sign-off

| Platform | Pass | Fail | Notes |
|----------|------|------|-------|
| Android  |      |      |       |
| iOS      |      |      |       |
| Desktop  |      |      |       |

**Promote `develop` → `main`:** only after this checklist is signed for the target APK SHA.
