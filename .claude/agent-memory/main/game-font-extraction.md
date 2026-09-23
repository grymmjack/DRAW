---
name: game-font-extraction
description: Where the DOOM/Heretic/Hexen/Blood CBF fonts came from and the format traps hit extracting them (WAD patches, Blood RFF/QFN)
metadata:
  type: project
---

2026-09-23: 19 CBF fonts (DOOM*, HERETIC*, HEXEN*, BLOOD*) in `ASSETS/FONTS/COLOR_BITMAP/` were extracted
directly from game data, not screenshots (see [[create-color-bitmap-font-from-image]] skill).

- IWADs live in the user's Dropbox: `~/Dropbox/DOOM Maps/gzdoom/` (doom.wad, DOOM2.WAD, HERETIC.WAD, HEXEN.WAD).
  DOOM and DOOM II font lumps are byte-identical — one `DOOM` font covers both.
- Lumps: Doom `STCFN033..095` + `STCFN121` (which is really `|`); number sets STTNUM/WINUM/STYSNUM/STGNUM.
  Heretic/Hexen `FONTA`/`FONTAY`/`FONTB` start at `!`; FONTB unused slots are 2x1 dot stubs, FONTA `& < >`
  are solid blocks, FONTA59 (`[` slot) is really `_`. Patch placement = y - topoffset, x - leftoffset.
- Blood: the user did not own it; used shareware v1.11 from archive.org item `blood.exe` → `emulated.zip`
  (pre-installed; the other items ship only the DOS `SHARE.SHR` installer archive). Shareware `SHARE000.ART`
  has NO font tiles (stops at 3965) — the fonts are the five `.QFN` files inside `BLOOD.RFF` (RFF v3 dict is
  XOR-encrypted, key = offset + (ver&0xff)*offset; QFN glyph data is column-major, 255 = transparent).
  Layout per NBlood `view.cpp` FontSet/viewDrawText. FONTSMAL.QFN skipped (single colour).

**Why:** re-extraction or adding more game fonts should reuse the lump-level route, not screenshot fitting.
**How to apply:** CBF glyphs need width >= 2 (adjacent markers merge); fill gaps with blank glyphs to keep
positional ASCII order.

2026-09-23 round 2: +93 fonts from the user's Steam installs
(`~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/`, Flatpak Steam) [Linux]:
Quake/Q2 (conchars + num/anum), Doom 64 (SFONT, SYMBOLS via Doom64EX symboldata), Strife (+SVE), Doom &
Heretic/Hexen KEX `Common.kpf` fonts (-EX), Duke3D/SW/RR tile fonts (verified vs jfduke3d/jfsw/NBlood rr),
retail Blood tile fonts 4096-4575 (retail has NO QFN; replaced BLOOD/BLOOD-GOTHIC with retail builds),
Dark Forces FNT+LFD (TheForceEngine), Daggerfall FNT (daggerfall-unity colours), Outlaws .LAF (format
inferred from ScummVM Grim LAF reader — colours UNVERIFIED). PowerSlave Exhumed install is KEX-only (no DOS data).
KEX-CONSOLE (confont.tga) is byte-identical in every KEX .kpf — ship once.

2026-09-23 round 3: +466 fonts → 622 CBFs in COLOR_BITMAP/ (then sorted into subfolders — see below).
- 448 from github.com/ianhan/BitmapFonts (Amiga demoscene sheets, no metadata; 24 of DRAW's older CBFs — xenon2,
  lem*, mario3 … — already came from this repo). Converted with a spec-driven sheet tool (cell/pitch/order/blank/
  erase/parts). Traps: pick bg from the sheet BORDER, not whole-image majority (heavy fills outnumber bg);
  NAOS-family sheets use a 47px pitch with 31px cells, not 48 (drift clips later columns).
- 18 DP-* from Deluxe Paint IV/V + DPaint Colour Fonts ADFs (oldfag.top id=1566): real Amiga ColorTextFonts,
  decoded via AROS text.h/diskfont.h + HUNK_RELOC32; advance = CharKern + CharSpace.
- New sheets saved as 8-bit palettised BMP (lossless; loader does _LOADIMAGE(,32)) — 69 MB → 24 MB.
  Loading all 622 sheets takes ~0.14 s [Linux], so scan cost is not a concern.

2026-09-23 sort: COLOR_BITMAP/ split into DOS GAMES (87), DEMO RIPS (394), DELUXE PAINT (16, colour DP-* only),
MONOCHROME (109, any 1-colour sheet incl. DP-DPAINT-5/8 and plain Apple ][ amber/green/white); 14 Apple ][
colour/CRT/SCAN stay at root. Removed exact dups 08X08-F3 (=08X08-F2) and PP_PURSY (=ST_PURSY) → 620 fonts.
Code: FONT_LIST_scan_nested_subfolders tags fonts in COLOR_BITMAP/<sub> as their own dropdown group
"COLOR_BITMAP/<sub>" (other nested dirs like BITMAP/FONTRAPTION still merge into the parent). Also applies to
the user-data FONTS/COLOR_BITMAP/<sub>. build_apple2_color.py --all now writes the mono variants to MONOCHROME/.

Later same day: subfolders renamed to GAMES / DEMOS / DPAINT / MONO (dropdown truncated the long names), and
FONT_LIST_build_display_list now sorts folder groups A-Z case-insensitively so COLOR_BITMAP/* sit together.
All 20 Apple ][ fonts (incl. the 6 mono phosphor ones) now live in COLOR_BITMAP/APPLE][/ — the generator writes there. MONO = 103.
Font dropdown (2026-09-23): FONT_LIST_build_display_list now emits a DRAW section (folders with any bundled
font A-Z, then favorites + bundled root fonts) then a USER section (user/OS folders, then their root fonts);
FONT_DD_USER_START marks the first USER row and TEXT_BAR draws a 2px full-width rule above it (no new row type,
so click/hover/nav code is untouched). Dotfile fonts/dirs are skipped everywhere (FONT_LIST_is_dotname%,
FONT_LIST_has_hidden_part% checks only BELOW the scan base — the user font dir itself is under ~/.local).
[Linux] GUI screenshots under Xvfb: brew ImageMagick has no X11 — use /usr/bin/import; xdotool clicks need
mousedown/sleep 0.15/mouseup or DRAW's per-frame poll misses them.
All 20 Apple ][ fonts moved from COLOR_BITMAP/APPLE][/ to COLOR_BITMAP/APPLE2/ (2026-09-23): the brackets broke the Windows CI packaging step (PowerShell Get-ChildItem treats [] as a wildcard). [Windows CI] Avoid [ ] in any bundled folder name.
