#!/usr/bin/env python3
"""
fix-font-metrics.py — Patch TTF/OTF fonts whose vertical metrics clip glyphs.

QB64-PE (SDL2_ttf / FreeType) clips glyphs that exceed the declared
ascent/descent metrics. Many free/pixel fonts have broken metrics where
glyph outlines extend beyond the declared ascent or descent, causing
the tops of capital letters or bottoms of descenders to be chopped off.

This tool:
  1. Scans fonts for glyphs that overflow the declared metrics
  2. Expands hhea.ascent/descent, OS/2 usWinAscent/usWinDescent,
     and OS/2 sTypoAscender/sTypoDescender to fit all glyphs
  3. Backs up originals to *.orig and saves patched fonts in-place

Usage:
  python3 fix-font-metrics.py [OPTIONS] [PATHS...]

  PATHS can be individual .ttf/.otf files or directories to scan.
  Default: ../ASSETS/FONTS

Options:
  --dry-run       Report issues without modifying files
  --no-backup     Don't create .orig backup files
  --padding N     Extra units above/below glyph bounds (default: 0)
  --verbose       Show per-glyph overflow details
  --force         Patch even if no clipping detected (re-sync all metrics)
  --help          Show this message

Examples:
  python3 fix-font-metrics.py --dry-run
  python3 fix-font-metrics.py ../ASSETS/FONTS/dp-tuxedo.ttf
  python3 fix-font-metrics.py --padding 32 ../ASSETS/FONTS
"""

import argparse
import os
import shutil
import sys

try:
    from fontTools.ttLib import TTFont
except ImportError:
    print("ERROR: fontTools is required. Install with: pip install fonttools", file=sys.stderr)
    sys.exit(1)


def analyze_font(path, padding=0, verbose=False):
    """Analyze a font and return dict of issues and proposed fixes."""
    try:
        font = TTFont(path)
    except Exception as e:
        return {"error": str(e)}

    head = font.get("head")
    hhea = font.get("hhea")
    os2 = font.get("OS/2")

    if not head or not hhea:
        return {"error": "Missing head or hhea table"}

    upm = head.unitsPerEm
    actual_ymax = head.yMax
    actual_ymin = head.yMin

    result = {
        "font": font,
        "path": path,
        "upm": upm,
        "actual_ymax": actual_ymax,
        "actual_ymin": actual_ymin,
        "changes": [],
        "needs_fix": False,
    }

    # --- hhea ascent/descent ---
    target_ascent = actual_ymax + padding
    target_descent = actual_ymin - padding  # negative value

    if hhea.ascent < target_ascent:
        result["changes"].append(
            f"  hhea.ascent: {hhea.ascent} -> {target_ascent} "
            f"(glyphs reach {actual_ymax}, was short by {target_ascent - hhea.ascent})"
        )
        result["fix_hhea_ascent"] = target_ascent
        result["needs_fix"] = True
    if hhea.descent > target_descent:
        result["changes"].append(
            f"  hhea.descent: {hhea.descent} -> {target_descent} "
            f"(glyphs reach {actual_ymin}, was short by {hhea.descent - target_descent})"
        )
        result["fix_hhea_descent"] = target_descent
        result["needs_fix"] = True

    # --- OS/2 usWinAscent/usWinDescent (unsigned, absolute values) ---
    if os2:
        target_win_ascent = actual_ymax + padding
        target_win_descent = abs(actual_ymin) + padding

        if os2.usWinAscent < target_win_ascent:
            result["changes"].append(
                f"  OS/2.usWinAscent: {os2.usWinAscent} -> {target_win_ascent}"
            )
            result["fix_usWinAscent"] = target_win_ascent
            result["needs_fix"] = True
        if os2.usWinDescent < target_win_descent:
            result["changes"].append(
                f"  OS/2.usWinDescent: {os2.usWinDescent} -> {target_win_descent}"
            )
            result["fix_usWinDescent"] = target_win_descent
            result["needs_fix"] = True

        # --- OS/2 sTypoAscender/sTypoDescender ---
        if os2.sTypoAscender < target_ascent:
            result["changes"].append(
                f"  OS/2.sTypoAscender: {os2.sTypoAscender} -> {target_ascent}"
            )
            result["fix_sTypoAscender"] = target_ascent
            result["needs_fix"] = True
        if os2.sTypoDescender > target_descent:
            result["changes"].append(
                f"  OS/2.sTypoDescender: {os2.sTypoDescender} -> {target_descent}"
            )
            result["fix_sTypoDescender"] = target_descent
            result["needs_fix"] = True

    # --- Verbose: show worst offending glyphs ---
    if verbose and result["needs_fix"]:
        glyf = font.get("glyf")
        cmap = font.getBestCmap()
        if glyf and cmap:
            overflow_glyphs = []
            for cp, gname in sorted(cmap.items()):
                try:
                    g = glyf[gname]
                    if g.numberOfContours == 0 or not hasattr(g, "yMax") or g.yMax is None:
                        continue
                    if g.yMax > hhea.ascent or g.yMin < hhea.descent:
                        ch = chr(cp) if 32 <= cp < 127 else f"U+{cp:04X}"
                        overflow_glyphs.append(
                            f"    {ch} ({gname}): yMin={g.yMin} yMax={g.yMax}"
                        )
                except Exception:
                    pass
            if overflow_glyphs:
                result["changes"].append("  Overflowing glyphs:")
                result["changes"].extend(overflow_glyphs[:20])
                if len(overflow_glyphs) > 20:
                    result["changes"].append(
                        f"    ... and {len(overflow_glyphs) - 20} more"
                    )

    return result


