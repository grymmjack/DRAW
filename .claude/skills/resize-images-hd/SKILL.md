---
name: resize-images-hd
description: "Resize all PNG images in a folder recursively to 800% using nearest-neighbor scaling (pixel-perfect, no blurring). Outputs each image as the same filename with -hd.png suffix. Ideal for generating HD preview versions of pixel art / icon assets."
---

# Resize Images HD — Batch 8× PNG Upscale

Recursively resize all PNG files in a target folder to 800% of their original size using ImageMagick's nearest-neighbor filter (no anti-aliasing or blurring). Each output file is named `{original-name}-hd.png` and placed alongside its source.

---

## Step 1 — Confirm Target Folder

Ask the user which folder to process if not already specified. The folder must exist in the workspace.

Example folders in this project:
- `DEV/IMAGES` — development/reference screenshots

---

## Step 2 — Preview File Count

Before processing, count the files that will be affected:

```bash
find /path/to/folder -name "*.png" ! -name "*-hd.png" | wc -l
```

Report the count to the user before proceeding.

---

## Step 3 — Run the Batch Resize

Use ImageMagick `convert` with `-filter point -resize 800%` to upscale without blurring. Skip any files already ending in `-hd.png` to avoid double-processing.

```bash
find /path/to/folder -name "*.png" ! -name "*-hd.png" | while read f; do
    dir=$(dirname "$f")
    base=$(basename "$f" .png)
    convert "$f" -filter point -resize 800% "$dir/${base}-hd.png"
done && echo "Done"
```

**Key flags:**
- `-filter point` — nearest-neighbor (pixel-perfect, ideal for pixel art and icons)
- `-resize 800%` — 8× enlargement
- `! -name "*-hd.png"` — prevents reprocessing already-generated HD files

---

## Step 4 — Verify Output

Spot-check a few output files to confirm they were created at the expected size:

```bash
find /path/to/folder -name "*-hd.png" | head -5 | while read f; do
    identify -format "%f: %wx%h\n" "$f"
done
```

---

## Notes

- To use a different scale factor, replace `800%` with e.g. `400%` (4×) or `1600%` (16×).
- To resize in-place (overwrite originals) instead of creating `-hd` copies, remove the suffix and write to the same path — but confirm with the user first as this is destructive.
- For non-pixel-art images where smoothing is acceptable, omit `-filter point` to use ImageMagick's default Lanczos filter.
- Requires `imagemagick` to be installed (`convert` command available).
