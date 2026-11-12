# dungeon - torches, skull candles, spiders, a bat, a ghost, drips; 48 frames, loops. See dungeon.py.
if open_scene dungeon 48; then
    source "$ANS_DIR/moves.sh"
    sound_drop "$ANS_DIR/dungeon-music.wav"
    sound_drop "$ANS_DIR/dungeon-sfx.wav"
    finish_scene dungeon
fi
