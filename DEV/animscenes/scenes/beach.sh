# beach - a sunny beach (48 frames, loops). beach.py writes the moves.
if open_scene beach 48; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/beach-music.wav"
    sound_drop "$ANS_DIR/beach-sfx.wav"
    finish_scene beach
fi
