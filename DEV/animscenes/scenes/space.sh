# space - orbit (frames 1-30), a fade to black, landing (31-64). See space.py.
if open_scene space 64 shots; then
    fg_key "$KEY_ORANGE"   # the re-entry tint (picked before anything covers the sun)
    # -- shot 1: outside orbit --
    layer stars-far; pick 1 2 stars-far
    mv 100 60 80 60 label="far stars drift left (slow parallax)" from=1 count=30
    layer stars-near; pick 2 2 stars-near
    mv 100 60 40 60 label="near stars drift left (fast parallax)" from=1 count=30
    layer planet; pick 3 4 planet
    mv 100 90 100 90 label="the planet grows as we close in (SIZE 100 > 125)" from=1 count=30 s1=125 every=2
    layer satellite; pick 5 2 satellite
    mv 10 22 150 40 label="a satellite tumbles past (TURN Z 540, TURN X 360)" from=1 count=30 tz=540 tx=360 every=2
    layer ship; pick 4 2 ship
    mv 0 0 0 0 label="the ship curves down: DRAWN path, Z 0 > 500, TURN Z 35, TINT to orange (ease in)" path=drawn \
        pts="8,50 24,44 40,41 56,41 70,43 84,48 96,54 106,61 114,68 120,74" from=1 count=30 z=500 tz=35 t1=70 ease=1
    # -- shot 2: the surface --
    layer moon; pick 10 1 moon
    mv 128 24 128 18 label="a moon rises and fades in (OPACITY 0 > 100)" from=31 count=34 o0=0 o1=100
    layer beacons; pick 11 4 beacon
    mv 46 96 46 96 label="landing light, left" from=31 count=34 every=2
    mv 114 96 114 96 label="landing light, right" from=31 count=34 every=2
    layer lander; pick 7 4 lander
    mv 80 4 80 84 label="the lander comes down (SIZE 20 > 100, ease out)" from=31 count=24 s0=20 ease=2
    layer parked; pick 8 4 lander-idle
    mv 80 84 80 84 label="parked, lights blinking" from=55 count=10 every=2
    layer dust; pick 9 4 dust
    mv 80 90 80 90 label="touchdown dust (SIZE 40 > 230, OPACITY 100 > 0, ease out)" from=50 count=15 s0=40 s1=230 o1=0 ease=2 every=2
    # -- the cut --
    layer cut; pick 6 1 black
    mv 80 60 80 60 label="fade to black (OPACITY 0 > 100, frames 24-30)" from=24 count=7 o0=0
    mv 80 60 80 60 label="fade up from black (OPACITY 100 > 0, frames 31-36)" from=31 count=6 o1=0
    sound_drop "$ANS_DIR/space-music.wav"
    sound_drop "$ANS_DIR/space-sfx.wav"
    finish_scene space
fi