def apply_fix(result, backup=True):
    """Apply metric fixes to the font and save."""
    font = result["font"]
    path = result["path"]
    hhea = font["hhea"]
    os2 = font.get("OS/2")

    if "fix_hhea_ascent" in result:
        hhea.ascent = result["fix_hhea_ascent"]
    if "fix_hhea_descent" in result:
        hhea.descent = result["fix_hhea_descent"]

    if os2:
        if "fix_usWinAscent" in result:
            os2.usWinAscent = result["fix_usWinAscent"]
        if "fix_usWinDescent" in result:
            os2.usWinDescent = result["fix_usWinDescent"]
        if "fix_sTypoAscender" in result:
            os2.sTypoAscender = result["fix_sTypoAscender"]
        if "fix_sTypoDescender" in result:
            os2.sTypoDescender = result["fix_sTypoDescender"]

    if backup:
        backup_path = path + ".orig"
        if not os.path.exists(backup_path):
            shutil.copy2(path, backup_path)

    font.save(path)


def collect_fonts(paths):
    """Expand paths into list of .ttf/.otf files."""
    files = []
    for p in paths:
        if os.path.isfile(p):
            if p.lower().endswith((".ttf", ".otf")):
                files.append(p)
        elif os.path.isdir(p):
            for fn in sorted(os.listdir(p)):
                if fn.lower().endswith((".ttf", ".otf")):
                    files.append(os.path.join(p, fn))
    return files


def main():
    parser = argparse.ArgumentParser(
        description="Fix TTF/OTF font vertical metrics to prevent glyph clipping in QB64-PE / SDL2_ttf.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("paths", nargs="*", default=None, help="Font files or directories (default: ../ASSETS/FONTS)")
    parser.add_argument("--dry-run", action="store_true", help="Report without modifying")
    parser.add_argument("--no-backup", action="store_true", help="Don't create .orig backups")
    parser.add_argument("--padding", type=int, default=0, help="Extra units above/below bounds (default: 0)")
    parser.add_argument("--verbose", action="store_true", help="Show per-glyph details")
    parser.add_argument("--force", action="store_true", help="Patch even if no clipping detected")
    args = parser.parse_args()

    # Default path: ../ASSETS/FONTS relative to this script
    if not args.paths:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        default_dir = os.path.join(script_dir, "..", "ASSETS", "FONTS")
        if os.path.isdir(default_dir):
            args.paths = [default_dir]
        else:
            print("ERROR: No font paths specified and default ../ASSETS/FONTS not found.", file=sys.stderr)
            sys.exit(1)

    fonts = collect_fonts(args.paths)
    if not fonts:
        print("No .ttf/.otf files found in the specified paths.")
        sys.exit(0)

    fixed = 0
    skipped = 0
    errors = 0

    for fp in fonts:
        name = os.path.basename(fp)
        result = analyze_font(fp, padding=args.padding, verbose=args.verbose)

        if "error" in result:
            print(f"  ERR  {name}: {result['error']}")
            errors += 1
            continue

        if not result["needs_fix"]:
            if args.verbose:
                print(f"  OK   {name}")
            skipped += 1
            continue

        print(f"  FIX  {name}")
        for line in result["changes"]:
            print(line)

        if not args.dry_run:
            apply_fix(result, backup=not args.no_backup)
            fixed += 1
            print(f"       -> saved{' (backup: ' + name + '.orig)' if not args.no_backup else ''}")
        else:
            fixed += 1

    print()
    print(f"Summary: {fixed} fixed, {skipped} OK, {errors} errors  (total: {len(fonts)} fonts)")
    if args.dry_run and fixed > 0:
        print("(dry-run mode — no files were modified)")


if __name__ == "__main__":
    main()
