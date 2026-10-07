# Color cycling examples

Fifteen palette-cycling scenes (320x200), each saved in every format DRAW
can write with its cycle ranges:

| File | What it is |
|------|------------|
| `NAME.draw` | The DRAW document. Open it and press **Shift+Tab** to cycle. |
| `NAME.bas` | A single-file QB64 program that plays the cycle: `qb64pe -x NAME.bas`. SPACE pauses, `+`/`-` change speed, R restarts, ESC quits. |
| `NAME.gif` | A still GIF carrying GrafX2 `CRNG` cycle ranges. It cycles in GrafX2 and loads back into DRAW with its ranges. |
| `ANIMATED_GIF_VERSION/NAME-anim.gif` | An animated GIF of one full cycle loop, for browsers and chat. It is a recording, not a cycling document: it has no ranges, so opening it in DRAW won't cycle. |
| `NAME.lbm` | A DeluxePaint ILBM with `CRNG` chunks, for DeluxePaint, GrafX2, PyDPainter and others. |

| Scene | Ranges |
|-------|--------|
| `waterfall` | water falls (16 colors, forward, 16 steps/s); foam ripples outward (8 colors, 8/s) |
| `fire` | flames rise (24 colors, forward, 24/s); embers flicker (8 colors, ping-pong, 7/s) |
| `tunnel` | a rainbow spiral turns (24 colors, reverse, 12/s) |
| `marquee` | chase lights run around the sign (4 colors, 8/s); the letters glow (10 colors, ping-pong, 9/s) |
| `ocean-sunset` | waves roll in (12 colors, reverse, 6/s); the sun's glitter shimmers (8 colors, ping-pong, 7/s) |
| `pinwheel` | the wheel spins (24 colors, 12/s); the stars twinkle (4 colors, 3/s) |
| `candles` | three flames flicker, each at its own speed (12 colors each, 12/18/24 steps/s); their glow on the wall breathes (10 colors, ping-pong, 9/s) |
| `hanukkah` | nine menorah flames flicker in three speeds (10 colors each, 10/15/20/s); the glow breathes and the greeting shimmers (10 colors each, ping-pong, 9/s) |
| `halloween` | jack-o'-lantern faces flicker (12 colors, ping-pong, 11/s); fog drifts (12 colors, 6/s); two flocks of bats flap across the sky (10 and 8 colors, 10/s and 8/s) |
| `skull` | fire burns up out of each eye (24 and 20 colors, 24/s and 20/s); the sockets' rims glow (8 colors, ping-pong, 7/s); embers drift up (40 colors, 20/s) |
| `snake` | the scales slither toward the head (two 12-color ranges in step, 6/s); the forked tongue darts out and back (five 16-color ranges in step, 16/s); fireflies blink (10 colors, ping-pong, 9/s) |
| `christmas` | snow falls, far and near (48 and 40 colors, 24/s and 40/s); the star shimmers (8 colors, ping-pong, 7/s) and shoots sparkles (16 colors, 16/s); the lights chase (8 colors, 4/s); the greeting shimmers (10 colors, ping-pong, 9/s) |
| `new-year` | five rockets climb and burst in turn (one range each, 30 to 40 colors, every 2 s); the city's windows flicker (20 colors, 10/s); the greeting shimmers (10 colors, ping-pong, 9/s) |
| `valentine` | the heart beats outward in rings (12 colors, 12/s) over a turning sunburst (16 colors, 8/s); sparkles twinkle (8 colors, ping-pong, 7/s); the letters shimmer (10 colors, ping-pong, 9/s) |
| `st-patricks` | the rainbow's colors flow outward (20 colors, 10/s); the pot of gold glitters (10 colors, ping-pong, 9/s); the greeting shimmers (10 colors, ping-pong, 9/s) |

The bats, snow, embers, rockets and the snake's tongue use DeluxePaint-era
tricks rather than plain gradients:

- **Sprite path** (bats): every position along the flight path holds its own
  copy of the bat, drawn in its own palette index. Only one entry of the range
  is bat-colored and the rest are the sky color, so rotating the range shows
  one bat at a time and it hops along the path.
- **Streak** (snow, embers, rockets): one bright entry, a few fading entries
  behind it, and the rest the background color, run along a line of indices.
  The head moves along the line and leaves a tail.
- **Timeline** (the tongue): each tongue segment is drawn in the *first* index
  of its own range, and the range's colors are that segment's frames (on or
  off) played in order. The five ranges have the same length and speed, so they
  stay in step and the tongue extends one segment at a time.

These only work over a flat background, because the range's "off" colors must
match the pixels around the moving thing. Every range in these scenes repeats
within 2 s, so each animated GIF loops in 2 s.

These files are generated. To rebuild them, run
`DEV/tools/make-cycle-examples.sh`, which draws each scene with
`DEV/tools/cycle-examples.py` and then calls DRAW's batch mode:

```bash
DRAW scene.png --palette scene.gpl --cycle 27-42:16 --cycle 43-50:8 --export scene.draw
DRAW scene.draw --export scene.bas      # also .gif, .lbm, or --export-anim scene-anim.gif
```

How color cycling works in DRAW is covered in the manual: *Color & Palette > Color Cycling*.
