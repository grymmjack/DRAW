"""fireworks - a night show over the harbour with a grand finale (60 frames, 12 fps).

Rockets climb on straight paths (ease out: they slow at the top), each burst is ONE still
brush grown and faded by the Move Brush - SIZE 20 > 150, OPACITY 100 > 0, TINT from white-hot
to its own colour (TINT 70 > 0 toward white) - a ring burst is tilted in 3D (TURN X 65), the
willow sags (a straight path down while it grows), a pinwheel spins on its post the whole
time (TURN Z 1440), smoke drifts off and thins (SIZE + OPACITY), the crowd bobs (AnimBrush
stamp), and the finale fires three at once, a sky flash (OPACITY 45 > 0) and glitter.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('fireworks', sys.argv[1], frames=60, cols=10, fps=12)
W, H, N = S.w, S.h, S.frames
rnd = random.Random(77)

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 84, ['ink', 'ink', 'night', 'deep'])
for _ in range(60):
    x, y = rnd.randrange(W), rnd.randrange(70)
    bg.set(x, y, col(rnd.choice(['grey', 'slate', 'mist'])))
# the city skyline
x = 0
while x < W:
    w_ = rnd.randint(7, 15); h_ = rnd.randint(8, 26)
    if 60 < x < 92:
        h_ = rnd.randint(4, 9)            # a gap over the water for the rockets
    bg.rect(x, 84 - h_, x + w_ - 1, 84, col('ink'))
    for wy in range(84 - h_ + 2, 83, 3):
        for wx in range(x + 1, x + w_ - 1, 2):
            if rnd.random() < 0.28:
                bg.set(wx, wy, col(rnd.choice(['amber', 'yellow', 'sand'])))
    x += w_
bg.rect(118, 48, 119, 58, col('ink')); bg.set(118, 47, col('red'))   # a mast with its light
# the water, with the skyline's lights smeared into it
for y in range(85, 104):
    for x in range(W):
        c = bg.get(x, 84 - (y - 84) * 2) if 84 - (y - 84) * 2 >= 0 else col('ink')
        base = col('night') if dith(x, y, 0.5 + (y - 85) / 40.0) else col('ink')
        bg.set(x, y, c if (c != col('ink') and (x + y) % 3 == 0) else base)
bg.rect(0, 85, W - 1, 85, col('slate'))
# the quay
bg.rect(0, 104, W - 1, H - 1, col('night')); bg.rect(0, 104, W - 1, 104, col('stone'))
for x in range(0, W, 10):
    bg.rect(x, 105, x, H - 1, col('ink'))
# the pinwheel's post and the launch tubes
bg.rect(139, 92, 140, 104, col('wood'))
for tx in (40, 80, 110, 35, 125):
    bg.rect(tx - 1, 101, tx + 1, 104, col('slate'))
bg.rect(4, 108, 8, 110, col('white')); bg.rect(4, 108, 8, 110, col('white'))   # a white sign: the tint key


# ------------------------------------------------------------ brushes -------
def rocket():
    cels = []
    for k in range(4):
        c = Img(5, 14)
        c.rect(2, 0, 2, 3, col('white')); c.set(1, 2, col('mist')); c.set(3, 2, col('mist'))
        for t in range(4, 14):
            if (t + k) % 2 == 0 or t < 7:
                c.set(2 + (rnd.random() < 0.3) * rnd.choice((-1, 1)), t, col('yellow' if t < 7 else ('orange' if t < 10 else 'red')))
        cels.append(c)
    return cels


def burst(cols_, rays=18, size=64, willow=False, seed=1):
    r_ = random.Random(seed)
    c = Img(size, size); m = size / 2.0 - 0.5; R = size / 2.0 - 2
    for a in range(rays):
        ang = a * 2 * math.pi / rays + r_.uniform(-0.08, 0.08)
        L = R * r_.uniform(0.75, 1.0)
        for t in range(int(L)):
            u = t / L
            x = m + math.cos(ang) * t
            y = m + math.sin(ang) * t + (willow * 10 * u * u)
            if u > 0.35 and (t % 2 == 0 or u > 0.8):
                c.set(x, y, col(cols_[min(len(cols_) - 1, int(u * len(cols_)))]))
        x = m + math.cos(ang) * L; y = m + math.sin(ang) * L + willow * 10
        c.disc(x, y, 1.2, col('white'))
    c.disc(m, m, 2, col('white'))
    return [c]


def ring():
    c = Img(48, 48)
    for a in range(28):
        ang = a * 2 * math.pi / 28
        for t in (19, 20, 21):
            c.set(23.5 + math.cos(ang) * t, 23.5 + math.sin(ang) * t, col('lime' if t != 21 else 'cyan'))
        c.disc(23.5 + math.cos(ang) * 22, 23.5 + math.sin(ang) * 22, 0.9, col('white'))
    return [c]


def wheel():
    c = Img(24, 24)
    for a in range(6):
        ang = a * math.pi / 3
        for t in range(12):
            x = 11.5 + math.cos(ang + t * 0.12) * t; y = 11.5 + math.sin(ang + t * 0.12) * t
            c.set(x, y, col(['yellow', 'amber', 'orange', 'red'][min(3, t // 3)]))
    c.disc(11.5, 11.5, 2, col('white'))
    return [c]


def glitter():
    cels = []
    for k in range(4):
        r_ = random.Random(40 + k); c = Img(40, 30)
        for _ in range(26):
            x, y = r_.randrange(40), r_.randrange(30)
            c.set(x, y, col(r_.choice(['white', 'yellow', 'mist', 'amber'])))
            if r_.random() < 0.3:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    c.set(x + dx, y + dy, col('yellow', 180))
        cels.append(c)
    return cels


def smoke():
    c = Img(30, 18)
    for dx, dy, r in ((-8, 2, 5), (-2, -1, 7), (6, 1, 6), (11, 4, 4)):
        for y in range(18):
            for x in range(30):
                if (x - 15 - dx) ** 2 + (y - 9 - dy) ** 2 <= r * r and dith(x, y, 0.45):
                    c.set(x, y, col('slate', 150))
    return [c]


def crowd():
    cels = []
    for k in range(2):
        r_ = random.Random(9); c = Img(70, 12)
        for i in range(12):
            x = 3 + i * 5.6 + r_.uniform(-1, 1); up = ((i + k) % 3 == 0) * 1
            h_ = r_.randint(7, 10)
            c.disc(x, 12 - h_ - up, 1.8, col('ink')); c.rect(x - 2, 12 - h_ + 2 - up, x + 2, 11, col('ink'))
            if (i + k) % 4 == 0:
                c.line(x + 2, 12 - h_ + 2 - up, x + 3, 12 - h_ - 3 - up, col('ink'))   # an arm up
        cels.append(c)
    return cels


def flash():
    c = Img(W, 86)
    for y in range(86):
        for x in range(W):
            c.set(x, y, col('mist', int(150 * (1 - y / 86.0)) + 40))
    return [c]


S.brush(1, 'rocket', rocket(), 'a rocket with its spark trail: straight up, ease out')
S.brush(2, 'peony-red', burst(['red', 'pink', 'rose'], 20, seed=3), 'a red peony burst: SIZE 20 > 150, OPACITY > 0, TINT white 70 > 0')
S.brush(3, 'chrysanth-blue', burst(['blue', 'cyan', 'mist'], 26, seed=5), 'a blue chrysanthemum: the same grow / fade / cool')
S.brush(4, 'willow-gold', burst(['amber', 'yellow', 'orange'], 16, willow=True, seed=7), 'a gold willow: grows while it sags (a path down)')
S.brush(5, 'ring-green', ring(), 'a ring burst: TURN X 65 tilts it in 3D')
S.brush(6, 'pinwheel', wheel(), 'a pinwheel on its post: TURN Z 1440 over the whole show')
S.brush(7, 'glitter', glitter(), 'finale glitter: stamped, twinkling')
S.brush(8, 'smoke', smoke(), 'burst smoke: drifts, SIZE 100 > 200, OPACITY 100 > 0')
S.brush(9, 'crowd', crowd(), 'the crowd on the quay, bobbing: stamp')
S.brush(10, 'flash', flash(), 'the finale sky flash: OPACITY 45 > 0')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_WHITE=S.find(bg, E['white'], 2, 106, 10, 112))

# (x, top, launch frame, rise frames, burst brush slot/name, burst frames, extra)
SHOTS = [(40, 38, 1, 8, (2, 'peony-red'), 12, ''),
         (110, 30, 6, 8, (3, 'chrysanth-blue'), 12, ''),
         (80, 24, 18, 8, (4, 'willow-gold'), 14, 'sag'),
         (35, 30, 36, 7, (2, 'peony-red'), 14, 'big'),
         (80, 20, 36, 7, (3, 'chrysanth-blue'), 14, 'big'),
         (125, 30, 36, 7, (4, 'willow-gold'), 14, 'big sag')]
mv = ['layer crowd; pick 9 2 crowd', 'stamp 36 110 0', 'stamp 106 111 1',
      'layer pinwheel; pick 6 1 pinwheel',
      'mv 140 92 140 92 label="the pinwheel spins all show long (TURN Z 1440)" from=1 count=60 tz=1440',
      'layer rockets; pick 1 4 rocket']
for x, top, f, n, _, _, _ in SHOTS:
    mv.append('mv %d 100 %d %d label="a rocket climbs to %d (ease out)" from=%d count=%d ease=2' % (x, x, top, top, f, n))
mv.append('mv 110 100 125 44 label="a rocket for the ring" from=22 count=7 ease=2')
mv += ['fg_key "$KEY_WHITE"', 'layer bursts']
for x, top, f, n, (slot, name), bn, extra in SHOTS:
    s1 = 190 if 'big' in extra else 150
    y1 = top + (12 if 'sag' in extra else 2)
    mv.append('pick %d 1 %s' % (slot, name))
    mv.append('mv %d %d %d %d label="%s bursts (SIZE 20 > %d, OPACITY > 0, TINT white 70 > 0, ease out)" from=%d count=%d s0=20 s1=%d o1=0 t0=70 ease=2'
              % (x, top, x, y1, name, s1, f + n, bn, s1))
mv += ['pick 5 1 ring-green',
       'mv 125 44 125 46 label="a ring bursts, tilted in 3D (TURN X 65, TURN Z 40, SIZE 20 > 140, OPACITY > 0)" from=29 count=12 tx=65 tz=40 s0=20 s1=140 o1=0 t0=70 ease=2',
       'layer smoke; pick 8 1 smoke',
       'mv 40 40 70 30 label="smoke drifts off and thins (SIZE 100 > 200, OPACITY 70 > 0)" from=14 count=24 s1=200 o0=70 o1=0',
       'mv 110 32 140 22 label="more smoke" from=20 count=22 s1=200 o0=70 o1=0',
       'layer flash; pick 10 1 flash',
       'mv 80 43 80 43 label="the finale flash (OPACITY 45 > 0, ease out)" from=43 count=6 o0=45 o1=0 ease=2',
       'layer glitter; pick 7 4 glitter',
       'mv 50 30 50 50 label="finale glitter falls and fades (OPACITY > 0)" from=48 count=13 o1=0',
       'mv 110 28 110 50 label="more glitter" from=50 count=11 o1=0']
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'fireworks festival, grand celebration', 'opl', 7701, '--mood', 'grand', '--key', 'Bb major', '--bpm', 96, '--seconds', 5)
crowd_ = au.chatter(T, 71)
au.mix(os.path.join(S.dir, 'fireworks-music.wav'), T, [(au.fit(au.load(music), T), 0, 0.6), (crowd_, 0, 0.35)])
boom = au.soundmon(A, 'boom', 'firework burst boom', 'oplfx', 7702, '--fx-archetype', 'boom')
sfx = []
for x, top, f, n, _, _, extra in SHOTS:
    sfx.append((au.whistle(n / 12.0, 700 + x * 3, 1900 + x * 4, seed=f), S.t(f), 0.35))
    sfx.append((boom, S.t(f + n), 1.0 if 'big' in extra else 0.8))
    sfx.append((au.crackle(0.9, 30, seed=f + 3, gain=0.6), S.t(f + n + 2), 0.6))
sfx += [(au.whistle(7 / 12.0, 1000, 2300, seed=99), S.t(22), 0.3), (boom, S.t(29), 0.7),
        (au.crackle(1.6, 40, seed=5, gain=0.7), S.t(48), 0.7)]
au.mix(os.path.join(S.dir, 'fireworks-sfx.wav'), T, sfx)
print('fireworks ok', S.dir)
