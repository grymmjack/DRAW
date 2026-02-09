''
' GPU-Accelerated Window Scaling Test for DRAW
' =============================================================================
' Tests whether glutReshapeWindow() can be used to decouple window size from
' SCREEN buffer size, letting $RESIZE:STRETCH do GPU-accelerated scaling.
'
' HYPOTHESIS: If we use SCREEN at 640x400 and call glutReshapeWindow(1280,800),
' $RESIZE:STRETCH will GPU-scale the buffer to fill the window. This would
' eliminate the 12-18ms _PUTIMAGE software scaling step in DRAW's render.
'
' @author Rick Christy <grymmjack@gmail.com>
' =============================================================================
'
OPTION _EXPLICIT
$RESIZE:STRETCH

DECLARE LIBRARY "./glut_reshape"
    SUB glutReshapeWindow (BYVAL width AS LONG, BYVAL height AS LONG)
END DECLARE

' ---- Constants ----
CONST LOGICAL_W = 640
CONST LOGICAL_H = 400
CONST SCALE_FACTOR = 2
CONST WINDOW_W = LOGICAL_W * SCALE_FACTOR  ' 1280
CONST WINDOW_H = LOGICAL_H * SCALE_FACTOR  ' 800
CONST TEST_FRAMES = 300
CONST WARMUP_FRAMES = 60

' ---- Setup ----
DIM scrn AS LONG
scrn& = _NEWIMAGE(LOGICAL_W, LOGICAL_H, 32)
SCREEN scrn&
_DELAY 0.1  ' Let window initialize

' Reshape window to 2x size — GPU will stretch the 640x400 buffer
glutReshapeWindow WINDOW_W, WINDOW_H
_DELAY 0.2  ' Let reshape settle

_TITLE "GPU Scale Test - " + STR$(LOGICAL_W) + "x" + STR$(LOGICAL_H) + " -> " + STR$(WINDOW_W) + "x" + STR$(WINDOW_H)
_MOUSEHIDE

' ---- Timing variables ----
DIM t_draw_start AS DOUBLE, t_draw_end AS DOUBLE
DIM t_display_start AS DOUBLE, t_display_end AS DOUBLE
DIM t_frame_start AS DOUBLE, t_frame_end AS DOUBLE
DIM draw_total AS DOUBLE, display_total AS DOUBLE, frame_total AS DOUBLE
DIM frame_count AS LONG
DIM avg_draw AS DOUBLE, avg_display AS DOUBLE, avg_frame AS DOUBLE

' For comparison: software scale timing
DIM sw_img AS LONG
DIM t_sw_start AS DOUBLE, t_sw_end AS DOUBLE
DIM sw_total AS DOUBLE, avg_sw AS DOUBLE

' ---- Checkerboard + content buffer (simulate DRAW's canvas) ----
DIM canvas AS LONG
canvas& = _NEWIMAGE(LOGICAL_W, LOGICAL_H, 32)

' ---- Mouse tracking ----
DIM mx AS INTEGER, my AS INTEGER
DIM raw_mx AS INTEGER, raw_my AS INTEGER

' ---- Test Phase 1: GPU-scaled rendering ----
_LOGINFO "=========================================="
_LOGINFO "GPU SCALE TEST: Phase 1 - GPU-Accelerated"
_LOGINFO "  Screen buffer: " + STR$(LOGICAL_W) + "x" + STR$(LOGICAL_H)
_LOGINFO "  Window size:   " + STR$(WINDOW_W) + "x" + STR$(WINDOW_H)
_LOGINFO "  Scale factor:  " + STR$(SCALE_FACTOR) + "x"
_LOGINFO "=========================================="

draw_total = 0
display_total = 0
frame_total = 0
frame_count = 0

DIM phase AS INTEGER
DIM i AS INTEGER, xx AS INTEGER, yy AS INTEGER
DIM anim_offset AS INTEGER
DIM col AS _UNSIGNED LONG

