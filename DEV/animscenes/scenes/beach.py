"""beach - a sunny beach (48 frames, 12 fps, loops).

Umbrellas flap and the surf rolls (AnimBrush stamps, every frame at once, phases offset),
a beach ball bounces across and is thrown back (DRAWN arcs, TURN Z 720 each way), one gull
sails in toward us (SIZE 30 > 130) while another flies off into the distance (MOVE Z 0 >
700), a sunbather reddens in the sun and cools off (TINT toward red 0 > 45 and back), a
crab scuttles (straight paths, there and back), the sailboat drifts on the horizon, a
cloud fades in and out (OPACITY).
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('beach', sys.argv[1], frames=48, cols=8, fps=12)
W, H, N = S.w, S.h, S.frames

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 44, ['blue', 'blue', 'cyan', 'mist'])
bg.disc(132, 14, 8, col('yellow')); bg.disc(132, 14, 6, col('white'))
for y in range(45, 64):   # the sea
    for x in range(W):
        t = (y - 45) / 19.0
        c = col('navy') if dith(x, y, 0.6 - t * 0.6) else col('blue')
        if (x + y * 7) % 23 == 0 or ((x * 3 + y * 11) % 37 == 0 and y > 52):
            c = col('cyan')
        bg.set(x, y, c)
bg.rect(0, 45, W - 1, 45, col('mist'))
for y in range(64, H):    # the sand
    for x in range(W):
        bg.set(x, y, col('tan') if dith(x, y, 0.3 - (y - 64) / 200.0) else col('sand'))
        if (x * 13 + y * 7) % 41 == 0:
            bg.set(x, y, col('clay'))
bg.rect(0, 64, W - 1, 66, col('mist'))   # wet sand line under the surf
for y in range(67, 70):
    for x in range(W):
        if dith(x, y, 0.5):
            bg.set(x, y, col('tan'))


def towel(img, x, y, c1, c2):
    for j in range(8):
        img.rect(x, y + j, x + 26, y + j, col(c1 if (j // 2) % 2 else c2))


towel(bg, 14, 94, 'pink', 'white'); towel(bg, 104, 100, 'lime', 'yellow')
bg.rect(52, 84, 52, 108, col('grey')); bg.rect(126, 80, 126, 102, col('grey'))   # umbrella poles
# sunbather on the right towel (the other one is a brush)
bg.ellipse(115, 103, 8, 2.5, col('skin')); bg.disc(124, 103, 2.5, col('skin')); bg.rect(109, 102, 112, 104, col('navy'))
bg.disc(125, 102, 1.5, col('bark'))
# a red bucket + spade: the sunburn tint key
bg.rect(70, 104, 76, 112, col('red')); bg.rect(70, 104, 76, 104, col('pink')); bg.line(77, 103, 81, 112, col('grey'))
# sandcastle
bg.rect(84, 106, 98, 114, col('tan')); bg.rect(87, 101, 95, 106, col('tan')); bg.rect(90, 97, 92, 101, col('tan'))
for x in (84, 88, 92, 96):
    bg.set(x, 105, col('tan'))
bg.line(91, 92, 91, 97, col('bark')); bg.rect(92, 92, 95, 94, col('red'))


# ------------------------------------------------------------ brushes -------
def umbrella(c1, c2):
    cels = []
    for k in range(4):
        c = Img(36, 14)
        flap = [0, 1, 2, 1][k]
        for i in range(6):
            x0 = 2 + i * 5.33
            for xx in range(int(x0), int(x0 + 6)):
                u = (xx - 18) / 16.0
                top = 2 + int(8 * u * u) - (flap if i in (0, 5) else 0)
                bot = 10 + (flap if i % 2 else 0) - int(1 * u * u)
                for yy in range(top, bot):
                    c.set(xx, yy, col(c1 if i % 2 else c2))
        c.rect(17, 0, 18, 2, col('grey'))
        cels.append(c)
    return cels


def surf():
    cels = []
    for k in range(4):
        c = Img(54, 6)
        for x in range(54):
            yy = 2 + 1.6 * math.sin((x + k * 13.5) * 2 * math.pi / 54)
            for t in range(3):
                c.set(x, yy + t, col('white' if t == 0 else ('mist' if t == 1 else 'cyan')))
        cels.append(c)
    return cels


def ball():
    cels = []
    for k in range(2):
        c = Img(11, 11)
        cols = ['red', 'white', 'blue', 'yellow', 'white', 'lime']
        for y in range(11):
            for x in range(11):
                dx, dy = x - 5, y - 5
                if dx * dx + dy * dy <= 27:
                    a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
                    c.set(x, y, col(cols[int(a * 6 + k * 0.5) % 6]))
        c.disc(5, 5, 1.2, col('white')); c.set(3, 3, col('white'))
        cels.append(c)
    return cels


def gull():
    cels = []
    for k in range(4):
        c = Img(15, 7)
        lift = [0, 2, 3, 2][k]
        c.line(0, 1 + lift, 6, 4, col('white')); c.line(14, 1 + lift, 8, 4, col('white'))
        c.line(1, 2 + lift, 6, 5, col('mist')); c.line(13, 2 + lift, 8, 5, col('mist'))
        c.rect(6, 4, 8, 5, col('white')); c.set(9, 4, col('amber'))
        cels.append(c)
    return cels


def sunbather():
    c = Img(28, 8)
    c.ellipse(11, 4, 9, 2.5, col('skin')); c.disc(22, 4, 2.6, col('skin'))
    c.rect(5, 3, 8, 5, col('orange')); c.rect(12, 3, 14, 4, col('orange'))
    c.disc(23, 3, 1.6, col('bark')); c.rect(20, 2, 25, 2, col('ink'))   # hair, sunglasses
    return [c]


def crab():
    cels = []
    for k in range(2):
        c = Img(11, 6)
        c.ellipse(5, 3, 3.5, 2, col('rust')); c.set(4, 1, col('ink')); c.set(6, 1, col('ink'))
        for i, x in enumerate((1, 2, 8, 9)):
            c.set(x, 4 + ((i + k) % 2), col('rust'))
        c.set(0, 1 + k, col('red')); c.set(10, 1 + k, col('red'))
        cels.append(c)
    return cels


def boat():
    c = Img(12, 12)
    c.line(6, 0, 6, 9, col('bark')); c.rect(1, 9, 11, 10, col('wood')); c.rect(3, 11, 9, 11, col('wood'))
    for y in range(1, 9):
        c.rect(7, y, 7 + (y * 4) // 8, y, col('white'))
        c.rect(6 - (y * 3) // 9, y, 5, y, col('mist'))
    return [c]


def cloud():
    c = Img(30, 10)
    for dx, r in ((-9, 3), (-3, 5), (4, 4), (10, 3)):
        c.disc(15 + dx, 5, r, col('white'))
    c.rect(4, 7, 26, 9, col('mist'))
    return [c]


S.brush(1, 'umbrella-red', umbrella('red', 'white'), 'a beach umbrella flapping: stamp, every frame at once')
S.brush(2, 'umbrella-blue', umbrella('blue', 'yellow'), 'another umbrella')
S.brush(3, 'surf', surf(), 'the surf rolling in: stamp along the shore, phases offset')
S.brush(4, 'beachball', ball(), 'a beach ball: DRAWN bounces, TURN Z 720')
S.brush(5, 'gull', gull(), 'a gull: SIZE 30 > 130 toward us, or MOVE Z 0 > 700 away')
S.brush(6, 'sunbather', sunbather(), 'a sunbather: TINT toward red 0 > 45, then back')
S.brush(7, 'crab', crab(), 'a crab: straight paths there and back')
S.brush(8, 'sailboat', boat(), 'a sailboat on the horizon: a slow straight path')
S.brush(9, 'cloud', cloud(), 'a cloud: OPACITY 100 > 40 and back')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_RED=S.find(bg, E['red'], 68, 103, 78, 113))


def arc_pts(x0, x1, base, heights, n=9):
    """bounces from x0 to x1: one parabola per height (equal widths)."""
    pts = []
    k = len(heights); seg = (x1 - x0) / k
    for j, h in enumerate(heights):
        for i in range(n + (1 if j == k - 1 else 0)):
            t = i / n
            pts.append((round(x0 + seg * (j + t)), round(base - h * 4 * t * (1 - t))))
    return ' '.join('%d,%d' % p for p in pts)


mv = ['layer umbrellas; pick 1 4 umbrella-red', 'stamp 52 80 0', 'pick 2 4 umbrella-blue', 'stamp 126 76 2',
      'layer surf; pick 3 4 surf', 'stamp 27 63 0', 'stamp 80 64 1', 'stamp 133 63 2',
      'layer sailboat; pick 8 1 sailboat',
      'mv 30 40 46 40 label="the sailboat drifts out" from=1 count=24 ease=3',
      'mv 46 40 30 40 label="... and back" from=25 count=24 ease=3',
      'layer cloud; pick 9 1 cloud',
      'mv 40 16 52 16 label="a cloud drifts and thins (OPACITY 100 > 40)" from=1 count=24 o1=40 ease=3',
      'mv 52 16 40 16 label="... and thickens again (OPACITY 40 > 100)" from=25 count=24 o0=40 ease=3',
      'fg_key "$KEY_RED"',
      'layer sunbather; pick 6 1 sunbather',
      'mv 27 98 27 98 label="the sunbather reddens (TINT red 0 > 45)" from=1 count=24 t1=45 ease=3',
      'mv 27 98 27 98 label="... and cools off in the shade (TINT 45 > 0)" from=25 count=24 t0=45 ease=3',
      'layer crab; pick 7 2 crab',
      'mv 8 80 40 84 label="a crab scuttles right" from=1 count=24',
      'mv 40 84 8 80 label="... and back" from=25 count=24',
      'layer ball; pick 4 2 beachball',
      'mv 0 0 0 0 label="the beach ball bounces across (DRAWN, TURN Z 720)" path=drawn pts="%s" from=1 count=24 tz=720' % arc_pts(20, 140, 100, (36, 22, 12)),
      'mv 0 0 0 0 label="... and is thrown back (DRAWN, TURN Z -720)" path=drawn pts="%s" from=25 count=24 tz=-720' % arc_pts(140, 20, 100, (40,)),
      'layer gulls; pick 5 4 gull',
      'mv 150 10 -14 40 label="a gull sails in toward us and out of the frame (SIZE 30 > 130)" from=1 count=30 s0=30 s1=130 every=2',
      'mv 20 30 110 12 label="a gull flies off into the distance (MOVE Z 0 > 700)" from=20 count=29 z=700 every=2']
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'sunny beach day, carefree', 'chip', 5501, '--mood', 'playful', '--key', 'C major', '--bpm', 120, '--seconds', 4)
bed = [(au.fit(au.load(music), T), 0, 0.55), (au.surf(T, [0.4, 2.4], 51), 0, 0.9)]
au.mix(os.path.join(S.dir, 'beach-music.wav'), T, bed)
bounce = au.thud(140, 0.25)
sfx = [(au.gull(), S.t(4), 0.8), (au.gull(), S.t(27), 0.6), (bounce, S.t(9), 0.5), (bounce, S.t(17), 0.4),
       (bounce, S.t(24), 0.3), (bounce, S.t(48), 0.4)]
au.mix(os.path.join(S.dir, 'beach-sfx.wav'), T, sfx)
print('beach ok', S.dir)
