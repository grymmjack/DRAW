# a740g GLFW regression: Ctrl+Alt+letter swallows the letter key

**Summary:** When DRAW is built with a740g's GLFW-backend PR, `Ctrl+Alt+O`
(Toggle CRT effect) no longer fires. Root cause, confirmed with a keycode
scanner under both compilers: **a740g's GLFW backend drops the letter keypress
entirely while Ctrl+Alt are held** — neither `_KEYHIT` nor `_KEYDOWN` ever sees
it. The modifiers themselves are detected fine. The stable SDL2 build (v450)
reports the same physical input correctly. This is a **backend regression in the
PR**, not a DRAW bug — there is no code for DRAW to check, because the key event
never arrives.

## Environment

- Broken: a740g compiler — `~/git/qb64pe-a740g-test/qb64pe` (GLFW backend)
- Works: v450 compiler — `~/git/qb64pe-450/qb64pe` (SDL2 backend)
- OS: Linux (X11, display :1). [Linux] — needs confirmation on macOS/Windows.

## Reproduce (no DRAW needed — standalone scanner)

```bash
cd PLANS/TESTS/GLFW
make a740g-run TEST=KEYCODE                                     # GLFW build
make a740g-run TEST=KEYCODE QB64PE=$HOME/git/qb64pe-450/qb64pe  # SDL2 build
```

Focus the window, **hold Ctrl+Alt, then press O**. Watch the `O key` row and the
`Ctrl+Alt+O FIRES` line. (Automated here via `xdotool keydown ctrl alt o` +
`import` capture; identical input to both builds.)

## A/B evidence

Same identical synthetic input (`Ctrl` down, `Alt` down, `O` down, held), the
only variable is the compiler:

| Scanner readout (held Ctrl+Alt+O) | a740g (GLFW) | v450 (SDL2) |
|-----------------------------------|:------------:|:-----------:|
| `CTRL` (`_KEYDOWN 100305/100306`) | **ON** (100306=Y) | ON (100306=Y) |
| `ALT` (`_KEYDOWN 100307/100308`)  | **ON** (100308=Y) | ON (100308=Y) |
| `O key` `_KEYDOWN(111)` lowercase | **n** | **Y** |
| `O key` `_KEYDOWN(79)` uppercase  | n | n |
| `O key` `_KEYDOWN(15)` `^O`       | n | n |
| `O` seen in `_KEYHIT` history     | **no — only `100308 100306`** | **yes — `111 100308 100306`** |
| Currently DOWN codes              | `100306 100308` (2) | `111 100306 100308` (3) |
| **Ctrl+Alt+O FIRES (DRAW logic)** | **off** | **ON** |

Screenshots in `evidence/`:
- `a740g_ctrl-alt-o_BROKEN.png` — letter swallowed, FIRES=off
- `v450_ctrl-alt-o_WORKS.png` — letter present (111), FIRES=ON
- `a740g_ctrl-o_works.png` — see scope below

## Scope

- **Ctrl+Alt+letter → BROKEN** under a740g (letter event dropped).
- **Plain Ctrl+letter → WORKS** under a740g: holding just `Ctrl+O` reports
  `_KEYDOWN(111)=Y` and `_KEYHIT 111` (see `a740g_ctrl-o_works.png`). So
  DRAW's common `Ctrl+Z` / `Ctrl+B` / `Ctrl+S` hotkeys are unaffected.
- **Alt-alone + letter → untested via automation:** synthetic `Alt` alone gets
  grabbed by the window manager (Alt is a WM drag/Alt+F4 modifier), so xdotool
  can't deliver it cleanly. Worth a manual check on a740g.

## Why this is the backend, not DRAW

DRAW detects the hotkey at `INPUT/KEYBOARD.BM:3391`:
```qb64
IF MODIFIERS.ctrl% AND MODIFIERS.alt% AND NOT MODIFIERS.shift% AND _
   (_KEYDOWN(111) OR _KEYDOWN(79)) THEN  ' MODIFIERS.* come from _KEYDOWN(100305..100308)
```
The modifiers resolve true under a740g (confirmed), but `_KEYDOWN(111)` and
`_KEYDOWN(79)` are both false and `_KEYHIT` never returns `111` — the letter
event is gone before QB64 keyword level. The usual "accept both physical codes"
workaround can't help: **no code lights up at all.** The same DRAW code path
works under v450. The fix belongs in the GLFW key-translation path of the PR.

## Suggested next step (for a740g)

Investigate the GLFW key callback / event translation for the case where Ctrl
**and** Alt modifiers are active: the non-modifier key event appears to be
filtered or remapped away (possibly treated like an AltGr / compose sequence).
Expected: a letter pressed with Ctrl+Alt should still surface as its base
`_KEYHIT`/`_KEYDOWN` code (e.g. `111`), exactly as the SDL2 backend does.

## DRAW action

**None.** DRAW's hotkey code is correct and works on SDL2; do not patch it.
Re-test `Ctrl+Alt+O` (and the text-tool `Ctrl+Alt+.` / `Ctrl+Alt+,` /
`Ctrl+Alt+Up` / `Ctrl+Alt+Down`) once a740g updates the PR.
