# Color cycling examples

Six classic palette-cycling scenes (320x200), each saved in every format DRAW
can write with its cycle ranges:

| File | What it is |
|------|------------|
| `NAME.draw` | The DRAW document. Open it and press **Shift+Tab** to cycle. |
| `NAME.bas` | A single-file QB64 program that plays the cycle: `qb64pe -x NAME.bas`. SPACE pauses, `+`/`-` change speed, R restarts, ESC quits. |
| `NAME.gif` | A still GIF carrying GrafX2 `CRNG` cycle ranges. It cycles in GrafX2 and loads back into DRAW with its ranges. |
| `NAME-anim.gif` | An animated GIF of one full cycle loop, for browsers and chat. |
| `NAME.lbm` | A DeluxePaint ILBM with `CRNG` chunks, for DeluxePaint, GrafX2, PyDPainter and others. |

| Scene | Ranges |
|-------|--------|
| `waterfall` | water falls (16 colors, forward, 16 steps/s); foam ripples outward (8 colors, 8/s) |
| `fire` | flames rise (24 colors, forward, 24/s); embers flicker (8 colors, ping-pong, 7/s) |
| `tunnel` | a rainbow spiral turns (24 colors, reverse, 12/s) |
| `marquee` | chase lights run around the sign (4 colors, 8/s); the letters glow (10 colors, ping-pong, 9/s) |
| `ocean-sunset` | waves roll in (12 colors, reverse, 6/s); the sun's glitter shimmers (8 colors, ping-pong, 7/s) |
| `pinwheel` | the wheel spins (24 colors, 12/s); the stars twinkle (4 colors, 3/s) |

These files are generated. To rebuild them, run
`DEV/tools/make-cycle-examples.sh`, which draws each scene with
`DEV/tools/cycle-examples.py` and then calls DRAW's batch mode:

```bash
DRAW scene.png --palette scene.gpl --cycle 27-42:16 --cycle 43-50:8 --export scene.draw
DRAW scene.draw --export scene.bas      # also .gif, .lbm, or --export-anim scene-anim.gif
```

How color cycling works in DRAW is covered in the manual: *Color & Palette > Color Cycling*.
