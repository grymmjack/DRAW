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
command -v png2icns >/dev/null 2>&1 || missing="$missing icnsutils"
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

# --- macOS ICNS ---
echo "  icon.icns"
rm -rf icon.iconset
mkdir icon.iconset
for size in 16 32 128 256 512; do
    convert icon-1024.png -resize ${size}x${size} \
        icon.iconset/icon_${size}x${size}.png
    double=$((size * 2))
    convert icon-1024.png -resize ${double}x${double} \
        icon.iconset/icon_${size}x${size}@2x.png
done
png2icns icon.icns icon.iconset/icon_*.png
rm -rf icon.iconset

echo ""
echo "Done! Generated all platform icons."
