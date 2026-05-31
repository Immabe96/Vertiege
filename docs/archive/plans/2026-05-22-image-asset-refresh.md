# Image asset refresh — Vertiege

**Goal:** Replace outdated `assets/generated/` art with a coherent, on-brand set that matches each world name, profession, and achievement category.

**Inventory:** 64 files (see manifest below). Code reads paths from `lib/utils/world_assets.dart` and `lib/config/cosmetics.dart` — **filenames must stay the same** unless you update those maps in the same PR.

---

## Can your $20 Codex plan do this?

| Tool | Best for |
|------|----------|
| **Codex / ChatGPT (coding)** | Writing prompts, batch scripts, resizing, renaming, PR checklist — not always image output |
| **ChatGPT image generation** (if included in your subscription) | One-off or small batches from the prompt table below |
| **OpenAI Images API** (DALL·E / gpt-image) | Scripted batch generation; billed per image, separate from Codex tokens |
| **Cursor GenerateImage** | Spot-check style references (1–3 hero images) before a full batch |

**Practical approach:** Use Codex to run the **pipeline** (manifest + prompts + `scripts/validate_assets.ps1`), and use **ChatGPT Images or the Images API** for actual pixels. Do not rename files without updating Dart maps.

---

## Art direction (lock this first)

**Brand:** “Tier-gated social worlds” — premium, slightly futuristic, not cartoonish.

### Hard rules (non‑negotiable)

| Rule | Applies to |
|------|------------|
| **No text anywhere in the image** | **All `world-*.jpg` banners** and **all `badge-*.png` / `prof-*.png`** |
| No letters, numbers, words, logos, street signs, neon signage, UI labels, watermarks | Banners + badges (and still avoid on everything else) |
| **Transparent background** | `badge-*.png`, `prof-*.png`, `ach-*.png`, `tier-*.png` |
| Full-bleed background OK (opaque) | `world-*.jpg`, `bg-*.jpg`, `empty-*.jpg` |
| Avatars | PNG; **prefer transparent** around the bust so `CircleAvatar` clips cleanly (soft vignette OK, no rectangular frame) |

**Why:** Banners sit under gradients and UI copy in-app — any baked-in text clashes with world names. Badges render on coloured tiles; they must be **icon-only emblems** on **alpha**, not stickers on white squares.

| Rule | Value |
|------|--------|
| Mood | Cinematic, high contrast, subtle neon accents |
| Palette | Black / white base, violet `#7C3AED`, blue `#007AFF`, gold highlights |
| Worlds | Wide **16:9** environment art only — **zero typography** in pixels |
| Badges / prof | **1:1** emblem, metallic rim, **alpha PNG**, readable at 48dp |
| Achievements | **1:1** category metaphor, same emblem style, **alpha PNG** |
| Tiers | **1:1** medal crest (bronze → diamond), **alpha PNG** |
| Empty states | Soft illustration, AMOLED-friendly **opaque** JPG |

### Negative prompts

**Banners (`world-*.jpg`) — append every time:**
```
no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing,
no watermarks, no UI, no captions, no banners with typography, no storefront names
```

**Badges & professions (`badge-*.png`, `prof-*.png`) — append every time:**
```
no text, no letters, no numbers, no words, no labels, no initials, no monograms,
transparent background, isolated emblem only, no white square backdrop, no drop shadow card
```

**All other PNGs (ach, tier, avatar):**
```
no text, no watermark, transparent background (avatars: transparent or soft vignette only),
no UI mockup, not clipart, not anime
```

**General (everything):** blurry, low contrast, oversaturated, crowded composition.

---

## Output specs (Flutter)

| Asset | File pattern | Size (px) | Format | Background |
|-------|----------------|------------|--------|------------|
| World banner | `world-{slug}.jpg` | **1200×675** (16:9) | JPG q85 | **Opaque** full scene |
| Avatar | `avatar-*.png` | **512×512** | PNG | **Transparent** preferred |
| Badge / profession | `badge-*.png`, `prof-*.png` | **512×512** | PNG | **Transparent (required)** |
| Achievement category | `ach-*.png` | **512×512** | PNG | **Transparent (required)** |
| Tier | `tier-*.png` | **512×512** | PNG | **Transparent (required)** |
| Empty / BG | `empty-*.jpg`, `bg-*.jpg` | **1080×1920** or **1200×800** | JPG | Opaque |

**Post-processing (if the model returns a white/coloured plate behind badges):**
- Remove background → true alpha (e.g. rembg, Photoshop, Photoroom).
- Reject any output that has readable characters — regen rather than ship.

After generation: resize with ImageMagick/ffmpeg; **verify alpha** on PNGs before commit.

```powershell
# Quick check: PNG has transparency (ImageMagick)
magick identify -format "%[opaque]" assets/generated/badge-doctor.png
# "false" = has transparency (good for emblems)
```

---

## World banners — prompt template

Use **one prompt per slug**; keep filename unchanged.

```
Cinematic wide establishing shot for a digital community themed as {THEME_ONE_LINE}.
Visual only: {MOTIF}. Environment and atmosphere only — do not depict the name "{DISPLAY_NAME}" as text.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing anywhere in the image.
Aspect ratio 16:9, full-bleed opaque photograph.
```

