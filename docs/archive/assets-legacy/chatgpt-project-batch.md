# Vertiege - ChatGPT Project batch file

Generated: 2026-05-22 17:37 | Pending assets: 16

Upload this file to a **ChatGPT Project** (Project files / knowledge). Use the custom instructions block below in Project settings.

---

## Custom instructions (paste into ChatGPT Project)

```text
You generate Vertiege mobile game art from the batch manifest in this file.

Rules for every image:
- Follow each asset PROMPT block exactly; one asset per generation unless user asks for the next numbered item.
- Use the exact SAVE_AS filename (ChatGPT only exports PNG).
- Match DIMENSIONS and ASPECT; world banners are 1200x675 landscape 16:9.
- No text, letters, numbers, logos, signage, or watermarks in the image.
- After each image, tell the user: SAVE_AS filename and ASSET_ID for renaming in Downloads.

When user says "batch" or "run the list", generate assets in manifest order (1, 2, 3...), one image per message, and stop if rate-limited.
```

## Local workflow (after ChatGPT)

1. Download each image and rename to **SAVE_AS** (see each asset).
2. Put files in `%USERPROFILE%\\Downloads` with that exact name.
3. In repo: `.\scripts\image_gen.ps1 mark -Id <ASSET_ID> -Status generated` (pulls from Downloads, converts JPG if needed).
4. When all done: `.\scripts\image_gen.ps1 promote -All` then rebuild APK.

## Manifest index

| # | ASSET_ID | SAVE_AS | SIZE | NOTES |
|---|----------|---------|------|-------|
| 1 | world-aetheria | world-aetheria.png | 1200x675 | -> world-aetheria.jpg |
| 2 | world-arts-pavilion | world-arts-pavilion.png | 1200x675 | -> world-arts-pavilion.jpg |
| 3 | world-aviation-heights | world-aviation-heights.png | 1200x675 | -> world-aviation-heights.jpg |
| 4 | world-azure-coast | world-azure-coast.png | 1200x675 | -> world-azure-coast.jpg |
| 5 | world-crimson-court | world-crimson-court.png | 1200x675 | -> world-crimson-court.jpg |
| 6 | world-crystal-shore | world-crystal-shore.png | 1200x675 | -> world-crystal-shore.jpg |
| 7 | world-financial-district | world-financial-district.png | 1200x675 | -> world-financial-district.jpg |
| 8 | world-golden-estate | world-golden-estate.png | 1200x675 | -> world-golden-estate.jpg |
| 9 | world-legal-plaza | world-legal-plaza.png | 1200x675 | -> world-legal-plaza.jpg |
| 10 | world-medical-nexus | world-medical-nexus.png | 1200x675 | -> world-medical-nexus.jpg |
| 11 | world-neon-district | world-neon-district.png | 1200x675 | -> world-neon-district.jpg |
| 12 | world-nova-station | world-nova-station.png | 1200x675 | -> world-nova-station.jpg |
| 13 | world-quantum-core | world-quantum-core.png | 1200x675 | -> world-quantum-core.jpg |
| 14 | world-silver-page | world-silver-page.png | 1200x675 | -> world-silver-page.jpg |
| 15 | world-sovereign-city | world-sovereign-city.png | 1200x675 | -> world-sovereign-city.jpg |
| 16 | world-tech-sprawl | world-tech-sprawl.png | 1200x675 | -> world-tech-sprawl.jpg |

## Kickoff prompts (try in Project chat)

- `Generate asset #1 from the manifest. Use its PROMPT block exactly.`
- `Batch mode: generate assets #1 through #16 in order, one per reply. Confirm SAVE_AS after each.`
- `Continue from asset #5.`

---

## Asset prompts

### 1. world-aetheria

| Field | Value |
|-------|-------|
| ASSET_ID | `world-aetheria` |
| SAVE_AS | `world-aetheria.png` |
| FINAL_FILE | `world-aetheria.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-aetheria.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-aetheria
File name when saving: world-aetheria.png
Final app file: world-aetheria.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as ethereal high society. Visual only: floating terraces in mist, soft aurora.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 2. world-arts-pavilion

| Field | Value |
|-------|-------|
| ASSET_ID | `world-arts-pavilion` |
| SAVE_AS | `world-arts-pavilion.png` |
| FINAL_FILE | `world-arts-pavilion.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-arts-pavilion.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-arts-pavilion
File name when saving: world-arts-pavilion.png
Final app file: world-arts-pavilion.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as creative elite. Visual only: modern gallery at dusk, sculpture garden.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 3. world-aviation-heights

| Field | Value |
|-------|-------|
| ASSET_ID | `world-aviation-heights` |
| SAVE_AS | `world-aviation-heights.png` |
| FINAL_FILE | `world-aviation-heights.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-aviation-heights.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-aviation-heights
File name when saving: world-aviation-heights.png
Final app file: world-aviation-heights.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as aviation prestige. Visual only: airport skyline, runway lights at dawn.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 4. world-azure-coast

| Field | Value |
|-------|-------|
| ASSET_ID | `world-azure-coast` |
| SAVE_AS | `world-azure-coast.png` |
| FINAL_FILE | `world-azure-coast.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-azure-coast.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-azure-coast
File name when saving: world-azure-coast.png
Final app file: world-azure-coast.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as coastal luxury. Visual only: cliff villas, turquoise water, golden hour.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 5. world-crimson-court

