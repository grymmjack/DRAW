"""carnival - a fairground from afternoon to lights-on (64 frames, 12 fps) - a PROJECT.

DAY 1-24: the Ferris wheel turns (ROTATE keys 0 > 360 over the loop: seamless), its four
gondolas ride a circle - each an X sine and a Y sine a quarter period apart, the four
clips a quarter loop apart (phases 0 / 16 / 32 / 48), all one source; three carousel
horses bob (Y sine, Copy / Paste Lanes, three phases) and circle (X sine); balloons drift
up (Y keys, X sine) - then Update Clip from AnimBrush turns every balloon of that source
blue at once (one source, three clips); a juggler juggles (ping-pong) and a mirrored one
(flip X, mode Reverse); the bunting flutters (ROTATE sine).
DUSK 25-44: the sky darkens (a full-frame dusk clip: OPACITY keys, TINT toward purple);
a balloon gets away and pops (mode Once, the pop a sound on its cel 3).
LIGHTS 45-64: two strings of bulbs switch on (OPACITY hold keys) and chase (OPACITY
square, half a period apart - pasted lanes, phase changed), a cheer when they start;
confetti falls (its cels + Y noise).
A layout guide is a reference layer; the ticket booth sign is drawn once, cells linked.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('carnival', sys.argv[1], frames=64, cols=8, fps=12)
W, H = S.w, S.h
R = random.Random(23)
WX, WY, WR = 52, 50, 30          # the wheel's hub and the gondolas' circle

bg = Img(W, H)
vgrad(bg, 0, 0, W - 1, 92, ['cyan', 'blue', 'mist', 'sand'])
for x in range(W):                                          # far hills
    for y in range(78 + int(4 * math.sin(x * 0.05 + 1)), 93):
        bg.set(x, y, col('green') if dith(x, y, 0.3) else col('lime'))
vgrad(bg, 0, 93, W - 1, H - 1, ['sand', 'tan'])
for y in range(96, H, 6):                                   # a path
    for x in range(0, W, 9): bg.rect(x + (y // 6) % 2 * 4, y, x + 3 + (y // 6) % 2 * 4, y + 1, col('clay'))
# the wheel's stand (the wheel itself is a clip)
bg.line(WX, WY, WX - 18, 96, col('slate')); bg.line(WX + 1, WY, WX - 17, 96, col('slate'))
bg.line(WX, WY, WX + 18, 96, col('slate')); bg.line(WX + 1, WY, WX + 19, 96, col('slate'))
# the carousel: canopy, poles, platform (the horses are clips)
bg.rect(98, 66, 156, 70, col('red'));
for x in range(98, 157, 6): bg.rect(x, 66, x + 2, 70, col('white'))
for x in range(98, 157, 4): bg.set(x, 71, col('amber'))
bg.line(97, 66, 127, 54, col('red')); bg.line(157, 66, 127, 54, col('red')); bg.disc(127, 53, 2, col('yellow'))
for x in (104, 118, 132, 146): bg.rect(x, 72, x, 90, col('amber'))
bg.rect(96, 91, 158, 95, col('wood')); bg.rect(96, 91, 158, 91, col('tan'))
# a ticket booth bottom left (its sign is linked cells)
bg.rect(4, 82, 26, 104, col('wine')); bg.rect(7, 88, 23, 96, col('ink')); bg.rect(2, 79, 28, 81, col('white'))
# a purple key for the dusk tint
bg.rect(0, 117, 2, 119, col('grape'))

def guide():
    g = Img(W, H)
    for a in range(0, 360, 6):
        g.set(WX + WR * math.cos(math.radians(a)), WY + WR * math.sin(math.radians(a)), col('red', 190))
    for x in range(0, W, 2): g.set(x, 95, col('amber', 190))
    g.disc(WX, WY, 1, col('yellow'))
    return [g]

def wheel():
    w = Img(70, 70); c = 35
    ring(w, c, c, WR + 1, 'white', 1.2); ring(w, c, c, WR - 3, 'mist', 1.0)
    for a in range(0, 360, 30):
        w.line(c, c, c + (WR + 1) * math.cos(math.radians(a)), c + (WR + 1) * math.sin(math.radians(a)), col('mist'))
    for a in range(0, 360, 45):
        w.disc(c + (WR + 1) * math.cos(math.radians(a)), c + (WR + 1) * math.sin(math.radians(a)), 1, col('amber'))
    w.disc(c, c, 3, col('red')); w.disc(c, c, 1, col('yellow'))
    return [w]

def gondola():
    g = Img(10, 12)
    g.line(5, 0, 5, 3, col('grey')); g.rect(1, 3, 8, 4, col('red')); g.rect(1, 5, 8, 10, col('yellow')); g.rect(2, 6, 7, 8, col('cyan', 180))
    g.rect(1, 11, 8, 11, col('red'))
    return [g]

def horse(body):
    cels = []
    for k in range(2):
        h = Img(18, 14)
        h.ellipse(9, 7, 6, 3, col(body)); h.disc(15, 4, 2, col(body)); h.line(14, 5, 12, 7, col(body))
        h.line(13, 2, 13, 4, col('wine'))                              # mane
        for x, d in ((5, -k), (8, k), (11, -k), (13, k)):
            h.line(x, 9, x + d, 13, col(body))
        h.line(9, 0, 9, 4, col('amber'))                               # the pole stub
        h.set(16, 4, col('ink')); h.line(3, 6, 1, 9, col('wine'))       # eye, tail
        cels.append(h)
    return cels

def balloon(c):
    b = Img(9, 20)
    b.ellipse(4.5, 5, 4, 5, col(c)); b.set(3, 2, col('white')); b.set(4, 10, col(c))
    for y in range(11, 20): b.set(4 + math.sin(y * 0.8) * 0.8, y, col('grey'))
    return [b]

def balloon_pop():
    cels = balloon('red') * 2
    p = Img(9, 20)
    for a in range(0, 360, 45):
        p.line(4.5 + 2 * math.cos(math.radians(a)), 5 + 2 * math.sin(math.radians(a)), 4.5 + 4.5 * math.cos(math.radians(a)), 5 + 4.5 * math.sin(math.radians(a)), col('red'))
    q = Img(9, 20)
    for a in range(0, 360, 60): q.set(4.5 + 5 * math.cos(math.radians(a)), 5 + 5 * math.sin(math.radians(a)), col('red'))
    return cels + [p, q]

def juggler():
    cels = []
    for k in range(6):
        j = Img(18, 26)
        j.disc(9, 4, 3, col('skin')); j.set(8, 3, col('ink')); j.set(10, 3, col('ink')); j.disc(9, 5, 1, col('red'))
        j.rect(6, 1, 12, 1, col('lime'))                                # hat brim
        j.rect(6, 8, 12, 16, col('grape')); j.rect(8, 8, 10, 16, col('yellow'))
        j.line(7, 17, 6, 25, col('navy')); j.line(11, 17, 12, 25, col('navy'))
        hand = (0, 1, 2, 1, 0, -1)[k]
        j.line(6, 9, 3, 12 - hand, col('skin')); j.line(12, 9, 15, 12 + hand, col('skin'))
        for i, c in enumerate(('red', 'cyan', 'yellow')):
            a = (k / 6.0 + i / 3.0) * 2 * math.pi
            j.disc(9 + 7 * math.cos(a), 6 - 5 * abs(math.sin(a)) - 1, 1, col(c))
        cels.append(j)
    return cels

def bunting():
    b = Img(64, 10)
    for x in range(64): b.set(x, 1 + int(2 * math.sin(x / 63.0 * math.pi)), col('ink'))
    for i, x in enumerate(range(2, 62, 6)):
        y = 2 + int(2 * math.sin(x / 63.0 * math.pi)); c = ('red', 'yellow', 'cyan', 'lime')[i % 4]
        for j in range(5): b.line(x + j * 0.4, y + j, x + 4 - j * 0.4, y + j, col(c))
    return [b]

def dusk():
    d = Img(W, H)
    for y in range(H):
        for x in range(W):
            d.set(x, y, col('grape', 120) if y < 80 else col('night', 90))
    return [d]

def bulbs():
    b = Img(70, 8)
    for x in range(70): b.set(x, 1 + int(3 * math.sin(x / 69.0 * math.pi)), col('ink'))
    for x in range(3, 70, 6):
        y = 2 + int(3 * math.sin(x / 69.0 * math.pi)); b.disc(x, y + 1, 1, col('yellow')); b.set(x, y + 1, col('white'))
    return [b]

def confetti():
    cels = []; rr = random.Random(5); bits = [(rr.randrange(W), rr.randrange(H), rr.choice(['red', 'yellow', 'cyan', 'lime', 'pink'])) for _ in range(70)]
    for k in range(4):
        c = Img(W, H)
        for x, y, cc in bits:
            yy = (y + k * 6) % H; c.set(x + (1 if (k + x) % 2 else 0), yy, col(cc)); c.set(x, yy + 1, col(cc))
        cels.append(c)
    return cels

def sign():
    s = Img(16, 6)
    font = {'T': ['111', '010', '010', '010', '010'], 'I': ['1', '1', '1', '1', '1'], 'C': ['11', '10', '10', '10', '11'],
            'K': ['101', '110', '100', '110', '101'], 'E': ['11', '10', '11', '10', '11'], 'S': ['11', '10', '11', '01', '11']}
    x = 0
    for ch in 'TICKETS':
        g = font[ch]
        for y, row in enumerate(g):
            for i, bit in enumerate(row):
                if bit == '1': s.set(x + i, y, col('yellow'))
        x += len(g[0]) + 0 if ch == 'I' else len(g[0])
        x += 0
    return [s]

S.brush(1, 'guide', guide(), 'the layout guide (the gondolas\' circle, the ground line): a REFERENCE layer')
S.brush(2, 'wheel', wheel(), 'the Ferris wheel: ROTATE keys 0 > 360 over the loop')
S.brush(3, 'gondola', gondola(), 'a gondola: X sine + Y sine a quarter apart = a circle; 4 clips, one source')
S.brush(4, 'horse', horse('white'), 'a carousel horse: Y sine bob + X sine (Copy / Paste Lanes)')
S.brush(5, 'horse2', horse('amber'), 'a gold carousel horse')
S.brush(6, 'balloon', balloon('red'), 'a red balloon: three clips of one source...')
S.brush(7, 'balloonblue', balloon('blue'), '...that Update Clip from AnimBrush turns blue')
S.brush(8, 'balloonpop', balloon_pop(), 'a balloon that pops: mode Once, a pop on cel 3')
S.brush(9, 'juggler', juggler(), 'a juggler: ping-pong; a second one flipped, mode Reverse')
S.brush(10, 'bunting', bunting(), 'bunting: ROTATE sine about the middle')
S.brush(11, 'dusk', dusk(), 'the dusk: a full-frame clip, OPACITY keys + TINT toward purple')
S.brush(12, 'bulbs', bulbs(), 'a string of bulbs: hold keys switch it on, OPACITY square chases')
S.brush(13, 'confetti', confetti(), 'confetti: its cels fall + Y noise')
S.brush(14, 'sign', sign(), 'TICKETS: drawn once, cells linked')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_PURPLE=S.find(bg, E['grape'], 0, 116, 3, 119), WX=WX, WY=WY, WR=WR)

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'cheerful fairground carousel waltz, calliope organ', 'chip', 6301, '--mood', 'playful', '--key', 'G major', '--bpm', 132, '--seconds', 6)
bed = [(au.fit(au.load(music), T), 0, 0.75), (au.chatter(T, 91), 0, 0.3)]
au.mix(os.path.join(S.dir, 'carnival-music.wav'), T, bed)
sfx = [(au.whistle(1.0, 1200, 2400, 92), S.t(3), 0.3), (au.clink(2800), S.t(45), 0.4)]
au.mix(os.path.join(S.dir, 'carnival-sfx.wav'), T, sfx)
au.mix(os.path.join(S.dir, 'pop.wav'), 0.2, [(au._hp(au.noise(0.12, 93, 0.9), 0.5), 0, 1.0)])
au.mix(os.path.join(S.dir, 'cheer.wav'), 1.6, [(au.chatter(1.6, 94), 0, 1.0), (au._hp(au.noise(1.6, 95, 0.5), 0.2), 0, 0.4)])
au.mix(os.path.join(S.dir, 'creak.wav'), 0.6, [(au.tone(0.5, 160, 110, 'saw', vib=0.1, gain=0.18), 0, 1.0)])
print('carnival ok', S.dir)
