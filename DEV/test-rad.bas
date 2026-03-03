' test-rad.bas — Quick .rad playback test for QB64PE
' Tests that _SNDOPEN / _SNDPLAY work with Reality Adlib Tracker (.rad) files.
' Run from the DRAW project root so relative paths resolve correctly.

OPTION _EXPLICIT

CONST MUSIC_DIR$ = "../ASSETS/THEMES/DEFAULT/MUSIC/"

' A handful of .rad files to cycle through
DIM tracks(0 TO 9) AS STRING
tracks(0) = "wayne kerr - emag006.rad"
tracks(1) = "void - terrania.rad"
tracks(2) = "phandral - dreaming.rad"
tracks(3) = "hannes seifert - hubbard.rad"
tracks(4) = "nula - reilax.rad"
tracks(5) = "marvin - popcorn.rad"
tracks(6) = "shiru - sunny_forest.rad"
tracks(7) = "extent of the jam - stack.rad"
tracks(8) = "void - waterfall.rad"
tracks(9) = "phandral - spiral.rad"
CONST TRACK_COUNT% = 10

DIM sndHandle AS LONG
DIM currentTrack AS INTEGER
DIM vol AS SINGLE
DIM pressedKey AS LONG

currentTrack% = 0
vol! = 0.8
sndHandle& = 0

' ── helpers ──────────────────────────────────────────────────────────────────
DECLARE SUB LoadTrack (idx AS INTEGER, h AS LONG, v AS SINGLE)
DECLARE SUB DrawUI (idx AS INTEGER, h AS LONG, v AS SINGLE, tracks() AS STRING)

SCREEN _NEWIMAGE(640, 200, 32)
_TITLE "RAD Playback Test — QB64PE"

LoadTrack currentTrack%, sndHandle&, vol!

' ── main loop ─────────────────────────────────────────────────────────────────
DO
    pressedKey& = _KEYHIT

    SELECT CASE pressedKey&
        CASE 27                 ' Escape — quit
            EXIT DO
        CASE 32                 ' Space — next track
            IF sndHandle& > 0 THEN _SNDSTOP sndHandle&: _SNDCLOSE sndHandle&: sndHandle& = 0
            currentTrack% = (currentTrack% + 1) MOD TRACK_COUNT%
            LoadTrack currentTrack%, sndHandle&, vol!
        CASE 8                  ' Backspace — previous track
            IF sndHandle& > 0 THEN _SNDSTOP sndHandle&: _SNDCLOSE sndHandle&: sndHandle& = 0
            currentTrack% = (currentTrack% - 1 + TRACK_COUNT%) MOD TRACK_COUNT%
            LoadTrack currentTrack%, sndHandle&, vol!
        CASE ASC("+"), ASC("=") ' Volume up
            vol! = vol! + 0.1
            IF vol! > 1.0 THEN vol! = 1.0
            IF sndHandle& > 0 THEN _SNDVOL sndHandle&, vol!
        CASE ASC("-")           ' Volume down
            vol! = vol! - 0.1
            IF vol! < 0.0 THEN vol! = 0.0
            IF sndHandle& > 0 THEN _SNDVOL sndHandle&, vol!
        CASE ASC("p"), ASC("P") ' Pause / resume toggle
            IF sndHandle& > 0 THEN
                IF _SNDPLAYING(sndHandle&) THEN
                    _SNDPAUSE sndHandle&
                ELSE
                    _SNDPLAY sndHandle&
                END IF
            END IF
        CASE ASC("r"), ASC("R") ' Restart current track
            IF sndHandle& > 0 THEN _SNDSTOP sndHandle&: _SNDCLOSE sndHandle&: sndHandle& = 0
            LoadTrack currentTrack%, sndHandle&, vol!
    END SELECT

    ' Auto-advance when track finishes
    IF sndHandle& > 0 AND NOT _SNDPLAYING(sndHandle&) AND NOT _SNDPAUSED(sndHandle&) THEN
        _SNDCLOSE sndHandle&
        sndHandle& = 0
        currentTrack% = (currentTrack% + 1) MOD TRACK_COUNT%
        LoadTrack currentTrack%, sndHandle&, vol!
    END IF

    DrawUI currentTrack%, sndHandle&, vol!, tracks()

    _DISPLAY
    _LIMIT 30
LOOP

