"""neon - a rainy night street in three acts (64 frames, 12 fps) - an animation PROJECT.

RAIN 1-20: two rain clips (near + far, the far one at half OPACITY), a BAR sign blinking
(OPACITY square), an arrow sign chasing (its own cels), the HOTEL sign buzzing (OPACITY
noise), puddles rippling (SCALE X sine), steam from a manhole (Move Brush > Apply as Clip,
turning as it rises), a walker with an umbrella crossing the whole loop (X keys, Y square =
the bob), a cat on the fence swishing its tail (ping-pong, a meow on cel 1).
TRAFFIC 21-44: a car left to right and one right to left (flipped; the same lanes pasted
and turned round) - X keys ease in-out, their engines sounds that start with the clip,
VOLUME up and down, PAN across.
BLACKOUT 45-64: lightning (a white flash clip, OPACITY keys, thunder when it starts),
the HOTEL sign dies (OPACITY keys with HOLD eases: flicker, flicker, off), three windows go
dark one by one (OPACITY hold keys) after warming (TINT toward amber).
A perspective guide is a reference layer; the poster is drawn once, cells linked.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('neon', sys.argv[1], frames=64, cols=8, fps=12)
W, H = S.w, S.h
R = random.Random(11)

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 92, ['ink', 'night', 'stone', 'slate'])
# buildings: left block, right block, a far tower between
bg.rect(0, 10, 58, 86, col('night')); bg.rect(0, 10, 58, 12, col('stone'))
bg.rect(104, 4, W - 1, 86, col('night')); bg.rect(104, 4, W - 1, 6, col('stone'))
bg.rect(66, 22, 96, 86, col('stone')); bg.rect(70, 26, 92, 86, col('slate'))
for x in range(72, 92, 5):
    for y in range(30, 80, 7):
        bg.rect(x, y, x + 2, y + 3, col('amber') if R.random() < 0.3 else col('night'))
def windows(x0, x1, y0, y1, lit):
    for x in range(x0, x1, 12):
        for y in range(y0, y1, 14):
            bg.rect(x, y, x + 7, y + 8, col('ink')); bg.rect(x + 1, y + 1, x + 6, y + 7, col('amber') if (x * 7 + y) % 5 < lit else col('stone'))
windows(6, 52, 18, 70, 1); windows(110, 156, 14, 70, 1)
# the street: pavement, kerb, road in perspective, wet shine
bg.rect(0, 86, W - 1, 90, col('slate')); bg.rect(0, 91, W - 1, 92, col('grey'))
vgrad(bg, 0, 93, W - 1, H - 1, ['stone', 'night', 'ink'])
for x in range(0, W, 16):                                  # lane marks
    bg.rect(x, 104, x + 7, 105, col('mist'))
for _ in range(60):                                        # wet glints on the road
    x, y = R.randrange(W), R.randrange(94, H)
    bg.set(x, y, col(R.choice(['pink', 'cyan', 'amber']), 120))
# a fence on the right (the cat sits on it), a lamp post on the left
for x in range(124, W, 4): bg.rect(x, 70, x + 1, 86, col('bark'))
bg.rect(124, 72, W - 1, 73, col('wood'))
bg.rect(30, 40, 31, 86, col('grey')); bg.rect(26, 38, 35, 40, col('grey')); bg.ellipse(30.5, 42, 3, 1.5, col('yellow'))
bg.ellipse(30, 89, 10, 2, col('amber', 90))
# sign boards (dark - the clips light them)
bg.rect(8, 22, 34, 32, col('ink')); bg.rect(112, 18, 152, 28, col('ink')); bg.rect(40, 46, 56, 52, col('ink'))
bg.ellipse(66, 112, 9, 2, col('stone'))                    # the manhole
bg.disc(140, 10, 0, col('mist'))
bg.rect(60, 92, 62, 94, col('cyan'))                       # a cyan key for the tint (the night)

# -------------------------------------------------------------- brushes -----
def guide():
    g = Img(W, H); vx, vy = 81, 60
    for ex, ey in ((0, 120), (40, 120), (120, 120), (159, 120), (0, 0), (159, 0), (0, 86), (159, 86)):
        n = max(abs(ex - vx), abs(ey - vy))
        for i in range(0, n, 2):
            g.set(vx + (ex - vx) * i / n, vy + (ey - vy) * i / n, col('red', 190))
    g.disc(vx, vy, 1, col('yellow'))
    return [g]

def rain(n, alpha, seed):
    cels = []; rr = random.Random(seed); drops = [(rr.randrange(W), rr.randrange(H)) for _ in range(n)]
    for k in range(3):
        r = Img(W, H)
        for x, y in drops:
            yy = (y + k * 13) % H
            r.line(x - 1, yy, x, yy + 3, col('mist', alpha))
        cels.append(r)
    return cels

def neon_text(text, c, w, h):
    glyph = {'B': ['111', '101', '110', '101', '111'], 'A': ['010', '101', '111', '101', '101'], 'R': ['110', '101', '110', '101', '101'],
             'H': ['101', '101', '111', '101', '101'], 'O': ['111', '101', '101', '101', '111'], 'T': ['111', '010', '010', '010', '010'],
             'E': ['111', '100', '110', '100', '111'], 'L': ['100', '100', '100', '100', '111']}
    img = Img(w, h); x0 = (w - (len(text) * 4 - 1) * 1) // 2; y0 = (h - 5) // 2
    for i, ch in enumerate(text):
        for y, row in enumerate(glyph[ch]):
            for x, b in enumerate(row):
                if b == '1':
                    img.set(x0 + i * 4 + x, y0 + y, col('white'))
    glow = Img(w, h)
    for y in range(h):
        for x in range(w):
            if img.get(x, y) is None and any(img.get(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                glow.set(x, y, col(c, 200))
            elif img.get(x, y):
                glow.set(x, y, col('white'))
    return glow

def arrow():
    cels = []
    for k in range(3):
        a = Img(18, 8)
        for i in range(5):
            on = (i % 3) == k
            a.disc(2 + i * 3, 4, 1, col('cyan') if on else col('navy'))
        a.line(15, 1, 17, 4, col('cyan')); a.line(15, 7, 17, 4, col('cyan'))
        cels.append(a)
    return cels

def window_light():
    w = Img(8, 9); w.rect(0, 0, 7, 8, col('yellow')); w.rect(1, 1, 6, 7, col('amber'))
    w.line(0, 4, 7, 4, col('wood')); w.line(4, 0, 4, 8, col('wood')); return [w]

def puddle():
    cels = []
    for k in range(4):
        p = Img(20, 5); p.ellipse(10, 2.5, 9, 2, col('stone'))
        ring(p, 10 + k * 0.0, 2.5, 1 + k * 2, 'cyan', 0.8)
        p2 = Img(20, 5)
        for y in range(5):
            for x in range(20):
                q = p.get(x, y)
                if q and (((x - 10) / 9.0) ** 2 + ((y - 2.5) / 2.2) ** 2) <= 1: p2.set(x, y, q)
        cels.append(p2)
    return cels

def steam():
    s = Img(12, 12)
    for y in range(12):
        for x in range(12):
            d = math.hypot(x - 5.5, y - 5.5) / 6
            if d < 1 and dith(x, y, 0.6 * (1 - d)): s.set(x, y, col('mist', 150))
    return [s]

def walker():
    cels = []
    for k in range(4):
        p = Img(14, 24); step = (0, 2, 0, -2)[k]
        p.ellipse(7, 3, 7, 3, col('red')); p.rect(0, 3, 13, 3, col('wine')); p.line(7, 3, 7, 10, col('grey'))   # umbrella
        p.disc(7, 9, 1.5, col('skin')); p.rect(5, 11, 9, 17, col('navy'))                                   # head, coat
        p.line(6, 18, 6 - step, 23, col('ink')); p.line(8, 18, 8 + step, 23, col('ink'))
        cels.append(p)
    return cels

def car(body, trim):
    cels = []
    for k in range(2):
        c = Img(36, 14)
        c.rect(2, 6, 33, 11, col(body)); c.rect(9, 2, 26, 6, col(body)); c.rect(11, 3, 17, 6, col('cyan', 180)); c.rect(19, 3, 24, 6, col('cyan', 180))
        c.rect(32, 7, 34, 8, col('yellow')); c.rect(1, 7, 2, 8, col('red'))
        for wx in (8, 27):
            c.disc(wx, 11.5, 2.5, col('ink')); c.set(wx + (1 if k else -1), 11, col('grey'))
        c.line(3, 9, 32, 9, col(trim))
        cels.append(c)
    return cels

def cat():
    cels = []
    for k in range(4):
        c = Img(16, 12)
        c.ellipse(8, 8, 4, 3, col('ink')); c.disc(12, 5, 2.5, col('ink'))
        c.set(11, 2, col('ink')); c.set(13, 2, col('ink')); c.set(12, 5, col('lime')); c.set(13, 5, col('lime'))
        ang = (-0.9, -0.4, 0.2, 0.7)[k]
        for i in range(7):
            c.set(4 - i * math.cos(ang) * 0.8, 8 - i * math.sin(ang + 1.2), col('ink'))
        cels.append(c)
    return cels

def flash():
    f = Img(W, H, fill=col('white', 160)); return [f]

def poster():
    p = Img(14, 18); p.rect(0, 0, 13, 17, col('coral')); p.rect(2, 2, 11, 9, col('yellow')); p.disc(6.5, 6, 2.5, col('red'))
    for y in (12, 14): p.line(2, y, 11, y, col('wine'))
    return [p]

S.brush(1, 'guide', guide(), 'the perspective guide (vanishing point): a REFERENCE layer')
S.brush(2, 'rain', rain(70, 200, 1), 'rain, near: full-frame clip, its cels fall')
S.brush(3, 'rainfar', rain(110, 140, 2), 'rain, far: the same at OPACITY 50')
S.brush(4, 'bar', [neon_text('BAR', 'pink', 26, 10)], 'the BAR sign: OPACITY square (blinks)')
S.brush(5, 'arrow', arrow(), 'an arrow sign chasing (3 cels, loop)')
S.brush(6, 'hotel', [neon_text('HOTEL', 'cyan', 40, 10)], 'the HOTEL sign: OPACITY noise (buzz), then hold keys (dies)')
S.brush(7, 'window', window_light(), 'a lit window: TINT toward amber, OPACITY hold keys (goes dark)')
S.brush(8, 'puddle', puddle(), 'a puddle ripple: SCALE X sine')
S.brush(9, 'steam', steam(), 'manhole steam: Move Brush > Apply as Clip (size, fade, turn)')
S.brush(10, 'walker', walker(), 'a walker with an umbrella: X keys over the loop, Y square (bob)')
S.brush(11, 'car', car('red', 'wine'), 'a red car: X keys ease in-out, engine VOLUME + PAN')
S.brush(12, 'car2', car('blue', 'navy'), 'a blue car: flipped, the lanes pasted and turned round')
S.brush(13, 'cat', cat(), 'a cat on the fence: ping-pong tail, a meow on cel 1')
S.brush(14, 'flash', flash(), 'lightning: a white flash clip, OPACITY keys, thunder when it starts')
S.brush(15, 'poster', poster(), 'a poster: drawn once, cells linked over every frame')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_CYAN=S.find(bg, E['cyan'], 58, 90, 64, 96))

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'rainy night city, lonely saxophone noir jazz', 'opl', 6201, '--mood', 'melancholy', '--key', 'C minor', '--bpm', 70, '--seconds', 6)
bed = [(au.fit(au.load(music), T), 0, 0.6), (au._hp(au.noise(T, 81, 0.6), 0.3), 0, 0.3)]
au.mix(os.path.join(S.dir, 'neon-music.wav'), T, bed)
sfx = [(au.hiss(T, 82, 0.2), 0, 0.5), (au.drip(1500), S.t(9), 0.4), (au.drip(1300), S.t(37), 0.4)]
au.mix(os.path.join(S.dir, 'neon-sfx.wav'), T, sfx)
eng = au.tone(1.4, 70, 95, 'saw', vib=0.05, gain=0.35)
au.mix(os.path.join(S.dir, 'engine.wav'), 1.5, [(au._lp(eng, 0.25), 0, 1.0), (au._hp(au.noise(1.4, 83, 0.4), 0.4), 0, 0.3)])
au.mix(os.path.join(S.dir, 'thunder.wav'), 2.0, [(au._lp(au.noise(2.0, 84, 0.03), 0.015), 0, 1.0), (au.thud(40, 1.0), 0, 0.6)])
au.mix(os.path.join(S.dir, 'meow.wav'), 0.5, [(au.tone(0.4, 700, 500, 'tri', vib=0.04, gain=0.4), 0, 1.0)])
print('neon ok', S.dir)
