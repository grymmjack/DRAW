DRAW animation projects

Four complete animation projects that use the clip and lane features together: clip layers,
keyframe lanes with eases, modulators, shared clip sources, sounds on clips, tags, frame notes,
holds, a reference layer and linked cells - plus a soundtrack. Each was built by DRAW itself,
driven step by step (DEV/animscenes in the source tree), so every clip and lane is real and
editable: open the project, click a clip layer and its settings are in the Animation panel.

PLAY ONE
  File > Open NAME/NAME.draw, then Num 0 (the lightbox) and Num Enter (play).
  The X-sheet (Num 8) shows the acts as TAGS, the director's notes, the holds, and the
  soundtrack's two tracks (music + effects). The clips' own sounds play with them.

LOOK INSIDE
  Click a layer whose name ends in "(clip)" - or any layer named in NAME-clips.txt. The
  Animation panel shows its clip rows (IN / OUT, START CEL / EVERY, X / Y, mode, flip, its
  SOURCE and SOUNDS) and the lane rows: LANE < > picks X, Y, SCALE X / Y, ROTATE, OPACITY,
  TINT, PIVOT X / Y, VOLUME or PAN; KEYS shows that lane's keys (KEY / DEL / the ease);
  MOD shows its modulator (sine, triangle, square, saw or noise: amount, period, phase / seed).
  Step through the frames and watch the values change.

IN EACH FOLDER
  NAME.draw          the project: layers, clips, lanes, tags, notes, holds, soundtrack
  NAME.gif           the same, exported (no sound; the reference layer is left out)
  NAME-clips.txt     how it was built, in order: every clip with its settings, every lane
                     key (frame = value, ease 0 linear 1 in 2 out 3 in-out 4 hold), every
                     modulator, the shared sources, tags, notes, holds
  NAME-pack.dset     its AnimBrush pack: Drawer > Load Set. Hover a bin to play it.
  NAME-pack.txt      what each bin is and how the project uses it
  brushes/*.png      each brush as a strip with frame data (ANIM > AnimBrush > Load...)
  brushes/*.gif      the same as animated GIFs
  *.wav              the music and effects tracks, and the sounds the clips play - keep
                     them beside the .draw: DRAW finds them there by name

THE PROJECTS  (160x120, 12 fps, 64 frames)
  reef       CALM / SHARK / TREASURE. Light rays (OPACITY sine + SCALE X triangle, two clips
             of one source, phases apart); kelp swaying about its foot (ROTATE triangle,
             PIVOT Y key, ping-pong); a school of five fish of ONE source (X keys that drift
             then dart - ease in, Y sine at five phases, a scatter key) - Copy / Paste Lanes;
             a jellyfish rising (ease in-out), pulsing (SCALE Y sine), blubbing each time it
             loops (sound on loop, VOLUME); the shark (frames 25-44: X keys, ROTATE keys, its
             rumble when it starts, VOLUME and PAN keys); a crab (X triangle, a click on a
             cel); the chest (mode Hold, a creak, TINT toward gold); a blue school swimming
             back flipped; bubbles from a Move Brush applied as a clip; a linked starfish.
  neon       RAIN / TRAFFIC / BLACKOUT. A rainy street at night: windows tinted toward TV
             cyan that go dark one by one (OPACITY hold keys); BAR blinking (OPACITY square);
             HOTEL buzzing (OPACITY noise + keys - it dies in the blackout); puddles rippling
             (SCALE X sine); steam from a Move Brush applied as a clip; a walker (X keys, Y
             square); a cat (ping-pong, a meow on a cel); a red car and a blue one, flipped,
             with their engines panned and faded (VOLUME / PAN keys); lightning (OPACITY hold
             keys, thunder when it starts).
  carnival   DAY / DUSK / LIGHTS. The ferris wheel turns once a loop (ROTATE saw); four
             gondolas ride its circle (X sine + Y sine a quarter period apart, one source,
             four phases); bunting flutters; carousel horses bob and circle; three balloons of
             one source turn blue in one step (Update Clip from AnimBrush); one gets away and
             pops (mode Once, a sound on a cel); jugglers (ping-pong; flipped + reverse); the
             dusk falls purple (TINT toward FG + OPACITY keys); the lights switch on (hold
             keys) and chase (OPACITY square, half a period apart); confetti (Y noise).
  farm       DAWN / NOON / DUSK / NIGHT. The sun's arc (X / Y keys with eases, TINT keys red
             at sunrise and sunset); the near windmill (ROTATE keys) and the far one (ROTATE
             saw, scaled, then Bake Clip to Pixels); clouds (X keys in-out, SCALE X sine); the
             tractor (X keys, its engine's VOLUME and PAN keys, a bump keyed by nudging the
             clip with Ctrl+arrows); a sheep drawn as four frames and turned into a clip
             (Make Clip from Selected Frames) and a second sheep switched to that source; the
             rooster (frames 1-16, ping-pong, a crow); warm and night skies (full-frame clips,
             OPACITY keys); stars, the moon, the owl (mode Hold, a hoot), fireflies (X / Y
             noise with their own seeds, OPACITY sine); a linked FARM sign.

Every project also has a layout guide on top as a REFERENCE layer: you see it while you
work, it is never exported. The backgrounds use Layer Same on Every Frame.
