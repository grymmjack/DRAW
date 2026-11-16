# brick-breaker - an original brick breaker, simulated in brick-breaker.py, which writes the
# moves (moves.sh: paddle segments, the bricks held then bursting, the ball's drawn path,
# the capsule and the catch sparkle).
if open_scene brick-breaker 48; then
    fg_white   # the bursting bricks flash white (the sparkle picks gold itself)
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/brick-breaker-music.wav"
    sound_drop "$ANS_DIR/brick-breaker-sfx.wav"
    finish_scene brick-breaker
fi
