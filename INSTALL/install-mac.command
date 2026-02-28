#!/bin/bash
# Install DRAW for macOS
# Downloads the latest release from GitHub and extracts it to ~/Applications/DRAW/.
# Usage: Double-click install-mac.command in Finder, or run from Terminal
#   Run again to update to the latest release.
#   Run with --uninstall to remove.

set -e

INSTALL_DIR="$HOME/Applications/DRAW"
GITHUB_REPO="grymmjack/DRAW"
ARCHIVE_NAME="DRAW-osx-x64.tar.gz"

if [ "$1" = "--uninstall" ]; then
    echo "Uninstalling DRAW..."
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "Removed: $INSTALL_DIR"
    else
        echo "Nothing to remove ($INSTALL_DIR not found)."
    fi
    echo "Done."
    exit 0
fi

# --- Locate curl or wget ---
if command -v curl &>/dev/null; then
    FETCH_CMD="curl -fsSL"
elif command -v wget &>/dev/null; then
    FETCH_CMD="wget -qO-"
else
    echo "ERROR: curl or wget is required. Install one and try again."
    exit 1
fi

# --- Resolve latest release tag via GitHub API ---
echo "Checking latest release..."
LATEST_TAG=$($FETCH_CMD "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "ERROR: Could not determine latest release. Check your internet connection."
    exit 1
fi
echo "  Latest release: $LATEST_TAG"

DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_TAG/$ARCHIVE_NAME"
TMPFILE="$(mktemp /tmp/DRAW_macos_XXXXXX.tar.gz)"

# --- Download ---
echo "Downloading $ARCHIVE_NAME..."
if command -v curl &>/dev/null; then
    curl -fL --progress-bar -o "$TMPFILE" "$DOWNLOAD_URL"
else
    wget --show-progress -O "$TMPFILE" "$DOWNLOAD_URL"
fi

# --- Extract ---
echo "Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMPFILE" -C "$INSTALL_DIR" --strip-components=1
rm -f "$TMPFILE"

# Make the binary executable
chmod +x "$INSTALL_DIR/DRAW.run" 2>/dev/null || true
chmod +x "$INSTALL_DIR/DRAW"     2>/dev/null || true

echo
echo "Done! DRAW $LATEST_TAG is installed:"
echo "  Location : $INSTALL_DIR"
echo "  To run   : open $INSTALL_DIR/DRAW.run   (or double-click in Finder)"
echo
echo "To update  : run this script again"
echo "To uninstall: $0 --uninstall"