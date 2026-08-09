''
' DRAW - INPUT/MOUSE.BI
' =============================================================================
' UDT for mouse input handling.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE MOUSE_OBJ
    X                 AS INTEGER
    Y                 AS INTEGER
    OLD_X             AS INTEGER
    OLD_Y             AS INTEGER
    RAW_X             AS INTEGER ' Viewport X coordinate (window / displayScale)
    RAW_Y             AS INTEGER ' Viewport Y coordinate (window / displayScale)
    ' Chrome renders into SCRN.GUI&, which is guiScale times smaller than the
    ' viewport and blitted back magnified — so a widget drawn at GUI (gx,gy)
    ' appears at viewport (gx*guiScale, gy*guiScale). Hit-testing anything on
    ' that surface must use these, NOT RAW_X/RAW_Y. Identical to RAW at scale 1.
    ' Floating overlays (preview, colour mixer, tooltip) and the command palette
    ' draw to screen 0 / the canvas, so they keep using RAW_X/RAW_Y.
    GUI_X             AS INTEGER ' RAW_X \ guiScale — chrome hit-testing
    GUI_Y             AS INTEGER ' RAW_Y \ guiScale — chrome hit-testing
    UNSNAPPED_X       AS INTEGER ' Canvas X before grid snap (for fill, picker, etc.)
    UNSNAPPED_Y       AS INTEGER ' Canvas Y before grid snap (for fill, picker, etc.)
    CON_X             AS INTEGER
    CON_Y             AS INTEGER
    B1                AS INTEGER
    B2                AS INTEGER
    B3                AS INTEGER
    OLD_B1            AS INTEGER
    OLD_B2            AS INTEGER
    OLD_B3            AS INTEGER
    OSW               AS INTEGER
    SW                AS INTEGER
    DRAG              AS STRING
    B3_CLICK_TIME     AS DOUBLE
    B1_CLICK_TIME     AS DOUBLE
    UI_CHROME_CLICKED AS INTEGER
    DEFERRED_ACTION   AS INTEGER ' Action to perform after mouse processing (0 = none, 1 = save, 2 = load, 3 = open DRW, 4 = export, 5 = drawer slot import)
    SUPPRESS_FRAMES   AS INTEGER ' Frames to suppress button input after native dialogs (prevents phantom clicks)
    STARTED_ON_APRON  AS INTEGER ' TRUE when button press began outside canvas bounds (apron area) — blocks tool dispatch for entire stroke
END TYPE

DIM SHARED MOUSE AS MOUSE_OBJ

MOUSE_init
