# DRAW - Pixel Art Editor
# Makefile generated from .vscode/tasks.json
#
# Usage:
#   make              Build DRAW (auto-detects OS)
#   make run          Build and run
#   make run-logged   Build and run with full QB64PE logging
#   make run-log-bas  Build and run with basic logging
#   make clean        Remove built binary and log files
#   make clean-log    Remove log file only
#
# Compiler selection (default = $(HOME)/git/qb64pe/qb64pe):
#   make a740g            Build with the a740g PR compiler
#   make v450             Build with the qb64pe-450 compiler
#   make a740g-run        Build & run with a740g
#   make v450-run         Build & run with v450
#   make COMPILER=a740g <target>   Combine with any other target
#   make COMPILER=v450 clean       (e.g. clean using v450 build dir)
#   make QB64PE=/full/path         Override path directly
#
# Compile output is appended to .claude/make.log (project-local, gitignored)
# so a side terminal can `tail -f .claude/make.log` to watch warnings/errors
# across builds. The pipeline strips QB64-PE's ANSI progress bar so only
# meaningful lines (warnings, errors, "Compiling..." / "Output:") land in
# both the terminal and the log.

# Use bash with pipefail so `qb64pe ... | tee` propagates compile failures
# instead of returning tee's exit code.
SHELL       := /bin/bash
.SHELLFLAGS := -o pipefail -c

# ---------- Source / output ---------------------------------------------------
SRC       := DRAW.BAS
BASENAME  := DRAW
LOGFILE   := $(BASENAME).log
MAKE_LOG  := .claude/make.log

# ---------- Compiler ----------------------------------------------------------
COMPILER ?=
ifeq ($(COMPILER),a740g)
    QB64PE := $(HOME)/git/qb64pe-a740g-test/qb64pe
else ifeq ($(COMPILER),v450)
    QB64PE := $(HOME)/git/qb64pe-450/qb64pe
else
    QB64PE ?= $(HOME)/git/qb64pe/qb64pe
endif
THREADS   ?= 12
QB64FLAGS := -w -x -f:MaxCompilerProcesses=$(THREADS)

# ---------- OS detection ------------------------------------------------------
# All recipes run under bash (SHELL := /bin/bash above) — including on Windows,
# where that means Git Bash / MSYS2. So use bash's `rm` everywhere; cmd.exe's
# `del` does not exist in that shell.
#
# Output naming convention: the binary always carries `.run` (grymmjack's marker
# for "build artifact, never committed" — see .gitignore `*.run` / `*.run.exe`).
# On Windows we append `.exe` as well so the OS will actually execute it, giving
# DRAW.run.exe; Linux/macOS just use DRAW.run.
RM := rm -f
ifeq ($(OS),Windows_NT)
    EXT := .run.exe
else
    EXT := .run
endif

OUT := $(BASENAME)$(EXT)

# ---------- Dependency tracking (compile goals only — no side effects) ---------
# QB64-PE compiles the whole program as ONE unit: DRAW.BAS pulls in the entire
# .BI/.BM tree via _ALL.BI/_ALL.BM. Make can't see those $INCLUDE chains, so the
# binary must depend on EVERY .BI/.BM plus the entry .BAS for change detection.
#
# The `find` that builds that list runs ONLY when the requested goal actually
# compiles (or no goal was given, which defaults to `all`). `make clean`,
# `make clean-log`, `make -n clean`, etc. take the cheap branch — no disk walk,
# no scanning, no side effects. Standalone *.BAS programs under includes/ are
# not part of DRAW, so we glob .BI/.BM only and name DRAW.BAS explicitly.
COMPILE_GOALS := all run run-logged run-log-bas $(OUT)
GOALS         := $(if $(MAKECMDGOALS),$(MAKECMDGOALS),all)
ifeq ($(filter $(COMPILE_GOALS),$(GOALS)),)
    SOURCES := $(SRC)
else
    SOURCES := $(SRC) $(shell find . -type f \( -name '*.BI' -o -name '*.BM' \) -not -path './.git/*')
