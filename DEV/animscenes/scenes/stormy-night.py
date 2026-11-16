"""stormy-night - the EXTRA CREDIT pack and its sampler scene (48 frames, 12 fps, loops).

A room on a stormy night: rain on the window (AnimBrush stamp), lightning twice (the bolt and
the window flash, OPACITY 100 > 0), a storm cloud drifting past; a TV flipping channels, a
radio playing (music notes float out on DRAWN waves, TURN Z, OPACITY > 0), a computer
scrolling, a snow globe; a dog asleep on the rug (Zs grow and fade: SIZE 60 > 150 +
OPACITY), a cat walking across and back, a flying eyeball monster swooping through
(DRAWN path, TURN Y flips), and a fuzzy monster that peeks up in front of us (SIZE 80 > 130,
a path up and back down).
The pack also has brushes the scene does not use: snow, sun, a bird and a fish.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('stormy-night', sys.argv[1], frames=48, cols=8, fps=12)
W, H, N = S.w, S.h, S.frames
rnd = random.Random(99)

GX0, GY0, GX1, GY1 = 10, 14, 46, 48     # the window glass
bg = Img(W, H)
for y in range(92):                       # striped wallpaper
    for x in range(W):
        bg.set(x, y, col('wine') if x % 10 in (0, 1) else (col('plum') if dith(x, y, 0.85) else col('wine')))
for y in range(92, H):                    # floorboards
    for x in range(W):
        c = col('wood') if dith(x, y, 0.4) else col('bark')
        if y % 7 == 0 or (x + (y // 7) * 23) % 41 == 0:
            c = col('bark')
        bg.set(x, y, c)
bg.rect(0, 90, W - 1, 92, col('bark'))   # skirting
# the window
bg.rect(GX0 - 3, GY0 - 3, GX1 + 3, GY1 + 3, col('wood')); bg.rect(GX0 - 4, GY1 + 3, GX1 + 4, GY1 + 5, col('tan'))
vgrad(bg, GX0, GY0, GX1, GY1, ['ink', 'night', 'deep'])
for x in range(GX0, GX1 + 1):            # the town's roofs out there
    h_ = 6 + (x * 7 % 5) + (4 if 20 < x < 30 else 0)
    bg.rect(x, GY1 - h_, x, GY1, col('ink'))
bg.rect(28, GY0, 28, GY1, col('wood')); bg.rect(GX0, 31, GX1, 31, col('wood'))   # glazing bars
# the TV cabinet + TV body
bg.rect(56, 74, 98, 92, col('bark')); bg.rect(56, 74, 98, 75, col('wood')); bg.rect(60, 80, 75, 89, col('wood')); bg.rect(79, 80, 94, 89, col('wood'))
# a shelf for the radio
bg.rect(104, 40, 152, 42, col('wood')); bg.rect(108, 43, 109, 47, col('bark')); bg.rect(147, 43, 148, 47, col('bark'))
# the desk
bg.rect(104, 70, 156, 73, col('wood')); bg.rect(106, 74, 109, 92, col('bark')); bg.rect(151, 74, 154, 92, col('bark'))
# the rug
for y in range(100, 113):
    for x in range(14, 72):
        if ((x - 43) / 29.0) ** 2 + ((y - 106) / 6.5) ** 2 <= 1:
            bg.set(x, y, col('red') if ((x + y) // 3) % 4 else col('amber'))
# a picture frame
bg.rect(70, 14, 92, 32, col('amber')); bg.rect(72, 16, 90, 30, col('pine')); bg.disc(81, 22, 4, col('yellow'))
bg.rect(130, 104, 134, 108, col('white')); bg.rect(130, 104, 134, 108, col('white'))   # a white sock: the lightning tint key


# ------------------------------------------------------------ brushes -------
def rain():
    cels = []
    gw, gh = GX1 - GX0 + 1, GY1 - GY0 + 1
    drops = [(rnd.randrange(gw), rnd.randrange(gh)) for _ in range(34)]
    for k in range(4):
        c = Img(gw, gh)
        for x, y in drops:
            yy = (y + k * gh // 4) % gh
            c.line(x, yy, x - 1, yy + 3, col('cyan', 170))
        cels.append(c)
    return cels


def snow(w=37, h=35, n=30, seed=4):
    r_ = random.Random(seed); flakes = [(r_.randrange(w), r_.randrange(h), r_.random()) for _ in range(n)]
    cels = []
    for k in range(4):
        c = Img(w, h)
        for x, y, ph in flakes:
            c.set(x + round(math.sin(ph * 6 + k * 1.6)), (y + k * h // 4) % h, col('white'))
        cels.append(c)
    return cels


def bolt():
    c = Img(16, 34)
    pts = [(9, 0), (6, 9), (10, 12), (4, 22), (8, 24), (2, 33)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        c.line(x0, y0, x1, y1, col('white')); c.line(x0 + 1, y0, x1 + 1, y1, col('yellow', 180))
    c.line(6, 9, 13, 18, col('mist'))
    return [c]


def flashpane():
    c = Img(GX1 - GX0 + 1, GY1 - GY0 + 1, col('mist', 200))
    return [c]


def stormcloud():
    cels = []
    for k in range(2):
        c = Img(24, 9)
        for dx, r in ((-7, 3), (-2, 4), (4, 4), (8, 3)):
            c.disc(12 + dx, 5, r, col('slate'))
        c.rect(3, 6, 21, 8, col('stone'))
        if k:
            c.set(10, 8, col('yellow')); c.set(11, 7, col('yellow'))
        cels.append(c)
    return cels


def sun():
    cels = []
    for k in range(4):
        c = Img(22, 22)
        for a in range(8):
            ang = a * math.pi / 4 + k * math.pi / 16
            c.line(11 + math.cos(ang) * 7, 11 + math.sin(ang) * 7, 11 + math.cos(ang) * 10, 11 + math.sin(ang) * 10, col('amber'))
        c.disc(10.5, 10.5, 6, col('yellow')); c.disc(9, 9, 2, col('white'))
        cels.append(c)
    return cels


def tv():
    cels = []
    for k in range(4):
        c = Img(30, 26)
        c.rect(0, 0, 29, 21, col('wood')); c.rect(0, 0, 29, 0, col('tan')); c.rect(2, 2, 21, 19, col('ink'))
        c.disc(25, 6, 1.6, col('amber')); c.disc(25, 12, 1.6, col('amber')); c.rect(24, 16, 27, 17, col('bark'))
        c.rect(5, 22, 6, 25, col('bark')); c.rect(23, 22, 24, 25, col('bark'))
        c.line(10, 0, 5, -6, col('grey')); c.line(18, 0, 23, -6, col('grey'))
        sx0, sy0 = 3, 3
        if k == 0:    # static
            for y in range(16):
                for x in range(18):
                    c.set(sx0 + x, sy0 + y, col(rnd.choice(['grey', 'mist', 'slate', 'white'])))
        elif k == 1:  # bars
            for i, bc in enumerate(['white', 'yellow', 'cyan', 'lime', 'pink', 'red', 'blue']):
                c.rect(sx0 + i * 18 // 7, sy0, sx0 + (i + 1) * 18 // 7 - 1, sy0 + 11, col(bc))
            c.rect(sx0, sy0 + 12, sx0 + 17, sy0 + 15, col('navy'))
        elif k == 2:  # a show: a sunset over the sea
            vgrad(c, sx0, sy0, sx0 + 17, sy0 + 9, ['pink', 'orange'])
            c.rect(sx0, sy0 + 10, sx0 + 17, sy0 + 15, col('blue')); c.disc(sx0 + 9, sy0 + 10, 3, col('yellow'))
        else:         # a face talking
            c.rect(sx0, sy0, sx0 + 17, sy0 + 15, col('cyan'))
            c.disc(sx0 + 9, sy0 + 8, 5, col('skin')); c.set(sx0 + 7, sy0 + 7, col('ink')); c.set(sx0 + 11, sy0 + 7, col('ink'))
            c.rect(sx0 + 8, sy0 + 10, sx0 + 10, sy0 + 11, col('red'))
        cels.append(c)
    return cels


def radio():
    cels = []
    for k in range(2):
        c = Img(24, 15)
        c.rect(0, 2, 23, 14, col('rust')); c.rect(0, 2, 23, 2, col('coral'))
        c.rect(14, 0, 14, 2, col('grey'))
        r = 4 + k
        c.disc(7, 8, r, col('bark')); c.disc(7, 8, 2, col('ink'))
        c.rect(15, 5, 21, 8, col('sand')); c.set(17 + k * 2, 6, col('red'))
        c.disc(16, 11, 1.2, col('amber')); c.disc(20, 11, 1.2, col('amber'))
        cels.append(c)
    return cels


def note():
    c = Img(7, 9)
    c.ellipse(2, 7, 2, 1.4, col('yellow')); c.rect(4, 0, 4, 7, col('yellow')); c.line(4, 0, 6, 2, col('yellow'))
    return [c]


def computer():
    cels = []
    lines = [rnd.randint(4, 15) for _ in range(12)]
    for k in range(4):
        c = Img(28, 24)
        c.rect(2, 0, 25, 16, col('sand')); c.rect(4, 2, 23, 13, col('ink'))
        for i in range(5):
            L = lines[(i + k) % 12]
            c.rect(5, 3 + i * 2, 5 + L, 3 + i * 2, col('lime'))
        if k % 2:
            c.rect(5 + lines[(4 + k) % 12] + 1, 11, 5 + lines[(4 + k) % 12] + 2, 11, col('white'))
        c.rect(10, 17, 17, 18, col('tan')); c.rect(0, 19, 27, 23, col('sand'))
        for x in range(2, 26, 3):
            c.set(x, 21, col('grey'))
        c.set(20, 15, col('lime' if k % 2 else 'pine'))
        cels.append(c)
    return cels


def globe():
    cels = []
    fl = snow(13, 11, 10, 7)
    for k in range(4):
        c = Img(15, 16)
        c.disc(7, 7, 6.5, col('cyan', 90)); c.rect(3, 13, 11, 15, col('wood'))
        c.rect(6, 7, 8, 11, col('pine')); c.set(7, 6, col('pine')); c.rect(7, 12, 7, 12, col('bark'))
        c.blit(fl[k], 1, 2)
        for y in range(16):
            for x in range(15):
                if (x - 7) ** 2 + (y - 7) ** 2 > 42 and y < 13:
                    c.p[y * c.w + x] = None
        cels.append(c)
    return cels


def dog():
    cels = []
    for k in range(2):
        c = Img(30, 13)
        c.ellipse(13, 8 - k * 0.5, 11, 4.5 + k * 0.5, col('tan')); c.ellipse(13, 9, 8, 2, col('sand'))
        c.disc(24, 8, 4, col('tan')); c.ellipse(27, 9, 2.5, 1.6, col('sand')); c.set(29, 9, col('ink'))
        c.ellipse(21, 6, 2, 3.5, col('bark'))   # ear
        c.line(23, 8, 25, 8, col('ink'))        # a closed eye
        c.line(2, 9, 0, 6, col('tan'))          # tail
        cels.append(c)
    return cels


def zzz():
    c = Img(7, 7)
    c.rect(0, 0, 6, 0, col('white')); c.line(6, 0, 0, 6, col('white')); c.rect(0, 6, 6, 6, col('white'))
    return [c]


def cat(left=True):
    cels = []
    for k in range(4):
        c = Img(20, 12)
        c.ellipse(9, 7, 6, 2.6, col('ink')); c.disc(15, 4, 2.6, col('ink'))
        c.set(14, 1, col('ink')); c.set(17, 1, col('ink')); c.set(14, 4, col('lime')); c.set(16, 4, col('lime'))
        for i, lx in enumerate((5, 7, 11, 13)):
            c.rect(lx + [0, 1, 0, -1][(k + i) % 4], 9, lx + [0, 1, 0, -1][(k + i) % 4], 11, col('ink'))
        c.line(3, 6, 0, 2 + (k % 2), col('ink')); c.set(0, 1 + (k % 2), col('ink'))
        cels.append(c if not left else flip_h(c))
    return cels


def eyeball():
    cels = []
    for k in range(4):
        c = Img(26, 14)
        c.disc(13, 7, 5, col('white')); c.disc(14, 7, 2.6, col('lime')); c.disc(14, 7, 1.2, col('ink'))
        c.line(9, 4, 11, 6, col('red')); c.line(16, 10, 17, 11, col('red'))
        lift = [0, 3, 5, 3][k]
        for s_ in (-1, 1):
            for i in range(7):
                c.set(13 + s_ * (6 + i), 6 - lift + abs(i - 3) * lift / 3.0, col('grape'))
                c.set(13 + s_ * (6 + i), 7 - lift + abs(i - 3) * lift / 3.0, col('plum'))
        cels.append(c)
    return cels


def fuzzy():
    cels = []
    for k in range(2):
        c = Img(34, 30)
        r_ = random.Random(5)
        for y in range(30):
            for x in range(34):
                d = ((x - 17) / 15.0) ** 2 + ((y - 18) / 14.0) ** 2
                if d <= 1 or (d <= 1.15 and r_.random() < 0.5):
                    c.set(x, y, col('green') if dith(x, y, 0.5) else col('lime'))
        for ex in (11, 23):
            if k == 0:
                c.disc(ex, 13, 4, col('white')); c.disc(ex + 1, 14, 2, col('ink'))
            else:
                c.rect(ex - 3, 13, ex + 3, 13, col('pine'))
        c.rect(12, 21, 22, 23, col('ink')); c.set(14, 21, col('white')); c.set(20, 21, col('white'))
        c.rect(8, 2, 9, 6, col('grape')); c.rect(25, 2, 26, 6, col('grape'))   # horns
        cels.append(c)
    return cels


def bird():
    cels = []
    for k in range(4):
        c = Img(12, 8)
        c.ellipse(6, 5, 3, 2, col('blue')); c.disc(9, 4, 1.6, col('blue')); c.set(11, 4, col('amber')); c.set(9, 3, col('white'))
        lift = [0, 2, 3, 2][k]
        c.line(4, 4, 7, 4 - lift, col('navy'))
        cels.append(c)
    return cels


def fish():
    cels = []
    for k in range(2):
        c = Img(12, 7)
        c.ellipse(5, 3, 4, 2.5, col('orange')); c.set(7, 2, col('ink'))
        c.line(1, 3, 0, 0 + k, col('amber')); c.line(1, 3, 0, 6 - k, col('amber')); c.set(4, 1, col('yellow'))
        cels.append(flip_h(c))
    return cels


S.brush(1, 'rain', rain(), 'weather: rain on the window pane - stamp')
S.brush(2, 'snow', snow(), 'weather: falling snow (not in the scene: try it on the window instead of rain)')
S.brush(3, 'lightning', bolt(), 'weather: a lightning bolt - OPACITY 100 > 0 in 3 frames')
S.brush(4, 'window-flash', flashpane(), 'weather: the pane lighting up - OPACITY 90 > 0')
S.brush(5, 'storm-cloud', stormcloud(), 'weather: a storm cloud with a spark - a slow path')
S.brush(6, 'sun', sun(), 'weather: a turning sun (not in the scene) - try TURN Z 90 for a loop')
S.brush(7, 'tv', tv(), 'a TV set flipping channels: static, bars, a sunset, a talker - stamp, next every 6')
S.brush(8, 'radio', radio(), 'a radio, the speaker pulsing - stamp')
S.brush(9, 'note', note(), 'a music note: DRAWN wavy path up, TURN Z, OPACITY > 0')
S.brush(10, 'computer', computer(), 'a computer, text scrolling - stamp')
S.brush(11, 'snow-globe', globe(), 'a snow globe - stamp')
S.brush(12, 'dog-asleep', dog(), 'a dog asleep, breathing - stamp, next every 6')
S.brush(13, 'zzz', zzz(), 'a Z: up and away, SIZE 60 > 150, OPACITY > 0')
S.brush(14, 'cat-left', cat(True), 'a cat walking left - straight path')
S.brush(15, 'cat-right', cat(False), 'a cat walking right - straight path')
S.brush(16, 'eyeball', eyeball(), 'a flying eyeball monster: DRAWN swoop, TURN Y')
S.brush(17, 'fuzzy', fuzzy(), 'a fuzzy monster, blinking: peeks up in front, SIZE 80 > 130')
S.brush(18, 'bird', bird(), 'a bird flapping (not in the scene)')
S.brush(19, 'fish', fish(), 'a fish (not in the scene) - try a DRAWN loop in a bowl')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys(KEY_WHITE=S.find(bg, E['white'], 128, 102, 136, 110))

GCX, GCY = (GX0 + GX1) // 2, (GY0 + GY1) // 2
swoop = []
for i in range(17):          # the eyeball's swoop: in from the left, a dip, out at the top right
    t = i / 16.0
    swoop.append((round(4 + 150 * t), round(30 + 34 * math.sin(t * math.pi) - 18 * t)))
waves = lambda x0, y0, sgn: ' '.join('%d,%d' % (round(x0 + sgn * 3 * i), round(y0 - 4 * i + 3 * math.sin(i * 1.3))) for i in range(9))
mv = ['layer weather; pick 1 4 rain', 'stamp %d %d 0' % (GCX, GCY),
      'layer room; pick 7 4 tv', 'stamp 77 63 0',
      'pick 8 2 radio', 'stamp 120 32 0',
      'pick 10 4 computer', 'stamp 140 58 0',
      'pick 11 4 snow-globe', 'stamp 116 62 1',
      'pick 12 2 dog-asleep', 'stamp 42 103 0',
      'pick 5 2 storm-cloud',
      'mv 22 20 34 21 label="a storm cloud drifts across the window" from=1 count=24 every=6',
      'mv 34 21 22 20 label="... and back" from=25 count=24 every=6',
      'fg_white', 'pick 4 1 window-flash',
      'mv %d %d %d %d label="lightning: the pane flashes (OPACITY 90 > 0, ease out)" from=10 count=4 o0=90 o1=0 ease=2' % (GCX, GCY, GCX, GCY),
      'mv %d %d %d %d label="... and again" from=31 count=4 o0=90 o1=0 ease=2' % (GCX, GCY, GCX, GCY),
      'pick 3 1 lightning',
      'mv 20 31 20 31 label="the bolt (OPACITY 100 > 0)" from=10 count=3 o1=0',
      'mv 36 31 36 31 label="another bolt (TURN Y 180 flips it)" from=31 count=3 o1=0 ty=180',
      'layer notes; pick 9 1 note',
      'mv 0 0 0 0 label="a note floats out of the radio (DRAWN, TURN Z 30, OPACITY > 0)" path=drawn pts="%s" from=1 count=16 tz=30 o1=0' % waves(110, 28, -1),
      'mv 0 0 0 0 label="another" path=drawn pts="%s" from=17 count=16 tz=-30 o1=0' % waves(112, 28, -1),
      'mv 0 0 0 0 label="and another" path=drawn pts="%s" from=33 count=16 tz=30 o1=0' % waves(108, 28, -1),
      'layer zzz; pick 13 1 zzz',
      'mv 54 96 66 80 label="a Z drifts up from the dog (SIZE 60 > 150, OPACITY > 0)" from=1 count=16 s0=60 s1=150 o1=0',
      'mv 54 96 66 80 label="Z" from=17 count=16 s0=60 s1=150 o1=0',
      'mv 54 96 66 80 label="Z" from=33 count=16 s0=60 s1=150 o1=0',
      'layer cat; pick 14 4 cat-left',
      'mv 150 112 96 112 label="the cat walks left" from=1 count=24',
      'pick 15 4 cat-right',
      'mv 96 112 150 112 label="... and back right" from=25 count=24',
      'layer eyeball; pick 16 4 eyeball',
      'mv 0 0 0 0 label="the eyeball monster swoops through (DRAWN, TURN Y 360)" path=drawn pts="%s" from=14 count=17 ty=360' % ' '.join('%d,%d' % p for p in swoop),
      'layer fuzzy; pick 17 2 fuzzy',
      'mv 24 119 24 104 label="the fuzzy monster peeks up at us (SIZE 80 > 130, ease out)" from=34 count=8 s0=80 s1=130 ease=2 every=4',
      'mv 24 104 24 119 label="... and ducks down (SIZE 130 > 80, ease in)" from=42 count=7 s0=130 s1=80 ease=1 every=4']
open(os.path.join(S.dir, 'moves.sh'), 'w').write('\n'.join(mv) + '\n')

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'old radio tune, cosy jazz', 'opl', 9901, '--mood', 'serene', '--key', 'Eb major', '--bpm', 100, '--seconds', 4)
radio_ = au._hp(au._lp(au.fit(au.load(music), T), 0.35), 0.05)   # thin it out: a little speaker
rain_ = au._lp(au.noise(T, 91, 0.6), 0.3)
au.mix(os.path.join(S.dir, 'stormy-night-music.wav'), T, [(radio_, 0, 0.55), (rain_, 0, 0.35)])
thunder = au.soundmon(A, 'thunder', 'thunder clap', 'oplfx', 9902, '--fx-archetype', 'crash')
growl = au.soundmon(A, 'growl', 'little monster growl', 'chipfx', 9903, '--fx-archetype', 'growl')
whoosh = au.soundmon(A, 'whoosh', 'eyeball swoop', 'chipfx', 9904, '--fx-archetype', 'whoosh')
snore = au._lp(au.noise(1.0, 92, 0.4), 0.08)
sfx = [(thunder, S.t(10), 1.0), (thunder, S.t(31), 0.9), (whoosh, S.t(18), 0.6), (growl, S.t(36), 0.7),
       (snore, S.t(2), 0.5), (snore, S.t(18), 0.5), (snore, S.t(34), 0.5)]
au.mix(os.path.join(S.dir, 'stormy-night-sfx.wav'), T, sfx)
print('stormy-night ok', S.dir)
