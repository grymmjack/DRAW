DRAW animated scenes

Nine animated scenes with sound. Each has its OWN AnimBrush pack, and each was built by
DRAW itself: every moving thing is a Move Brush with typed values (position on straight
and drawn paths, SIZE, MOVE Z, TURN X / Y / Z, OPACITY, TINT) on its own layer.

PLAY ONE
  File > Open NAME/NAME.draw, then Num 0 (the lightbox) and Num Enter (play).
  The two sound tracks (music + effects) are in the X-sheet; the WAVs sit beside the .draw.
  ANIM > Big Frame + X-Sheet shows the frame big, under the X-sheet.

IN EACH FOLDER
  NAME.draw          the scene: layers, frames, soundtrack
  NAME.gif           the same, exported (no sound)
  NAME-pack.dset     its AnimBrush pack: Drawer > Load Set. Hover a bin to play it.
  NAME-pack.txt      what each bin is and how the scene uses it
  brushes/*.png      each brush as a strip with frame data: ANIM > AnimBrush > Load...
  NAME-music.wav     the music track       NAME-sfx.wav   the effects track
  NAME-moves.txt     every Move Brush in the scene, one per line:
                     label | path | from>to | from F count C every E ease E |
                     z / turn x/y/z / size a>b / op a>b / tint a>b / the FG (tint) colour
                     (ease: 0 none, 1 in, 2 out, 3 in-out; count 0 = to the last frame)

THE SCENES  (160x120, 12 fps)
  space          64 frames  two shots: orbit (parallax stars, the planet growing, a ship
                            curving down - Z, turn, tint) and a fade through black to the
                            surface (a moon fading in, the lander coming down, dust)
  alien-attack   48         an original invaders-style loop: the formation marches, a tank
                            fires, bombs flip down, the mothership blows apart; seamless
  brick-breaker  48         a simulated rally: the ball on a drawn path, bricks bursting,
                            a capsule flipping into the paddle
  bakery         48         a sunlit table: steam that grows and fades, dust motes on
                            drawn loops, a sunbeam brightening and warming
  beach          48         umbrellas, surf, a spinning beach ball, a gull toward you (SIZE),
                            one away (MOVE Z), a sunbather turning red (TINT)
  dungeon        48         torches and skull candles, spiders on silk, a turning key,
                            a ghost fading in and out, drips, a bat flying at you
  fireworks      60         rockets, bursts that grow, fade and cool from white, a tilted
                            ring (TURN X), a pinwheel, a grand finale
  platformer     60         an original robot runs and jumps (drawn arcs), coins flip
                            (TURN Y), the fall into the pit, GAME OVER
  stormy-night   48         the extra pack: rain, lightning, a storm cloud, a TV, a radio,
                            a computer, a snow globe, a dog, a cat and two monsters
                            (its pack also has snow, sun, a bird and a fish)

REBUILD AN ELEMENT
  Pick its bin, ANIM > Move Brush > Start, drag its path in the lightbox (Path: Line or
  Drawn), type the numbers from NAME-moves.txt into the Move boxes, Enter. For a tint, set
  the FG colour first.

The arcade and platformer scenes are original designs in those genres: no characters,
sprites, names or music from existing games. The art and sounds were made for DRAW
(DEV/animscenes/ in the source has the scripts that made them).