endif

# ---------- Logging env vars --------------------------------------------------
LOG_ENV_FULL  := QB64PE_LOG_HANDLERS=console,file \
                 QB64PE_LOG_SCOPES=runtime,qb64,libqb,libqb-audio,libqb-image \
                 QB64PE_LOG_LEVEL=1 \
                 QB64PE_LOG_FILE_PATH=$(LOGFILE)

LOG_ENV_BASIC := QB64PE_LOG_HANDLERS=console,file \
                 QB64PE_LOG_SCOPES=runtime,qb64 \
                 QB64PE_LOG_LEVEL=2 \
                 QB64PE_LOG_FILE_PATH=$(LOGFILE)

# ---------- Targets -----------------------------------------------------------
.PHONY: help all run run-logged run-log-bas clean clean-log \
        a740g v450 a740g-run v450-run
.DEFAULT_GOAL := all

# `make help` lists every target by scanning this file for TARGET-DEFINITION
# lines tagged with a trailing `#: description`. The scan is anchored so it can
# only match a real rule header (start-of-line name, then `:`), never a recipe
# or printf line. To document a NEW target, add `#: ...` after its prerequisites.
help:  #: Show this help (targets + variable overrides)
	@awk 'BEGIN{FS="[ \t]*#: "} /^[a-zA-Z][a-zA-Z0-9_-]*:([^=]|$$)/ && /#: / {name=$$1; sub(/:.*/,"",name); printf "  \033[36m%-12s\033[0m %s\n", name, $$2}' $(MAKEFILE_LIST) | sort
	@printf '\nVariable overrides (append VAR=value to any target):\n'
	@printf '  COMPILER=a740g|v450   use an alternate qb64pe build\n'
	@printf '  QB64PE=/full/path     override the compiler path directly\n'
	@printf '  THREADS=N             parallel compiler processes (default 12)\n'

all: $(OUT)  #: Build DRAW (default) -> DRAW.run, or DRAW.run.exe on Windows

$(OUT): $(SOURCES)
	$(RM) $(OUT)
	@mkdir -p $(dir $(MAKE_LOG))
	@printf '\n=== %s  %s %s %s -o %s ===\n' "$$(date '+%Y-%m-%d %H:%M:%S')" "$(QB64PE)" "$(QB64FLAGS)" "$(SRC)" "$(OUT)" | tee -a $(MAKE_LOG)
	$(QB64PE) $(QB64FLAGS) $(SRC) -o $(OUT) 2>&1 \
	    | sed -u 's/\x1b\[[0-9;]*[A-Za-z]//g' \
	    | grep --line-buffered -v '^\[[ .]*\][[:space:]]*[0-9]\+%' \
	    | tee -a $(MAKE_LOG)

run: $(OUT)  #: Build then run DRAW
	./$(OUT)

run-logged: clean-log $(OUT)  #: Build & run with FULL QB64-PE logging -> DRAW.log
	$(LOG_ENV_FULL) ./$(OUT)

run-log-bas: clean-log $(OUT)  #: Build & run with BASIC logging -> DRAW.log
	$(LOG_ENV_BASIC) ./$(OUT)

clean:  #: Remove the built binary and log file
	$(RM) $(OUT)
	$(RM) $(LOGFILE)

clean-log:  #: Remove the log file only
	$(RM) $(LOGFILE)

# ---------- Compiler shortcuts ------------------------------------------------
# Each shortcut recurses into make with COMPILER=<alias> so the ifeq chain
# above resolves QB64PE to the matching path.
a740g:  #: Build with the a740g PR compiler
	@$(MAKE) --no-print-directory COMPILER=a740g all

v450:  #: Build with the qb64pe-450 compiler
	@$(MAKE) --no-print-directory COMPILER=v450 all

a740g-run:  #: Build & run with the a740g compiler
	@$(MAKE) --no-print-directory COMPILER=a740g run

v450-run:  #: Build & run with the qb64pe-450 compiler
	@$(MAKE) --no-print-directory COMPILER=v450 run