| Field | Value |
|-------|-------|
| ASSET_ID | `world-crimson-court` |
| SAVE_AS | `world-crimson-court.png` |
| FINAL_FILE | `world-crimson-court.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-crimson-court.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-crimson-court
File name when saving: world-crimson-court.png
Final app file: world-crimson-court.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as power and ceremony. Visual only: crimson-lit grand hall, velvet, chandeliers.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 6. world-crystal-shore

| Field | Value |
|-------|-------|
| ASSET_ID | `world-crystal-shore` |
| SAVE_AS | `world-crystal-shore.png` |
| FINAL_FILE | `world-crystal-shore.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-crystal-shore.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-crystal-shore
File name when saving: world-crystal-shore.png
Final app file: world-crystal-shore.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as serene wealth. Visual only: crystal-clear bay, minimalist piers.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 7. world-financial-district

| Field | Value |
|-------|-------|
| ASSET_ID | `world-financial-district` |
| SAVE_AS | `world-financial-district.png` |
| FINAL_FILE | `world-financial-district.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-financial-district.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-financial-district
File name when saving: world-financial-district.png
Final app file: world-financial-district.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as finance capital. Visual only: glass towers, night glow, no readable signs.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 8. world-golden-estate

| Field | Value |
|-------|-------|
| ASSET_ID | `world-golden-estate` |
| SAVE_AS | `world-golden-estate.png` |
| FINAL_FILE | `world-golden-estate.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-golden-estate.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-golden-estate
File name when saving: world-golden-estate.png
Final app file: world-golden-estate.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as old money estate. Visual only: manor drive, hedges, warm sunset.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 9. world-legal-plaza

| Field | Value |
|-------|-------|
| ASSET_ID | `world-legal-plaza` |
| SAVE_AS | `world-legal-plaza.png` |
| FINAL_FILE | `world-legal-plaza.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-legal-plaza.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-legal-plaza
File name when saving: world-legal-plaza.png
Final app file: world-legal-plaza.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as law and order. Visual only: courthouse columns, marble, blue hour.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 10. world-medical-nexus

| Field | Value |
|-------|-------|
| ASSET_ID | `world-medical-nexus` |
| SAVE_AS | `world-medical-nexus.png` |
| FINAL_FILE | `world-medical-nexus.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-medical-nexus.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-medical-nexus
File name when saving: world-medical-nexus.png
Final app file: world-medical-nexus.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as medical excellence. Visual only: futuristic hospital campus, white and violet.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 11. world-neon-district

| Field | Value |
|-------|-------|
| ASSET_ID | `world-neon-district` |
| SAVE_AS | `world-neon-district.png` |
| FINAL_FILE | `world-neon-district.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-neon-district.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-neon-district
File name when saving: world-neon-district.png
Final app file: world-neon-district.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as cyber nightlife. Visual only: neon alley, rain reflections, glowing shapes only no readable signs.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 12. world-nova-station

| Field | Value |
|-------|-------|
| ASSET_ID | `world-nova-station` |
| SAVE_AS | `world-nova-station.png` |
| FINAL_FILE | `world-nova-station.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-nova-station.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-nova-station
File name when saving: world-nova-station.png
Final app file: world-nova-station.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as space research. Visual only: orbital station window, nebula view.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 13. world-quantum-core

| Field | Value |
|-------|-------|
| ASSET_ID | `world-quantum-core` |
| SAVE_AS | `world-quantum-core.png` |
| FINAL_FILE | `world-quantum-core.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-quantum-core.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-quantum-core
File name when saving: world-quantum-core.png
Final app file: world-quantum-core.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as tech science. Visual only: particle accelerator aesthetic, blue energy.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 14. world-silver-page

| Field | Value |
|-------|-------|
| ASSET_ID | `world-silver-page` |
| SAVE_AS | `world-silver-page.png` |
| FINAL_FILE | `world-silver-page.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-silver-page.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-silver-page
File name when saving: world-silver-page.png
Final app file: world-silver-page.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as media publishing. Visual only: abstract press room, paper stacks, no headlines.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 15. world-sovereign-city

| Field | Value |
|-------|-------|
| ASSET_ID | `world-sovereign-city` |
| SAVE_AS | `world-sovereign-city.png` |
| FINAL_FILE | `world-sovereign-city.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-sovereign-city.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-sovereign-city
File name when saving: world-sovereign-city.png
Final app file: world-sovereign-city.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as capital metropolis. Visual only: panoramic city crown, citadel, no skyline text.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---

### 16. world-tech-sprawl

| Field | Value |
|-------|-------|
| ASSET_ID | `world-tech-sprawl` |
| SAVE_AS | `world-tech-sprawl.png` |
| FINAL_FILE | `world-tech-sprawl.jpg` |
| DIMENSIONS | 1200x675 |
| CATEGORY | world_banner |
| STAGING | `assets/staging/generated/world-tech-sprawl.jpg` |

**PROMPT (copy for image generation):**

```text
Vertiege premium mobile game asset.
Asset ID: world-tech-sprawl
File name when saving: world-tech-sprawl.png
Final app file: world-tech-sprawl.jpg
Dimensions: 1200x675 pixels (generate at this exact size).
Format: PNG from ChatGPT; repo converts to JPG on import.
Aspect: 16:9 landscape.

Cinematic wide establishing shot themed as startup megacity. Visual only: tech campus, holographic light shapes, no words on billboards.
Lighting: dramatic rim light, deep shadows, subtle violet and gold accents.
Style: premium mobile game key art, photorealistic environment, no people.
CRITICAL: absolutely no text, letters, signs, logos, or readable writing in the image.
Aspect ratio 16:9, full-bleed opaque photograph.

Avoid: no text, no letters, no numbers, no words, no logos, no signage, no neon signs with writing, no watermarks, no UI, no captions
No text, letters, numbers, logos, watermarks, or UI.
```

---


