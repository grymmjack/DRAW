''
' DRAW - TOOLS/ANIM-SOUND.BI
' =============================================================================
' The soundtrack (Animation L.1, round 2 R-12 B): a WAV / OGG / MP3 / FLAC /
' MIDI / tracker file timed against the frames; since F6, clips of any of
' them on up to 4 tracks (ANIM_SC_*, ANIM.BI). Frame k starts at the sum of
' the earlier frames' times (holds / FPS), in sheet order. The clips are
' saved with the frames (drAn v6 / v7); every change is one undo step.
'
'   Playback: starting playback plays the sound from the current frame's
'   time; a frame shown out of turn (a loop back to the start, reverse /
'   ping-pong, a jump) seeks it there, and it is put right when it drifts.
'   Stopping stops it. Stepping frames while stopped plays just that frame's
'   slice (scrub).
'   X-sheet: a SOUND row per track under HOLD draws each clip's waveform
'   along the frames (peaks per 1/100 s from _MEMSOUND; none for MIDI /
'   trackers). Pick a clip and drag it (it snaps to frame starts; Shift =
'   free; up / down = another track); Ctrl+C / X / V and Delete act on the
'   selected frames' span of the track (one frame selected: the clip);
'   right-click = the SOUND menu.
'   BAS players (ANIM-EXPORT): one clip's file is copied beside the .bas,
'   a mix is written as a WAV there; it plays in step with the frames.
'
' Volume: CFG.ANIM_SOUND_VOLUME (0-100). The sound is opened lazily by
' ANIM_SND_tick (DRAW.BAS, every frame) whenever the clips change - load,
' undo, an edit, a new document - so no other code opens or closes it.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_SOUNDTRACK    = 2549 ' ANIM > Soundtrack... (pick a file: track 1, or a new track)
CONST ANIM_ACT_SOUND_REMOVE  = 2550 ' ANIM > Remove Soundtrack (every clip)
' the SOUND rows' menu / keys (F6)
CONST ANIM_ACT_SOUND_ADD_HERE  = 2552 ' Add Sound Here... (the track and frame clicked)
CONST ANIM_ACT_SOUND_ADD_TRACK = 2553 ' Add Sound on a New Track...
CONST ANIM_ACT_SOUND_COPY      = 2554 ' Ctrl+C
CONST ANIM_ACT_SOUND_CUT       = 2555 ' Ctrl+X
CONST ANIM_ACT_SOUND_PASTE     = 2556 ' Ctrl+V: at the current frame
CONST ANIM_ACT_SOUND_DELETE    = 2557 ' Delete
CONST ANIM_ACT_SOUND_SPLIT     = 2558 ' Split at the current frame
CONST ANIM_ACT_SOUND_REMOVE_CLIP = 2559 ' Remove the clip
CONST ANIM_ACT_SOUND_EMPTY_TRACK = 2560 ' Add Empty Track (a silent SOUND row to put sound on)
CONST ANIM_ACT_SOUND_REMOVE_TRACK = 2561 ' Remove Track (its clips; the tracks under it move up)
CONST ANIM_SND_PK_RATE       = 100  ' waveform peaks per second
CONST ANIM_SND_PK_MAX        = 360000 ' an hour of them (all the files)
CONST ANIM_SND_MIX_MAX_S     = 600  ' a mix of clips is at most 10 minutes

' The files the clips play (opened once per document / set of files; see
' ANIM_SS_sync): where each was found, its open sound (noasync: _MEMSOUND
' reads it), its length and its waveform peaks (ANIM_SND_PK(PK0 ..)).
CONST ANIM_SS_MAX = 32
DIM SHARED ANIM_SS_N AS INTEGER
DIM SHARED ANIM_SS_PATH(1 TO ANIM_SS_MAX) AS STRING
DIM SHARED ANIM_SS_FILE(1 TO ANIM_SS_MAX) AS STRING ' "" = not found
DIM SHARED ANIM_SS_H(1 TO ANIM_SS_MAX) AS LONG      ' 0 = not found / can't open
DIM SHARED ANIM_SS_MS(1 TO ANIM_SS_MAX) AS LONG
DIM SHARED ANIM_SS_PK0(1 TO ANIM_SS_MAX) AS LONG
DIM SHARED ANIM_SS_PKN(1 TO ANIM_SS_MAX) AS LONG    ' 0 = no waveform (MIDI, a tracker)
DIM SHARED ANIM_SS_SIG AS STRING
' ANIM_SND_smp! found its sound memory gone (the loop reading it stops: a
' _MEM error is critical in QB64-PE, ON ERROR never sees it)
DIM SHARED ANIM_SND_MEM_LOST AS INTEGER
' ANIM_SND_close closed a sound _MEMSOUND read: ANIM_SND_let_go waits
DIM SHARED ANIM_SND_CLOSED AS INTEGER ' the document folder + paths they were opened for

