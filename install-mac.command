#!/bin/bash
# Install DRAW for macOS (.app bundle + file association)
# Usage: Double-click install-mac.command in Finder, or run from Terminal
#   Run again to update. Run with --uninstall to remove.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="DRAW"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
BUNDLE_ID="com.grymmjack.draw"

if [ "$1" = "--uninstall" ]; then
    echo "Uninstalling DRAW..."
    rm -rf "$APP_BUNDLE"
    # Remove LaunchServices registration
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -u "$APP_BUNDLE" 2>/dev/null || true
    echo "Done. DRAW has been uninstalled."
    exit 0
fi

echo "Installing DRAW from: $SCRIPT_DIR"
echo

# --- Find the DRAW executable ---
DRAW_BIN=""
if [ -f "$SCRIPT_DIR/DRAW" ]; then
    DRAW_BIN="$SCRIPT_DIR/DRAW"
elif [ -f "$SCRIPT_DIR/DRAW.run" ]; then
    DRAW_BIN="$SCRIPT_DIR/DRAW.run"
else
    echo "ERROR: No DRAW executable found. Build the project first."
    echo "  Expected: DRAW or DRAW.run in $SCRIPT_DIR"
    exit 1
fi

# --- Create .app bundle as AppleScript applet ---
# AppleScript applets natively handle macOS Apple Events (kAEOpenDocuments),
# which is how Finder sends file-open requests when double-clicking .draw files.
# A plain bash launcher can't receive these events.
echo "  Creating $APP_NAME.app bundle (AppleScript applet)..."

# Remove old bundle if exists (osacompile needs a clean target)
rm -rf "$APP_BUNDLE"
mkdir -p "$(dirname "$APP_BUNDLE")"

# Write AppleScript source
ASCRIPT_SRC="$(mktemp /tmp/DRAW_launcher.XXXXXX.applescript)"
cat > "$ASCRIPT_SRC" << 'APPLESCRIPT'
on run
    set myDir to POSIX path of (path to me)
    set resDir to myDir & "Contents/Resources/"
    set binPath to myDir & "Contents/MacOS/DRAW.bin"
    do shell script "cd " & quoted form of resDir & " && " & quoted form of binPath & " > /dev/null 2>&1 &"
end run

on open theFiles
    set filePath to POSIX path of (item 1 of theFiles)
    set myDir to POSIX path of (path to me)
    set resDir to myDir & "Contents/Resources/"
    set binPath to myDir & "Contents/MacOS/DRAW.bin"
    do shell script "cd " & quoted form of resDir & " && DRAW_OPEN_FILE=" & quoted form of filePath & " " & quoted form of binPath & " > /dev/null 2>&1 &"
end open
APPLESCRIPT

# Compile into a proper AppleScript applet (.app bundle with Apple Event handling)
osacompile -o "$APP_BUNDLE" "$ASCRIPT_SRC"
rm -f "$ASCRIPT_SRC"

# --- Add DRAW binary and resources ---
echo "  Copying DRAW binary and resources..."

# Copy QB64-PE executable into the applet bundle
cp "$DRAW_BIN" "$APP_BUNDLE/Contents/MacOS/DRAW.bin"
chmod +x "$APP_BUNDLE/Contents/MacOS/DRAW.bin"

# Copy icon (replace default applet icon)
if [ -f "$SCRIPT_DIR/ASSETS/ICONS/icon.icns" ]; then
    cp "$SCRIPT_DIR/ASSETS/ICONS/icon.icns" "$APP_BUNDLE/Contents/Resources/icon.icns"
    # Also replace the default applet icon
    cp "$SCRIPT_DIR/ASSETS/ICONS/icon.icns" "$APP_BUNDLE/Contents/Resources/applet.icns"
fi

# Copy assets (needed at runtime)
if [ -d "$SCRIPT_DIR/ASSETS" ]; then
    cp -R "$SCRIPT_DIR/ASSETS" "$APP_BUNDLE/Contents/Resources/ASSETS"
fi

# Copy sample files
for f in "$SCRIPT_DIR"/*.draw; do
    [ -f "$f" ] && cp "$f" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
done

# --- Replace Info.plist with our custom one ---
# osacompile generates a basic plist; we need document type + UTI declarations
echo "  Configuring Info.plist with .draw file association..."
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>droplet</string>
    <key>CFBundleIdentifier</key>
    <string>com.grymmjack.draw</string>
    <key>CFBundleName</key>
    <string>DRAW</string>
    <key>CFBundleDisplayName</key>
    <string>DRAW</string>
    <key>CFBundleVersion</key>
    <string>0.7.5</string>
    <key>CFBundleShortVersionString</key>
    <string>0.7.5</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>DRAW</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleScriptEnabled</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>DRAW Project</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeIconFile</key>
            <string>icon</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>draw</string>
            </array>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.grymmjack.draw-project</string>
            </array>
        </dict>
    </array>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.grymmjack.draw-project</string>
            <key>UTTypeDescription</key>
            <string>DRAW Project File</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.data</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>draw</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
PLIST

# --- Register with LaunchServices ---
echo "  Registering file associations..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$APP_BUNDLE" 2>/dev/null || true

echo
echo "Done! DRAW is now installed:"
echo "  - App bundle: $APP_BUNDLE"
echo "  - .draw files are associated with DRAW"
echo "  - .draw files show the DRAW icon in Finder"
echo
echo "To uninstall: $0 --uninstall"
