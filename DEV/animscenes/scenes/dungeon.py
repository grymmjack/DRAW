"""dungeon - cobblestone, torches, spiders in webs, skulls with candles (48 frames, loops).

Torches and skull candles flicker (AnimBrush stamps, every frame at once, phases offset),
the torchlight swells and ebbs (OPACITY 55 > 100 + TINT toward orange, there and back),
two spiders lower themselves on silk and climb back (straight paths, ease, TURN Z 20 twist),
a bat bursts out of the doorway at us (SIZE 15 > 420), a ghost drifts and fades in and out
(OPACITY 0 > 75 > 0, TURN Y), water drips from the ceiling (straight paths, OPACITY > 0),
a key turns on its nail (TURN Y 353, one turn per loop).
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('dungeon', sys.argv[1], frames=48, cols=8, fps=12)
W, H, N = S.w, S.h, S.frames
rnd = random.Random(66)

bg = Img(W, H, col('ink'))
# cobblestone wall: staggered rounded stones
for row, y in enumerate(range(0, 92, 9)):
    x = -((row % 2) * 7)
    while x < W:
        w_ = rnd.randint(11, 17)
        shade = rnd.choice(['stone', 'stone', 'slate', 'night'])
        for yy in range(y + 1, y + 8):
            for xx in range(x + 1, x + w_ - 1):
                corner = (yy in (y + 1, y + 7)) and (xx in (x + 1, x + w_ - 2))
                if not corner:
                    bg.set(xx, yy, col(shade))
        bg.rect(x + 2, y + 1, x + w_ - 3, y + 1, col('slate' if shade != 'slate' else 'grey'))
        if rnd.random() < 0.3:
            bg.set(x + rnd.randint(3, w_ - 4), y + rnd.randint(3, 6), col('night'))
        if rnd.random() < 0.15:
            bg.set(x + rnd.randint(2, w_ - 3), y + 2, col('pine'))   # moss
        x += w_
# floor: flagstones in perspective
for y in range(92, H):
    for x in range(W):
        t = (y - 92) / 28.0
        u = (x - 80) / (0.6 + t)
        edge = abs(u % 24) < 1.2 or (y - 92) in (5, 12, 21)
        bg.set(x, y, col('night') if edge else (col('stone') if dith(x, y, 0.3 + t * 0.3) else col('slate')))
# the arched doorway
for y in range(30, 92):
    for x in range(64, 97):
        dy = max(0, 48 - y)
        if (x - 80) ** 2 / 16.0 ** 2 + (dy / 18.0) ** 2 <= 1.0 or y >= 48:
            bg.set(x, y, col('ink'))
for y in range(28, 92):
    for x in (62, 63, 97, 98):
        if y >= 46:
            bg.set(x, y, col('grey'))
# bars in the door
for x in range(68, 94, 6):
    bg.rect(x, 40 if abs(x - 80) < 8 else 44, x, 91, col('stone'))
# torch brackets
for tx in (36, 124):
    bg.rect(tx - 1, 50, tx + 1, 58, col('bark')); bg.rect(tx - 3, 48, tx + 3, 49, col('grey'))
# the ledge with skulls
bg.rect(6, 84, 54, 86, col('grey')); bg.rect(6, 84, 54, 84, col('mist'))
SKULL = ['..wwwww..', '.wwwwwww.', 'wwkkwkkww', 'wwkkwkkww', '.wwwkwww.', '..wkwkw..', '..wwwww..']
for sx in (14, 30, 46):
    bg.blit(sprite(SKULL, dict(w='mist', k='ink')), sx - 4, 77)
    bg.rect(sx - 1, 73, sx + 1, 77, col('sand')); bg.set(sx, 72, col('bark'))   # the candle on it
# cobwebs in the top corners
for cx, cy, sgn in ((0, 0, 1), (W - 1, 0, -1)):
    for a in range(5):
        ang = a * math.pi / 8
        bg.line(cx, cy, cx + sgn * 26 * math.cos(ang), cy + 26 * math.sin(ang), col('grey'))
    for r in (7, 13, 19, 25):
        for a in range(4):
            a0, a1 = a * math.pi / 8, (a + 1) * math.pi / 8
            bg.line(cx + sgn * r * math.cos(a0), cy + r * math.sin(a0), cx + sgn * r * math.cos(a1), cy + r * math.sin(a1), col('grey'))
bg.rect(108, 26, 110, 28, col('bark'))   # the key's nail
bg.rect(112, 100, 116, 102, col('orange'))   # an ember on the floor: the glow's tint key
bg.rect(112, 100, 116, 102, col('orange'))

# ------------------------------------------------------------ brushes -------
SW = [-1.2, 0.4, 1.3, 0.2, -0.8, 1.0]; FL = [0.6, -0.4, 0.8, -0.7, 0.3, -0.5]


def torch():
    cels = []
    for k in range(6):
        c = Img(11, 16)
        flame(c, 5.5, 15, 12 + (k % 3 == 1), 7, SW[k], FL[k], FIRE)
        cels.append(c)
    return cels


def candle():
    cels = []
    for k in range(6):
        c = Img(5, 7)
        flame(c, 2.5, 6, 5 + (k % 2), 3, SW[k] * 0.5, FL[k] * 0.5, [col('orange'), col('amber'), col('yellow')])
        cels.append(c)
    return cels


def glow():
    c = Img(64, 64)
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 32.0
            if d < 1 and dith(x, y, (1 - d) * 0.9):
                c.set(x, y, col('amber', 120 if d < 0.5 else 80))
    return [c]


def spider():
    cels = []
    for k in range(2):
        c = Img(11, 90)
        c.line(5, 0, 5, 82, col('mist', 160))
        c.ellipse(5, 85, 2.5, 2.5, col('ink')); c.ellipse(5, 82.5, 1.6, 1.6, col('night'))
        c.set(4, 82, col('red')); c.set(6, 82, col('red'))
        for i in range(4):
            yy = 83 + i + (k if i % 2 else -k) * 0.5
            c.line(3, 85, 0, yy - 2 + i, col('ink')); c.line(7, 85, 10, yy - 2 + i, col('ink'))
        cels.append(c)
    return cels


def bat():
    cels = []
    for k in range(4):
        c = Img(17, 9)
        lift = [0, 3, 4, 3][k]
        c.ellipse(8, 5, 2, 2.5, col('ink')); c.set(7, 4, col('red')); c.set(9, 4, col('red'))
        c.set(7, 2, col('ink')); c.set(9, 2, col('ink'))
        for s_ in (-1, 1):
            for i in range(7):
                c.set(8 + s_ * (2 + i), 4 - lift + abs(i - 3) * (lift / 3.0 if lift else 0) + (1 if i % 2 else 0), col('night'))
                c.set(8 + s_ * (2 + i), 5 - lift + abs(i - 3) * (lift / 3.0 if lift else 0), col('ink'))
        cels.append(c)
    return cels


def ghost():
    cels = []
    for k in range(4):
        c = Img(18, 22)
        c.disc(9, 8, 7, col('mist')); c.rect(2, 8, 16, 17, col('mist'))
        for i in range(4):
            c.disc(3.5 + i * 3.7, 18 + ((i + k) % 2), 1.9, col('mist'))
        c.disc(6, 8, 1.6, col('ink')); c.disc(12, 8, 1.6, col('ink')); c.ellipse(9, 13, 1.5, 2 - (k % 2) * 0.5, col('ink'))
        cels.append(c)
    return cels


def drop():
    c = Img(3, 5)
    c.set(1, 0, col('cyan')); c.rect(0, 2, 2, 3, col('cyan')); c.rect(1, 1, 1, 4, col('blue')); c.set(1, 2, col('white'))
    return [c]


def key():
    c = Img(9, 18)
    ring(c, 4, 4, 3, 'amber', 1.4); c.rect(4, 7, 4, 16, col('amber')); c.rect(5, 13, 7, 13, col('amber')); c.rect(5, 16, 6, 16, col('amber'))
    c.set(3, 1, col('yellow'))
    return [c]


S.brush(1, 'torch', torch(), 'a torch flame: stamp, every frame at once')
S.brush(2, 'candle', candle(), 'a skull candle flame: stamp, phases offset')
S.brush(3, 'torchglow', glow(), 'the torch glow: still, OPACITY 55 > 100 + TINT orange, there and back')
S.brush(4, 'spider', spider(), 'a spider on its silk (90 px tall): straight paths down and up, TURN Z twist')
S.brush(5, 'bat', bat(), 'a bat: out of the door at us, SIZE 15 > 420')
S.brush(6, 'ghost', ghost(), 'a ghost: OPACITY 0 > 75 > 0, TURN Y')
S.brush(7, 'drip', drop(), 'a water drip: straight down, OPACITY > 0')
S.brush(8, 'key', key(), 'a key on a nail: TURN Y 353, one turn per loop')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_ORANGE=S.find(bg, E['orange'], 110, 98, 118, 104))

mv = ['layer torches; pick 1 6 torch', 'stamp 36 41 0', 'stamp 124 41 3',
      'layer candles; pick 2 6 candle', 'stamp 14 69 0', 'stamp 30 69 2', 'stamp 46 69 4',
      'layer glow', 'fg_key "$KEY_ORANGE"', 'pick 3 1 torchglow',
      'mv 36 46 36 46 label="the left torchlight swells (OPACITY 55 > 100, TINT orange 0 > 40)" from=1 count=24 o0=55 t1=40 ease=3',
      'mv 36 46 36 46 label="... and ebbs" from=25 count=24 o1=55 t0=40 ease=3',
      'mv 124 46 124 46 label="the right torchlight ebbs" from=1 count=24 o1=55 t0=40 ease=3',
      'mv 124 46 124 46 label="... and swells" from=25 count=24 o0=55 t1=40 ease=3',
      'layer key; pick 8 1 key',
      'mv 109 36 109 36 label="a key turns on its nail (TURN Y 353)" from=1 count=48 ty=353',
      'layer spiders; pick 4 2 spider',
      'mv 20 0 20 30 label="spider 1 lowers itself (ease out, TURN Z 20)" from=1 count=24 tz=20 ease=2 every=3',
      'mv 20 30 20 0 label="... and climbs back (ease in)" from=25 count=24 tz=-20 ease=1 every=3',
      'mv 142 24 142 0 label="spider 2 climbs" from=1 count=24 tz=-15 ease=3 every=3',
      'mv 142 0 142 24 label="... and lowers itself again" from=25 count=24 tz=15 ease=3 every=3',
      'layer ghost; pick 6 4 ghost',
      'mv 60 70 96 62 label="a ghost drifts and fades in (OPACITY 0 > 75, TURN Y 40)" from=1 count=24 o0=0 o1=75 ty=40 ease=3 every=3',
      'mv 96 62 60 70 label="... and fades out (OPACITY 75 > 0, TURN Y -40)" from=25 count=24 o0=75 o1=0 ty=-40 ease=3 every=3',
      'layer drips; pick 7 1 drip',
      'mv 58 3 58 91 label="a drip falls (ease in, OPACITY > 30)" from=4 count=10 o1=30 ease=1',
      'mv 104 3 104 91 label="another drip" from=22 count=10 o1=30 ease=1',
      'mv 88 3 88 91 label="and another" from=37 count=10 o1=30 ease=1',
      'layer bat; pick 5 4 bat',
      'mv 80 58 40 -20 label="a bat bursts out of the door at us (SIZE 15 > 420, ease in)" from=12 count=18 s0=15 s1=420 ease=1']
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'dark dungeon, dread', 'opl', 6601, '--mood', 'ominous', '--key', 'D minor', '--bpm', 72, '--seconds', 4)
drone = au.tone(T, 55, 55, 'saw', gain=0.15)
bed = [(au.fit(au.load(music), T), 0, 0.8), (au._lp(drone, 0.05), 0, 1.0), (au.crackle(T, 14, 67, 0.4), 0, 0.5)]
au.mix(os.path.join(S.dir, 'dungeon-music.wav'), T, bed)
flap = au.soundmon(A, 'flap', 'bat wings', 'chipfx', 6602, '--fx-archetype', 'whoosh')
wail = au.tone(1.6, 520, 380, 'sine', vib=0.05, a=0.4, r=0.6, gain=0.25)
sfx = [(au.drip(1500), S.t(13), 0.8), (au.drip(1200), S.t(31), 0.8), (au.drip(1700), S.t(46), 0.8),
       (flap, S.t(12), 0.7), (flap, S.t(20), 0.8), (wail, S.t(10), 1.0)]
au.mix(os.path.join(S.dir, 'dungeon-sfx.wav'), T, sfx)
print('dungeon ok', S.dir)
