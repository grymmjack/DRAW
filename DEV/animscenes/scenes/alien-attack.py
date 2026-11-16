"""alien-attack - an ORIGINAL fixed-shooter loop (48 frames of 160x120, 12 fps = 4 s,
seamless): the formation of eye-pods, jellies and spinners marches right and back,
the hover tank tracks under it, bombs zigzag down (TURN Y flips) and splash, a comet
mothership crosses and is shot down - the blast grows, flashes white and fades (SIZE,
TINT, OPACITY), shards spin away (TURN Z), "+500" floats up and fades.
Genre homage only: every sprite, name and the music are made here.
"""
import math, os, random, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('alien-attack', sys.argv[1], frames=48, cols=8, fps=12)
W, H = S.w, S.h

bg = Img(W, H, col('ink'))
rnd = random.Random(5)
for _ in range(40):
    bg.set(rnd.randrange(W), rnd.randrange(100), col(rnd.choice(['stone', 'slate', 'night'])))
for x in range(W):  # the ground
    bg.set(x, 110, col('lime')); bg.set(x, 111, col('green'))
    for y in range(112, H):
        bg.set(x, y, col('pine') if dith(x, y, 0.4) else col('deep'))
CRYSTAL = ['....pp....', '...pppp...', '..pprppp..', '.pppppppp.', 'pppp..pppp', 'ppp....ppp']
for cx in (26, 80, 134):  # crystal shields
    bg.blit(sprite(CRYSTAL, dict(p='rose', r='pink'), 2), cx - 10, 88)

EYEPOD = [['..c.c.c..', '.ccccccc.', 'ccwwkwwcc', 'ccwkkkwcc', '.ccccccc.', 'c.c...c.c'],
          ['.c..c..c.', '.ccccccc.', 'ccwwkwwcc', 'ccwwkkwcc', '.ccccccc.', '.c.c.c.c.']]
JELLY = [['..lllll..', '.llllllll', 'llkllkll.', 'lllllllll', 'l.l.l.l.l', '.l.l.l.l.'],
         ['..lllll..', 'llllllll.', '.llkllkll', 'lllllllll', '.l.l.l.l.', 'l.l.l.l.l']]
BEETLE = [['....o....', '...ooo...', '..oyoyo..', '.ooooooo.', 'o.ooooo.o', '...o.o...'],
          ['...o.o...', '...ooo...', '..oyoyo..', 'ooooooooo', '..ooooo..', '....o....']]
CM = dict(c='cyan', w='white', k='ink', l='lime', o='orange', y='yellow')


def formation():
    cels = []
    for k in range(2):
        c = Img(5 * 16, 3 * 12 - 6)
        for r, art in enumerate((EYEPOD, JELLY, BEETLE)):
            for i in range(5):
                c.blit(sprite(art[k], CM), i * 16 + 3, r * 12)
        cels.append(c)
    return cels


TANK = ['......w......', '.....www.....', '...lllllll...', '.lllllllllll.', 'sssssssssssss', 's.s.s.s.s.s.s']


def tank():
    return [sprite(TANK, dict(w='white', l='lime', s='slate')),
            sprite(TANK, dict(w='yellow', l='lime', s='grey'))]


def bolt():
    c = Img(3, 7)
    c.rect(1, 0, 1, 6, col('white')); c.set(0, 1, col('cyan')); c.set(2, 1, col('cyan')); c.set(1, 6, col('cyan'))
    return [c]


def bomb():
    cels = []
    for k in range(2):
        c = Img(5, 7)
        for y in range(7):
            c.set(2 + (1 if (y + k) % 4 < 2 else -1), y, col('pink' if y < 5 else 'red'))
        c.set(2, 6, col('yellow'))
        cels.append(c)
    return cels


def mothership():
    cels = []
    for k in range(4):
        c = Img(24, 10)
        c.ellipse(12, 6, 11, 3, col('grape')); c.ellipse(12, 3, 5, 3, col('rose')); c.ellipse(11, 2, 2, 1, col('coral'))
        for i in range(5):
            c.set(4 + i * 4, 7, col('yellow' if (i + k) % 4 == 0 else 'wine'))
        for t in range(3):  # the comet tail
            c.set(0 + t, 6 + (k + t) % 2, col('cyan' if t == 2 else 'blue'))
        cels.append(c)
    return cels


