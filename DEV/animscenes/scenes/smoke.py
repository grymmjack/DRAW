"""smoke - the pipeline's own check: every Move Brush value + the soundtrack (not shipped)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from kit import *
import audio as au

S = Scene('smoke', sys.argv[1], frames=24, cols=6)
bg = Img(S.w, S.h)
vgrad(bg, 0, 0, S.w - 1, S.h - 1, ['ink', 'night', 'stone'])
bg.rect(0, 0, 3, 3, col('red'))          # a tint key at (1,1)
star = []
for k in range(4):
    c = Img(9, 9)
    c.rect(3, 0, 5, 8, col('yellow')); c.rect(0, 3, 8, 5, col('yellow'))
    c.rect(4, 1 + k % 2, 4, 7 - k % 2, col('white'))
    star.append(c)
S.brush(1, 'star', star, 'Move Brush test')
S.write_pack(); S.write_base(bg)
open(os.path.join(S.dir, 'size.txt'), 'w').write('%d %d\n' % (S.w, S.h))
A = os.path.join(S.dir, 'audio')
music = au.soundmon(A, 'music', 'test tune', 'chip', 101, '--mood', 'playful', '--key', 'C major', '--bpm', 120, '--seconds', 2)
zap = au.soundmon(A, 'zap', 'zap', 'chipfx', 7, '--fx-archetype', 'coin')
au.mix(os.path.join(S.dir, 'smoke-music.wav'), S.seconds(), [(au.fit(au.load(music), S.seconds()), 0, 1.0)])
au.mix(os.path.join(S.dir, 'smoke-sfx.wav'), S.seconds(), [(zap, S.t(1), 1), (zap, S.t(12), 1), (au.thud(), S.t(20), 1)])
print('smoke ok', S.dir)
