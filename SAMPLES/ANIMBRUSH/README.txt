DRAW AnimBrush examples

A pack of 15 animated brushes (AnimBrushes) and three scenes built from it.

THE PACK
ASSETS/DSETS/BRUSHES/animbrush-pack.dset is a Drawer brush set: each bin holds an
AnimBrush. Open it from the Drawer's brush set list (or Drawer > Load Set), click a bin,
and the brush has all its cels.

 bin  brush       size    cels  use it with
  1   torch       9x18     6    Every Frame at Once. Alt+] before the next torch so they
                                don't flicker together
  2   campfire   20x16     6    Every Frame at Once
  3   smoke      10x26     8    Every Frame at Once; it rises and loops seamlessly
  4   star        7x7      8    Every Frame at Once; scatter several, each with its own Alt+]
  5   firefly     7x7      8    Every Frame at Once; pulses on and off
  6   flag       14x14     6    Every Frame at Once; the pole's foot is the brush's bottom left
  7   bat        17x10     4    Move Brush (drag a path, Enter)
  8   ghost      12x15     4    Move Brush, Ease In-Out, Next Cel Every 2 Frames
  9   owl        11x14    12    Every Frame at Once; blinks once every 12 frames
 10   waterfall  16x16     4    Every Frame at Once; stack copies straight down, same phase
 11   splash     26x11     4    Every Frame at Once, where falling water lands
 12   ripple     17x7      8    Every Frame at Once, on still water
 13   grass      10x10     3    AnimBrush Order: Ping-Pong, Every Frame at Once - it sways
 14   butterfly   9x7      4    Move Brush, Ease In-Out
 15   bird       13x7      4    Move Brush, Next Cel Every 2 Frames

brushes/NAME.png    each brush on its own, as a strip with frame data:
                    ANIM > AnimBrush > Load... takes it; File > Open shows its frames.

THE SCENES  (24 frames of 160x120 at 12 fps - Num 0 = lightbox, Num Enter = play)
scenes/castle-night.draw     stars, flags and torches stamped on every frame with
                             different phases; a bat and a ghost on Move Brush paths
scenes/campfire-night.draw   smoke, campfire, an owl that blinks, fireflies
scenes/waterfall-day.draw    four stacked waterfall tiles, splash, ripples, ping-pong
                             grass, a butterfly and a bird on Move Brush paths
scenes/NAME.gif              the same, exported (ANIM > Export Animated GIF...)
scenes/NAME-base.png         where each scene started: the background in frame 1 only

HOW A SCENE IS MADE
1. File > New Animation... (or open a picture with frames). Pick a frame count every
   loop divides into: 24 frames fit loops of 2, 3, 4, 6, 8 and 12 cels.
2. Draw the background in frame 1 and turn on ANIM > Layer Same on Every Frame: every
   frame shows it.
3. Num 0 (the lightbox). ANIM > AnimBrush > Every Frame at Once.
4. For each animated thing: a new layer (Ctrl+Shift+N), click its Drawer bin, Alt+]
   a few times so it is out of step with its neighbours, click where it goes.
   One click = every frame, each with its own cel, one undo step.
5. Things that travel: ANIM > Move Brush > Start, drag the path, Enter. Set the ease
   and "next cel every N frames" in the same menu first.
6. Num Enter plays it. ANIM > Export Animated GIF... when you like it.

Made by DEV/animbrush-pack/make-pack.py (the brushes, the pack, the backgrounds) and
DEV/animbrush-pack/build-scenes.sh (DRAW itself building the scenes from the pack).
