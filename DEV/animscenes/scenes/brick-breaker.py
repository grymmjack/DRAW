"""brick-breaker - an ORIGINAL brick-breaking game, simulated (48 frames of 160x120, 12 fps).

The ball is simulated here (constant speed, walls, bricks, the paddle) and the moves DRAW
makes are written for the driver (moves.sh): the ball runs a DRAWN path through its
position in every frame (arc length = time at constant speed), the paddle slides between
the spots it meets the ball, each brick the ball breaks is held until its frame and then
bursts - bigger, spinning, flashing white, fading (SIZE, TURN Z, TINT, OPACITY) - and a
capsule falls from the first one, flipping (TURN Y 720), into the paddle: a sparkle
(SIZE + TINT to gold + OPACITY).
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('brick-breaker', sys.argv[1], frames=48, cols=8, fps=12)
W, H, N = S.w, S.h, S.frames

ROWS = ['red', 'orange', 'amber', 'lime', 'cyan']
BW, BH, BX0, BY0 = 16, 6, 16, 14


def brick(c):
    b = Img(BW - 1, BH - 1)
    b.rect(0, 0, BW - 2, BH - 2, col(c))
    b.rect(0, 0, BW - 2, 0, mix(col(c), col('white'), 0.5)); b.rect(0, BH - 2, BW - 2, BH - 2, mix(col(c), col('ink'), 0.4))
    return b


# ----------------------------------------------------------- simulate -------
alive = {(c, r) for c in range(8) for r in range(len(ROWS))}
x, y, vx, vy = 30.0, 96.0, -3.4, -5.4   # picked from a search: 3 bricks, 2 returns, 2 wall bounces
pos, hits, bounces, pad_hits = [], [], [], [(1, 30)]
for f in range(1, N + 1):
    pos.append((int(round(x)), int(round(y))))
    nx, ny = x + vx, y + vy
    if nx < 8 or nx > 152:
        vx = -vx; nx = x + vx; bounces.append(f)
    if ny < 8:
        vy = -vy; ny = y + vy; bounces.append(f)
    c, r = int((nx - BX0) // BW), int((ny - BY0) // (BH + 1))
    if (c, r) in alive and 0 <= c < 8:
        alive.discard((c, r)); hits.append((f + 1, c, r)); vy = -vy; ny = y + vy
    if ny > 98 and vy > 0:
        vy = -vy; ny = y + vy; pad_hits.append((f + 1, int(round(nx))))
        vx += 0.4 * (1 if len(pad_hits) % 2 else -1)
    x, y = nx, ny
pad_hits.append((N, max(14, min(146, pos[-1][0]))))   # the paddle heads for the ball

# ---------------------------------------------------------------- bg --------
bg = Img(W, H, col('night'))
for yy in range(H):
    for xx in range(W):
        if xx % 8 == 0 or yy % 8 == 0:
            bg.set(xx, yy, col('ink'))
bg.rect(0, 0, W - 1, 3, col('slate')); bg.rect(0, 0, 3, H - 1, col('slate')); bg.rect(W - 4, 0, W - 1, H - 1, col('slate'))
bg.rect(0, 3, W - 1, 3, col('grey')); bg.rect(3, 3, 3, H - 1, col('grey')); bg.rect(W - 4, 3, W - 4, H - 1, col('grey'))
hit_cells = {(c, r) for _, c, r in hits}
for c in range(8):
    for r in range(len(ROWS)):
        if (c, r) not in hit_cells:
            bg.blit(brick(ROWS[r]), BX0 + c * BW, BY0 + r * (BH + 1))
bg.disc(W - 12, H - 8, 3, col('yellow'))   # a gold lamp: the sparkle's tint key
bg.disc(W - 12, H - 8, 1.5, col('yellow'))

# ------------------------------------------------------------ brushes -------
def ball():
    cels = []
    for k in range(4):
        c = Img(6, 6)
        c.disc(3, 3, 2.6, col('cyan' if k % 2 else 'blue', 120)); c.disc(3, 3, 1.6, col('white'))
        cels.append(c)
    return cels


def paddle():
    cels = []
    for k in range(2):
        c = Img(24, 5)
        c.rect(1, 0, 22, 4, col('grape')); c.rect(1, 0, 22, 0, col('rose')); c.rect(0, 1, 0, 3, col('pink' if k else 'red'))
        c.rect(23, 1, 23, 3, col('pink' if k else 'red'))
        for i in range(4, 21, 4):
            c.set(i, 2, col('coral'))
        cels.append(c)
    return cels


def capsule():
    cels = []
    for k in range(2):
        c = Img(11, 5)
        c.rect(1, 0, 9, 4, col('lime')); c.rect(1, 0, 9, 0, col('white'))
        for xx, ch in ((3, 'W'),):
            pass
        c.rect(4, 1, 4, 3, col('pine')); c.rect(6, 1, 6, 3, col('pine')); c.set(5, 2, col('pine'))  # a "W" for wide
        cels.append(c)
    return cels


def sparkle():
    cels = []
    for k in range(4):
        c = Img(15, 15)
        L = 3 + k * 2
        for a in range(8):
            ang = a * math.pi / 4 + k * 0.2
            for t in range(L if a % 2 == 0 else L // 2):
                c.set(7 + math.cos(ang) * t, 7 + math.sin(ang) * t, col('white' if t < 2 else 'yellow'))
        cels.append(c)
    return cels


S.brush(1, 'ball', ball(), 'the ball, glow pulse: DRAWN path through its simulated position in every frame')
S.brush(2, 'paddle', paddle(), 'the paddle: straight paths between the spots it meets the ball')
for i, r in enumerate(range(len(ROWS))):
    S.brush(3 + i, 'brick-' + ROWS[r], [brick(ROWS[r])], 'a brick: held until it is hit, then SIZE 100 > 180, TURN Z, TINT white, OPACITY > 0')
S.brush(8, 'capsule', capsule(), 'a WIDE capsule: falls into the paddle, TURN Y 720')
S.brush(9, 'sparkle', sparkle(), 'the catch: SIZE 40 > 200, TINT to gold, OPACITY > 0')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_GOLD=S.find(bg, E['yellow'], W - 20, H - 14))

# ------------------------------------------------- the moves for DRAW -------
mv = []
mv.append('layer paddle; pick 2 2 paddle')
for (f0, x0), (f1, x1) in zip(pad_hits, pad_hits[1:]):
    if f1 > f0:
        mv.append('mv %d 103 %d 103 label="paddle %d -> %d (frames %d-%d)" from=%d count=%d every=4 ease=3'
                  % (x0, x1, x0, x1, f0, f1 - 1 if f1 < N else N, f0, (f1 - f0) if f1 < N else (N - f0 + 1)))
mv.append('layer bricks')
for f, c, r in hits:
    bx, by = BX0 + c * BW + (BW - 1) // 2, BY0 + r * (BH + 1) + (BH - 1) // 2
    mv.append('pick %d 1 brick-%s' % (3 + r, ROWS[r]))
    mv.append('mv %d %d %d %d label="brick %d,%d held until frame %d" from=1 count=%d' % (bx, by, bx, by, c, r, f, f - 1))
    mv.append('mv %d %d %d %d label="brick %d,%d bursts (SIZE 100 > 180, TURN Z 45, TINT white, OPACITY > 0)" from=%d count=%d s1=180 tz=45 t1=100 o1=0 ease=2'
              % (bx, by, bx, by + 4, c, r, f, min(6, N - f + 1)))
pts = ' '.join('%d,%d' % p for p in pos)
mv.append('layer ball; pick 1 4 ball')
mv.append('mv 0 0 0 0 label="the ball: DRAWN path, one point per frame" path=drawn pts="%s" from=1 count=%d' % (pts, N))
if hits:
    f, c, r = hits[0]
    bx, by = BX0 + c * BW + (BW - 1) // 2, BY0 + r * (BH + 1) + (BH - 1) // 2
    fc = min(N - 4, f + 18)
    # where the paddle is at frame fc
    px = pad_hits[-1][1]
    for (f0, x0), (f1, x1) in zip(pad_hits, pad_hits[1:]):
        if f0 <= fc < f1:
            t = (fc - f0) / max(1, f1 - 1 - f0); t = t * t * (3 - 2 * t); px = int(round(x0 + (x1 - x0) * t))
    mv.append('layer capsule; pick 8 2 capsule')
    mv.append('mv %d %d %d 99 label="the capsule falls into the paddle (TURN Y 720, ease in)" from=%d count=%d ty=720 ease=1' % (bx, by, px, f, fc - f + 1))
    mv.append('fg_key "$KEY_GOLD"; layer sparkle; pick 9 4 sparkle')
    mv.append('mv %d 100 %d 100 label="the catch sparkles (SIZE 40 > 200, TINT gold, OPACITY > 0)" from=%d count=%d s0=40 s1=200 t1=100 o1=0 ease=2'
              % (px, px, fc + 1, N - fc))
    CATCH = fc + 1
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')
print('hits', hits, 'paddle', pad_hits, 'bounces', bounces)

# --------------------------------------------------------------- audio ------
A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'brick breaker arcade, upbeat', 'chip', 3301, '--mood', 'driving', '--key', 'A minor', '--bpm', 132, '--seconds', 4)
au.mix(os.path.join(S.dir, 'brick-breaker-music.wav'), T, [(au.fit(au.load(music), T), 0, 1.0)])
blip = au.soundmon(A, 'blip', 'wall bounce', 'chipfx', 3302, '--fx-archetype', 'blip')
pad = au.soundmon(A, 'pad', 'paddle hit', 'chipfx', 3303, '--fx-archetype', 'hit')
crack = au.soundmon(A, 'crack', 'brick break', 'chipfx', 3304, '--fx-archetype', 'crack')
fan = au.soundmon(A, 'fanfare', 'power up', 'chipfx', 3305, '--fx-archetype', 'confirmup')
sfx = [(blip, S.t(f), 0.5) for f in bounces] + [(pad, S.t(f), 0.7) for f, _ in pad_hits[1:-1]]
sfx += [(crack, S.t(f), 0.8) for f, _, _ in hits]
if hits:
    sfx.append((fan, S.t(CATCH), 0.8))
au.mix(os.path.join(S.dir, 'brick-breaker-sfx.wav'), T, sfx)
print('brick-breaker ok', S.dir)
