#!/bin/bash
# Install DRAW for Linux (desktop launcher + .draw file association)
# Usage: ./install-linux.sh
#   Run again to update. Run with --uninstall to remove.

set -e

DRAW_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP_FILE="$HOME/.local/share/applications/DRAW.desktop"
MIME_DIR="$HOME/.local/share/mime"
ICON_DIR="$HOME/.local/share/icons/hicolor"

if [ "$1" = "--uninstall" ]; then
    echo "Uninstalling DRAW..."
    rm -f "$DESKTOP_FILE"
    rm -f "$MIME_DIR/packages/draw-project.xml"
    for size in 16 32 48 64 128 256; do
        rm -f "$ICON_DIR/${size}x${size}/apps/draw.png"
        rm -f "$ICON_DIR/${size}x${size}/mimetypes/application-x-draw-project.png"
    done
    [ -x "$(command -v update-mime-database)" ] && update-mime-database "$MIME_DIR" 2>/dev/null || true
    [ -x "$(command -v update-desktop-database)" ] && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    [ -x "$(command -v gtk-update-icon-cache)" ] && gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
    echo "Done. DRAW has been uninstalled."
    exit 0
fi

echo "Installing DRAW from: $DRAW_DIR"

# --- Desktop launcher ---
mkdir -p "$HOME/.local/share/applications"
sed "s|DRAW_INSTALL_PATH|$DRAW_DIR|g" "$DRAW_DIR/DRAW.desktop" > "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"
echo "  Desktop launcher: $DESKTOP_FILE"

# --- MIME type for .draw files ---
mkdir -p "$MIME_DIR/packages"
cp "$DRAW_DIR/draw-project.xml" "$MIME_DIR/packages/draw-project.xml"
echo "  MIME type: application/x-draw-project (.draw)"

# --- Icons (app + mime type) ---
for size in 16 32 48 64 128 256; do
    src="$DRAW_DIR/ASSETS/ICONS/icon-${size}.png"
    if [ -f "$src" ]; then
        # App icon
        mkdir -p "$ICON_DIR/${size}x${size}/apps"
        cp "$src" "$ICON_DIR/${size}x${size}/apps/draw.png"
        # MIME type icon (so .draw files show the DRAW icon)
        mkdir -p "$ICON_DIR/${size}x${size}/mimetypes"
        cp "$src" "$ICON_DIR/${size}x${size}/mimetypes/application-x-draw-project.png"
    fi
done
echo "  Icons installed to: $ICON_DIR"

# --- Update databases ---
if command -v update-mime-database &>/dev/null; then
    update-mime-database "$MIME_DIR" 2>/dev/null
    echo "  MIME database updated"
fi
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
    echo "  Desktop database updated"
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
    echo "  Icon cache updated"
fi

echo ""
echo "Done! DRAW is now installed:"
echo "  - Application appears in your desktop menu"
echo "  - .draw files are associated with DRAW"
echo "  - .draw files show the DRAW icon in file managers"
echo ""
echo "To uninstall: $0 --uninstall"
