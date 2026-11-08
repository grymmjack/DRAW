---
name: qb64pe-sndopen-async-memsound
description: QB64-PE _SNDOPEN decodes asynchronously by default; _MEMSOUND right after reads a half-filled buffer (flaky all-zero waveform) - open with "noasync"
metadata:
  type: reference
---

QB64-PE (v4.6+, confirmed in ~/git/qb64pe internal/c/parts/audio/audio.cpp) opens sounds with
MA_SOUND_FLAG_DECODE | MA_SOUND_FLAG_ASYNC by default. `_MEMSOUND(h, 0)` right after `_SNDOPEN`
returns a valid _MEM over a buffer that is still being filled, so reading samples gives zeros
on some runs only (seen as a flat soundtrack waveform at the 3x user profile, fine at 2x).
Fix: `_SNDOPEN(f, "noasync")` when the samples are read straight away (DRAW TOOLS/ANIM-SOUND
ANIM_SND_sync). Other flags in the same parser: "stream", "nodecode", "memory".
Also: `_MEMSOUND` data is resampled to `_SNDRATE` (48000 here), so a sharp edge in a fixture
leaks a few samples into the next 1/100 s bin - keep test silences away from bin edges.

Related: [[project-animation]]
