# Vertiege assets — ChatGPT batch workflow

Use **ChatGPT** (Images / DALL·E in your Plus plan) for pixels. Use **`image_gen.ps1`** only to track progress in git.

## Quick loop (one image)

1. **Next job**
   ```powershell
   cd C:\Users\Immabe\Vertiege
   .\scripts\image_gen.ps1 next
   ```
2. **ChatGPT** — new chat or same thread:
   - Paste the block from `docs/assets/chatgpt-pending-prompts.md` for that `id`, **or** paste `prompt` + `negativePrompt` from `next` JSON.
   - For **PNG badges/icons**: ask for **transparent background**, square **512×512**, no text.
   - For **JPG banners**: **16:9**, **no text**, opaque photo.
3. **Download** → save to the exact `stagingPath` (e.g. `assets/staging/generated/ach-education.png`).
4. **Mark + commit**
   ```powershell
   .\scripts\image_gen.ps1 mark -Id ach-education -Status generated
   git add docs/assets/image-manifest.json assets/staging/generated/ach-education.png
   git commit -m "assets(staging): ach-education"
   ```
5. Repeat `next` until `done: true`.

## ChatGPT prompt

Each section in `chatgpt-pending-prompts.md` includes **Asset ID**, **file name**, **dimensions**, and **format** inside the copy box. Paste the whole `text` block into ChatGPT.

Or run `.\scripts\image_gen.ps1 next` and use the `chatgptPrompt` field from the JSON.

## Rate limits

If ChatGPT refuses or you hit the daily image cap:

```powershell
.\scripts\image_gen.ps1 mark -Id <id> -Status failed -Notes "chatgpt daily limit"
```

`next` will retry `failed` after `pending` is empty.

## After staging looks good

Copy approved files into the app bundle:

```powershell
.\scripts\image_gen.ps1 promote -Id world-golden-estate
# or all generated at once:
.\scripts\image_gen.ps1 promote -All
```

Then commit `assets/generated/` + manifest.

## App launcher icons (not in batch queue)

Light and dark launcher art live at the **repo root** (not `assets/generated/`):

| File | Use |
|------|-----|
| `veritiege-light-mode.svg` | Light theme launcher source |
| `veritiege-dark-mode.svg` | Dark theme launcher source |

Regenerate Android mipmaps from those SVGs:

```powershell
node convert-icons.js
```

Outputs under `android/app/src/main/res/mipmap-*`. Do not regenerate these via ChatGPT unless you are intentionally replacing branding.

## Reference files

| File | Purpose |
|------|---------|
| `docs/assets/chatgpt-pending-prompts.md` | All pending prompts (generated export) |
| `docs/assets/image-manifest.json` | Source of truth + status |
| `docs/assets/CODEX_IMAGE_WORKFLOW.md` | Full rules (formats, no text) |

## Regenerate export

```powershell
.\scripts\image_gen.ps1 export-chatgpt
```
