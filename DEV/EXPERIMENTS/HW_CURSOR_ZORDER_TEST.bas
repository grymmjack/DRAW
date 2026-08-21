' ============================================================================
' HW_CURSOR_ZORDER_TEST.bas
' ----------------------------------------------------------------------------
' PURPOSE: Empirically prove three claims about the OS hardware cursor
' (_MOUSECURSOR -> glfwCreateCursor/glfwSetCursor, QB64-PE GLFW build PR #701)
' BEFORE we refactor DRAW to lean on it:
'
'   CLAIM 1 (Z-ORDER): the OS cursor is composited ABOVE the entire QB64-PE
'           framebuffer -- above BOTH the software SCREEN surface AND a
'           hardware image (_COPYIMAGE ,33 / _PUTIMAGE). It is NOT one of the
'           _DISPLAYORDER layers (_SOFTWARE/_HARDWARE/_HARDWARE1/_GLRENDER);
'           it is the operating system's own cursor plane.
'
'   CLAIM 2 (NO REDRAW): moving the cursor needs ZERO render work from us. We
'           can FREEZE our render loop entirely (stop drawing, stop _DISPLAY)
'           and the cursor still glides over the last presented frame, because
'           the compositor -- not QB64-PE -- moves it. A render counter proves
'           we never repaint while the cursor moves.
'
'   CLAIM 3 (INDEPENDENT / UNLIMITED): the OS cursor does not consume a
'           QB64-PE hardware-image slot. Hardware images keep rendering
'           normally with the custom cursor installed.
'
' METHOD: draw a static scene (software gradient + a HARDWARE-image panel laid
' on top so their overlap is visible), install a distinctive custom cursor,
' then let the user FREEZE rendering with SPACE. While frozen, renderCount and
' displayCount stop advancing; the cursor keeps moving. Hover the software/
' hardware boundary to see the cursor ride OVER the hardware panel.
'
' BUILD (must use the GLFW PR #701 compiler -- v450 lacks _MOUSECURSOR):
'   ~/git/qb64pe-a740g-test/qb64pe -w -x -o DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST \
'       DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST.bas
'   ./DEV/EXPERIMENTS/HW_CURSOR_ZORDER_TEST
'
' Writes HW_CURSOR_ZORDER_TEST-log.txt with the run facts.
' ============================================================================
$CONSOLE
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0

CONST SCRW = 820, SCRH = 520

SCREEN _NEWIMAGE(SCRW, SCRH, 32)
_TITLE "HW Cursor Z-Order / Freeze Test (PR #701)"

' --- Build a distinctive custom cursor: magenta diamond + yellow center dot.
' Deliberately larger than a stock arrow so it is unmistakable which pointer is
' active and easy to see riding over the hardware panel. Hotspot = center.
DIM cur AS LONG, oldDest AS LONG
cur = _NEWIMAGE(28, 28, 32)
oldDest = _DEST
_DEST cur
CLS , _RGBA32(0, 0, 0, 0)
LINE (14, 1)-(27, 14), _RGB32(255, 0, 255)
LINE (27, 14)-(14, 27), _RGB32(255, 0, 255)
LINE (14, 27)-(1, 14), _RGB32(255, 0, 255)
LINE (1, 14)-(14, 1), _RGB32(255, 0, 255)
LINE (14, 6)-(14, 22), _RGB32(255, 255, 0)
LINE (6, 14)-(22, 14), _RGB32(255, 255, 0)
CIRCLE (14, 14), 2, _RGB32(255, 255, 0)
PAINT (14, 14), _RGB32(255, 255, 0), _RGB32(255, 255, 0)
_DEST oldDest

