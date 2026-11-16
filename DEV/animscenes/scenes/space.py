"""space - orbit to landing in two shots (64 frames of 160x120 at 12 fps).

Shot 1 (frames 1-30), outside orbit: two star layers drifting at different speeds
(parallax), the planet growing as we close in, a satellite tumbling past, the ship
curving down toward the planet - smaller with distance (MOVE Z), nose tipping (TURN Z),
glowing orange with re-entry heat (TINT). A fade to black (OPACITY) cuts to
shot 2 (frames 31-64), the surface at dusk: the lander comes down out of the sky (SIZE
20 -> 100 %, ease out), a moon fades in, dust billows out as it touches down (SIZE +
OPACITY), the landing lights blink.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('space', sys.argv[1], frames=64, cols=8, fps=12)
W, H = S.w, S.h

# ------------------------------------------------------------ shot 1 bg -----
orbit = Img(W, H)
for y in range(H):
    for x in range(W):
        t = 0.25 * (1 + math.sin(x * 0.045 + y * 0.03) * math.sin(y * 0.07 - 0.5))
        orbit.set(x, y, col('night') if dith(x, y, t * 0.6) else col('ink'))
rnd = random.Random(2)
for _ in range(26):
    orbit.set(rnd.randrange(W), rnd.randrange(H), col(rnd.choice(['stone', 'slate'])))
# a far orange sun, top left (the re-entry tint key)
orbit.disc(14, 14, 7, col('orange')); orbit.disc(14, 14, 4, col('amber')); orbit.disc(14, 14, 2, col('yellow'))

# ------------------------------------------------------------ shot 2 bg -----
ground = Img(W, H)
vgrad(ground, 0, 0, W - 1, 78, ['grape', 'rose', 'coral', 'dusk'])
for x in range(W):  # far ridge, near ridge
    top = 66 - 8 * math.sin(x * 0.05 + 1) - 4 * math.sin(x * 0.13)
    for y in range(int(top), 82):
        ground.set(x, y, col('plum'))
    top2 = 76 - 5 * math.sin(x * 0.08 + 3) - 3 * math.sin(x * 0.21)
    for y in range(int(top2), 90):
        ground.set(x, y, col('wine') if dith(x, y, (y - top2) / 14.0) else col('plum'))
vgrad(ground, 0, 88, W - 1, H - 1, ['clay', 'rust', 'bark'])
for k in range(40):  # pebbles
    ground.set((k * 37) % W, 92 + (k * 13) % 27, col('wine'))
ground.rect(44, 95, 116, 98, col('stone')); ground.rect(44, 95, 116, 95, col('slate'))   # the pad
for x in range(46, 116, 10):
    ground.rect(x, 96, x + 4, 97, col('amber'))

# ------------------------------------------------------------- brushes ------
def stars(n, seed, big):
    cels = []
    pts = [(random.Random(seed + i).randrange(320), random.Random(seed * 7 + i).randrange(H)) for i in range(n)]
    for k in range(2):
        c = Img(320, H)
        for i, (x, y) in enumerate(pts):
            on = (i + k) % 5 != 0
            if big:
                c.set(x, y, col('white' if on else 'mist'))
                if on and i % 3 == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        c.set(x + dx, y + dy, col('grey'))
            else:
                c.set(x, y, col('mist' if on else 'slate'))
        cels.append(c)
    return cels


def planet():
    cels = []
    for k in range(4):
        c = Img(150, 100)
        cx, cy, r = 100, 100, 88
        for y in range(c.h):
            for x in range(c.w):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if d > r + 2:
                    continue
                if d > r:
                    c.set(x, y, col('cyan', 150)); continue
                u = (x - cx) / r; v = (y - cy) / r
                land = math.sin(u * 7 + k * 0.35) * math.sin(v * 5 + 1.3) + 0.4 * math.sin(u * 13 - k * 0.35 + v * 3)
                base = col('green') if land > 0.35 else (col('lime') if land > 0.25 else col('blue'))
                if land <= 0.25 and dith(x, y, 0.3):
                    base = col('navy')
                cloud = math.sin(u * 9 + v * 4 - k * 0.6) * math.sin(v * 11 + u * 2)
                if cloud > 0.55:
                    base = col('white') if cloud > 0.7 else col('mist')
                shade = (u * 0.7 - v * 0.7 + 0.3)        # lit from the top left
                if shade < -0.2 and dith(x, y, min(1.0, -shade - 0.2) * 1.5):
                    base = col('deep') if base[2] > base[1] else col('pine')
                if d > r - 2:
                    base = col('cyan')
                c.set(x, y, base)
        cels.append(c)
    return cels


SHIP = ['.....ww.......',
        '...wwmmww.....',
        'gggmmmmmmwwc..',
        'gmmmmmmmmmmccw',
        'gggmmmmmmwwc..',
        '...wwmmww.....',
        '.....ww.......']
ship_cmap = dict(w='white', m='mist', g='grey', c='cyan')


def ship():
    cels = []
    for k in range(2):
        c = Img(18, 7)
        c.blit(sprite(SHIP, ship_cmap), 4, 0)
        L = 3 + k
        for i in range(L):
            c.set(3 - i, 3, col('yellow' if i < 1 else 'orange'))
        c.set(3, 2, col('orange')); c.set(3, 4, col('orange'))
        cels.append(c)
    return cels


SAT = ['bb.......bb',
       'bbb.....bbb',
       'bbbgwwwgbbb',
       'bbbgwrwgbbb',
       'bbbgwwwgbbb',
       'bbb.....bbb',
       'bb.......bb']


def satellite():
    cels = []
    for k in range(2):
        cm = dict(b='navy' if k else 'blue', g='grey', w='mist', r='red' if k else 'wine')
        cels.append(sprite(SAT, cm))
    return cels


LANDER = ['......wwww......',
          '....wwmmmmww....',
          '...wmmcccc mw...'.replace(' ', 'm'),
          '..wmmmccccmmmw..',
          '.gmmmmmmmmmmmmg.',
          'gggggggggggggggg',
          '.ss..ss....ss..s'.replace('s', 'g'),
          '.g....g....g...g',
          'gg...gg....gg..g']


def lander(flame):
    cels = []
    for k in range(4):
        c = Img(20, 22)
        body = sprite(LANDER, dict(w='white', m='mist', c='cyan', g='slate', s='slate'))
        c.blit(body, 2, 0)
        lights = ['red', 'amber'] if k % 2 == 0 else ['wine', 'yellow']
        c.set(4, 4, col(lights[0])); c.set(15, 4, col(lights[1]))
        if flame:
            flame_(c, 10, 9, 10 + (k % 2) * 2, 5, [-0.8, 0.5, 0.9, -0.3][k], [0.5, -0.4, 0.6, -0.5][k])
        cels.append(c)
    return cels


def flame_(img, cx, top, length, w, sway, flick):  # a flame hanging DOWN from y = top
    tmp = Img(img.w, img.h)
    flame(tmp, cx, img.h - 1, length, w, sway, flick, FIRE)
    for y in range(length + 1):
        for x in range(img.w):
            p = tmp.get(x, img.h - 1 - length + y)
            if p:
                img.set(x, top + (length - y), p)


def dust():
    cels = []
    for k in range(4):
        c = Img(60, 18)
        for i in range(9):
            x = 30 + (i - 4) * (5 + k * 0.6)
            r = 3 + (4 - abs(i - 4)) * 0.8 + k * 0.4
            c.disc(x, 12 - (4 - abs(i - 4)) * 0.5, r, col('tan' if (i + k) % 3 else 'sand'))
            c.disc(x - r * 0.3, 11 - (4 - abs(i - 4)) * 0.5, r * 0.5, col('sand'))
        cels.append(c)
    return cels


def black():
    c = Img(W, H, col('ink'))
    return [c]


def moon():
    c = Img(15, 15)
    c.disc(7, 7, 7, col('sand')); c.disc(9, 6, 2, col('tan')); c.disc(4, 9, 1.5, col('tan')); c.disc(8, 11, 1, col('tan'))
    return [c]


def beacon():
    cels = []
    for k in range(4):
        c = Img(5, 5)
        if k < 2:
            c.disc(2.5, 2.5, 2.5 - k, col('red' if k == 0 else 'pink'))
            c.set(2, 2, col('white'))
        else:
            c.set(2, 2, col('wine'))
        cels.append(c)
    return cels


S.brush(1, 'stars-far', stars(70, 11, False), 'far star layer, 320 wide: Move Brush slowly left (parallax)')
S.brush(2, 'stars-near', stars(28, 23, True), 'near star layer, 320 wide: Move Brush quickly left (parallax)')
S.brush(3, 'planet', planet(), 'the planet, 4 cels of cloud drift: still path, SIZE 100 -> 125')
S.brush(4, 'ship', ship(), 'the ship, thruster flicker: DRAWN path, MOVE Z 0 -> 500, TURN Z 35, TINT to orange')
S.brush(5, 'satellite', satellite(), 'a satellite: straight path, TURN Z 540, TURN X 360')
S.brush(6, 'black', black(), 'a black frame: OPACITY 0 -> 100 / 100 -> 0 for the cut')
S.brush(7, 'lander', lander(True), 'the lander firing: SIZE 20 -> 100, ease out')
S.brush(8, 'lander-idle', lander(False), 'the lander parked, lights blinking: held in frames 55-64')
S.brush(9, 'dust', dust(), 'touchdown dust: SIZE 40 -> 230, OPACITY 100 -> 0')
S.brush(10, 'moon', moon(), 'a moon: OPACITY 0 -> 100 over the second shot')
S.brush(11, 'beacon', beacon(), 'a landing light, blinking')
print('\n'.join(S.write_pack()))
S.write_base_shots([(1, 30, orbit), (31, 64, ground)])
S.keys(KEY_ORANGE=S.find(orbit, E['orange'], 0, 0, 30, 30))

# --------------------------------------------------------------- audio ------
A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'space voyage, descending to a new planet', 'opl', 4401,
                    '--mood', 'wondrous', '--key', 'D major', '--bpm', 84, '--seconds', 6)
rumble = au.noise(T, 31, 0.01)
bed = [(au.fit(au.load(music), T), 0, 0.7),
       ([v * 4 * (1 if i < S.t(31) * au.RATE else 0.0) for i, v in enumerate(rumble)], 0, 0.5),
       ([v * (0 if i < S.t(31) * au.RATE else 1) for i, v in enumerate(au.wind(T, 3))], 0, 0.5)]
au.mix(os.path.join(S.dir, 'space-music.wav'), T, bed)
beep = au.soundmon(A, 'beep', 'satellite beep', 'chipfx', 45, '--fx-archetype', 'blip')
sweep = au.soundmon(A, 'sweep', 'whoosh cut', 'oplfx', 46, '--fx-archetype', 'sweepup')
chime = au.soundmon(A, 'chime', 'landing chime', 'chipfx', 47, '--fx-archetype', 'chime')
heat = au.hiss(S.t(31) - S.t(14), 5, 0.7)
roar = [v * (0.4 + 0.6 * i / (S.t(55) - S.t(31)) / au.RATE) for i, v in enumerate(au.noise(S.t(55) - S.t(31), 8, 0.12))]
sfx = [(beep, S.t(f), 0.5) for f in (3, 11, 19)]
sfx += [(heat, S.t(14), 1.0), (sweep, S.t(27), 0.8), ([v * 3 for v in roar], S.t(31), 1.0),
        (au.thud(55, 0.7), S.t(55), 1.2), (chime, S.t(57), 0.6), (chime, S.t(61), 0.5)]
au.mix(os.path.join(S.dir, 'space-sfx.wav'), T, sfx)
print('space ok', S.dir)
