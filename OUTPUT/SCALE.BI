''
' DRAW - OUTPUT/SCALE.BI
' =============================================================================
' Unified UI scale model.
'
' One master scale (CFG.UI_SCALE%, or the auto-detected display scale) drives
' the whole UI. Every widget's effective integer scale is resolved from that
' master times a per-widget ratio (CFG.SCALE_RATIO_*), clamped to a sane range.
' A legacy absolute *_SCALE field set > 0 overrides its widget's ratio.
'
' Subsystems READ the resolved values from the USCALE singleton below; they
' must never recompute scale from CFG ratios themselves. SCALE_resolve_all (in
' SCALE.BM) recomputes the whole struct and is called from SCREEN_init and on
' every runtime scale change.
'
' The singleton is named USCALE (not SCALE) on purpose: "scale" is used as a
' local variable name (scale%) throughout the codebase, and a global named SCALE
' collides with it ("Invalid expression" at compile time).
'
' NOTE: this .BI must be included BEFORE OUTPUT/SCREEN.BI in _ALL.BI, because
' SCREEN_init runs at include time and calls SCALE_resolve_all — the DIM SHARED
' below must already exist by then. It declares state only (no init call), so
' early inclusion is safe.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SCALE_OBJ
    canvas        AS INTEGER ' canvas / window magnification (== SCRN.displayScale%)
    toolbar       AS INTEGER ' toolbar icons / buttons
    organizer     AS INTEGER ' organizer strip
    drawer        AS INTEGER ' drawer bins
    flyout        AS INTEGER ' subtool flyout
    tooltip       AS INTEGER ' tooltips
    preview       AS INTEGER ' preview window chrome
    mixer         AS INTEGER ' color mixer chrome
    dialog        AS INTEGER ' generic modal dialog chrome
    about         AS INTEGER ' about dialog
    palettePicker AS INTEGER ' palette picker dialog
    fdFont        AS INTEGER ' modal file dialog font
    fdIcon        AS INTEGER ' modal file dialog icons
    colorPick     AS INTEGER ' color picker dialog
    msgBox        AS INTEGER ' message box dialog
    inputBox      AS INTEGER ' input box dialog
    browser       AS INTEGER ' docked browser render scale
    browserFont   AS INTEGER ' docked browser font
    browserIcon   AS INTEGER ' docked browser icons
END TYPE

DIM SHARED USCALE AS SCALE_OBJ
