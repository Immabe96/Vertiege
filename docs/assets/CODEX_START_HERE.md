# Codex: start here (image refresh)

Copy the block below into a **new Codex chat** tied to this repo.

---

```
Vertiege image refresh — resumable queue (64 assets).

Read first:
- docs/assets/CODEX_IMAGE_WORKFLOW.md
- docs/plan/2026-05-22-image-asset-refresh.md

Each session:
1. cd <repo-root>
2. .\scripts\image_gen.ps1 next
3. Generate ONE image; save to the exact stagingPath from JSON (under assets/staging/generated/)
4. .\scripts\image_gen.ps1 mark -Id <id> -Status generated
5. git add docs/assets/image-manifest.json assets/staging/generated/<file>
6. git commit -m "assets(staging): <id>"

If daily image limit hit:
.\scripts\image_gen.ps1 mark -Id <id> -Status failed -Notes "daily limit"
Stop. Next session: run `next` again — continues from manifest.

Rules: world JPG = no text. badge/prof/ach/tier PNG = transparent, no text.
Do not write to assets/generated/ until user runs promote.
```

Queue file: `docs/assets/image-manifest.json`  
Staging (you save here): `assets/staging/generated/`
