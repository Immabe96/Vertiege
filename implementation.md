# Vertiege Implementation Plan & Vision Alignment

This document outlines the roadmap to align the Vertiege application with the intended product vision. It serves as a persistent guide for AI agents and developers.

## Vision Overview
Vertiege is a highly gamified, exclusive, tier-gated social network. The core loop involves:
1. **Onboarding**: Users register, state an occupation, start unverified, and get access to starter worlds.
2. **Progression**: Users submit real-world proof to verify their occupation. They earn XP to level up their Tier (class).
3. **Exclusivity**: Users unlock "Wealth Worlds" by reaching a high enough Tier, or by buying their way in. Verified users get access to exclusive Occupation Worlds.
4. **Sovereignty**: High-level users unlock the ability to create their own worlds and become a Sovereign.
5. **Monetization**: Users can spend Sovereign Coins in the shop for XP boosters, new features (extra world slots), and cosmetics.

## Current Status & Roadmap

### Phase 1: Verification & Admin Tools [✅ COMPLETED]
- **Status:** Done
- **Work Completed:**
  - Updated `VerificationService.approve` to automatically assign the `verified_roles` to the user's database entry.
  - Exposed the hidden `VerificationReviewScreen` as an Admin Dashboard accessible from the Profile Screen (restricted to users named 'Immabe', 'Creator', or 'Admin').

### Phase 2: Starter Worlds Auto-Join [✅ COMPLETED]
- **Status:** Done
- **Gap:** The database supports `is_default` for worlds, but the onboarding flow never joins new users to them. Users wake up to an empty feed.
- **Implementation:**
  - Modified `lib/screens/onboarding/onboarding_screen.dart` to fetch worlds where `isDefault == true` instead of relying on hardcoded slugs.
  - The resident provider already handles joining these worlds automatically upon resident creation.

### Phase 3: Wealth World Level-Up Access [✅ COMPLETED]
- **Status:** Done
- **Gap:** The app forces users to buy their way into Wealth Worlds via In-App Purchases, even if their `ResidentTier` qualifies them.
- **Implementation:**
  - Verified `canAccessWorld` already successfully grants free access if `resident.tier >= world.requiredTier`.
  - The gap was in the UI. Updated `WorldAccessGuard` to display a detailed progress breakdown comparing the user's current Tier vs the Required Tier, and explicitly stating they can level up via XP to enter for free, rather than presenting a hard paywall.

### Phase 4: Sovereign Level-Gate [✅ COMPLETED]
- **Status:** Done
- **Gap:** The required level for world creation was too low (Tier 2 - High Roller, 500 XP), allowing early accounts to create worlds instantly.
- **Implementation:**
  - Updated `CreateWorldScreen` (`lib/screens/create_world_screen.dart`).
  - Increased the gate to require Tier 3 (Elite) and 2000 XP to make world creation a meaningful mid-to-late game milestone.

### Phase 5: Real-World Achievements & Shop Expansions [✅ COMPLETED]
- **Status:** Done
- **Gap:** No way to submit proof for real-world achievements. Shop only has cosmetics, lacking XP boosters and feature unlocks.
- **Implementation:**
  - Wired up the orphaned `SubmitAchievementScreen` by adding a "Submit Proof" Floating Action Button to the Achievements index.
  - Added new "Extra World Slot" and "2x XP Boost" items to the Cosmetics Shop (under the Seeds and Boosts tabs) purchasable with in-game Sovereign Coins.

---
*Note: Agents should update the status tags in this file as work is completed.*
