# bakery - morning sun on a bakery table (48 frames, loops). bakery.py writes the moves
# (the steam puffs that run past frame 48 finish on frames 1..: a seamless loop).
if open_scene bakery 48; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/bakery-music.wav"
    sound_drop "$ANS_DIR/bakery-sfx.wav"
    finish_scene bakery
fi
