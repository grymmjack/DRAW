#!/bin/bash
# =============================================================================
# anim-new-animation.sh — QA test: File > New Animation, and the build's git
# info after the version (Rick 2026-11-09, field kit T-3: "we could add FILE ->
# NEW ANIMATION - and let it pick the frame size"; "for interim not official
# release builds, i'd like to have in the about box (parenthesis) for the git
# hash and branch ... same for title bar ... same with --version or -v").
#
# New Animation asks for "WxH frames" (optional "@FPS") and makes a new
# document: a sheet of that many blank frames, as square as it fits (6 frames
# -> 3 x 2), at that FPS, with a fresh history (Ctrl+Z has nothing to undo).
# It is on the FILE menu and in the command palette. The old build had no such
# command.
#
# Version: an interim build (HEAD not on a v* tag) shows "X.Y.Z (sha branch)"
# from --version / -v and in the title bar; a release build the bare version.
#
# Dump: ANIM active count current frameW frameH gutter margin cols rows fps ...
# canvasW canvasH; ANIMMENUX id:checked:enabled.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== File > New Animation, and the build's version info ==="

NA_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
na_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
na_anim() { na_settle; read -r _ A_ON A_COUNT A_CUR A_FW A_FH _ _ A_COLS A_ROWS A_FPS _ _ _ _ A_CW A_CH _ <<< "$(grep -m1 '^ANIM ' "$NA_DUMP" 2>/dev/null)"; }
na_s() { echo "active ${A_ON:-?} frames ${A_COUNT:-?} cur ${A_CUR:-?} frame ${A_FW:-?}x${A_FH:-?} grid ${A_COLS:-?}x${A_ROWS:-?} fps ${A_FPS:-?} canvas ${A_CW:-?}x${A_CH:-?}"; }
na_palette() { park_mouse; key question; wait_for 1.0 "Command palette"; type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.2 "$1"; }

# -- the version: (sha branch) on an interim build --
NA_VER=$("$DRAW_BIN" --version 2>/dev/null | tr -d '\r' | head -1)
NA_V=$("$DRAW_BIN" -v 2>/dev/null | tr -d '\r' | head -1)
NA_SHA=$(git -C "$DRAW_ROOT" rev-parse --short=8 HEAD 2>/dev/null)
NA_BRANCH=$(git -C "$DRAW_ROOT" symbolic-ref --short -q HEAD 2>/dev/null)
NA_INFO=""
if git -C "$DRAW_ROOT" tag --points-at HEAD 2>/dev/null | grep -qE '^v[0-9]'; then
    [[ "$NA_VER" =~ ^DRAW\ [0-9.]+$ ]] && pass "--version on a release build: the bare version ($NA_VER)" || fail "--version on a release build: '$NA_VER'"
elif [[ "$NA_VER" =~ ^DRAW\ [0-9.]+\ \(([0-9a-f]{7,})\ (.+)\)$ ]]; then
    NA_INFO="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    # the binary may be a commit or two behind HEAD; the branch must match
    [[ -z "$NA_BRANCH" || "${BASH_REMATCH[2]}" == "$NA_BRANCH" ]] \
        && pass "--version on an interim build: '$NA_VER' (HEAD $NA_SHA $NA_BRANCH)" || fail "--version branch: '$NA_VER', HEAD on $NA_BRANCH"
else
    fail "--version on an interim build: '$NA_VER', wanted 'DRAW X.Y.Z (sha branch)'"
fi
[[ -n "$NA_VER" && "$NA_V" == "$NA_VER" ]] && pass "-v prints the same: '$NA_V'" || fail "-v: '$NA_V', --version: '$NA_VER'"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 1.0 "DRAW up"
assert_no_crash
if [[ -n "$NA_INFO" ]]; then
    assert_window_title "($NA_INFO)"
fi

# -- File > New Animation: 6 frames of 16x16 at 12 FPS --
na_anim
[[ "$A_ON" == 0 ]] || info "(started with frames: $(na_s))"
na_palette "new animation"
type_text "16x16 6 @12"; wait_for 0.3 "typed"
key Return; wait_for 1.2 "New Animation"
na_anim
if [[ "$A_ON" == -1 && "$A_COUNT" == 6 && "$A_CUR" == 1 && "$A_FW" == 16 && "$A_FH" == 16 && "$A_COLS" == 3 && "$A_ROWS" == 2 && "$A_FPS" == 12 && "$A_CW" == 48 && "$A_CH" == 32 ]]; then
    pass "New Animation '16x16 6 @12': 6 frames of 16x16 on a 48x32 sheet (3 x 2), 12 FPS, frame 1 current"
else
    fail "New Animation '16x16 6 @12': $(na_s)"
fi
park_mouse; key ctrl+z; wait_for 0.6 "Ctrl+Z"
na_anim
[[ "$A_ON" == -1 && "$A_COUNT" == 6 && "$A_CW" == 48 ]] && pass "a fresh history: Ctrl+Z leaves the new animation as it is" || fail "Ctrl+Z after New Animation: $(na_s)"

# -- FILE menu entry (ANIMMENUX lists the ANIM-range ids, 2562 included) --
na_settle
[[ " $(grep -m1 '^ANIMMENUX' "$NA_DUMP" 2>/dev/null) " == *" 2562:0:-1 "* ]] && pass "FILE > NEW ANIMATION... in the menu, enabled" || fail "no enabled New Animation menu item: $(grep -m1 '^ANIMMENUX' "$NA_DUMP")"

# -- the default is remembered; no frame count = 1 frame --
na_palette "new animation"
type_text "24x20"; wait_for 0.3 "typed"
key Return; wait_for 1.2 "New Animation"
na_anim
[[ "$A_ON" == -1 && "$A_COUNT" == 1 && "$A_FW" == 24 && "$A_FH" == 20 && "$A_CW" == 24 && "$A_CH" == 20 ]] \
    && pass "New Animation '24x20': one frame of 24x20" || fail "New Animation '24x20': $(na_s)"
screenshot "anim-new-animation"
assert_no_crash

draw_quit
draw_settle
draw_launch 15
assert_window_exists
