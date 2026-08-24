#!/bin/bash
# Generate all platform icons from icon.svg (developer tool)
# Requires: imagemagick, icnsutils, icoutils
#
# Generates:
#   icon-1024.png          High-res master raster
#   icon-{16..512}.png     Linux sized PNGs + runtime icon
#   icon.png               256px copy for QB64PE _LOADIMAGE
#   icon.ico               Windows multi-res ICO (16-256px)
#   icon.icns              macOS ICNS (16-512px + @2x retina)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SVG="icon.svg"

# --- Preflight checks ---
if [ ! -f "$SVG" ]; then
    echo "ERROR: $SVG not found in $SCRIPT_DIR"
    exit 1
fi

missing=""
command -v convert  >/dev/null 2>&1 || missing="$missing imagemagick"
command -v png2icns >/dev/null 2>&1 || command -v iconutil >/dev/null 2>&1 || missing="$missing icnsutils"
command -v icotool  >/dev/null 2>&1 || missing="$missing icoutils"

if [ -n "$missing" ]; then
    echo "ERROR: Missing required packages:$missing"
    echo "Install with:  sudo apt install$missing"
    exit 1
fi

echo "Generating icons from $SVG ..."

# --- Master 1024px raster from SVG ---
echo "  icon-1024.png (master raster)"
convert -background none -density 384 "$SVG" -resize 1024x1024 icon-1024.png

# --- Linux sized PNGs ---
for size in 16 32 48 64 128 256 512; do
    echo "  icon-${size}.png"
    convert icon-1024.png -resize ${size}x${size} icon-${size}.png
done

# --- QB64PE runtime icon (256px) ---
echo "  icon.png (runtime)"
cp icon-256.png icon.png

# --- Windows ICO ---
echo "  icon.ico"
convert icon-1024.png \
    -define icon:auto-resize=256,128,64,48,32,16 \
    icon.ico

# --- macOS ICNS (rounded squircle, native format) ---
# macOS renders the .icns AS-IS (no auto-rounding), so we bake in the rounded-rect
# "squircle" corners here — otherwise a full-bleed square looks unlike native icons
# (the "gray background / not edge to edge" complaint). We also build a modern
# multi-size icns: on macOS via the native `iconutil` (produces the Retina types
# ic10-ic14 Big Sur expects); on Linux we fall back to png2icns, which emits only the
# LEGACY types — so build the shipping icon.icns on a Mac (or keep the committed one).
echo "  icon-macos-1024.png (rounded master)"
convert -size 1024x1024 xc:none -fill white \
    -draw "roundrectangle 0,0,1023,1023,224,224" _rounded_mask.png
convert icon-1024.png _rounded_mask.png -compose DstIn -composite icon-macos-1024.png
rm -f _rounded_mask.png

echo "  icon.icns"
rm -rf icon.iconset
mkdir icon.iconset
# Apple iconset names: <base> and <base>@2x, base sizes 16/32/128/256/512.
_gen() { convert icon-macos-1024.png -resize "${1}x${1}" "icon.iconset/${2}"; }
_gen 16   icon_16x16.png;    _gen 32   icon_16x16@2x.png
_gen 32   icon_32x32.png;    _gen 64   icon_32x32@2x.png
_gen 128  icon_128x128.png;  _gen 256  icon_128x128@2x.png
_gen 256  icon_256x256.png;  _gen 512  icon_256x256@2x.png
_gen 512  icon_512x512.png;  _gen 1024 icon_512x512@2x.png
if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns icon.iconset -o icon.icns
else
    echo "    (no iconutil — using png2icns; icon.icns will lack Retina sizes."
    echo "     Rebuild it on macOS with: iconutil -c icns icon.iconset -o icon.icns)"
    png2icns icon.icns icon.iconset/*.png
fi
rm -rf icon.iconset

echo ""
echo "Done! Generated all platform icons."
