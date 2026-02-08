# DRAW v0.7.4 Release Notes

**Release Date:** February 8, 2026
**Previous Release:** v0.7.3 (February 8, 2026)

---

## Highlights

This release focuses on **OS integration and branding**: a new application icon across all
platforms, the `.draw` file extension replacing `.drw`, cross-platform installer scripts with
native file associations, and a dynamic window title bar showing the current file and unsaved
changes.

---

## New Features

### Application Icon

DRAW now has a proper application icon rendered from an SVG source at all standard sizes.

- **Windows**: Embedded in the `.exe` via `$EXEICON` metacommand; `.draw` files display the
  icon in Explorer after running the installer
- **macOS**: Bundled as `.icns` in the `.app` bundle; `.draw` files display the icon in Finder
- **Linux**: Installed into the hicolor icon theme at 16–256px for both the app launcher and
  `.draw` file MIME type
- **Runtime**: Window icon set via `_ICON` + `_LOADIMAGE` on all platforms (SDL2)

### Dynamic Window Title Bar

The window title now displays version, filename, and unsaved-changes state:

```
DRAW v0.7.4                     (no file open)
DRAW v0.7.4 - myart.draw        (clean)
DRAW v0.7.4 - myart.draw *      (unsaved changes)
```

- Updates efficiently — only calls `_TITLE` when dirty state or filename actually changes
- Works for both `.draw` project files and imported images

### Cross-Platform Installer Scripts

| Script | Platform | What It Does |
|--------|----------|--------------|
| `install-linux.sh` | Linux | Desktop launcher, MIME type registration, hicolor icons |
| `install-windows.cmd` | Windows | Registry file association, Explorer icon, Start Menu shortcut |
| `install-mac.command` | macOS | `.app` bundle in `~/Applications`, LaunchServices registration |

All installers support uninstall (`--uninstall` / `/uninstall`).

### `.draw` File Association

Each installer registers the `.draw` extension with the OS so that double-clicking a `.draw`
file opens it in DRAW. On Linux, a custom MIME type (`application/x-draw-project`) is
registered via `draw-project.xml`.

---

## Changes

### File Extension: `.drw` → `.draw`

The native project file extension has been renamed from `.drw` to `.draw` to avoid conflicts
with CorelDRAW's `.drw` format. All dialogs, filters, keyboard shortcut labels, command
palette entries, documentation, and sample files have been updated.

**Migration:** Rename existing `.drw` files to `.draw`. The binary format is unchanged.

### DRW Format v3: Palette Name Persistence

The native file format is now version 3. Projects now save the active palette name (as a
64-byte fixed string). On load, DRAW matches the saved name against available GPL palettes
and reloads the palette from the GPL file for accurate colors. Falls back to the
color values stored in the file if the palette is not found.

- v1 and v2 files continue to load without issue
- Palette strip scroll position is reset on load
- Palette loader color count is synced on load so the strip displays correctly

### Command Line File Opening

Opening a `.draw` file from the command line now correctly sets `CURRENT_DRW_FILENAME$` so
the title bar displays the filename immediately.

---

## Technical Details

### Icon Pipeline

A developer script (`ASSETS/ICONS/generate-icons.sh`) regenerates all platform icons from
`icon.svg`:

- `icon-{16..512}.png` — Linux sized PNGs
- `icon.png` — 256px runtime icon for `_LOADIMAGE`
- `icon.ico` — Windows multi-resolution ICO (16–256px)
- `icon.icns` — macOS ICNS with @2x retina variants

Requires `imagemagick`, `icnsutils`, and `icoutils`.

### GitHub Actions: macOS `.app` Bundle

The CI workflow now creates a full `.app` bundle for macOS releases with:
- `Info.plist` declaring `CFBundleDocumentTypes` and `UTExportedTypeDeclarations` for `.draw`
- Application icon (`icon.icns`)
- Bundled ASSETS directory

### Files Changed

| File | Changes |
|------|---------|
| `_COMMON.BI` | Added `APP_VERSION$` constant, title-tracking variables |
| `_COMMON.BM` | Added `TITLE_update` and `TITLE_check` subs |
| `DRAW.BAS` | `$EXEICON` metacommand, `TITLE_update`/`TITLE_check` calls, `.draw` extension handling, command-line filename tracking |
| `OUTPUT/SCREEN.BM` | Runtime `_ICON` loading in `SCREEN_init` |
| `TOOLS/DRW.BI` | Format version bumped to 3, `.draw` in comments |
| `TOOLS/DRW.BM` | v3 palette name save/load, `.draw` extension in dialogs/filters/messages, palette strip fixes |
| `GUI/COMMAND.BM` | Command labels updated to `.draw` |
| `INPUT/KEYBOARD.BM` | Comments updated to `.draw` |
| `.github/workflows/build-release.yml` | macOS `.app` bundle creation step |
| `ASSETS/ICONS/*` | New icon assets (SVG, PNG, ICO, ICNS) and generator script |
| `install-linux.sh` | New: desktop launcher + MIME + icons installer |
| `install-windows.cmd` | New: registry file association + Start Menu installer |
| `install-mac.command` | New: `.app` bundle + LaunchServices installer |
| `draw-project.xml` | New: Linux MIME type definition for `.draw` |
| `DRAW.desktop` | New: Linux desktop launcher template |
| `README.MD` | Installation section, `.drw` → `.draw` references |
| `CHEATSHEET.md` | `.drw` → `.draw` references |

---

## Breaking Changes

### File Extension Rename

The project file extension changed from `.drw` to `.draw`. Existing `.drw` files must be
renamed to `.draw` — the binary contents are identical and require no conversion.

### DRW Format Version

The format version is now 3 (was 2). DRAW v0.7.4 can still open v1 and v2 files. Files
saved by v0.7.4 cannot be opened by v0.7.3 or earlier.

---

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

Requires QB64-PE v3.12 or later.
