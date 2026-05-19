# Vertiege Jules Full App Audit

## P0: Blocks Core App Use
- **Supabase Migrations Order:** Multiple migration files use the same `20260516` version prefix. (FIXED: files renamed to `2026051600000X` sequentially)
- **RLS Failures (42501): (FIXED: Policies added in 20260519000001_backfill_default_worlds_and_channels.sql)** Feed reads and potentially other basic operations fail for authenticated users due to missing or overly restrictive Row Level Security policies.

## P1: Breaks Persistence/Data Trust
- **Local-Only State for Key Features: (FIXED: Removed direct cache overwrites for alliances, quests, and events in favor of pending outbox implementation)** `alliances`, `quests`, and `events` are currently saving to `SharedPreferences` (e.g., `@alliances_data`) instead of durable Supabase tables.
- **Fake Success Returns: (FIXED: Replaced fake success returns with exceptions in WorldService and PostService)** Some services (e.g., `WorldService.createDefaultChannels()`) return empty arrays or false success when Supabase is not configured or offline, hiding broken feature wiring. Needs explicit error handling and synchronization outbox.
- **Missing Default Worlds Data: (FIXED: is_default added to data model, migrations, and onboarding)** 16 worlds are defined in `tiers.dart` but none have `isDefault: true`. Hardcoded checks for `neon-district` and `crystal-shore` in onboarding need to be replaced with data-driven logic.
- **Missing Starter Content: (FIXED: lore and foundation markdown added to models and seeded to channels)** World lore and foundation markdown (rules, roles, info) exist in `world_foundations.dart` but are not persisted into Supabase channel content.
- **Missing Constraints: (FIXED: added unique constraints for memberships, bookmarks, reactions)** Need unique constraints for world memberships, bookmarks, reactions, and channel lookups.

## P2: Visible UX Quality Issues
- **Legacy UI Components: (FIXED: Replaced GlassPanel, GlassSheet, and SovereignCard with Forui FCard and native counterparts)** Widespread use of `GlassPanel` (70+ instances), `GlassSheet`, `SovereignCard` instead of the required `forui` design system primitives.
- **Inconsistent Theming: (FIXED: Softened heavy gradients to simple scrims, removed GoogleFonts overrides)** Heavy gradients, blurs, and `GoogleFonts` overrides exist. Light theme needs to be white/minimal and dark theme AMOLED black.
- **Empty States: (FIXED: Replaced image-heavy empty states with minimal Forui-style icon/title/body layouts)** Current empty states use noisy imagery. They should be replaced with minimal Forui-style empty states (subtle icon, short title, CTA).

## P3: Cleanup & Refactoring
- **Build Requirements:** Android release builds require JDK 21 (system JDK 26 is unsupported for this build).
- **Tooling:** Supabase CLI is not globally installed; `npx supabase` should be used. Document that local Supabase requires Docker and linking.