' What plays: one clip that runs to the end plays its file itself (MIDI and
' trackers too); anything else is mixed into one sound (_SNDNEW, files that
' _MEMSOUND can read). ANIM_SND_BASE = s into it where frame 1 starts.
DIM SHARED ANIM_SND_H AS LONG          ' the sound playing (0 = none)
DIM SHARED ANIM_SND_MIXED AS INTEGER   ' ANIM_SND_H is a mix (ours to close), else a file's
DIM SHARED ANIM_SND_BASE AS DOUBLE
DIM SHARED ANIM_SND_SIG AS STRING      ' the clips ANIM_SND_H was made for
DIM SHARED ANIM_SND_SKIPPED AS INTEGER ' clips left out of the mix (no samples to read)
DIM SHARED ANIM_SND_FILE AS STRING     ' the file (a single clip) / "" (a mix)
DIM SHARED ANIM_SND_LEN AS DOUBLE      ' seconds
DIM SHARED ANIM_SND_PKN AS LONG        ' peaks of all the files (0 = no waveform)
REDIM SHARED ANIM_SND_PK(0) AS _UNSIGNED _BYTE ' 0-255, each file's loudest = 255
DIM SHARED ANIM_SND_SEEN_CUR AS INTEGER  ' the frame at the last tick
DIM SHARED ANIM_SND_SEEN_PLAY AS INTEGER ' playback on at the last tick
DIM SHARED ANIM_SND_ON AS INTEGER        ' we have it playing
DIM SHARED ANIM_SND_STOP_AT AS DOUBLE    ' scrub: TIMER when the slice ends (0 = none)
DIM SHARED ANIM_SND_STARTS AS LONG       ' QA: times it was started at a frame's time
DIM SHARED ANIM_SND_LAST_T AS DOUBLE     ' QA: the time (s) it was last started at
DIM SHARED ANIM_SND_VOL AS INTEGER       ' the volume applied (-1 = not yet)
ANIM_SND_VOL = -1

' Editing the clips on the X-sheet's SOUND rows (F6): a press on a row gives
' it the keys (Ctrl+C / X / V, Delete; Esc or a press elsewhere takes them
' back) and picks the clip under the pointer; a drag moves that clip.
DIM SHARED ANIM_SC_SEL AS INTEGER    ' the clip picked (0 none)
DIM SHARED ANIM_SC_TRACK AS INTEGER  ' the track the keys / menu act on
DIM SHARED ANIM_SC_FOCUS AS INTEGER  ' the SOUND rows have the keys
DIM SHARED ANIM_SC_KEEP AS INTEGER   ' this frame's press was theirs (their menu): they keep the keys
DIM SHARED ANIM_SC_MENU_T AS LONG    ' the frame start (timeline ms) last pressed on the rows: the menu's Here
DIM SHARED ANIM_SC_FROM_MENU AS INTEGER ' the command is the menu's: Paste / Split Here, not at the current frame
DIM SHARED ANIM_SC_DRAG AS INTEGER   ' a clip is being dragged: no new mix until it is let go
DIM SHARED ANIM_SC_DRAG_AT AS LONG   ' its at / track at the press
DIM SHARED ANIM_SC_DRAG_TRK AS INTEGER
DIM SHARED ANIM_SC_BEFORE AS STRING  ' the undo snapshot from the press
DIM SHARED ANIM_SND_PEAK_L AS SINGLE ' the last mix's loudest sample, left / right (QA: ANIMSCGV)
DIM SHARED ANIM_SND_PEAK_R AS SINGLE
