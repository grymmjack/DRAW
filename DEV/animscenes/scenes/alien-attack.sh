# alien-attack - an original fixed-shooter loop, 48 frames, seamless. See alien-attack.py.
# Timing: the tank is at x = 40 + 70 (f - 1) / 23 on frames 1-24 and 110 - 70 (f - 25) / 23
# on 25-48, so it is under x 83 at frames 15 and 34 - when it fires.
if open_scene alien-attack 48; then
    fg_white   # the blast flashes toward white
    layer formation; pick 1 2 formation
    mv 60 42 76 42 label="the formation marches right (next pose every 6 frames)" from=1 count=24 every=6
    mv 76 42 60 42 label="... and back left: the loop closes" from=25 count=24 every=6
    layer tank; pick 2 2 tank
    mv 40 106 110 106 label="the tank tracks right" from=1 count=24 every=3
    mv 110 106 40 106 label="... and back" from=25 count=24 every=3
    layer shots; pick 3 1 bolt
    mv 83 100 83 16 label="shot 1 (hits the mothership at frame 22)" from=15 count=8
    mv 83 100 83 2 label="shot 2 (a miss, through the formation)" from=34 count=11
    layer bombs; pick 4 2 bomb
    mv 0 0 0 0 label="bomb 1 zigzags down, flipping (DRAWN, TURN Y 720)" path=drawn \
        pts="110,58 114,66 106,74 114,82 106,90 114,98 110,106" from=4 count=11 ty=720
    mv 0 0 0 0 label="bomb 2 zigzags down, flipping (DRAWN, TURN Y 720)" path=drawn \
        pts="50,58 54,66 46,74 54,82 46,90 54,98 50,106" from=30 count=13 ty=720
    layer splashes; pick 6 4 blast
    mv 110 107 110 107 label="bomb 1 splash (SIZE 20 > 70, OPACITY > 0)" from=15 count=5 s0=20 s1=70 o1=0
    mv 50 107 50 107 label="bomb 2 splash" from=43 count=5 s0=20 s1=70 o1=0
    layer mothership; pick 5 4 mothership
    mv 4 14 83 14 label="the comet mothership crosses" from=12 count=11
    layer blast; pick 6 4 blast
    mv 83 14 83 14 label="the blast: SIZE 60 > 220, TINT to white, OPACITY > 0, TURN Z 90 (ease out)" from=23 count=8 s0=60 s1=220 o1=0 t1=100 tz=90 ease=2 every=2
    layer shards; pick 7 2 shard
    mv 83 14 60 44 label="shard 1 spins away (TURN Z 720, OPACITY > 0)" from=23 count=12 tz=720 o1=0 ease=2
    mv 83 14 108 42 label="shard 2" from=23 count=12 tz=-720 o1=0 ease=2
    mv 83 14 98 1 label="shard 3" from=23 count=10 tz=540 o1=0 ease=2
    layer score; pick 8 1 score
    mv 83 24 83 6 label="+500 floats up and fades (ease out)" from=23 count=14 o1=0 ease=2
    sound_drop "$ANS_DIR/alien-attack-music.wav"
    sound_drop "$ANS_DIR/alien-attack-sfx.wav"
    finish_scene alien-attack
fi