FOR phase = 1 TO 2
    IF phase = 1 THEN
        _LOGINFO ""
        _LOGINFO "--- Warmup (" + STR$(WARMUP_FRAMES) + " frames) ---"
    ELSE
        _LOGINFO ""
        _LOGINFO "--- Measuring (" + STR$(TEST_FRAMES) + " frames) ---"
        draw_total = 0
        display_total = 0
        frame_total = 0
        frame_count = 0
    END IF
    
    DIM max_frames AS LONG
    IF phase = 1 THEN max_frames& = WARMUP_FRAMES ELSE max_frames& = TEST_FRAMES
    
    FOR i = 1 TO max_frames&
        t_frame_start = TIMER(0.001)
        
        ' ---- Draw Phase (simulate DRAW's render pipeline) ----
        t_draw_start = TIMER(0.001)
        
        anim_offset% = i MOD 20
        
        ' Draw directly to SCREEN (the 640x400 buffer)
        ' This simulates what DRAW would do: compositing onto CANVAS
        _DEST scrn&
        
        ' 1. Clear with checkerboard pattern
        FOR yy = 0 TO LOGICAL_H - 1 STEP 8
            FOR xx = 0 TO LOGICAL_W - 1 STEP 8
                IF ((xx \ 8 + yy \ 8) MOD 2) = 0 THEN
                    col~& = _RGB32(200, 200, 200)
                ELSE
                    col~& = _RGB32(160, 160, 160)
                END IF
                LINE (xx, yy)-(xx + 7, yy + 7), col~&, BF
            NEXT xx
        NEXT yy
        
        ' 2. Draw some content (simulates layers)
        ' Filled rectangles
        LINE (50 + anim_offset%, 50)-(200 + anim_offset%, 150), _RGB32(255, 0, 0, 180), BF
        LINE (100, 100 + anim_offset%)-(300, 250 + anim_offset%), _RGB32(0, 0, 255, 180), BF
        LINE (250 + anim_offset%, 30)-(450, 200), _RGB32(0, 200, 0, 180), BF
        
        ' 3. Draw grid lines (simulates grid overlay)
        DIM gx AS INTEGER, gy AS INTEGER
        FOR gx = 0 TO LOGICAL_W - 1 STEP 10
            LINE (gx, 0)-(gx, LOGICAL_H - 1), _RGBA32(255, 255, 255, 40)
        NEXT gx
        FOR gy = 0 TO LOGICAL_H - 1 STEP 10
            LINE (0, gy)-(LOGICAL_W - 1, gy), _RGBA32(255, 255, 255, 40)
        NEXT gy
        
        ' 4. Draw mouse cursor (simulates pointer)
        DO WHILE _MOUSEINPUT: LOOP
        raw_mx% = _MOUSEX
        raw_my% = _MOUSEY
        ' With $RESIZE:STRETCH, _MOUSEX/_MOUSEY should already be in
        ' logical (screen buffer) coordinates
        mx% = raw_mx%
        my% = raw_my%
        
        ' Clamp to canvas
        IF mx% < 0 THEN mx% = 0
        IF my% < 0 THEN my% = 0
        IF mx% >= LOGICAL_W THEN mx% = LOGICAL_W - 1
        IF my% >= LOGICAL_H THEN my% = LOGICAL_H - 1
        
        ' Draw crosshair cursor
        LINE (mx% - 10, my%)-(mx% + 10, my%), _RGB32(255, 255, 0)
        LINE (mx%, my% - 10)-(mx%, my% + 10), _RGB32(255, 255, 0)
        CIRCLE (mx%, my%), 5, _RGB32(255, 255, 0)
        
        ' 5. Status text
        COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0, 180)
        _PRINTSTRING (5, 5), "GPU SCALE TEST - Frame " + STR$(i)
        _PRINTSTRING (5, 20), "Mouse: " + STR$(mx%) + "," + STR$(my%) + " (raw: " + STR$(raw_mx%) + "," + STR$(raw_my%) + ")"
        _PRINTSTRING (5, 35), "Screen: " + STR$(_WIDTH) + "x" + STR$(_HEIGHT) + "  Window: " + STR$(_SCALEDWIDTH) + "x" + STR$(_SCALEDHEIGHT)
        IF phase = 2 AND frame_count > 0 THEN
            _PRINTSTRING (5, 50), "Avg draw: " + LEFT$(STR$(avg_draw * 1000), 8) + "ms  Avg _DISPLAY: " + LEFT$(STR$(avg_display * 1000), 8) + "ms"
        END IF
        
        t_draw_end = TIMER(0.001)
        
        ' ---- Display Phase (GPU stretch happens here) ----
        t_display_start = TIMER(0.001)
        _DISPLAY
        t_display_end = TIMER(0.001)
        
        t_frame_end = TIMER(0.001)
        
        ' ---- Accumulate timings ----
        IF phase = 2 THEN
            ' Handle midnight rollover
            DIM dt_draw AS DOUBLE, dt_display AS DOUBLE, dt_frame AS DOUBLE
            dt_draw = t_draw_end - t_draw_start
            IF dt_draw < 0 THEN dt_draw = dt_draw + 86400
            dt_display = t_display_end - t_display_start
            IF dt_display < 0 THEN dt_display = dt_display + 86400
            dt_frame = t_frame_end - t_frame_start
            IF dt_frame < 0 THEN dt_frame = dt_frame + 86400
            
            draw_total = draw_total + dt_draw
            display_total = display_total + dt_display
            frame_total = frame_total + dt_frame
            frame_count = frame_count + 1
            
            avg_draw = draw_total / frame_count
            avg_display = display_total / frame_count
            avg_frame = frame_total / frame_count
        END IF
        
        _LIMIT 60
        
        IF _KEYHIT = 27 THEN GOTO done
    NEXT i
