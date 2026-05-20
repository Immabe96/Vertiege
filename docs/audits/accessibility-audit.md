# Accessibility Audit

**Date:** 2026-05-19
**Phase:** 12 — Accessibility, Mobile Quality & Internationalization

---

## Text Scaling

| Screen | 1.0x | 1.3x | 1.6x | Notes |
|--------|------|------|------|-------|
| Nexus | Unknown | Unknown | Unknown | Needs device testing |
| Explore | Unknown | Unknown | Unknown | Grid layout may overflow |
| Chat | Unknown | Unknown | Unknown | Rail layout at 72px may clip |
| World Detail | Unknown | Unknown | Unknown | Tab labels may clip |
| Identity | Unknown | Unknown | Unknown | Nameplate may overflow |
| More | Unknown | Unknown | Unknown | List tiles should handle overflow |

**Action:** Test with `MediaQuery.textScaler` on device at 1.0, 1.3, 1.6.

---

## Tap Targets

- Minimum 44x44 touch target partially enforced via `VTouchTarget` class
- IconButtons default to 48x48 (Material default) — compliant
- `_MoreItem` ListTile has inherent 48px min height — compliant
- World rail icons at 44x44 — borderline, should be 48x48 minimum

**Action:** Increase world rail icons from 44x44 to 48x48.

---

## Semantic Labels

- 53 IconButtons found, 28 have tooltips (53%)
- High-traffic untooltipped icons:
  - `chat_list_screen.dart`: person_add button
  - `explore_screen.dart`: search clear (x), sort, filter buttons
  - `nexus_screen.dart`: notification bell
  - `world_detail_screen.dart`: back, share, settings buttons
  - `identity_screen.dart`: edit profile, share buttons

**Action:** Add tooltip/semanticLabel to all 25 untooltipped IconButtons.

---

## Keyboard Avoidance

- `Scaffold.resizeToAvoidBottomInset` defaults to true — all screens are covered
- `showModalBottomSheet(isScrollControlled: true)` used for composer — correct
- Screens with text input verified: LoginScreen, ChatRoomScreen, PostInput, CommentSheet
- **No issues found.**

---

## Safe Areas

- `SafeArea` widget used in tab_layout.dart bottom nav
- Most screens rely on Scaffold's built-in safe area handling
- World detail screen uses `MediaQuery.of(context).padding.top` for overlay positioning — correct
- **No issues found.**

---

## Reduced Motion

- No `MediaQuery.of(context).disableAnimations` checks found
- Animations present in: splash, tab transitions, XP toast, tier celebration
- **Action:** Add `if (!context.disableAnimations)` guards to non-essential animations.

---

## Contrast

- Light theme: dark text on white surfaces — high contrast
- Dark theme: light text on AMOLED black — high contrast
- Accent colors (VColors.primary on surface) — previously validated
- Hero overlay icons (white + shadow over images) — acceptable scrim pattern
- **No issues found in code.** Device testing recommended for actual rendered output.

---

## Summary

| Area | Status |
|------|--------|
| Text scaling | Needs device testing |
| Tap targets | Mostly compliant, rail icons need +4px |
| Semantic labels | 53% coverage, 25 icons need tooltips |
| Keyboard avoidance | No issues |
| Safe areas | No issues |
| Reduced motion | Not implemented (desirable) |
| Contrast | No code issues, needs device verification |
| String extraction | Not started (English only) |
