---
name: qb64pe-memsound-24bit
description: QB64-PE _MEMSOUND returns no samples (SIZE 0) for 24-bit audio even though it plays; DRAW reads such WAVs itself
metadata:
  type: reference
---

[Linux, QB64-PE v4.6+ main repo, 2026-11-10] `_MEMSOUND(h, 0)` gives `_MEMEXISTS = 0, SIZE 0,
TYPE 0` for any 24-bit file (a 20 s clip too), with or without "noasync" — while `_SNDOPEN`,
`_SNDLEN` and playback work. The 16-bit copy of the same file, full 2:33 length, gives
TYPE 130 normally. So it is the sample format, not length or flags. Untested on macOS/Windows.

Effect in DRAW before the fix: no X-sheet waveform (the file name only) and the clip was
silently LEFT OUT of a mix of clips. Fix: `ANIM_SND_readable%` + `ANIM_SND_wav_load&`
(TOOLS/ANIM-SOUND.BM) — DRAW parses the WAV and builds a `_SNDNEW` stereo float copy.
24-bit FLAC / AIFF still have no waveform. Related: [[qb64pe-sndopen-async-memsound]],
[[qb64pe-mem-errors-critical]].
