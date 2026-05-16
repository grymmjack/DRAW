# DRAW — Sound System

**Files**: `CORE/SOUND.BI` (constants + declarations), `CORE/SOUND.BM` (loader + playback SUBs)

---

## Sound Category Constants (`SOUND_HANDLES` array, indices 1–21)

| Constant          | Value | Trigger |
| ----------------- | ----- | ------- |
| `SND_MENU_OPEN`   | 1     | Opening a root menu |
| `SND_MENU_SELECT` | 2     | Selecting a menu item |
| `SND_NEW_FILE`    | 3     | New file / startup |
| `SND_NEW_LAYER`   | 4     | New layer |
| `SND_LAYER_OP`    | 5     | Delete / arrange / duplicate / merge layer |
| `SND_CLIPBOARD`   | 6     | Copy / Cut / Paste |
| `SND_FILL`        | 7     | Flood fill |
| `SND_SELECTION`   | 8     | Selection ops (looped while dragging a marquee) |
| `SND_DRAW`        | 9     | Brush / dot / spray initial click |
| `SND_TRANSFORM`   | 10    | Flip / scale / rotate |
| `SND_TEXT_ENTER`  | 11    | Text tool — commit line (Enter) |
| `SND_MENU_HOVER`  | 12    | Hover over new menu item |
| `SND_TOOL_SELECT` | 13    | Toolbox button clicked |
| `SND_TEXT_CHAR`   | 14    | Text tool — printable character typed |
| `SND_ERASER`      | 15    | Eraser stroke initial click |
| `SND_DRAW_REV`    | 16    | Reversed draw sound (cardinal direction change) |
| `SND_ERASER_REV`  | 17    | Reversed eraser sound |
| `SND_SLIDER`      | 18    | Opacity/value slider drag, mousewheel, release |
| `SND_DRAG_DROP`   | 19    | Layer drag-and-drop; shape/selection commit |
| `SND_POINT`       | 20    | Click to place a point (line/shape/poly/dot tools) |
| `SND_ORGANIZER`   | 21    | Organizer widget click or mousewheel |

---

## Playback SUBs

```qb64
SOUND_play SND_FILL              ' Fire-and-forget
SOUND_loop SND_SELECTION         ' Per-frame: plays only if NOT _SNDPLAYING (prevents restart stutter)
SOUND_stop SND_SELECTION         ' Stop a looping sound
SOUND_play_pitched SND_DRAW, 0.8, 1.2, 0.9  ' Randomised pitch between speedMin/speedMax
```

**NEVER call `_SNDPLAY` directly** — always use `SOUND_play` / `SOUND_loop`. They guard `CFG.SOUNDS_ENABLED%` and handle validity.

---

## Key Config Fields

| Key              | Purpose |
| ---------------- | ------- |
| `SOUNDS_ENABLED` | 0=disabled, 1=enabled |
| `SOUNDS_VOLUME`  | 0–100 SFX volume (default 35) |
| `SOUNDS_MUTED`   | 0/1 — mute SFX without disabling |
| `MUSIC_ENABLED`  | 0=off, 1=on |
| `MUSIC_VOLUME`   | 0–100 music volume (default 35) |
| `MUSIC_MUTED`    | 0/1 — mute music without stopping |

---

## Music System

- `MUSIC_HANDLE` (LONG, shared) — current tracker file handle
- `MUSIC_CURRENT_FILE$` — filename of playing track; empty when not playing
- `MUSIC_play_random` — scans `ASSETS/THEMES/DEFAULT/MUSIC/` for `.mod/.xm/.it/.s3m/.rad/.mid/.midi/.rmi`, picks random (avoids repeating last track when 2+ exist)
- `MUSIC_init` — clears `MUSIC_CURRENT_FILE$`, delegates to `MUSIC_play_random`
- `MUSIC_tick` — called every frame; triggers `MUSIC_play_random` when track ends (auto-shuffle)
- `MUSIC_stop` — `_SNDSTOP` + `_SNDCLOSE`, clears `MUSIC_CURRENT_FILE$`
- `SOUND_apply_volume` — applies separate sfx/music volumes to all handles, respects mute flags
- `RANDOMIZE TIMER` called once at startup before `SOUND_init`

### MIDI Playback & SoundFont2

DRAW supports MIDI (`.mid`, `.midi`) and RIFF MIDI (`.rmi`) via QB64-PE's built-in `_SNDOPEN`. Before opening a MIDI/RMI track, call `_MIDISOUNDBANK` if `CFG.MIDI_SF2_FILE$` is non-empty:

```qb64
IF RIGHT$(UCASE$(file$), 4) = ".MID" OR RIGHT$(UCASE$(file$), 5) = ".MIDI" OR RIGHT$(UCASE$(file$), 4) = ".RMI" THEN
    IF LEN(_TRIM$(CFG.MIDI_SF2_FILE$)) > 0 THEN
        _MIDISOUNDBANK CFG.MIDI_SF2_FILE$, "sf2"
    END IF
END IF
MUSIC_HANDLE = _SNDOPEN(file$)
```

- `_MIDISOUNDBANK` must be called **before** `_SNDOPEN` for the SF2 to take effect
- If `MIDI_SF2_FILE$` is empty or the file is not found, QB64-PE falls back to built-in OPL3 FM emulation
- SF2 path is configured via **Settings → Audio → MIDI Soundfont** (Clear button removes it without reopening the Browse dialog)
- `MIDI_SF2_FILE` key in `DRAW.cfg` stores the path persistently

### NOW PLAYING Format

NOW PLAYING menu item (action 426, always disabled) shows:
```
NOW: <name> [<EXT>]
```
- `<name>` is the filename without extension, truncated to 32 chars
- `<EXT>` is the uppercase extension without the dot (e.g. `MOD`, `MID`, `RMI`)

AUDIO root menu: parentIdx=10 (rightmost), action IDs 417–426. Item 426 is always disabled (NOW PLAYING label only).

All sound filenames live in `ASSETS/THEMES/DEFAULT/THEME.CFG` (`THEME.SOUND_*_FILE$`). To replace a sound: edit THEME.CFG, no recompile needed.

---

## Where Sounds Are Wired

- **Shape tool clicks** (`INPUT/MOUSE.BM`): `SOUND_play SND_POINT` after `STROKE_begin`; `SOUND_play SND_DRAG_DROP` in `MOUSE_release_*`
- **Dot tool**: `SOUND_play SND_POINT` on every click
- **Marquee tools**: `SND_POINT` on click/vertex, `SOUND_loop SND_SELECTION` per frame while dragging, `SND_POINT` + `SND_DRAG_DROP` on finish (all 5 variants)
- **Opacity slider**: `SOUND_play SND_SLIDER` on drag release + wheel (layers panel + mouse handler)
- **Organizer widget**: `SOUND_play SND_ORGANIZER` on left/right/middle-click + wheel
