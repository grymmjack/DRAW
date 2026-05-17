#!/usr/bin/env bash
# Activity logger hook for Claude Code.
#
# Wired in .claude/settings.local.json as both a PreToolUse and PostToolUse
# hook on the Bash and Agent matchers. Reads the Claude Code hook JSON on
# stdin, appends a human-readable record to .claude/activity.log, and exits
# silently. Never prints to stdout (Claude Code interprets hook stdout as
# protocol JSON).
#
# Tail it in a side terminal:  tail -f .claude/activity.log
#
# Output is capped per call so a runaway compile log can't fill the file
# unboundedly; the raw compile output still lives in DRAW.log when you use
# `make run-logged`.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/activity.log"
MAX_LINES=80      # cap stdout/stderr lines per record
MAX_CHARS=8000    # cap total bytes shown per stream

input="$(cat)"
[ -z "$input" ] && exit 0

# jq is required; fail silently if missing rather than blocking tool calls.
command -v jq >/dev/null 2>&1 || exit 0

event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
tool=$(printf '%s' "$input"  | jq -r '.tool_name // empty')
ts=$(date '+%Y-%m-%d %H:%M:%S')

# Only log Bash and Agent (background-capable) tool calls.
case "$tool" in
    Bash|Agent) ;;
    *) exit 0 ;;
esac

truncate_stream() {
    # Stdin -> stdout, capped by line count and byte count, with a marker
    # appended if either cap was hit. Indents each line with "  | ".
    awk -v max_lines="$MAX_LINES" -v max_chars="$MAX_CHARS" '
        BEGIN { lines = 0; chars = 0; truncated = 0 }
        {
            lines++
            chars += length($0) + 1
            if (lines > max_lines || chars > max_chars) {
                if (!truncated) { print "  | ... [truncated]"; truncated = 1 }
                next
            }
            print "  | " $0
        }
    '
}

case "$event" in
    PreToolUse)
        if [ "$tool" = "Bash" ]; then
            cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
            desc=$(printf '%s' "$input" | jq -r '.tool_input.description // ""')
            bg=$(printf '%s' "$input"  | jq -r '.tool_input.run_in_background // false')
            timeout_ms=$(printf '%s' "$input" | jq -r '.tool_input.timeout // empty')
            cwd=$(printf '%s' "$input"  | jq -r '.cwd // ""')

            marker=""
            [ "$bg" = "true" ] && marker=" [BG]"
            [ -n "$timeout_ms" ] && marker="$marker [timeout=${timeout_ms}ms]"

            {
                printf '\n=== %s  START Bash%s ===\n' "$ts" "$marker"
                [ -n "$desc" ] && printf '  desc: %s\n' "$desc"
                printf '  cwd:  %s\n' "$cwd"
                printf '  cmd:  %s\n' "$cmd"
            } >> "$LOG_FILE"
        else
            # Agent
            subagent=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // "general-purpose"')
            agent_desc=$(printf '%s' "$input" | jq -r '.tool_input.description // ""')
            agent_bg=$(printf '%s' "$input"  | jq -r '.tool_input.run_in_background // false')
            marker=""
            [ "$agent_bg" = "true" ] && marker=" [BG]"
            {
                printf '\n=== %s  START Agent(%s)%s ===\n' "$ts" "$subagent" "$marker"
                printf '  desc: %s\n' "$agent_desc"
            } >> "$LOG_FILE"
        fi
        ;;

    PostToolUse)
        if [ "$tool" = "Bash" ]; then
            cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
            stdout=$(printf '%s' "$input" | jq -r '.tool_response.stdout // ""')
            stderr=$(printf '%s' "$input" | jq -r '.tool_response.stderr // ""')
            interrupted=$(printf '%s' "$input" | jq -r '.tool_response.interrupted // false')

            {
                printf -- '--- %s  END Bash ---\n' "$ts"
                [ "$interrupted" = "true" ] && printf '  !! INTERRUPTED\n'
                if [ -n "$stdout" ] && [ "$stdout" != "null" ]; then
                    printf '  -- stdout --\n'
                    printf '%s\n' "$stdout" | truncate_stream
                fi
                if [ -n "$stderr" ] && [ "$stderr" != "null" ]; then
                    printf '  -- stderr --\n'
                    printf '%s\n' "$stderr" | truncate_stream
                fi
            } >> "$LOG_FILE"
        else
            # Agent: tool_response is usually a string (the agent's final message).
            response=$(printf '%s' "$input" | jq -r '.tool_response // ""')
            {
                printf -- '--- %s  END Agent ---\n' "$ts"
                if [ -n "$response" ] && [ "$response" != "null" ]; then
                    printf '  -- response --\n'
                    printf '%s\n' "$response" | truncate_stream
                fi
            } >> "$LOG_FILE"
        fi
        ;;
esac

exit 0