NEXT phase

' ---- Report GPU results ----
_LOGINFO ""
_LOGINFO "========= GPU SCALE RESULTS ========="
_LOGINFO "  Frames measured:     " + STR$(frame_count)
_LOGINFO "  Avg draw time:       " + LEFT$(STR$(avg_draw * 1000), 10) + " ms"
_LOGINFO "  Avg _DISPLAY time:   " + LEFT$(STR$(avg_display * 1000), 10) + " ms"
_LOGINFO "  Avg total frame:     " + LEFT$(STR$(avg_frame * 1000), 10) + " ms"
_LOGINFO "  Est. FPS (uncapped): " + LEFT$(STR$(1.0 / avg_frame), 8)
_LOGINFO "====================================="

' ---- Test Phase 2: Software scale comparison ----
_LOGINFO ""
_LOGINFO "=========================================="
_LOGINFO "GPU SCALE TEST: Phase 2 - Software Scale"
_LOGINFO "  (Simulating current DRAW approach)"
_LOGINFO "=========================================="

' Create a window-sized image for software scaling
sw_img& = _NEWIMAGE(WINDOW_W, WINDOW_H, 32)

sw_total = 0
DIM sw_count AS LONG
sw_count = 0

FOR i = 1 TO TEST_FRAMES
    t_frame_start = TIMER(0.001)
    
    ' Draw the same content to the logical-size buffer
    t_draw_start = TIMER(0.001)
    
    anim_offset% = i MOD 20
    _DEST scrn&

    ' Same drawing as above (checkerboard + content + grid + cursor)
    FOR yy = 0 TO LOGICAL_H - 1 STEP 8
        FOR xx = 0 TO LOGICAL_W - 1 STEP 8
            IF ((xx \ 8 + yy \ 8) MOD 2) = 0 THEN
                col~& = _RGB32(200, 200, 200)
            ELSE
                col~& = _RGB32(160, 160, 160)
            END IF
            LINE (xx, yy)-(xx + 7, yy + 7), col~&, BF
        NEXT xx
    NEXT yy
    
    LINE (50 + anim_offset%, 50)-(200 + anim_offset%, 150), _RGB32(255, 0, 0, 180), BF
    LINE (100, 100 + anim_offset%)-(300, 250 + anim_offset%), _RGB32(0, 0, 255, 180), BF
    LINE (250 + anim_offset%, 30)-(450, 200), _RGB32(0, 200, 0, 180), BF
    
    FOR gx = 0 TO LOGICAL_W - 1 STEP 10
        LINE (gx, 0)-(gx, LOGICAL_H - 1), _RGBA32(255, 255, 255, 40)
    NEXT gx
    FOR gy = 0 TO LOGICAL_H - 1 STEP 10
        LINE (0, gy)-(LOGICAL_W - 1, gy), _RGBA32(255, 255, 255, 40)
    NEXT gy
    
    DO WHILE _MOUSEINPUT: LOOP
    mx% = _MOUSEX: my% = _MOUSEY
    IF mx% < 0 THEN mx% = 0: IF my% < 0 THEN my% = 0
    IF mx% >= LOGICAL_W THEN mx% = LOGICAL_W - 1
    IF my% >= LOGICAL_H THEN my% = LOGICAL_H - 1
    LINE (mx% - 10, my%)-(mx% + 10, my%), _RGB32(255, 255, 0)
    LINE (mx%, my% - 10)-(mx%, my% + 10), _RGB32(255, 255, 0)
    CIRCLE (mx%, my%), 5, _RGB32(255, 255, 0)
    
    COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0, 180)
    _PRINTSTRING (5, 5), "SW SCALE TEST - Frame " + STR$(i)
    IF sw_count > 0 THEN
        _PRINTSTRING (5, 20), "Avg SW scale: " + LEFT$(STR$(avg_sw * 1000), 8) + "ms  Avg _DISPLAY: " + LEFT$(STR$(avg_display * 1000), 8) + "ms"
    END IF
    
    t_draw_end = TIMER(0.001)
    
    ' ---- SOFTWARE SCALE: _PUTIMAGE from 640x400 to 1280x800 ----
    t_sw_start = TIMER(0.001)
    _DEST sw_img&
    _DONTBLEND sw_img&
    _PUTIMAGE (0, 0)-(WINDOW_W - 1, WINDOW_H - 1), scrn&, sw_img&
    t_sw_end = TIMER(0.001)
    ' (We don't display sw_img, just measure the _PUTIMAGE cost)
    
    ' Display the GPU-scaled version (since SCREEN is still the small buffer)
    t_display_start = TIMER(0.001)
    _DISPLAY
    t_display_end = TIMER(0.001)
    
    t_frame_end = TIMER(0.001)
    
    ' Accumulate
    DIM dt_sw AS DOUBLE
    dt_sw = t_sw_end - t_sw_start
    IF dt_sw < 0 THEN dt_sw = dt_sw + 86400
    dt_draw = t_draw_end - t_draw_start
    IF dt_draw < 0 THEN dt_draw = dt_draw + 86400
    dt_display = t_display_end - t_display_start
    IF dt_display < 0 THEN dt_display = dt_display + 86400
    dt_frame = t_frame_end - t_frame_start
    IF dt_frame < 0 THEN dt_frame = dt_frame + 86400
    
    sw_total = sw_total + dt_sw
    draw_total = draw_total + dt_draw
    display_total = display_total + dt_display
    frame_total = frame_total + dt_frame
    sw_count = sw_count + 1
    
    avg_sw = sw_total / sw_count
    avg_draw = draw_total / sw_count
    avg_display = display_total / sw_count
    avg_frame = frame_total / sw_count
    
    _LIMIT 60
    
    IF _KEYHIT = 27 THEN GOTO done