| Slug | DISPLAY_NAME | THEME | MOTIF |
|------|--------------|-------|-------|
| aetheria | Aetheria | ethereal high society | floating terraces in mist, soft aurora |
| arts-pavilion | Arts Pavilion | creative elite | modern gallery at dusk, sculpture garden |
| aviation-heights | Aviation Heights | aviation prestige | airport skyline, runway lights, dawn |
| azure-coast | Azure Coast | coastal luxury | cliff villas, turquoise water, golden hour |
| crimson-court | Crimson Court | power & ceremony | crimson-lit grand hall, velvet, chandeliers |
| crystal-shore | Crystal Shore | serene wealth | crystal-clear bay, minimalist piers |
| financial-district | Financial District | finance capital | glass towers, trading floor glow at night |
| golden-estate | Golden Estate | old money estate | manor drive, hedges, warm sunset |
| legal-plaza | Legal Plaza | law & order | courthouse columns, marble, blue hour |
| medical-nexus | Medical Nexus | medical excellence | futuristic hospital campus, clean white+violet |
| neon-district | Neon District | cyber nightlife | neon alley, rain reflections, purple+pink — **glowing shapes only, no readable signs** |
| nova-station | Nova Station | space / research | orbital station window, nebula view |
| quantum-core | Quantum Core | tech / science | particle accelerator aesthetic, blue energy |
| silver-page | Silver Page | media & publishing | abstract press room, paper stacks — **no headlines or pages with writing** |
| sovereign-city | Sovereign City | capital metropolis | panoramic city crown, citadel center — **no skyline text** |
| tech-sprawl | Tech Sprawl | startup megacity | dense tech campus, holographic light shapes — **no billboards with words** |

---

## Other asset prompts (short)

**Avatars (`avatar-1` … `avatar-6`):** “Studio portrait bust, diverse {gender/ethnicity}, violet rim light, **transparent background**, no text, no name tag, 1:1 PNG.”

**Named avatars:** Distinct faces only — **do not render the name as text** on the image.

**Professions (`prof-*.png`):** Single iconic object (stethoscope, blueprints, gavel, chart, palette, wings) as **3D metallic emblem, centered, transparent PNG, no text, no circular plaque with letters**.

**Badges (`badge-*.png`):** Same as professions — **symbol only** (marathon shoe, quill, laurel, compass…). **No badge captions, no “MD”, no rank numbers.**

**Achievement categories (`ach-*.png`):** Metaphor icons (books, briefcase, hearts, dumbbell, wrench, plane, coins, handshake, mask, palette) — **transparent PNG, no labels**.

**Tiers:** Bronze / silver / gold / diamond **medallions** — ornate metal only, **no tier name engraved**.

**Empty states:** `empty-feed` (quiet timeline), `empty-chat` (speech bubbles), `empty-worlds` (portal), `empty-notifications` (bell) — minimal, dark background.

**Backgrounds:** `bg-splash`, `bg-onboarding` — abstract violet/black gradients, no characters.

---

## Codex workflow (resumable — use this)

**Start:** [docs/assets/CODEX_START_HERE.md](../assets/CODEX_START_HERE.md)

```powershell
.\scripts\image_gen.ps1 next      # one job + prompts (JSON)
.\scripts\image_gen.ps1 mark -Id <id> -Status generated
.\scripts\image_gen.ps1 status    # progress
.\scripts\image_gen.ps1 promote -All   # when ready: staging → assets/generated
```

Files save to **`assets/staging/generated/`** (in repo — Cursor/Codex can read them). State tracked in **`docs/assets/image-manifest.json`**.

4. Run validation:
   ```powershell
   ./scripts/validate_assets.ps1
   flutter test
   ```
5. **One PR** `assets: refresh generated art` — no Dart changes if names unchanged.
6. **Manual check** on device: world detail hero, explore cards, achievement grid, default avatars.

---

## Accuracy checklist (fix “inaccurate” assets)

| Problem | Fix |
|---------|-----|
| World image doesn’t match name | Regenerate using table above; verify slug ↔ file |
| Medical world looks generic | Emphasize clinical / campus motif in prompt |
| Neon-district not neon | Force “neon alley, rain, night” in every regen |
| Badge doesn’t match profession | Align `badge-*` with `prof-*` visual language |
| Text baked into banner/badge | Reject file; regen with CRITICAL no-text block; check neon/city slugs especially |
| White square behind badge | Run background removal; require alpha PNG |
| Tier 4 and 5 share diamond art | Add `tier-platinum.png` in a follow-up if product wants 5 distinct tiers |

---

## Optional phase 2 (Supabase)

User-uploaded world banners already support `world-banners` bucket. Generated assets are **fallbacks** for seed worlds. Custom worlds can use uploaded banners later; local assets remain defaults for offline/demo.

---

## File manifest (64)

```
ach-career.png ach-community.png ach-creative.png ach-education.png ach-finance.png
ach-funny.png ach-health.png ach-relationships.png ach-skills.png ach-travel.png
avatar-1.png … avatar-6.png avatar-alistair.png avatar-elena.png avatar-marcus.png
badge-*.png (14) prof-*.png (6) tier-bronze.png tier-silver.png tier-gold.png tier-diamond.png
bg-onboarding.jpg bg-splash.jpg empty-chat.jpg empty-feed.jpg empty-notifications.jpg empty-worlds.jpg
world-aetheria.jpg … world-tech-sprawl.jpg (16)
```

Full path map: `lib/utils/world_assets.dart`.
