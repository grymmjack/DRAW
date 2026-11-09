---
name: qb64pe-mem-errors-critical
description: QB64-PE _MEM errors 300-315 bypass ON ERROR (dialog + exit); _MEMSOUND lock freed on another thread races the unlocked lock pool; QB64PE_NOPROMPT=y for test launches
metadata:
  type: reference
---

- QB64-PE `fix_error` sets `prevent_handling` for errors 300-315 (every `_MEM` error: region out of range, memory has been freed, ...): they are **critical**, `ON ERROR GOTO FatalError` never runs, the program shows a dialog and exits. Guard with `_MEMEXISTS(m)` before `_MEMGET` / `_MEMPUT` / `_MEMFREE` whenever the owner can disappear. (`_MEMFREE` on a dead block = error 307, also critical.)
- [Linux, QB64-PE v4.6+] A sound read with `_MEMSOUND` caches a mem lock on its handle; `_SNDCLOSE` only sets autoKill, and `AudioEngine::Update()` (MAIN_LOOP thread, ~60 Hz) later calls `free_mem_lock`. `new_mem_lock` / `free_mem_lock` (libqb/src/memblock.cpp) have no mutex, and QBMAIN takes/frees locks constantly (`_MEMIMAGE`, `_FREEIMAGE`), so one lock can be handed out twice → "Memory has been freed" later on an unrelated read. DRAW's workaround: `ANIM_SND_close` + `ANIM_SND_let_go` (`_DELAY 0.1` after closing, so the free happens while QBMAIN is quiet). Timing-dependent: logging on hid it; QA test `anim-sound-mem-race.sh` (8 drops) caught it on the old build.
- `QB64PE_NOPROMPT=y` makes critical / unhandled errors print `Runtime error: ...` to stderr and exit instead of a kdialog/zenity alert — which otherwise reaches the user's real desktop (D-Bus / Wayland) even from an Xvfb run. The qa-harness DRAW adapter sets it on launch (2026-11-09).
- Worth reporting upstream (a740g / QB64-PE audio + memblock): the lock pool needs a mutex, or ReleaseHandle should free locks on QBMAIN. Not filed yet.
