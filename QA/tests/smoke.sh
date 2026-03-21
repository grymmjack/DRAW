#!/bin/bash
# QA/tests/smoke.sh — Basic launch & sanity checks
# Verifies DRAW opens, shows the right title, and doesn't crash on idle.

assert_window_exists
assert_no_crash
assert_window_title "DRAW v"

wait_for 1 "idle render"
screenshot "smoke-launch"

assert_no_crash
