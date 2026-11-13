# carnival - a fairground from afternoon to lights-on (see carnival.py). Bottom to top.
if pj_open carnival 64; then
    # -- the wheel: ROTATE saw (amount 180, period 64 = one turn a loop, seamless); a creak
    #    when it starts
    pick 2 1 wheel
    clip_place "$WX" "$WY" 1 "ferris wheel"
    lane ROT; mod SAW 180 64 0
    clip_sound start creak.wav

    # -- four gondolas on the circle: X sine + Y sine a quarter period (16) apart, one source,
    #    the four clips a quarter loop apart. X is half a period on (= -sine), so they go round
    #    clockwise like the wheel (ROTATE + is clockwise on screen, the saw ramps up)
    pick 3 1 gondola
    clip_place "$WX" $(( WY + 6 )) 1 "gondola 1"
    share gondola
    lane X; mod SINE "$WR" 64 32
    lane Y; mod SINE "$WR" 64 16
    lanes_copy
    for p in 16 32 48; do
        pick 3 1 gondola
        clip_place "$WX" $(( WY + 6 )) 1 "gondola $(( p / 16 + 1 ))"
        share gondola
        lanes_paste
        lane X; mod SINE "$WR" 64 $(( (p + 32) % 64 ))
        lane Y; mod SINE "$WR" 64 $(( (p + 16) % 64 ))
    done

    # -- bunting flutters (ROTATE sine)
    pick 10 1 bunting
    clip_place 128 40 1 "bunting"
    lane ROT; mod SINE 4 24 0

    # -- three carousel horses: bob (Y sine) and circle (X sine); lanes copied, phases changed
    pick 4 2 horse
    clip_place 111 80 1 "horse 1"
    clip_every 4
    lane Y; mod SINE 3 16 0
    lane X; mod SINE 12 48 0
    lanes_copy
    n=2
    for spec in "5 128 82 5 16" "4 145 79 10 32"; do
        set -- $spec
        pick "$1" 2 horse
        clip_place "$2" "$3" 1 "horse $n"
        clip_every 4; clip_cel 2
        lanes_paste
        lane Y; mod SINE 3 16 "$4"
        lane X; mod SINE 12 48 "$5"
        n=$(( n + 1 ))
    done

    # -- TICKETS: drawn once on frame 1, cells linked over the loop
    layer sign; lname "tickets sign"
    stepset "animbrush step: cel follows the frame" 0
    pick 14 1 sign
    go 1; stamp 15 92
    link 1 64
    stepset "animbrush step: every frame at once" 2

    # -- three red balloons of ONE source bob on their strings; then Update Clip from
    #    AnimBrush swaps the source's cels: all three turn blue in one step
    n=1
    for spec in "26 66 0" "36 62 8" "66 78 16"; do
        set -- $spec
        pick 6 1 balloon
        clip_place "$1" "$2" 1 "balloon $n"
        share balloon
        lane Y; mod SINE 2 24 "$3"
        lane X; mod SINE 2 32 "$3"
        n=$(( n + 1 ))
    done
    pick 7 1 balloonblue
    clip_update_ab

    # -- the one that gets away (dusk): rises, then pops - mode Once, a pop on cel 3
    pick 8 4 balloonpop
    clip_place 84 70 25 "runaway balloon"
    clip_mode ONCE; clip_every 6
    lane Y; keys 25:0:1 37:-38
    lane X; mod SINE 3 12 0
    go 37; clip_sound cel pop.wav

    # -- jugglers: one ping-pong, one flipped and reversed
    pick 9 6 juggler
    clip_place 78 92 1 "juggler"
    share juggler
    clip_mode PING; clip_every 2
    pick 9 6 juggler
    clip_place 60 99 1 "juggler, mirrored"
    share juggler
    clip_flip X; clip_mode REV; clip_every 2

    # -- dusk: a full-frame clip, tinted toward purple, OPACITY keys (it falls from 25)
    fg_key "$KEY_PURPLE"
    pick 11 1 dusk
    clip_place 80 60 1 "dusk"
    tint_fg
    lane TINT; lkey 1 50
    lane OP; keys 1:0 25:0:3 44:85 64:95

    # -- the lights: two strings switch on at 45 (hold keys), chase (OPACITY square, half a
    #    period apart); a cheer when the first starts
    pick 12 1 bulbs
    clip_place 80 6 45 "lights A"
    lane OP; keys 45:0:4 47:100; mod SQUARE 40 4 0
    clip_sound start cheer.wav
    lanes_copy
    pick 12 1 bulbs
    clip_place 127 60 45 "lights B"
    lanes_paste
    lane OP; mod SQUARE 40 4 2

    # -- confetti from 45: its cels fall, Y noise jitters it
    pick 13 4 confetti
    clip_place 80 60 45 "confetti"
    clip_every 2
    lane Y; mod NOISE 2 3 5

    # -- the layout guide: a reference layer on top
    layer guide; lname "layout guide"
    pick 1 1 guide
    go 1; stamp 80 60
    reflayer

    tag 1 24 DAY; tag 25 44 DUSK; tag 45 64 LIGHTS
    note 1 "DAY: the wheel turns, the gondolas ride its circle"
    note 25 "DUSK: the sky falls purple, a balloon gets away"
    note 37 "pop!"
    note 45 "LIGHTS: the bulbs come on, confetti"
    hold 44 2; hold 45 2

    go 1
    sound_drop "$ANS_DIR/carnival-music.wav"
    sound_drop "$ANS_DIR/carnival-sfx.wav"
    pj_finish carnival
fi
