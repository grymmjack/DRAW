# MAKE-DSET — DRAW Drawer Set Creator

A command-line utility that creates `.dset` files from a directory of images for use with DRAW's drawer panel.

## Build

```bash
qb64pe -w -x -o DEV/MAKE-DSET.run DEV/MAKE-DSET.BAS
```

## Usage

```bash
MAKE-DSET [-b|-p|-g] <directory>
```

Where `<directory>` is a path (absolute or relative) to a folder containing image files.

### Mode Flags

| Flag | Mode | Description |
|---|---|---|
| `-b` | Brush | Creates brush drawer sets (default) |
| `-p` | Pattern | Creates pattern drawer sets |
| `-g` | Gradient | Creates gradient drawer sets |

If no flag is given, brush mode is used.

### Examples

```bash
# Brush set from Mario Paint sprites (default mode)
DEV/MAKE-DSET.run ASSETS/THEMES/DEFAULT/IMAGES/BRUSHES/MARIOPAINT

# Pattern set from DazzleDraw patterns
DEV/MAKE-DSET.run -p "ASSETS/DSETS/PATTERNS/DAZZLEDRAW/Original Patterns"

# Gradient set
DEV/MAKE-DSET.run -g /home/user/my-gradients

# Absolute path
DEV/MAKE-DSET.run -b /home/user/my-sprites
```

## What It Does

1. **Scans** the given directory for image files (`.png`, `.bmp`, `.jpg`, `.jpeg`)
2. **Sorts** them alphabetically by filename
3. **Packs** up to 30 images per `.dset` file (matching DRAW's `DRAWER_SLOT_COUNT`)
4. **Names** the output after the folder:
   - 30 or fewer images → `foldername.dset`
   - More than 30 → `foldername1.dset`, `foldername2.dset`, `foldername3.dset`, etc.
5. **Outputs** the `.dset` file(s) into the same directory as the source images

## .dset File Format

The `.dset` format is a binary file that stores images inline — no references to files on disk. The format is:

### Header (10 bytes)

| Field | Type | Size | Value |
|---|---|---|---|
| Magic | `STRING * 4` | 4 bytes | `"DST1"` |
| Version | `INTEGER` | 2 bytes | `1` |
| Mode | `INTEGER` | 2 bytes | `1`=Brush, `2`=Pattern, `3`=Gradient |
| Selected Slot | `INTEGER` | 2 bytes | Default selected slot (1-based) |

### Slots (30 entries)

Each slot is:

| Field | Type | Size | Description |
|---|---|---|---|
| hasImage | `INTEGER` | 2 bytes | `TRUE` (-1) if slot has an image, `FALSE` (0) if empty |

If `hasImage` is `TRUE`:

| Field | Type | Size | Description |
|---|---|---|---|
| width | `INTEGER` | 2 bytes | Image width in pixels |
| height | `INTEGER` | 2 bytes | Image height in pixels |
| pixels | `_UNSIGNED LONG` × (w×h) | 4 bytes each | Raw BGRA pixel data, row by row |

Empty slots after the last image are written as `hasImage = FALSE` (2 bytes each).

## Using .dset Files in DRAW

### Loading manually

In DRAW, right-click on the drawer panel and select **LOAD DRAWER SET (.dset)** to import a set via file dialog.

### Loading on startup via DRAW.cfg

Add any of these lines to `DRAW.cfg` to auto-load drawer sets on startup:

```ini
DEFAULT_DSET_BRUSHES_FILE=brush-set.dset
DEFAULT_DSET_PATTERNS_FILE=my-patterns.dset
DEFAULT_DSET_GRADIENTS_FILE=my-gradients.dset
```

Paths can be absolute or relative (resolved from the directory DRAW is launched from). Empty value = use built-in theme samples.

## Notes

- MAKE-DSET creates sets in whichever mode you specify with `-b` (brush, default), `-p` (pattern), or `-g` (gradient). The mode is stored in the .dset header and DRAW's import honors it, loading into the correct drawer panel.
- Images of any size are supported. DRAW's drawer panel will scale them to fit the slot display.
- The pixel data is uncompressed — a 16×16 sprite uses 1,024 bytes per slot. A full 30-slot set of 16×16 images is roughly 31 KB.
- The utility skips files it can't load (unsupported format, corrupted) and writes an empty slot instead.
