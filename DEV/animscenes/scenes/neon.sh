# neon - a rainy night street in three acts (see neon.py). Bottom to top.
if pj_open neon 64; then
    # -- far rain at half opacity
    pick 3 3 rainfar
    clip_place 80 60 1 "rain far"
    lane OP; lkey 1 50

    # -- three lit windows: they cool toward TV-cyan (TINT keys), then go dark one by one
    #    (OPACITY keys with HOLD eases)
    fg_key "$KEY_CYAN"
    n=1
    for spec in "22 36 49" "46 50 53" "126 32 58"; do
        set -- $spec
        pick 7 1 window
        clip_place "$1" "$2" 1 "window $n"
        share window
        tint_fg
        lane TINT; keys 1:0:3 30:45
        lane OP; keys 1:100 $(( $3 - 1 )):100:4 "$3":0
        n=$(( n + 1 ))
    done

    # -- the signs: BAR blinks (OPACITY 55 + a square of 45), the arrow chases (its cels),
    #    HOTEL buzzes (OPACITY noise) and dies in act 3 (hold keys: flicker, flicker, off)
    pick 4 1 bar
    clip_place 21 27 1 "BAR sign"
    lane OP; lkey 1 55; mod SQUARE 45 8 0
    pick 5 3 arrow
    clip_place 48 49 1 "arrow sign"
    clip_every 2
    pick 6 1 hotel
    clip_place 132 23 1 "HOTEL sign"
    lane OP; mod NOISE 20 2 3; keys 1:85 44:85:4 46:15:4 48:80:4 50:0

    # -- a poster drawn once, its cells linked over the loop
    layer poster; lname poster
    stepset "animbrush step: cel follows the frame" 0
    pick 15 1 poster
    go 1; stamp 12 74
    link 1 64
    stepset "animbrush step: every frame at once" 2

    # -- puddles ripple (SCALE X sine)
    pick 8 4 puddle
    clip_place 40 100 1 "puddle A"
    share puddle
    clip_every 2; lane SX; mod SINE 12 12 0
    lanes_copy
    pick 8 4 puddle
    clip_place 112 113 1 "puddle B"
    share puddle
    clip_every 2; clip_cel 3; lanes_paste; lane SX; mod SINE 12 12 6

    # -- manhole steam: a Move Brush applied as a clip, then its lanes on three more clips
    layer steam; lname steam
    pick 9 1 steam
    go 1
    mv_clip 66 110 70 78 label="steam rises (Apply as Clip)" count=16 s0=50 s1=210 o0=90 o1=0 tz=45
    crd; lname "steam 1"; share steam; clip_out 16
    lanes_copy
    for at in 17 33 49; do
        pick 9 1 steam
        clip_place 66 110 "$at" "steam"
        share steam
        clip_out $(( at + 15 )); lanes_paste
    done

    # -- the walker crosses the whole loop (X keys), bobbing (Y square)
    pick 10 4 walker
    clip_place 20 78 1 "walker"
    clip_every 2
    lane X; keys 1:-40 64:150
    lane Y; mod SQUARE 1 4 0

    # -- the cat on the fence: ping-pong tail, a meow on cel 1
    pick 13 4 cat
    clip_place 140 66 1 "cat"
    clip_mode PING; clip_every 3
    go 1; clip_sound cel meow.wav

    # -- traffic: the red car left to right, its engine swells and pans with it
    pick 11 2 car
    clip_place 80 100 21 "red car"
    clip_out 36
    lane X; keys 21:-120:3 36:110
    clip_sound start engine.wav
    lane VOL; keys 21:30:1 28:100:2 36:20
    lane PAN; keys 21:-100 36:100
    lanes_copy
    # the blue car: flipped, the same lanes pasted and turned round
    pick 12 2 car2
    clip_place 80 112 33 "blue car"
    clip_out 48; clip_flip X
    lanes_paste
    lane X; keys 33:110:3 48:-120
    lane PAN; keys 33:100 48:-100
    clip_sound start engine.wav

    # -- near rain
    pick 2 3 rain
    clip_place 80 60 1 "rain near"

    # -- act 3: lightning - a flash clip (OPACITY hold keys), thunder when it starts
    pick 14 1 flash
    clip_place 80 60 45 "lightning"
    clip_out 48
    lane OP; keys 45:90:4 46:0:4 47:70:4 48:0
    clip_sound start thunder.wav

    # -- the perspective guide: a reference layer on top
    layer guide; lname "perspective guide"
    pick 1 1 guide
    go 1; stamp 80 60
    reflayer

    tag 1 20 RAIN; tag 21 44 TRAFFIC; tag 45 64 BLACKOUT
    note 1 "RAIN: the street hums, BAR blinks, HOTEL buzzes"
    note 21 "TRAFFIC: red car left to right"
    note 33 "blue car back the other way"
    note 45 "BLACKOUT: lightning - HOTEL dies, windows go dark"
    hold 45 3; hold 64 2

    go 1
    sound_drop "$ANS_DIR/neon-music.wav"
    sound_drop "$ANS_DIR/neon-sfx.wav"
    pj_finish neon
fi