' --- Build the HARDWARE panel: a checkerboard we can clearly recognize, then
' promote it to a hardware image via _COPYIMAGE(handle, 33). This is the
' _HARDWARE layer in _DISPLAYORDER's default (_SOFTWARE, _HARDWARE, _GLRENDER,
' _HARDWARE1) -- i.e. it renders ON TOP of the software surface already.
CONST PANW = 320, PANH = 220
DIM panelSrc AS LONG, hwPanel AS LONG
panelSrc = _NEWIMAGE(PANW, PANH, 32)
_DEST panelSrc
DIM bx AS INTEGER, by AS INTEGER, c AS _UNSIGNED LONG
FOR by = 0 TO PANH - 1 STEP 20
    FOR bx = 0 TO PANW - 1 STEP 20
        IF ((bx \ 20) + (by \ 20)) MOD 2 = 0 THEN
            c = _RGB32(40, 90, 160)
        ELSE
            c = _RGB32(80, 150, 230)
        END IF
        LINE (bx, by)-(bx + 19, by + 19), c, BF
    NEXT bx
NEXT by
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (18, 12), "HARDWARE LAYER"
_PRINTSTRING (18, 30), "_COPYIMAGE(h, 33)"
_PRINTSTRING (18, 48), "_PUTIMAGE per frame"
_PRINTSTRING (18, 180), "Hover the diamond here."
_DEST oldDest
hwPanel = _COPYIMAGE(panelSrc, 33)
IF panelSrc < -1 THEN _FREEIMAGE panelSrc

' --- Install the custom OS cursor with a centered hotspot.
_MOUSECURSOR cur, (14, 14)

' --- Log the run facts.
DIM fh AS INTEGER
fh = FREEFILE
OPEN "HW_CURSOR_ZORDER_TEST-log.txt" FOR OUTPUT AS #fh
PRINT #fh, "=== HW_CURSOR_ZORDER_TEST ==="
PRINT #fh, "OS            = "; _OS$
PRINT #fh, "session       = "; ENVIRON$("XDG_SESSION_TYPE")
PRINT #fh, "cursor handle = "; cur
PRINT #fh, "hwPanel handle= "; hwPanel; "  (hardware image; large-negative handle, valid when < -1)"
PRINT #fh, "_MOUSECURSOR set (no runtime error trapped)"

DIM frozen AS INTEGER: frozen = FALSE
DIM renderCount AS LONG: renderCount = 0
DIM displayCount AS LONG: displayCount = 0
DIM frameCount AS LONG: frameCount = 0
DIM spaceLatch AS INTEGER: spaceLatch = FALSE
DIM autoQuit AS LONG: autoQuit = 0

' Headless auto-exit: if launched offscreen for a smoke run, quit after ~4s so
' the harness never strands a window. Live users just press ESC.
IF LEN(ENVIRON$("HWCUR_AUTOQUIT")) > 0 THEN autoQuit = VAL(ENVIRON$("HWCUR_AUTOQUIT"))

DIM py AS INTEGER, gcol AS _UNSIGNED LONG
DO
    frameCount = frameCount + 1

    ' SPACE toggles freeze (edge-latched).
    IF _KEYDOWN(32) THEN
        IF NOT spaceLatch THEN
            frozen = NOT frozen
            spaceLatch = TRUE
        END IF
    ELSE
        spaceLatch = FALSE
    END IF

    IF NOT frozen THEN
        ' ---- SOFTWARE surface: vertical gradient + labels
        FOR py = 0 TO SCRH - 1
            gcol = _RGB32(18 + py \ 12, 20, 44 + py \ 8)
            LINE (0, py)-(SCRW - 1, py), gcol
        NEXT py
        COLOR _RGB32(180, 220, 255), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (18, 16), "SOFTWARE LAYER (SCREEN surface)"
        COLOR _RGB32(230, 230, 230), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (18, 44), "The magenta DIAMOND is the OS cursor (_MOUSECURSOR)."
        _PRINTSTRING (18, 62), "It rides OVER the software gradient AND the hardware panel."
        _PRINTSTRING (18, 88), "SPACE = freeze render loop   |   ESC = quit"

        ' ---- HARDWARE layer: put the hardware panel on top of the software
        ' surface. Placed to straddle the SOFTWARE label so the z-order of the
        ' cursor over BOTH layers is visible at the seam.
        _PUTIMAGE (280, 150), hwPanel
        renderCount = renderCount + 1

        ' ---- live HUD
        COLOR _RGB32(120, 255, 160), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (18, SCRH - 96), "STATE   : LIVE (rendering every frame)"
        _PRINTSTRING (18, SCRH - 78), "renders : " + _TRIM$(STR$(renderCount))
        _PRINTSTRING (18, SCRH - 60), "displays: " + _TRIM$(STR$(displayCount))
        _PRINTSTRING (18, SCRH - 42), "mouse   : " + _TRIM$(STR$(_MOUSEX)) + " , " + _TRIM$(STR$(_MOUSEY))

        _DISPLAY
        displayCount = displayCount + 1
    ELSE
        ' ---- FROZEN: we deliberately do NOT draw and do NOT _DISPLAY.
        ' The window keeps showing the LAST presented frame. If the OS cursor
        ' still glides over it, the compositor owns the pointer -- proving we
        ' never need to repaint under the cursor. renders/displays stay put.
        ' (No _DISPLAY here on purpose.)
    END IF

    _LIMIT 60

    IF autoQuit > 0 AND frameCount >= autoQuit THEN EXIT DO
LOOP UNTIL _KEYDOWN(27)

PRINT #fh, "final renderCount = "; renderCount
PRINT #fh, "final displayCount= "; displayCount
PRINT #fh, "final frameCount  = "; frameCount
PRINT #fh, "note: if you froze, frameCount kept rising while render/display did not"
PRINT #fh, "      -- yet the cursor kept moving. That is CLAIM 2 confirmed."
CLOSE #fh

IF cur < -1 THEN _FREEIMAGE cur
IF hwPanel < -1 THEN _FREEIMAGE hwPanel
SYSTEM
