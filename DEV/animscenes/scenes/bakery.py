"""bakery - a table in the morning sun: bread, pastries and coffee (48 frames, 12 fps, loops).

Steam curls up from two coffees (SIZE 60 > 200, OPACITY > 0, TURN Z drift), dust motes
drift through the sunbeam on DRAWN paths (OPACITY twinkle), the sunbeam itself warms and
cools (TINT toward amber + OPACITY, there and back), a cake turns on its stand (TURN Y
360 - one turn per loop), the OPEN sign flips in the draught (TURN Y 180 and back), a fly
buzzes a figure eight round the pastries (DRAWN path, closed).
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('bakery', sys.argv[1], frames=48, cols=8, fps=12)
W, H = S.w, S.h

bg = Img(W, H)
for y in range(H):  # the wall: warm plaster
    for x in range(W):
        bg.set(x, y, col('tan') if dith(x, y, 0.25 + 0.2 * math.sin(x * 0.05) * math.sin(y * 0.09)) else col('sand'))
bg.rect(0, 72, W - 1, 75, col('wood'))   # dado rail
for y in range(76, 84):
    for x in range(W):
        bg.set(x, y, col('clay') if (x // 10) % 2 else col('tan'))
# the window, top left: sky, frame
vgrad(bg, 8, 8, 52, 58, ['cyan', 'blue', 'mist'])
bg.disc(20, 20, 5, col('white')); bg.disc(26, 18, 4, col('white')); bg.disc(40, 30, 3, col('white'))
for x in (8, 30, 52):
    bg.rect(x - 1, 6, x + 1, 60, col('bark'))
for y in (6, 32, 58):
    bg.rect(7, y - 1, 53, y + 1, col('bark'))
bg.rect(5, 60, 55, 62, col('wood'))   # sill
# shelves with loaves, right
for sy in (24, 46):
    bg.rect(86, sy, 152, sy + 2, col('bark')); bg.rect(86, sy, 152, sy, col('wood'))
    for i, lx in enumerate(range(92, 150, 15)):
        if (i + sy) % 3 == 0:
            bg.ellipse(lx, sy - 4, 7, 4, col('wood')); bg.ellipse(lx, sy - 5, 6, 3, col('tan'))
            for k in range(3):
                bg.line(lx - 4 + k * 3, sy - 7, lx - 2 + k * 3, sy - 3, col('wood'))
        else:
            bg.ellipse(lx, sy - 5, 6, 5, col('clay')); bg.ellipse(lx - 1, sy - 6, 4, 3, col('tan'))
            bg.line(lx - 3, sy - 6, lx + 3, sy - 6, col('wood'))
# chalkboard
bg.rect(60, 12, 80, 40, col('ink')); bg.rect(59, 11, 81, 11, col('wood')); bg.rect(59, 41, 81, 41, col('wood'))
for i, w_ in enumerate((14, 10, 12, 8)):
    bg.rect(63, 16 + i * 6, 63 + w_, 16 + i * 6, col('mist' if i % 2 else 'white'))
# the table
for y in range(84, H):
    for x in range(W):
        plank = (y - 84) // 9
        c = col('wood') if (x + plank * 23) % 40 else col('bark')
        if dith(x, y, 0.15) and (x * 3 + y) % 7 == 0:
            c = col('bark')
        bg.set(x, y, c)
bg.rect(0, 84, W - 1, 85, col('clay'))


def croissant(img, cx, cy):
    for k in range(5):
        a = (k - 2) * 0.55
        img.ellipse(cx + math.sin(a) * 7, cy - math.cos(a) * 2 + 2, 3.2 - abs(k - 2) * 0.5, 2.6, col('orange' if k % 2 else 'tan'))
    img.line(cx - 7, cy + 2, cx + 7, cy + 2, col('wood'))


croissant(bg, 30, 92); croissant(bg, 44, 96)
bg.ellipse(37, 100, 17, 3, col('mist')); bg.ellipse(37, 99, 15, 2, col('white'))   # their plate
bg.ellipse(110, 92, 22, 4, col('wood')); bg.ellipse(110, 91, 21, 3, col('tan'))     # baguette board
bg.ellipse(110, 89, 18, 3, col('clay')); bg.ellipse(110, 88, 16, 2, col('tan'))
for k in range(4):
    bg.line(98 + k * 7, 87, 101 + k * 7, 89, col('wood'))


def cup(img, cx, cy):
    img.ellipse(cx, cy + 6, 9, 2, col('mist')); img.ellipse(cx, cy + 5, 8, 2, col('white'))   # saucer
    img.rect(cx - 5, cy - 3, cx + 5, cy + 5, col('white')); img.rect(cx + 4, cy - 3, cx + 5, cy + 5, col('mist'))
    img.ellipse(cx, cy - 3, 5, 1.5, col('bark')); img.ellipse(cx, cy - 3, 3, 0.8, col('wood'))
    ring(img, cx + 7, cy + 1, 2.2, 'white', 1.2)


cup(bg, 72, 98); cup(bg, 140, 104)
# the cake stand (the cake itself is a brush)
bg.rect(66, 78, 66, 82, col('grey')); bg.ellipse(66, 83, 6, 1.5, col('mist')); bg.ellipse(66, 78, 11, 1.5, col('mist'))
# the sunbeam key: a gold spot on the sill
bg.rect(14, 60, 18, 62, col('amber'))
# OPEN sign hook
bg.line(31, 62, 31, 64, col('bark'))

# ------------------------------------------------------------ brushes -------
def wisp():
    cels = []
    for k in range(4):
        c = Img(12, 14)
        for j in range(5):
            t = j / 4.0
            x = 6 + math.sin(t * 5 + k * 1.2) * 2.2
            c.disc(x, 13 - j * 3, 1.8 + t * 0.8, col('white', int(210 - t * 120)))
        cels.append(c)
    return cels


def mote():
    cels = []
    for k in range(4):
        c = Img(3, 3)
        c.set(1, 1, col('white' if k < 2 else 'yellow'))
        if k == 0:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                c.set(1 + dx, 1 + dy, col('yellow', 140))
        cels.append(c)
    return cels


def beam():
    c = Img(70, 60)
    for y in range(60):
        for x in range(70):
            u = x - y * 0.9
            if 0 <= u < 26 and dith(x, y, 0.5 - abs(u - 13) / 30):
                c.set(x, y, col('yellow', 70))
    return [c]


def cake():
    c = Img(22, 14)
    c.rect(2, 4, 19, 12, col('rose')); c.rect(2, 7, 19, 8, col('white')); c.rect(2, 4, 19, 5, col('coral'))
    c.ellipse(10.5, 4, 9, 2, col('white'))
    for x in (4, 8, 12, 16):
        c.disc(x, 2, 1.2, col('red'))
    c.rect(15, 4, 19, 12, col('wine'))  # the shaded side: turning shows it
    return [c]


SIGN = ['bbbbbbbbbbbbbbbbb', 'bwwwwwwwwwwwwwwwb', 'bwgggwgggwgggwgwb', 'bwgwgwgwgwgwwwggb',
        'bwgwgwgggwggwwgwb', 'bwgggwgwwwgggwgwb', 'bwwwwwwwwwwwwwwwb', 'bbbbbbbbbbbbbbbbb']


def sign():
    c = Img(17, 11)
    c.line(4, 0, 8, 2, col('bark')); c.line(12, 0, 8, 2, col('bark'))
    c.blit(sprite(SIGN, dict(b='wine', w='sand', g='pine')), 0, 3)
    return [c]


def fly():
    cels = []
    for k in range(2):
        c = Img(7, 5)
        c.rect(2, 2, 4, 3, col('ink')); c.set(5, 2, col('stone'))
        wing = col('mist', 200)
        if k:
            c.set(2, 0, wing); c.set(4, 0, wing); c.set(3, 1, wing)
        else:
            c.set(1, 1, wing); c.set(5, 1, wing); c.set(3, 1, wing)
        cels.append(c)
    return cels


S.brush(1, 'steam', wisp(), 'a curl of steam: straight path up, SIZE 60 > 200, OPACITY 90 > 0, TURN Z 25')
S.brush(2, 'mote', mote(), 'a dust mote twinkling: DRAWN wavy path, OPACITY 100 > 30')
S.brush(3, 'sunbeam', beam(), 'the sunbeam: still, TINT to amber 0 > 70 + OPACITY 60 > 100, then back')
S.brush(4, 'cake', cake(), 'the cake on its stand: TURN Y 360 over the loop')
S.brush(5, 'sign', sign(), 'the OPEN sign: TURN Y 180 and back (ease in-out)')
S.brush(6, 'fly', fly(), 'a fly: DRAWN figure-eight round the pastries')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_AMBER=S.find(bg, E['amber'], 12, 59, 20, 63))

# ------------------------------------------------- the moves for DRAW -------
N = S.frames
mv = ['fg_key "$KEY_AMBER"   # the sunbeam warms toward amber',
      'layer sunbeam; pick 3 1 sunbeam',
      'mv 45 62 45 62 label="the sunbeam warms (TINT amber 0 > 70, OPACITY 60 > 100, ease in-out)" from=1 count=24 o0=60 t1=70 ease=3',
      'mv 45 62 45 62 label="... and cools (TINT 70 > 0, OPACITY 100 > 60)" from=25 count=24 o1=60 t0=70 ease=3',
      'layer cake; pick 4 1 cake',
      'mv 66 71 66 71 label="the cake turns on its stand (TURN Y 353: one turn per loop)" from=1 count=48 ty=%d' % round(360 * (N - 1) / N),
      'layer sign; pick 5 1 sign',
      'mv 31 70 31 70 label="the OPEN sign flips in the draught (TURN Y 353, ease in-out)" from=1 count=48 ty=%d ease=3' % round(360 * (N - 1) / N),
      'layer steam; pick 1 4 steam']


def puff(x0, y0, x1, y1, start, life, tz, label):
    # values at life fraction a (0..1): position, size, opacity, turn
    def at(a):
        return (round(x0 + (x1 - x0) * a), round(y0 + (y1 - y0) * a), round(60 + 140 * a), round(90 - 90 * a), round(tz * a))
    out = []
    first_n = min(life, N - start + 1)
    a1 = (first_n - 1) / (life - 1)
    xa, ya, sa, oa, ta = at(0); xb, yb, sb, ob, tb = at(a1)
    out.append('mv %d %d %d %d label="%s, frame %d" from=%d count=%d s0=%d s1=%d o0=%d o1=%d tz=%d every=4'
               % (xa, ya, xb, yb, label, start, start, first_n, sa, sb, oa, ob, tb))
    if first_n < life:   # the rest of its life on frames 1.. (the loop)
        a0 = first_n / (life - 1)
        xa, ya, sa, oa, ta = at(a0); xb, yb, sb, ob, tb = at(1.0)
        out.append('mv %d %d %d %d label="%s, its end on frame 1 (the loop)" from=1 count=%d s0=%d s1=%d o0=%d o1=%d tz=%d every=4'
                   % (xa, ya, xb, yb, label, life - first_n, sa, sb, oa, ob, tb - ta))
    return out


for k in range(6):
    mv += puff(72, 92, 69, 64, 1 + 8 * k, 16, 25, 'steam over the near cup')
for k in range(3):
    mv += puff(140, 98, 143, 72, 1 + 16 * k, 16, -25, 'steam over the far cup')
mv.append('layer motes; pick 2 4 mote')
for k, (cx, cy, rx, ry) in enumerate(((26, 40, 9, 6), (40, 56, 7, 9), (52, 70, 10, 5), (34, 76, 6, 6))):
    ph = k * 1.3
    pts = ' '.join('%d,%d' % (round(cx + rx * math.sin(t * 2 * math.pi / 16 + ph)), round(cy + ry * math.sin(t * 4 * math.pi / 16 + ph * 2) * 0.6 + t * 0))
                   for t in range(17))
    mv.append('mv 0 0 0 0 label="dust mote %d drifts in the beam (DRAWN, a closed loop)" path=drawn pts="%s" from=1 count=48 every=3' % (k + 1, pts))
mv.append('layer fly; pick 6 2 fly')
pts = ' '.join('%d,%d' % (round(38 + 22 * math.sin(t * 2 * math.pi / 24)), round(84 + 7 * math.sin(t * 4 * math.pi / 24))) for t in range(25))
mv.append('mv 0 0 0 0 label="a fly buzzes a figure eight round the pastries (DRAWN, closed)" path=drawn pts="%s" from=1 count=48' % pts)
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')

# --------------------------------------------------------------- audio ------
A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'sunny bakery morning, gentle cafe tune', 'opl', 4401, '--mood', 'serene', '--key', 'F major', '--bpm', 90, '--seconds', 4)
bed = [(au.fit(au.load(music), T), 0, 0.8), (au.chatter(T, 41), 0, 0.25)]
au.mix(os.path.join(S.dir, 'bakery-music.wav'), T, bed)
buzz = [v * (0.5 + 0.5 * math.sin(i / au.RATE * 9)) for i, v in enumerate(au.tone(T, 220, 230, 'saw', vib=0.03, gain=0.05))]
sfx = [(au.clink(2600), S.t(6), 0.6), (au.clink(3100), S.t(30), 0.5), (au.hiss(1.0, 61, 0.25), S.t(1), 1.0),
       (au.hiss(1.0, 62, 0.25), S.t(17), 1.0), (au.hiss(1.0, 63, 0.25), S.t(33), 1.0), (au._lp(buzz, 0.3), 0, 1.0)]
au.mix(os.path.join(S.dir, 'bakery-sfx.wav'), T, sfx)
print('bakery ok', S.dir)
