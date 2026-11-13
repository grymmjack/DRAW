"""farm - a day on the farm, dawn to night (64 frames, 12 fps) - an animation PROJECT.

DAWN 1-16: the sun comes up (X / Y keys = an arc with eases, TINT keys from red), the
warm sky fades (a full-frame clip, OPACITY keys), the rooster crows (ping-pong, a crow
when the clip starts, IN 1 - OUT 16).
NOON 17-32: the near windmill spins (ROTATE keys, seamless for 4 blades); the far one
turns too (ROTATE saw, SCALE 60%) - then it is BAKED to pixels (Bake Clip to Pixels);
clouds drift (X keys ease in-out, SCALE X sine); a tractor crosses (X keys, its engine a
sound when it starts with VOLUME + PAN keys) and hits a bump - keyed by nudging the clip
with the Move tool's arrow keys on one frame; the sheep hops: drawn as four frames, then
Make Clip from Selected Frames turns them into a clip that walks (X keys); a second sheep
is another clip switched to the SAME source (Next Clip Source).
DUSK 33-48: the sun sets red, the sky warms again.
NIGHT 49-64: the night sky (OPACITY keys), the moon rises, stars twinkle, fireflies
wander (X / Y noise, different seeds - Copy / Paste Lanes) and glow (OPACITY sine), the
owl wakes (mode Hold, a hoot when it starts).
A horizon guide is a reference layer; the FARM sign on the barn is drawn once, cells linked.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('farm', sys.argv[1], frames=64, cols=8, fps=12)
W, H = S.w, S.h
R = random.Random(31)
M1 = (118, 52)    # the near windmill's hub
M2 = (148, 66)    # the far one's

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 80, ['blue', 'cyan', 'mist'])
for x in range(W):                                          # hills
    for y in range(66 + int(5 * math.sin(x * 0.04) + 3 * math.sin(x * 0.11)), 82):
        bg.set(x, y, col('green') if dith(x, y, 0.35) else col('pine'))
for y in range(80, H):                                      # the field, furrows
    for x in range(W):
        bg.set(x, y, col('lime') if dith(x, y, 0.25 + 0.2 * ((x + y * 3) // 7 % 2)) else col('green'))
for y in range(96, H, 5):
    for x in range(W): bg.set(x, y, col('green'))
bg.rect(0, 92, W - 1, 95, col('tan')); bg.rect(0, 93, W - 1, 94, col('sand'))      # the farm track
# the barn
bg.rect(12, 58, 50, 92, col('red')); bg.rect(12, 58, 50, 59, col('wine'))
for i in range(20): bg.line(12 + i, 58 - i * 0.6, 50 - i, 58 - i * 0.6, col('wine'))
bg.rect(25, 74, 37, 92, col('wine')); bg.line(25, 74, 37, 92, col('white')); bg.line(37, 74, 25, 92, col('white'))
bg.rect(22, 61, 40, 67, col('ink'))                          # the sign board (linked cells)
# a tree on the right edge (the owl's)
bg.rect(150, 58, 154, 92, col('bark'))
for cx, cy, r in ((152, 50, 9), (145, 56, 6), (158, 55, 7)): bg.disc(cx, cy, r, col('pine'))
# the windmill towers (the blades are clips)
for (hx, hy), h, w in ((M1, 40, 6), (M2, 22, 3)):
    for y in range(hy, hy + h):
        t = (y - hy) / float(h)
        bg.rect(hx - 1 - w * t, y, hx + 1 + w * t, y, col('stone'))
    bg.disc(hx, hy, 2 if w > 3 else 1, col('slate'))
# fence
for x in range(56, 106, 7): bg.rect(x, 84, x + 1, 92, col('wood'))
bg.rect(56, 86, 106, 86, col('wood'))
# colour keys: red (the sun's tint) on the barn, a navy speck
bg.rect(0, 117, 2, 119, col('navy'))

def guide():
    g = Img(W, H)
    for x in range(0, W, 2): g.set(x, 80, col('red', 190))
    for t in range(0, 49, 2):                                # the sun's path
        x = 80 + (-70 + 140 * t / 48.0); y = 50 + 45 - 70 * math.sin(math.pi * t / 48.0)
        g.set(x, y, col('amber', 200))
    return [g]

def sun():
    cels = []
    for k in range(2):
        s = Img(20, 20); s.disc(10, 10, 6, col('yellow')); s.disc(10, 10, 4, col('white'))
        for a in range(0, 360, 45):
            r0, r1 = (8, 10) if (a // 45 + k) % 2 else (8, 9)
            s.line(10 + r0 * math.cos(math.radians(a)), 10 + r0 * math.sin(math.radians(a)), 10 + r1 * math.cos(math.radians(a)), 10 + r1 * math.sin(math.radians(a)), col('yellow'))
        cels.append(s)
    return cels

def moon():
    m = Img(12, 12); m.disc(6, 6, 5, col('mist')); pass
    for x, y in ((4, 4), (7, 7), (5, 8)): m.set(x, y, col('grey'))
    return [m]

def stars():
    cels = []; rr = random.Random(3); pts = [(rr.randrange(W), rr.randrange(70)) for _ in range(45)]
    for k in range(2):
        s = Img(W, H)
        for i, (x, y) in enumerate(pts):
            s.set(x, y, col('white') if (i + k) % 3 else col('mist', 140))
            if i % 9 == k: s.set(x + 1, y, col('white', 150)); s.set(x - 1, y, col('white', 150))
        cels.append(s)
    return cels

def overlay(c, a, top=0):
    o = Img(W, H)
    for y in range(H):
        for x in range(W):
            o.set(x, y, col(c, a if y < 82 else a // 2))
    return [o]

def blades(r):
    b = Img(2 * r + 3, 2 * r + 3); c = r + 1
    for a in (0, 90, 180, 270):
        for t in range(2, r + 1):
            x = c + t * math.cos(math.radians(a)); y = c + t * math.sin(math.radians(a))
            b.set(x, y, col('wood'))
            for s in range(1, 3 if r > 8 else 2):
                b.set(x + s * math.cos(math.radians(a + 90)), y + s * math.sin(math.radians(a + 90)), col('white') if t > 3 else col('wood'))
    b.disc(c, c, 1, col('bark'))
    return [b]

def cloud():
    c = Img(32, 12)
    for cx, cy, r in ((8, 7, 4), (15, 5, 5), (23, 7, 4), (17, 8, 4)): c.disc(cx, cy, r, col('white'))
    for x in range(4, 28): c.set(x, 11, col('mist'))
    return [c]

def sheep():
    cels = []
    for k in range(4):
        s = Img(16, 14); lift = (0, 2, 3, 1)[k]
        y0 = 6 - lift
        for cx, cy in ((5, y0 + 2), (8, y0 + 1), (11, y0 + 2), (8, y0 + 3)): s.disc(cx, cy, 2.5, col('white'))
        s.disc(13.5, y0 + 1, 1.8, col('ink')); s.set(14, y0, col('white'))
        legs = 2 if lift else 3
        for x in (5, 10): s.line(x, y0 + 5, x, y0 + 5 + legs, col('ink'))
        cels.append(s)
    return cels

def rooster():
    cels = []
    for k in range(2):
        r = Img(12, 14)
        r.ellipse(5, 9, 4, 3, col('amber')); r.disc(8, 4, 2, col('amber')); r.set(8, 2, col('red')); r.set(9, 2, col('red'))
        r.line(10, 4, 11 + k, 4 - k, col('yellow'))                      # beak opens
        r.line(1, 7, 0, 3, col('red')); r.line(2, 7, 1, 4, col('wine'))   # tail
        r.line(5, 12, 5, 13, col('yellow')); r.line(7, 12, 7, 13, col('yellow')); r.set(8, 4, col('ink'))
        cels.append(r)
    return cels

def tractor():
    cels = []
    for k in range(2):
        t = Img(30, 20)
        t.rect(8, 6, 22, 13, col('lime')); t.rect(10, 1, 18, 6, col('cyan', 170)); t.rect(9, 0, 19, 1, col('green'))
        t.rect(22, 9, 28, 13, col('green')); t.rect(26, 4, 27, 9, col('grey'))
        t.disc(10, 15, 4.5, col('ink')); t.disc(10, 15, 2, col('grey')); t.disc(25, 16, 3, col('ink'))
        t.set(10 + (1 if k else -1), 15, col('ink')); t.set(26, 3 - k, col('mist', 150))
        cels.append(t)
    return cels

def firefly():
    cels = []
    for k in range(2):
        f = Img(5, 5); f.set(2, 2, col('yellow'));
        if k: [f.set(2 + dx, 2 + dy, col('lime', 140)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        cels.append(f)
    return cels

def owl():
    cels = []
    for k in range(2):
        o = Img(10, 12); o.ellipse(5, 7, 4, 4.5, col('wood')); o.ellipse(5, 8, 2.5, 3, col('tan'))
        o.set(1, 2, col('wood')); o.set(8, 2, col('wood'))
        if k: o.disc(3.5, 5, 1.2, col('yellow')); o.disc(6.5, 5, 1.2, col('yellow')); o.set(3, 5, col('ink')); o.set(6, 5, col('ink'))
        else: o.line(2, 5, 4, 5, col('bark')); o.line(6, 5, 8, 5, col('bark'))
        o.set(5, 7, col('amber'))
        cels.append(o)
    return cels

def sign():
    s = Img(9, 5); font = {'F': ['11', '10', '11', '10', '10'], 'A': ['010', '101', '111', '101', '101'], 'R': ['11', '11', '10', '11', '10'] if False else ['110', '101', '110', '101', '101'], 'M': ['101', '111', '111', '101', '101']}
    s = Img(16, 5); x = 0
    for ch in 'FARM':
        for y, row in enumerate(font[ch]):
            for i, b in enumerate(row):
                if b == '1': s.set(x + i, y, col('white'))
        x += len(font[ch][0]) + 1
    return [s]

S.brush(1, 'guide', guide(), 'the horizon + the sun\'s path: a REFERENCE layer')
S.brush(2, 'sun', sun(), 'the sun: an arc of X / Y keys with eases, TINT keys from red')
S.brush(3, 'moon', moon(), 'the moon: rises at night (X / Y keys, OPACITY fade in)')
S.brush(4, 'stars', stars(), 'stars: full-frame, twinkling cels, OPACITY keys')
S.brush(5, 'warm', overlay('orange', 150), 'the warm sky at dawn and dusk: full-frame, OPACITY keys')
S.brush(6, 'night', overlay('night', 200), 'the night sky: full-frame, OPACITY keys')
S.brush(7, 'blades', blades(14), 'the near windmill\'s blades: ROTATE keys (4 blades: seamless)')
S.brush(8, 'blades2', blades(8), 'the far blades: ROTATE saw + SCALE 60%, then BAKED to pixels')
S.brush(9, 'cloud', cloud(), 'a cloud: X keys ease in-out, SCALE X sine')
S.brush(10, 'sheep', sheep(), 'a sheep hop: stamped on frames 1-4, then Make Clip from Selected Frames')
S.brush(11, 'rooster', rooster(), 'the rooster: ping-pong, a crow when it starts (dawn)')
S.brush(12, 'tractor', tractor(), 'the tractor: X keys, engine VOLUME + PAN, a bump keyed with the Move tool')
S.brush(13, 'firefly', firefly(), 'a firefly: X / Y noise (seeds), OPACITY sine')
S.brush(14, 'owl', owl(), 'the owl: wakes at night (mode Hold), a hoot when it starts')
S.brush(15, 'sign', sign(), 'FARM: drawn once, cells linked')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_RED=S.find(bg, E['red'], 12, 70, 24, 90), KEY_NAVY=S.find(bg, E['navy'], 0, 116, 3, 119),
       M1X=M1[0], M1Y=M1[1], M2X=M2[0], M2Y=M2[1])

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'pastoral countryside folk, gentle and warm', 'opl', 6401, '--mood', 'serene', '--key', 'G major', '--bpm', 100, '--seconds', 6)
bed = [(au.fit(au.load(music), T), 0, 0.7), (au.wind(T, 101), 0, 0.15)]
au.mix(os.path.join(S.dir, 'farm-music.wav'), T, bed)
crickets = [v * (0.5 + 0.5 * math.sin(i / au.RATE * 40)) for i, v in enumerate(au.tone(T - S.t(49), 4200, 4300, 'tri', gain=0.06))]
sfx = [(au.gull(102), S.t(20), 0.25), (crickets, S.t(49), 1.0)]
au.mix(os.path.join(S.dir, 'farm-sfx.wav'), T, sfx)
au.mix(os.path.join(S.dir, 'crow.wav'), 1.2, [(au.tone(0.3, 600, 900, 'saw', gain=0.2), 0, 1.0), (au.tone(0.7, 900, 500, 'saw', vib=0.06, gain=0.2), 0.3, 1.0)])
au.mix(os.path.join(S.dir, 'putt.wav'), 2.0, [(au._lp([v * (1 if (i // 1500) % 2 else 0.3) for i, v in enumerate(au.tone(2.0, 60, 64, 'saw', gain=0.35))], 0.3), 0, 1.0)])
au.mix(os.path.join(S.dir, 'hoot.wav'), 1.2, [(au.tone(0.35, 420, 380, 'sine', gain=0.4), 0, 1.0), (au.tone(0.5, 400, 360, 'sine', gain=0.4), 0.5, 1.0)])
print('farm ok', S.dir)
