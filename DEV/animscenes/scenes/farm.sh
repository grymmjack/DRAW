# farm - a day on the farm, dawn to night (see farm.py). Bottom to top.
if pj_open farm 64; then
    # -- the sun: an arc of X / Y keys (ease out up, ease in down), cels every 4; tinted red
    #    at sunrise and sunset (TINT keys); gone after 48
    fg_key "$KEY_RED"
    pick 2 2 sun
    clip_place 80 60 1 "sun"
    clip_out 48; clip_every 4
    lane X; keys 1:-70 48:70
    lane Y; keys 1:35:2 24:-42:1 48:35
    tint_fg
    lane TINT; keys 1:85:2 12:0 36:0:1 48:90

    # -- the far windmill: ROTATE saw (45 degrees over 16 frames: seamless for 4 blades),
    #    SCALE 70%... then BAKED to pixels (the clip becomes an ordinary layer)
    pick 8 1 blades2
    clip_place "$M2X" "$M2Y" 1 "far windmill"
    lane SX; lkey 1 70
    lane SY; lkey 1 70
    lane ROT; mod SAW 45 16 0
    clip_bake; lname "far windmill (baked)"

    # -- the near windmill: ROTATE keys, 354 degrees over the loop (4 blades: seamless)
    pick 7 1 blades
    clip_place "$M1X" "$M1Y" 1 "windmill"
    lane ROT; keys 1:0 64:354

    # -- clouds drift (X keys, ease in-out) and breathe (SCALE X sine); lanes copied
    pick 9 1 cloud
    clip_place 40 16 1 "cloud 1"
    share cloud
    lane X; keys 1:-20:3 32:40:3 64:-20
    lane SX; mod SINE 8 32 0
    lanes_copy
    pick 9 1 cloud
    clip_place 112 28 1 "cloud 2"
    share cloud
    lanes_paste
    lane SX; mod SINE 8 32 16

    # -- the tractor (NOON): X keys across, its engine starts with the clip, swells (VOLUME
    #    keys) and pans (PAN keys); a bump keyed by nudging the clip with Ctrl+arrows
    pick 12 2 tractor
    clip_place 80 86 17 "tractor"
    clip_out 40; clip_every 2
    lane X; keys 17:-100:2 40:100
    lane Y; keys 17:0 25:0
    clip_sound start putt.wav
    lane VOL; keys 17:30 28:100 40:20
    lane PAN; keys 17:-100 40:100
    nudge 27 0 -3
    nudge 29 0 3

    # -- the sheep: drawn as four frames (cel k on frame k), then Make Clip from Selected
    #    Frames turns them into a clip; it hops along (X sine)
    layer sheep; lname "sheep drawing"
    stepset "animbrush step: cel follows the frame" 0
    pick 10 4 sheep
    for f in 1 2 3 4; do go "$f"; stamp 40 106; done
    stepset "animbrush step: every frame at once" 2
    clip_make 1 4 30 97 50 115 "sheep"
    SHEEP_SRC=$C_SRC
    clip_out 64; clip_every 2   # a made clip is IN-OUT of the frames it came from: out to the end
    lane X; mod SINE 18 64 0
    lanes_copy
    # -- a second sheep: placed from the brush, then switched to the made clip's source
    pick 10 4 sheep
    clip_place 92 110 1 "sheep 2"
    clip_src "$SHEEP_SRC"
    clip_every 2; clip_cel 3
    lanes_paste
    lane X; mod SINE 18 64 32

    # -- the rooster crows at dawn: ping-pong, frames 1-16, a crow when it starts
    pick 11 2 rooster
    clip_place 62 78 1 "rooster"
    clip_out 16; clip_mode PING; clip_every 3
    clip_sound start crow.wav

    # -- the sky: warm at dawn and dusk, dark at night (full-frame clips, OPACITY keys)
    pick 5 1 warm
    clip_place 80 60 1 "warm sky"
    lane OP; keys 1:70:3 12:0 32:0:1 44:60:2 52:0
    pick 6 1 night
    clip_place 80 60 1 "night sky"
    lane OP; keys 1:45:2 8:0 40:0:1 52:100 64:100

    # -- night: stars twinkle (cels every 4) and fade in; the moon rises
    pick 4 2 stars
    clip_place 80 60 1 "stars"
    clip_every 4
    lane OP; keys 1:30:2 6:0 46:0:1 54:100
    pick 3 1 moon
    clip_place 128 34 49 "moon"
    lane Y; keys 49:24:2 64:0
    lane OP; keys 49:0 56:100

    # -- the owl wakes: mode Hold (eyes open and stay open), a hoot when it starts
    pick 14 2 owl
    clip_place 146 61 52 "owl"
    clip_mode HOLD; clip_every 4
    clip_sound start hoot.wav

    # -- fireflies: X / Y noise (other seeds per fly), glowing (OPACITY sine); lanes pasted
    pick 13 2 firefly
    clip_place 70 84 49 "firefly 1"
    share firefly
    clip_every 3
    lane X; mod NOISE 14 6 11
    lane Y; mod NOISE 6 5 12
    lane OP; mod SINE 50 8 0
    lanes_copy
    n=2
    for spec in "96 78 21 22 3" "120 88 31 32 5" "54 72 41 42 6"; do
        set -- $spec
        pick 13 2 firefly
        clip_place "$1" "$2" 49 "firefly $n"
        share firefly
        clip_every 3; clip_cel 2
        lanes_paste
        lane X; mod NOISE 14 6 "$3"
        lane Y; mod NOISE 6 5 "$4"
        lane OP; mod SINE 50 8 "$5"
        n=$(( n + 1 ))
    done

    # -- FARM: drawn once on frame 1, cells linked over the loop
    layer sign; lname "farm sign"
    stepset "animbrush step: cel follows the frame" 0
    pick 15 1 sign
    go 1; stamp 31 64
    link 1 64
    stepset "animbrush step: every frame at once" 2

    # -- the layout guide: a reference layer on top
    layer guide; lname "layout guide"
    pick 1 1 guide
    go 1; stamp 80 60
    reflayer

    tag 1 16 DAWN; tag 17 32 NOON; tag 33 48 DUSK; tag 49 64 NIGHT
    note 1 "DAWN: the sun comes up red, the rooster crows"
    note 17 "NOON: the tractor crosses, the sheep hop"
    note 27 "the bump (keyed by nudging the clip)"
    note 33 "DUSK: the sun sets red"
    note 49 "NIGHT: the moon, stars, fireflies, the owl"
    hold 16 2; hold 48 2

    go 1
    sound_drop "$ANS_DIR/farm-music.wav"
    sound_drop "$ANS_DIR/farm-sfx.wav"
    pj_finish farm
fi