def blast():
    cels = []
    for k in range(4):
        c = Img(20, 20)
        r = 3 + k * 2.2
        for a in range(12):
            ang = a * math.pi / 6 + k * 0.3
            L = r + (2 if a % 2 else 0)
            for t in range(int(L)):
                c.set(10 + math.cos(ang) * t, 10 + math.sin(ang) * t, col('yellow' if t < L * 0.5 else 'orange'))
        c.disc(10, 10, max(1, 3 - k * 0.6), col('white'))
        cels.append(c)
    return cels


def shard():
    cels = []
    for k in range(2):
        c = Img(5, 5)
        c.line(0, 4, 4, 0, col('rose')); c.line(1, 4, 4, 1, col('coral' if k else 'grape'))
        cels.append(c)
    return cels


DIG = {'+': ['...', '.w.', 'www', '.w.', '...'], '5': ['www', 'w..', 'ww.', '..w', 'ww.'],
       '0': ['.w.', 'w.w', 'w.w', 'w.w', '.w.']}


def score():
    c = Img(17, 5)
    for i, ch in enumerate('+500'):
        c.blit(sprite(DIG[ch], dict(w='yellow')), i * 4 + (1 if i else 0), 0)
    return [c]


S.brush(1, 'formation', formation(), 'the marching formation, 2 poses: straight path right then back, next cel every 6')
S.brush(2, 'tank', tank(), 'the hover tank: straight path, ease none, tracks under the formation')
S.brush(3, 'bolt', bolt(), "the tank's shot: straight path up")
S.brush(4, 'bomb', bomb(), 'a zigzag bomb: DRAWN zigzag path down, TURN Y 720')
S.brush(5, 'mothership', mothership(), 'the comet mothership, lights chasing: straight path across')
S.brush(6, 'blast', blast(), 'the blast: SIZE 60 > 220, TINT to white, OPACITY 100 > 0, TURN Z 90')
S.brush(7, 'shard', shard(), 'debris: straight paths outward, TURN Z 720, OPACITY 100 > 0')
S.brush(8, 'score', score(), '"+500": up and fading out')
print('\n'.join(S.write_pack()))
S.write_base(bg)
S.keys()

A = os.path.join(S.dir, 'audio'); T = S.seconds()
music = au.soundmon(A, 'music', 'alien attack march, tense arcade', 'chip', 2201,
                    '--mood', 'tense', '--key', 'E minor', '--bpm', 120, '--seconds', 4)
au.mix(os.path.join(S.dir, 'alien-attack-music.wav'), T, [(au.fit(au.load(music), T), 0, 1.0)], fade=0)
zap = au.soundmon(A, 'zap', 'laser shot', 'chipfx', 2202, '--fx-archetype', 'blip')
boom = au.soundmon(A, 'boom', 'explosion', 'chipfx', 2203, '--fx-archetype', 'boom')
drop = au.soundmon(A, 'drop', 'bomb drop', 'chipfx', 2204, '--fx-archetype', 'errordown')
pop = au.soundmon(A, 'pop', 'small hit', 'chipfx', 2205, '--fx-archetype', 'hit')
coin = au.soundmon(A, 'coin', 'score', 'chipfx', 2206, '--fx-archetype', 'coin')
hum = au.tone(S.t(23) - S.t(12), 330, 340, 'square', vib=0.04, gain=0.12)
sfx = [(zap, S.t(15), 0.8), (zap, S.t(34), 0.8), (drop, S.t(4), 0.5), (drop, S.t(30), 0.5),
       (pop, S.t(15), 0.6), (pop, S.t(43), 0.6), (hum, S.t(12), 1.0), (boom, S.t(23), 1.0), (coin, S.t(24), 0.7)]
au.mix(os.path.join(S.dir, 'alien-attack-sfx.wav'), T, sfx, fade=0)
print('alien-attack ok', S.dir)
