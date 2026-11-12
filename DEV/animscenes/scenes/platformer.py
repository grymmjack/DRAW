"""platformer - an ORIGINAL platformer moment: a little robot runs and jumps up the ledges,
grabs two coins, goes for the big jump, comes up short and drops into the pit (60 frames).

The robot runs on straight paths (its run cycle stepping every 2 frames) and jumps on DRAWN
arcs, one point per frame; the coins flip in 3D (TURN Y) until they are grabbed, then pop -
up, bigger, fading (SIZE 100 > 170, OPACITY > 0); a blob patrols there and back; the fall
into the pit tumbles (TURN Z 720) away from us (MOVE Z 0 > 600) while it flashes red (TINT)
and fades; GAME OVER grows in (SIZE 60 > 100, OPACITY 0 > 100); the clouds drift.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('platformer', sys.argv[1], frames=60, cols=10, fps=12)
W, H, N = S.w, S.h, S.frames
rnd = random.Random(88)

GROUND, PIT0, PIT1 = 100, 128, 147
LEDGES = [(0, PIT0, GROUND), (52, 80, 82), (88, 118, 62), (PIT1, W, GROUND)]

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, H - 1, ['blue', 'cyan', 'mist'])
for hx, hr, hc in ((30, 50, 'green'), (110, 60, 'pine'), (160, 40, 'green')):   # far hills
    for y in range(H):
        for x in range(W):
            if (x - hx) ** 2 + ((y - 118) * 1.6) ** 2 <= hr * hr and y > 60:
                bg.set(x, y, mix(col(hc), col('mist'), 0.45))


def block(img, x0, x1, top):
    for y in range(top, H):
        for x in range(x0, x1):
            if y < top + 3:
                c = col('lime') if y == top else col('green')
            else:
                c = col('clay') if dith(x, y, 0.35) else col('rust')
                if (x - x0) % 8 == 0 and y > top + 3 and (y - top) % 8 == 4:
                    c = col('bark')
            img.set(x, y, c)
        img.set(x0 + rnd.randint(0, 2), top - 1, col('lime'))


for x0, x1, top in LEDGES:
    if top == GROUND:
        block(bg, x0, x1, top)
    else:
        for y in range(top, top + 6):   # floating ledges are slabs
            for x in range(x0, x1):
                bg.set(x, y, col('lime') if y == top else (col('green') if y < top + 3 else col('wood')))
        bg.rect(x0 + 2, top + 6, x1 - 3, top + 6, col('bark'))
for y in range(GROUND, H):          # the pit: dark, deeper toward the bottom
    for x in range(PIT0, PIT1):
        bg.set(x, y, col('night') if dith(x, y, (y - GROUND) / 20.0) else col('ink'))
# a little red flag at the start: the tint key
bg.rect(5, 82, 5, 99, col('grey')); bg.rect(6, 82, 12, 86, col('red'))
# a signpost before the pit
bg.rect(121, 90, 121, 99, col('wood')); bg.rect(117, 87, 125, 91, col('wood')); bg.line(118, 89, 124, 89, col('bark'))


# ------------------------------------------------------------ brushes -------
def robot(pose):
    """pose: 'run0..3', 'jump', 'hurt'."""
    c = Img(13, 15)
    c.rect(3, 2, 9, 8, col('grey')); c.rect(3, 2, 9, 2, col('mist')); c.rect(9, 3, 9, 8, col('slate'))  # head
    c.rect(6, 0, 6, 1, col('slate')); c.set(6, 0, col('red'))   # antenna
    if pose == 'hurt':
        for d in (0, 1):
            c.set(4 + d, 4 + d, col('ink')); c.set(5 - d, 4 + d, col('ink'))
            c.set(7 + d, 4 + d, col('ink')); c.set(8 - d, 4 + d, col('ink'))
    else:
        c.rect(5, 4, 5, 5, col('cyan')); c.rect(8, 4, 8, 5, col('cyan'))
    c.rect(6, 7, 7, 7, col('slate'))
    c.rect(4, 9, 8, 11, col('orange')); c.rect(4, 9, 8, 9, col('amber'))   # body
    if pose.startswith('run'):
        k = int(pose[3]); sw = [-1, 0, 1, 0][k]
        c.set(3 - sw, 10, col('grey')); c.set(9 + sw, 10, col('grey'))
        c.rect(5 + sw, 12, 5 + sw, 14, col('slate')); c.rect(7 - sw, 12, 7 - sw, 14, col('slate'))
    elif pose == 'jump':
        c.set(2, 8, col('grey')); c.set(10, 8, col('grey'))
        c.rect(4, 12, 5, 13, col('slate')); c.rect(8, 12, 8, 14, col('slate'))
    else:
        c.set(2, 9, col('grey')); c.set(10, 9, col('grey')); c.rect(5, 12, 5, 14, col('slate')); c.rect(7, 12, 7, 14, col('slate'))
    return c


def coin():
    cels = []
    for k in range(2):
        c = Img(9, 9)
        c.disc(4, 4, 4, col('amber')); c.disc(4, 4, 3, col('yellow')); c.rect(4, 2, 4, 6, col('amber'))
        if k:
            c.set(2, 2, col('white'))
        cels.append(c)
    return cels


def blob():
    cels = []
    for k in range(2):
        c = Img(14, 10)
        sq = k
        c.ellipse(7, 6 + sq * 0.5, 6 + sq, 4 - sq, col('grape')); c.rect(1, 8, 12, 9, col('grape'))
        c.ellipse(7, 4 + sq, 4, 1.5, col('plum'))
        c.set(5, 5 + sq, col('white')); c.set(9, 5 + sq, col('white')); c.set(5, 6 + sq, col('ink')); c.set(9, 6 + sq, col('ink'))
        cels.append(c)
    return cels


def cloud():
    c = Img(34, 12)
    for dx, dy, r in ((-10, 2, 4), (-3, 0, 6), (5, 1, 5), (11, 3, 3)):
        c.disc(17 + dx, 6 + dy, r, col('white'))
    c.rect(5, 8, 29, 10, col('mist'))
    return [c]


FONT = {'G': ['.###', '#...', '#.##', '#..#', '.###'], 'A': ['.##.', '#..#', '####', '#..#', '#..#'],
        'M': ['#...#', '##.##', '#.#.#', '#...#', '#...#'], 'E': ['####', '#...', '###.', '#...', '####'],
        'O': ['.##.', '#..#', '#..#', '#..#', '.##.'], 'V': ['#...#', '#...#', '#...#', '.#.#.', '..#..'],
        'R': ['###.', '#..#', '###.', '#.#.', '#..#'], ' ': ['..', '..', '..', '..', '..'],
        '+': ['...', '.#.', '###', '.#.', '...'], '1': ['.#', '##', '.#', '.#', '.#'], '0': ['###', '#.#', '#.#', '#.#', '###']}


def text(s, scale, fg, shadow):
    w = sum(len(FONT[ch][0]) + 1 for ch in s)
    c = Img(w * scale + scale, 5 * scale + scale)
    x = 0
    for ch in s:
        g = FONT[ch]
        for y, row in enumerate(g):
            for i, v in enumerate(row):
                if v == '#':
                    c.rect((x + i) * scale + scale, y * scale + scale, (x + i) * scale + 2 * scale - 1, y * scale + 2 * scale - 1, col(shadow))
                    c.rect((x + i) * scale, y * scale, (x + i) * scale + scale - 1, y * scale + scale - 1, col(fg))
        x += len(g[0]) + 1
    return [c]


S.brush(1, 'robot-run', [robot('run%d' % k) for k in range(4)], 'the robot running: straight paths, next pose every 2 frames')
S.brush(2, 'robot-jump', [robot('jump'), robot('stand')], 'the robot in the air: DRAWN arcs, one point per frame')
S.brush(3, 'robot-hurt', [robot('hurt')], 'the fall: TURN Z 720, MOVE Z 0 > 600, TINT red, OPACITY > 0')
S.brush(4, 'coin', coin(), 'a coin: TURN Y flips it; when grabbed, SIZE 100 > 170 + OPACITY > 0')
S.brush(5, 'blob', blob(), 'a blob: straight paths there and back')
S.brush(6, 'cloud', cloud(), 'a cloud: a slow drift')
S.brush(7, 'game-over', text('GAME OVER', 2, 'white', 'ink'), 'GAME OVER: SIZE 60 > 100, OPACITY 0 > 100')
S.brush(8, 'plus-100', text('+100', 1, 'yellow', 'bark'), '+100: up and fading')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_RED=S.find(bg, E['red'], 6, 82, 13, 87))


# ------------------------------------------------------------ the moves -----
def arc(x0, y0, x1, y1, peak, n, drop=0):
    """n points, one per frame: a jump from (x0,y0) to (x1,y1) peaking 'peak' px above the
    higher end; 'drop' more points continue the fall straight on past the landing."""
    top = min(y0, y1) - peak
    # parabola through the three: y = a t^2 + b t + y0 with y(tp) = top, y(1) = y1
    best = None
    for i in range(1, 100):
        tp = i / 100.0
        a = ((top - y0) - (y1 - y0) * tp) / (tp * tp - tp)
        b = (y1 - y0) - a
        if a > 0 and abs(-b / (2 * a) - tp) < 0.011:
            best = (a, b); break
    a, b = best
    pts = [(round(x0 + (x1 - x0) * i / (n - 1)), round(a * (i / (n - 1)) ** 2 + b * (i / (n - 1)) + y0)) for i in range(n)]
    for j in range(1, drop + 1):   # on down, nearly straight
        pts.append((x1 + (j + 1) // 2, min(H - 6, y1 + 7 * j)))
    return pts


def pts_s(pts):
    return ' '.join('%d,%d' % p for p in pts)


Y0 = GROUND - 7                                     # the robot's centre standing on the ground
J1 = arc(36, Y0, 62, 82 - 7, 16, 8)                 # frames 9-16
J2 = arc(72, 82 - 7, 98, 62 - 7, 14, 8)             # frames 21-28
J3 = arc(112, 62 - 7, 136, Y0, 12, 8, drop=3)       # frames 33-43: short of the far ledge, in
C1, C2 = J1[4], J2[4]                               # where the coins sit: grabbed mid-jump
F1, F2 = 9 + 4, 21 + 4
mv = ['layer clouds; pick 6 1 cloud',
      'mv 24 18 52 16 label="a cloud drifts" from=1 count=60',
      'mv 130 30 108 30 label="another, the other way" from=1 count=60',
      'layer blob; pick 5 2 blob',
      'mv 106 %d 122 %d label="the blob patrols right (next pose every 4)" from=1 count=30 every=4' % (GROUND - 5, GROUND - 5),
      'mv 122 %d 106 %d label="... and back" from=31 count=30 every=4' % (GROUND - 5, GROUND - 5),
      'layer coins; pick 4 2 coin',
      'mv %d %d %d %d label="coin 1 flips (TURN Y 720) until grabbed" from=1 count=%d ty=720' % (C1 + C1 + (F1 - 1,)),
      'mv %d %d %d %d label="coin 1 pops (SIZE 100 > 170, OPACITY > 0)" from=%d count=5 s1=170 o1=0 ease=2' % (C1[0], C1[1], C1[0], C1[1] - 8, F1),
      'mv %d %d %d %d label="coin 2 flips until grabbed" from=1 count=%d ty=1080' % (C2 + C2 + (F2 - 1,)),
      'mv %d %d %d %d label="coin 2 pops" from=%d count=5 s1=170 o1=0 ease=2' % (C2[0], C2[1], C2[0], C2[1] - 8, F2),
      'mv 154 70 154 70 label="coin 3, out of reach past the pit, flips all along (TURN Y 1440)" from=1 count=60 ty=1440',
      'layer score; pick 8 1 plus-100',
      'mv %d %d %d %d label="+100 floats up and fades" from=%d count=8 o1=0 ease=2' % (C1[0], C1[1] - 8, C1[0], C1[1] - 22, F1),
      'mv %d %d %d %d label="+100 again" from=%d count=8 o1=0 ease=2' % (C2[0], C2[1] - 8, C2[0], C2[1] - 22, F2),
      'layer robot; pick 1 4 robot-run',
      'mv 10 %d 36 %d label="run (next pose every 2 frames)" from=1 count=8 every=2' % (Y0, Y0),
      'mv 62 75 72 75 label="run along the ledge" from=17 count=4 every=2',
      'mv 98 55 112 55 label="run to the edge" from=29 count=4 every=2',
      'pick 2 2 robot-jump',
      'mv 0 0 0 0 label="jump 1 (DRAWN arc, one point per frame)" path=drawn pts="%s" from=9 count=8 every=8' % pts_s(J1),
      'mv 0 0 0 0 label="jump 2" path=drawn pts="%s" from=21 count=8 every=8' % pts_s(J2),
      'mv 0 0 0 0 label="the big jump comes up short, into the pit" path=drawn pts="%s" from=33 count=%d every=20' % (pts_s(J3), len(J3)),
      'fg_key "$KEY_RED"; pick 3 1 robot-hurt',
      'mv %d %d %d %d label="the fall: tumbles away (TURN Z 720, MOVE Z 0 > 600), flashes red (TINT 0 > 70), fades" from=%d count=8 z=600 tz=720 t1=70 o1=0 ease=1'
      % (J3[-1] + (J3[-1][0], J3[-1][1] - 4, 33 + len(J3))),
      'layer gameover; pick 7 1 game-over',
      'mv 80 48 80 48 label="GAME OVER grows in (SIZE 60 > 100, OPACITY 0 > 100, ease out)" from=46 count=15 s0=60 o0=0 ease=2']
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')
print('J3', J3, 'C1', C1, 'C2', C2)

# --------------------------------------------------------------- audio ------
A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'cheerful platformer level theme', 'chip', 8801, '--mood', 'playful', '--key', 'G major', '--bpm', 140, '--seconds', 4)
over = au.soundmon(A, 'over', 'game over, short and sad', 'chip', 8802, '--mood', 'melancholy', '--key', 'G minor', '--bpm', 90, '--seconds', 2)
FALL = 33 + len(J3)
au.mix(os.path.join(S.dir, 'platformer-music.wav'), T,
       [(au.fit(au.load(music), S.t(FALL)), 0, 0.8), (au.fit(au.load(over), T - S.t(46)), S.t(46), 0.8)])
jump = au.soundmon(A, 'jump', 'jump', 'chipfx', 8803, '--fx-archetype', 'sweepup')
coin_ = au.soundmon(A, 'coin', 'coin', 'chipfx', 8804, '--fx-archetype', 'coin')
death = au.soundmon(A, 'death', 'falling death', 'chipfx', 8805, '--fx-archetype', 'death')
sfx = [(jump, S.t(9), 0.6), (jump, S.t(21), 0.6), (jump, S.t(33), 0.6), (coin_, S.t(F1), 0.7), (coin_, S.t(F2), 0.7),
       (au.tone(0.8, 900, 120, 'square', a=0.01, r=0.1, gain=0.25), S.t(40), 1.0), (death, S.t(FALL), 0.8)]
au.mix(os.path.join(S.dir, 'platformer-sfx.wav'), T, sfx)
print('platformer ok', S.dir)
