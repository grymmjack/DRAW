"""reef - a coral reef in three acts (64 frames, 12 fps) - an animation PROJECT.

CALM 1-24: light rays shimmer (OPACITY sine, SCALE X triangle), seaweed sways (ping-pong
cels + ROTATE triangle about a PIVOT at its foot), a school of five fish - one clip source -
drifts right (X keys, Y sine at five phases), a jellyfish rises (Y keys ease in-out,
SCALE Y sine = the pulse).
SHARK 25-44: a shark crosses (X keys ease in-out, ROTATE keys, its rumble a sound when the
clip starts with VOLUME and PAN lanes: it swells and pans left to right); the fish dart
off (X keys ease out, Y keys scatter).
TREASURE 45-64: a crab scuttles back and forth (X triangle), the chest opens and stays
open (mode Hold, a creak when it starts, TINT toward gold), a flipped blue school swims
back in. Bubbles (Move Brush > Apply as Clip, a blub each time round) rise throughout.
A layout guide is a reference layer (seen, never exported); the starfish is drawn once
and its cells linked over every frame.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('reef', sys.argv[1], frames=64, cols=8, fps=12)
W, H = S.w, S.h
R = random.Random(7)

# ---------------------------------------------------------- background ------
bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 92, ['cyan', 'blue', 'navy', 'deep'])
for y in range(93, H):                                   # sand
    for x in range(W):
        bg.set(x, y, col('tan') if dith(x, y, 0.3 + 0.25 * math.sin(x * 0.21 + y * 0.4)) else col('sand'))
for x in range(W):                                       # the sand's edge, uneven
    for y in range(88 + int(3 * math.sin(x * 0.07) + 2 * math.sin(x * 0.23)), 94):
        bg.set(x, y, col('tan'))
for cx, cy, rx, ry in ((18, 96, 16, 9), (138, 94, 20, 11), (82, 99, 9, 5)):   # rocks
    bg.ellipse(cx, cy, rx, ry, col('stone')); bg.ellipse(cx - 2, cy - 2, rx - 4, ry - 3, col('slate'))
def coral_branch(x, y, h, c, lean):
    for k in range(h):
        bg.set(x + int(lean * k / h * 4), y - k, col(c)); bg.set(x + 1 + int(lean * k / h * 4), y - k, col(c))
        if k % 5 == 3:
            d = 1 if (k // 5) % 2 else -1
            bg.line(x + int(lean * k / h * 4), y - k, x + int(lean * k / h * 4) + 3 * d, y - k - 3, col(c))
for x, h, c, l in ((10, 18, 'coral', 0.5), (26, 13, 'rose', -0.8), (130, 20, 'coral', -0.4), (146, 14, 'pink', 0.7), (152, 10, 'rose', 0.2)):
    coral_branch(x, 92, h, c, l)
for x in range(60, 74, 2):                               # brain coral
    bg.ellipse(66, 92, 7, 4, col('amber')); bg.set(x, 91, col('clay'))
for cx in (100, 104, 109):                               # tube sponges
    bg.rect(cx, 80 + (cx % 3) * 2, cx + 2, 93, col('grape')); bg.set(cx + 1, 80 + (cx % 3) * 2, col('plum'))
bg.ellipse(50, 108, 6, 2, col('amber')); bg.ellipse(52, 107, 3, 1, col('yellow'))   # a pile of gold coins (the tint key)
for _ in range(40):                                      # specks in the water
    bg.set(R.randrange(W), R.randrange(88), col('mist', 120))

# -------------------------------------------------------------- brushes -----
def guide():
    g = Img(W, H); red = col('red', 200)
    for x in (W // 3, 2 * W // 3):
        for y in range(0, H, 2): g.set(x, y, red)
    for y in (H // 3, 2 * H // 3):
        for x in range(0, W, 2): g.set(x, y, red)
    for x in range(8, W - 8): g.set(x, 6, col('amber', 200)); g.set(x, H - 7, col('amber', 200))
    for y in range(6, H - 6): g.set(8, y, col('amber', 200)); g.set(W - 9, y, col('amber', 200))
    return [g]

def ray():
    r = Img(22, 90)
    for y in range(90):
        for x in range(22):
            cx = 11 + (y - 45) * 0.12
            d = abs(x - cx) / (6 + y * 0.06)
            if d < 1 and dith(x, y, 0.55 * (1 - d) * (1 - y / 110.0)):
                r.set(x, y, col('white', 70))
    return [r]

def seaweed(c1, c2, h=40):
    cels = []
    for k in range(4):                     # 4 sway poses (ping-pong)
        s = Img(12, h); bend = (k - 1.5) / 1.5
        for y in range(h):
            t = 1 - y / float(h - 1)
            x = 5 + bend * 3.5 * t * t + math.sin(y * 0.45) * 0.8
            s.set(x, y, col(c1)); s.set(x + 1, y, col(c1))
            if y % 6 == 2: s.line(x, y, x - 3, y - 2, col(c2))
            if y % 6 == 5: s.line(x + 1, y, x + 4, y - 2, col(c2))
        cels.append(s)
    return cels

def fish(body, fin, stripe):
    cels = []
    for k in range(4):
        f = Img(13, 8); w = (0, 1, 0, -1)[k]
        f.ellipse(5.5, 4, 5, 3, col(body))
        f.line(1, 4, 9, 4, col(stripe)) if stripe else None
        f.line(10, 4, 12, 1 + w, col(fin)); f.line(10, 4, 12, 7 + w, col(fin)); f.line(11, 3 + w, 11, 5 + w, col(fin))
        f.set(2, 3, col('white')); f.set(2, 3, col('ink')) if k == 3 else None
        f.set(5, 1, col(fin)); f.set(6, 1, col(fin))
        cels.append(flip_h(f))             # facing right
    return cels

def shark():
    cels = []
    for k in range(4):
        s = Img(44, 18); sw = (0, 2, 0, -2)[k]
        s.ellipse(20, 10, 17, 5, col('grey')); s.ellipse(21, 12, 14, 3, col('mist'))
        s.line(18, 5, 23, 0, col('slate')); s.line(23, 0, 25, 5, col('slate')); s.rect(19, 3, 23, 5, col('grey'))   # dorsal fin
        s.line(3, 10, 0, 4 + sw, col('slate')); s.line(3, 10, 0, 16 + sw, col('slate')); s.line(1, 6 + sw, 1, 14 + sw, col('grey'))
        s.line(18, 14, 14, 17, col('slate'))                                   # pectoral fin
        s.set(33, 8, col('ink')); s.line(31, 12, 36, 12, col('slate'))         # eye, mouth
        for g in (27, 29): s.line(g, 9, g, 11, col('slate'))                   # gills
        cels.append(s)
    return cels

def jelly():
    cels = []
    for k in range(4):
        j = Img(14, 20); sq = (0, 1, 2, 1)[k]
        j.ellipse(7, 4 + sq * 0.5, 6 - sq * 0.6, 4 - sq * 0.4, col('rose', 210))
        j.ellipse(7, 3, 3, 2, col('pink', 160))
        for t in range(4):
            x0 = 3 + t * 2.4
            for y in range(7, 19):
                j.set(x0 + math.sin(y * 0.6 + k * 1.2 + t) * 1.2, y, col('coral', 180))
        cels.append(j)
    return cels

def bubble():
    b = Img(5, 5); ring(b, 2.5, 2.5, 2, 'white'); b.set(1, 1, col('white')); return [b]

def chest():
    cels = []
    for k in range(4):                     # 0 shut .. 3 open with gold glowing
        c = Img(22, 18)
        c.rect(1, 9, 20, 17, col('wood')); c.rect(1, 9, 20, 10, col('bark')); c.rect(9, 11, 12, 14, col('amber'))
        for x in (1, 20): c.line(x, 9, x, 17, col('bark'))
        lift = k * 2
        if k == 0:
            c.rect(1, 4, 20, 8, col('wood')); c.rect(1, 4, 20, 4, col('bark'))
        else:
            c.rect(1, 8 - lift - 3, 20, 8 - lift, col('wood')); c.rect(1, 8 - lift - 3, 20, 8 - lift - 3, col('bark'))
            for x in range(3, 19):
                c.set(x, 8, col('yellow') if (x + k) % 3 else col('amber'))
            if k == 3:
                for x, y in ((5, 6), (11, 5), (16, 6)): c.set(x, y, col('white'))
        cels.append(c)
    return cels

def crab():
    cels = []
    for k in range(2):
        c = Img(14, 9)
        c.ellipse(7, 5, 5, 3, col('red')); c.ellipse(7, 4, 3, 1, col('coral'))
        c.set(5, 1, col('ink')); c.set(9, 1, col('ink')); c.line(5, 2, 5, 3, col('red')); c.line(9, 2, 9, 3, col('red'))
        c.disc(1.5, 3, 1.5, col('red')); c.disc(12.5, 3, 1.5, col('red'))     # claws
        for i, x in enumerate((3, 5, 9, 11)):
            c.line(x, 7, x + (1 if (i + k) % 2 else -1), 8, col('wine'))
        cels.append(c)
    return cels

def starfish():
    s = Img(11, 11)
    for a in range(5):
        ang = a * 2 * math.pi / 5 - math.pi / 2
        for r in range(6):
            s.set(5 + r * math.cos(ang), 5 + r * math.sin(ang), col('orange'))
            s.set(5 + r * math.cos(ang) + 0.6, 5 + r * math.sin(ang), col('orange'))
    s.disc(5.5, 5.5, 1.5, col('amber'))
    return [s]

S.brush(1, 'guide', guide(), 'the layout guide: thirds + the safe area (a REFERENCE layer: seen, not exported)')
S.brush(2, 'ray', ray(), 'a light ray: clip, OPACITY sine + SCALE X triangle')
S.brush(3, 'seaweed', seaweed('green', 'lime'), 'seaweed: ping-pong clip, ROTATE triangle about a PIVOT at its foot')
S.brush(4, 'fish', fish('orange', 'amber', 'white'), 'an orange fish: ONE source for the whole school (5 clips)')
S.brush(5, 'fishblue', fish('blue', 'cyan', None), 'a blue fish: the flipped school in act 3')
S.brush(6, 'shark', shark(), 'the shark: X keys ease in-out, ROTATE keys, a rumble with VOLUME + PAN lanes')
S.brush(7, 'jelly', jelly(), 'a jellyfish: Y keys rising, SCALE Y sine (the pulse)')
S.brush(8, 'bubble', bubble(), 'a bubble: Move Brush > Apply as Clip, a blub each time round')
S.brush(9, 'chest', chest(), 'the chest: mode Hold from frame 45, TINT toward gold, a creak when it starts')
S.brush(10, 'crab', crab(), 'a crab: X triangle (back and forth), a click on cel 1')
S.brush(11, 'starfish', starfish(), 'a starfish: drawn once, its cells linked over every frame')
S.brush(12, 'seaweed2', seaweed('pine', 'green', 30), 'darker seaweed for the back')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_GOLD=S.find(bg, E['amber'], 44, 105, 56, 110))

# ----------------------------------------------------------------- audio ----
A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'gentle underwater reef, slow dreamy arpeggios', 'opl', 6101, '--mood', 'serene', '--key', 'D minor', '--bpm', 80, '--seconds', 6)
bed = [(au.fit(au.load(music), T), 0, 0.7), (au._lp(au.noise(T, 61, 0.05), 0.04), 0, 0.35)]
au.mix(os.path.join(S.dir, 'reef-music.wav'), T, bed)
sfx = [(au.thud(55, 1.2), S.t(25), 0.5), (au.hiss(1.5, 62, 0.15), S.t(25), 0.6), (au.clink(3300), S.t(56), 0.4), (au.clink(3900), S.t(58), 0.35)]
au.mix(os.path.join(S.dir, 'reef-sfx.wav'), T, sfx)
# the clips' own sounds (the cues travel with the clips)
au.mix(os.path.join(S.dir, 'blub.wav'), 0.25, [(au._lp(au.tone(0.18, 300, 900, gain=0.6), 0.3), 0, 1.0)])
au.mix(os.path.join(S.dir, 'rumble.wav'), 1.6, [(au._lp(au.noise(1.6, 71, 0.02), 0.02), 0, 1.0), (au.tone(1.6, 48, 44, 'saw', gain=0.25), 0, 0.6)])
au.mix(os.path.join(S.dir, 'creak.wav'), 0.9, [(au.tone(0.8, 180, 120, 'saw', vib=0.08, gain=0.3), 0, 0.8), (au.clink(2400), 0.6, 0.5)])
au.mix(os.path.join(S.dir, 'click.wav'), 0.08, [(au.clink(5200), 0, 0.25)])
print('reef ok', S.dir)