NEXT i

' ---- Report comparison ----
_LOGINFO ""
_LOGINFO "========= SOFTWARE SCALE RESULTS ========="
_LOGINFO "  Frames measured:     " + STR$(sw_count)
_LOGINFO "  Avg SW _PUTIMAGE:    " + LEFT$(STR$(avg_sw * 1000), 10) + " ms  <-- THIS IS WHAT WE ELIMINATE"
_LOGINFO "  Avg draw time:       " + LEFT$(STR$(avg_draw * 1000), 10) + " ms"
_LOGINFO "  Avg _DISPLAY time:   " + LEFT$(STR$(avg_display * 1000), 10) + " ms"
_LOGINFO "  Avg total frame:     " + LEFT$(STR$(avg_frame * 1000), 10) + " ms"
_LOGINFO "============================================"

_LOGINFO ""
_LOGINFO "============================================"
_LOGINFO "  COMPARISON SUMMARY"
_LOGINFO "  SW _PUTIMAGE scale cost: " + LEFT$(STR$(avg_sw * 1000), 8) + " ms/frame"
_LOGINFO "  GPU _DISPLAY overhead:   already included in _DISPLAY"
_LOGINFO "  If > 1ms, GPU scaling saves significant time per frame."
_LOGINFO "============================================"

done:
' Cleanup
IF sw_img& < -1 THEN _FREEIMAGE sw_img&
IF canvas& < -1 THEN _FREEIMAGE canvas&

_LOGINFO ""
_LOGINFO "Test complete. Press any key to exit."
SLEEP
SYSTEM
