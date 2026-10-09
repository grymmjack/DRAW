@echo off
rem Windows twin of fake-capture.sh: DRAW runs CAPTURE_COMMAND through cmd.exe,
rem which cannot run a .sh. The QA adapter swaps .sh for .cmd on Windows.
copy /Y "%~dp0capture-fixture.png" %1 >NUL
