#!/bin/bash
# =============================================================================
# run-scene.sh - builds one animated example scene IN DRAW (not a test: a
# QA-harness script, so it runs offscreen under Xvfb on the pinned QA config).
# DEV/animscenes/build.sh copies it into QA/tests for the run and removes it.
#
#   ANS_NAME=beach ANS_DIR=/abs/build/beach FW=160 FH=120 \
#   ./QA/draw-qa.sh --rerun-passed tests/zz-animscene.sh
#
# Sound is off (ANIM_SOUND_VOLUME=0): a dropped soundtrack is never heard.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 TOOLTIPS_DISABLED=TRUE ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW ANIM_SOUND_VOLUME=0
# QA-TIMEOUT: 2700
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/DEV/animscenes/drive-lib.sh"
: "${ANS_NAME:?}"; : "${ANS_DIR:?}"; FW=${FW:-160}; FH=${FH:-120}
info "=== building scene $ANS_NAME in DRAW ==="
source "$DRAW_ROOT/DEV/animscenes/scenes/$ANS_NAME.sh"
park_mouse
