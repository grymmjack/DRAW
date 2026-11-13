# reef - a coral reef in three acts (see reef.py). Layers are built bottom to top: a
# placed clip goes on a new layer above the current one.
if pj_open reef 64; then
    # -- light rays: two clips of one source, OPACITY sine (phases apart), SCALE X triangle
    pick 2 1 ray
    clip_place 52 46 1 "ray A"
    share ray
    lane OP; mod SINE 35 32 0
    lane SX; mod TRI 15 48 0
    lanes_copy
    pick 2 1 ray
    clip_place 112 46 1 "ray B"
    share ray
    lanes_paste
    lane OP; mod SINE 35 32 16

    # -- back kelp: ping-pong cels, ROTATE triangle about a pivot at the foot (PIVOT Y +15)
    pick 12 4 seaweed2
    clip_place 42 78 1 "kelp back A"
    share kelpback
    clip_mode PING; clip_every 3
    lane ROT; mod TRI 5 36 0
    lane PVY; lkey 1 15
    lanes_copy
    pick 12 4 seaweed2
    clip_place 122 77 1 "kelp back B"
    share kelpback
    clip_mode PING; clip_every 3; clip_cel 3
    lanes_paste
    lane ROT; mod TRI 5 36 12

    # -- a starfish drawn once on frame 1, its cells linked over every frame
    layer starfish; lname starfish
    stepset "animbrush step: cel follows the frame" 0
    pick 11 1 starfish
    go 1; stamp 92 104
    link 1 64
    stepset "animbrush step: every frame at once" 2

    # -- the school: five clips of ONE source; X keys drift then dart (ease in), Y sine at
    #    five phases + a scatter key on frame 32
    pick 4 4 fish
    clip_place 40 40 1 "fish 1"
    share fish
    clip_every 2
    lane X; keys 1:-60 24:30:1 32:190
    lane Y; mod SINE 3 16 0; keys 1:0 24:0:2 32:-25
    lanes_copy
    n=2
    for spec in "28 52 3 20" "52 60 6 -10" "22 33 9 -35" "36 68 12 30"; do
        set -- $spec
        pick 4 4 fish
        clip_place "$1" "$2" 1 "fish $n"
        share fish
        clip_every 2; clip_cel $(( n % 4 + 1 ))
        lanes_paste
        lane Y; mod SINE 3 16 "$3"; lkey 32 "$4"
        n=$(( n + 1 ))
    done

    # -- the jellyfish rises the whole loop (ease in-out), pulses (SCALE Y sine), drifts (X
    #    sine), 80% opaque; a soft blub each time its cels start over, quietened by VOLUME
    pick 7 4 jelly
    clip_place 130 70 1 "jellyfish"
    clip_every 3
    lane Y; keys 1:0:3 64:-58
    lane SY; mod SINE 12 12 0
    lane X; mod SINE 4 32 0
    lane OP; lkey 1 80
    clip_sound loop blub.wav
    lane VOL; lkey 1 35

    # -- the shark: frames 25-44, X keys ease in-out, a slight ROTATE, a Y sine; its rumble
    #    starts with the clip, swells (VOLUME keys) and pans left to right (PAN keys)
    pick 6 4 shark
    clip_place 80 30 25 "shark"
    clip_out 44; clip_every 2
    lane X; keys 25:-110:3 44:125
    lane ROT; keys 25:-4:3 34:3:3 44:-2
    lane Y; mod SINE 3 20 0
    clip_sound start rumble.wav
    lane VOL; keys 25:20:1 34:100:2 44:10
    lane PAN; keys 25:-100 44:100

    # -- act 3: the crab scuttles (X triangle), a click on its cel 1
    pick 10 2 crab
    clip_place 70 103 45 "crab"
    clip_every 2
    lane X; mod TRI 18 24 0
    go 45; clip_sound cel click.wav

    # -- the chest opens on 45 and stays open (Hold), creaks, glows toward gold (TINT keys)
    pick 9 4 chest
    clip_place 112 100 45 "chest"
    clip_mode HOLD; clip_every 3
    clip_sound start creak.wav
    fg_key "$KEY_GOLD"; tint_fg
    lane TINT; keys 45:0 54:70:2 64:30

    # -- a blue school swims back in from the right, flipped
    pick 5 4 fishblue
    clip_place 132 46 45 "blue 1"
    share blue
    clip_flip X; clip_every 2
    lane X; keys 45:70:2 64:-80
    lane Y; mod SINE 2 16 0
    lanes_copy
    for spec in "146 56 5" "140 37 10"; do
        set -- $spec
        pick 5 4 fishblue
        clip_place "$1" "$2" 45 "blue fish"
        share blue
        clip_flip X; clip_every 2
        lanes_paste
        lane Y; mod SINE 2 16 "$3"
    done

    # -- bubbles: a Move Brush applied as a clip (straight up, growing, fading), then the
    #    same lanes on two more clips of the same source; the source's blub plays as each starts
    layer bubbles; lname bubbles
    pick 8 1 bubble
    go 1
    mv_clip 104 108 110 20 label="a bubble rises (Apply as Clip)" count=24 s0=60 s1=170 o0=100 o1=0
    crd; lname "bubble 1"; share bubble; clip_out 24
    clip_sound start blub.wav
    lanes_copy
    for at in 22 43; do
        pick 8 1 bubble
        clip_place 104 108 "$at" "bubble"
        share bubble
        clip_out $(( at + 23 > 64 ? 64 : at + 23 ))
        lanes_paste   # the blub is on the shared source: every bubble blubs when it starts
    done

    # -- front kelp, taller and faster
    for spec in "12 76 0" "150 74 9"; do
        set -- $spec
        pick 3 4 seaweed
        clip_place "$1" "$2" 1 "kelp front"
        share kelpfront
        clip_mode PING; clip_every 2
        lane ROT; mod TRI 7 30 "$3"
        lane PVY; lkey 1 20
    done

    # -- the layout guide on top: a reference layer (seen while you work, never exported)
    layer guide; lname "layout guide"
    pick 1 1 guide
    go 1; stamp 80 60
    reflayer

    # -- the acts, the director's notes, two holds
    tag 1 24 CALM; tag 25 44 SHARK; tag 45 64 TREASURE
    note 1 "CALM: rays shimmer, the school drifts right"
    note 25 "SHARK: in from the left - the fish dart"
    note 45 "TREASURE: the crab finds the chest"
    note 64 "loops back to CALM"
    hold 24 3; hold 44 2

    go 1
    sound_drop "$ANS_DIR/reef-music.wav"
    sound_drop "$ANS_DIR/reef-sfx.wav"
    pj_finish reef
fi
