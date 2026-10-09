#!/usr/bin/env bash
# qa-dash.sh - the live QA test dashboard (DEV/qa-dash.py; sibling of dash.sh).
exec uv run "$(dirname "$0")/qa-dash.py" --watch "${1:-3}"
