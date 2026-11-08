''
' DRAW - TOOLS/ANIM-SOUND.BI
' =============================================================================
' The soundtrack (Animation L.1, round 2 R-12 B): a WAV / OGG / MP3 / FLAC /
' MIDI / tracker file timed against the frames. Frame 1 starts ANIM_SND_OFS ms
' into it, frame k at the sum of the earlier frames' times (holds / FPS), in
' sheet order. The path (ANIM_SND_PATH, ANIM.BI) is saved with the frames
' (drAn v6) and set / removed as one undo step.
'
'   Playback: starting playback plays the sound from the current frame's
'   time; a frame shown out of turn (a loop back to the start, reverse /
'   ping-pong, a jump) seeks it there, and it is put right when it drifts.
'   Stopping stops it. Stepping frames while stopped plays just that frame's
'   slice (scrub).
'   X-sheet: a SOUND row under HOLD draws the waveform along the frames
'   (peaks per 1/100 s from _MEMSOUND; none for MIDI / trackers).
'   BAS players (ANIM-EXPORT): the file is copied beside the .bas and played
'   in step with the frames.
'
' Volume: CFG.ANIM_SOUND_VOLUME (0-100). The sound is opened lazily by
' ANIM_SND_tick (DRAW.BAS, every frame) whenever ANIM_SND_PATH changes -
' load, undo, a new document - so no other code opens or closes it.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_SOUNDTRACK    = 2549 ' ANIM > Soundtrack... (pick the file)
CONST ANIM_ACT_SOUND_REMOVE  = 2550 ' ANIM > Remove Soundtrack
CONST ANIM_SND_PK_RATE       = 100  ' waveform peaks per second
CONST ANIM_SND_PK_MAX        = 360000 ' an hour of them

DIM SHARED ANIM_SND_H AS LONG          ' the open sound (0 = none)
DIM SHARED ANIM_SND_LOADED AS STRING   ' the ANIM_SND_PATH that ANIM_SND_H was opened for
DIM SHARED ANIM_SND_FILE AS STRING     ' where it was found (the path, or beside the document)
DIM SHARED ANIM_SND_LEN AS DOUBLE      ' seconds
DIM SHARED ANIM_SND_PKN AS LONG        ' peaks (0 = no waveform)
REDIM SHARED ANIM_SND_PK(0) AS _UNSIGNED _BYTE ' 0-255, the loudest = 255
DIM SHARED ANIM_SND_SEEN_CUR AS INTEGER  ' the frame at the last tick
DIM SHARED ANIM_SND_SEEN_PLAY AS INTEGER ' playback on at the last tick
DIM SHARED ANIM_SND_ON AS INTEGER        ' we have it playing
DIM SHARED ANIM_SND_STOP_AT AS DOUBLE    ' scrub: TIMER when the slice ends (0 = none)
DIM SHARED ANIM_SND_STARTS AS LONG       ' QA: times it was started at a frame's time
DIM SHARED ANIM_SND_LAST_T AS DOUBLE     ' QA: the time (s) it was last started at
DIM SHARED ANIM_SND_VOL AS INTEGER       ' the volume applied (-1 = not yet)
ANIM_SND_VOL = -1
