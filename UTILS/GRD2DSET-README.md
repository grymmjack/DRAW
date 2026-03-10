# GRD2DSET — Gradient File to DRAW .dset Converter

A Python script that converts gradient files from popular graphics applications into DRAW's `.dset` format for use with the drawer panel.

## Requirements

- Python 3.6+
- [Pillow](https://pillow.readthedocs.io/) (optional, for PNG export)

```bash
pip install Pillow
```

## Supported Input Formats

| Format | Extension | Source Application | Versions |
|---|---|---|---|
| Photoshop Gradients | `.grd` | Adobe Photoshop | v3 (pre-PS6) and v5 (PS6+) |
| GIMP Gradient | `.ggr` | GIMP / Krita | All versions |

### Color Space Support

GRD files may contain stops defined in various color spaces. All are converted to RGB:

| Color Space | GRD v3 | GRD v5 |
|---|---|---|
| RGB | ✓ | ✓ |
| HSV / HSB | ✓ | ✓ |
| CMYK | ✓ | ✓ |
| Lab | ✓ | ✓ |
| Grayscale | ✓ | ✓ |
| Book/Spot Color | — | ✓ (fallback) |
| Foreground/Background | ✓ (black/white) | ✓ (black/white) |

## Usage

```bash
python3 grd2dset.py <input.grd|input.ggr> [options]
```

### Options

| Flag | Description | Default |
|---|---|---|
| `-o DIR` | Output directory for `.dset` files | Same as input file |
| `-l` | List gradients only (don't convert) | — |
| `--png DIR` | Also export individual gradients as PNG files | — |
| `--width N` | Ramp image width in pixels | 256 |
| `--height N` | Ramp image height in pixels | 1 |

### Examples

```bash
# List gradients in a Photoshop .grd file
python3 grd2dset.py "My Gradients.grd" -l

# Convert a .grd file with default settings (256×1 ramp)
python3 grd2dset.py "My Gradients.grd"

# Convert with PNG previews for visual verification
python3 grd2dset.py "My Gradients.grd" --png ./previews

# Convert with a taller ramp (useful for visual inspection)
python3 grd2dset.py "My Gradients.grd" --width 256 --height 16

# Convert a GIMP gradient file
python3 grd2dset.py fire.ggr -o ../ASSETS/DSETS

# Convert and output to DRAW's DSETS directory
python3 grd2dset.py "from-ps/Grymmjacks Essential Gradients.grd" -o ../ASSETS/DSETS
```

## What It Does

1. **Parses** the input gradient file, extracting color stops, transparency stops, and midpoints
2. **Renders** each gradient as a horizontal ramp image (default 256×1 pixels)
3. **Packs** up to 30 gradients per `.dset` file (matching DRAW's `DRAWER_SLOT_COUNT`)
4. **Names** the output after the input file:
   - 30 or fewer gradients → `filename.dset`
   - More than 30 → `filename1.dset`, `filename2.dset`, etc.
5. **Outputs** the `.dset` file(s) to the specified directory (or same as input)

### Gradient Rendering Details

- Color stops are linearly interpolated with midpoint support
- Transparency stops modulate the alpha channel independently
- Midpoints shift the interpolation center between two stops (Photoshop-style)
- Noise gradients (GRD v5 `ClNs` type) are exported as gray placeholders

## Output Format

The output `.dset` files use mode `3` (Gradient). See [MAKE-DSET-README.md](MAKE-DSET-README.md) for the full `.dset` binary format specification.

## Using Converted Gradients in DRAW

### Loading manually

In DRAW, right-click the drawer panel and select **LOAD DRAWER SET (.dset)** to import.

### Loading on startup via DRAW.cfg

```ini
DEFAULT_DSET_GRADIENTS_FILE=my-gradients.dset
```

## Where to Find Gradient Files

- **Photoshop .grd**: Bundled with Photoshop, widely shared on sites like DeviantArt and Gumroad
- **GIMP .ggr**: Included with GIMP and Krita installations (check `~/.local/share/krita/gradients/` or GIMP's `gradients/` directory)

## Reference

- [GRD format specification](https://www.selapa.net/swatches/gradients/fileformats.php)
- [Adobe Actions descriptor format](http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/#50577411_pgfId-1059252) (used by GRD v5)