IF sndHandle& > 0 THEN _SNDSTOP sndHandle&: _SNDCLOSE sndHandle&
SYSTEM

' ─────────────────────────────────────────────────────────────────────────────
SUB LoadTrack (idx AS INTEGER, h AS LONG, v AS SINGLE)
    DIM path AS STRING
    DIM newH AS LONG
    DIM tracks(0 TO 9) AS STRING
    tracks(0) = "wayne kerr - emag006.rad"
    tracks(1) = "void - terrania.rad"
    tracks(2) = "phandral - dreaming.rad"
    tracks(3) = "hannes seifert - hubbard.rad"
    tracks(4) = "nula - reilax.rad"
    tracks(5) = "marvin - popcorn.rad"
    tracks(6) = "shiru - sunny_forest.rad"
    tracks(7) = "extent of the jam - stack.rad"
    tracks(8) = "void - waterfall.rad"
    tracks(9) = "phandral - spiral.rad"

    path$ = MUSIC_DIR$ + tracks(idx%)
    newH& = _SNDOPEN(path$)
    IF newH& > 0 THEN
        h& = newH&
        _SNDVOL h&, v!
        _SNDPLAY h&
    ELSE
        h& = 0
    END IF
END SUB

SUB DrawUI (idx AS INTEGER, h AS LONG, v AS SINGLE, tracks() AS STRING)
    DIM playState AS STRING
    DIM handleState AS STRING
    DIM col AS _UNSIGNED LONG

    CLS , _RGB32(18, 18, 30)

    ' Title bar
    LINE (0, 0)-(639, 24), _RGB32(40, 40, 80), BF
    COLOR _RGB32(255, 220, 80)
    _PRINTSTRING (8, 6), "RAD PLAYBACK TEST  -  QB64PE  -  _SNDOPEN / _SNDPLAY"

    ' Track info
    COLOR _RGB32(160, 200, 255)
    _PRINTSTRING (8, 38), "Track  : " + LTRIM$(STR$(idx% + 1)) + " / " + LTRIM$(STR$(10))
    COLOR _RGB32(255, 255, 255)
    _PRINTSTRING (8, 56), "File   : " + tracks(idx%)

    ' Handle / status
    IF h& > 0 THEN
        handleState$ = "valid (" + LTRIM$(STR$(h&)) + ")"
        col = _RGB32(100, 220, 100)
    ELSE
        handleState$ = "FAILED (handle <= 0)"
        col = _RGB32(220, 80, 80)
    END IF
    COLOR col
    _PRINTSTRING (8, 74), "Handle : " + handleState$

    ' Play state
    IF h& > 0 THEN
        IF _SNDPAUSED(h&) THEN
            playState$ = "PAUSED"
            col = _RGB32(255, 200, 60)
        ELSEIF _SNDPLAYING(h&) THEN
            playState$ = "PLAYING"
            col = _RGB32(100, 220, 100)
        ELSE
            playState$ = "STOPPED"
            col = _RGB32(180, 180, 180)
        END IF
    ELSE
        playState$ = "N/A"
        col = _RGB32(180, 80, 80)
    END IF
    COLOR col
    _PRINTSTRING (8, 92), "State  : " + playState$

    ' Volume
    COLOR _RGB32(180, 180, 255)
    _PRINTSTRING (8, 110), "Volume : " + LTRIM$(STR$(INT(v! * 100))) + "%"

    ' Divider
    LINE (0, 132)-(639, 133), _RGB32(60, 60, 100), BF

    ' Controls hint
    COLOR _RGB32(140, 140, 160)
    _PRINTSTRING (8, 140), "SPACE=Next  BKSP=Prev  P=Pause/Resume  R=Restart  +/-=Volume  ESC=Quit"

    ' RESULT banner
    IF h& > 0 THEN
        LINE (0, 160)-(639, 199), _RGB32(20, 60, 20), BF
        COLOR _RGB32(80, 255, 80)
        _PRINTSTRING (8, 172), "RESULT: OK - _SNDOPEN succeeded for .rad file"
    ELSE
        LINE (0, 160)-(639, 199), _RGB32(60, 20, 20), BF
        COLOR _RGB32(255, 80, 80)
        _PRINTSTRING (8, 172), "RESULT: FAIL - _SNDOPEN returned 0 (check libxmp / QB64PE version)"
    END IF
END SUB
