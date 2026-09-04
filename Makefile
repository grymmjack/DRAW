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
# Compiler selection (default = $(HOME)/git/qb64pe/qb64pe — QB64-PE main, v4.6.0+):
#   make main             Build with the main-repo compiler ($(HOME)/git/qb64pe) [default]
#   make v450             Build with the legacy v4.5.0 compiler ($(HOME)/git/qb64pe-450)
#   make a740g            Build with the standalone a740g PR compiler (now redundant)
#   make main-run         Build & run with main
#   make v450-run         Build & run with v450
#   make a740g-run        Build & run with a740g
#   make COMPILER=main <target>    Combine with any other target
#   make COMPILER=main clean       (e.g. clean using main build dir)
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
# Default is the stock main-repo build ($(HOME)/git/qb64pe, QB64-PE v4.6.0+). The
# a740g GLFW work (PR #701) — including the hardware cursor (_MOUSECURSOR), DRAW's
# sole cursor path — has now merged upstream, so the ordinary compiler builds DRAW
# again and the a740g checkout is no longer required. Pick an alternate with
# COMPILER=v450|a740g, or override with QB64PE=/full/path.
COMPILER ?=
ifeq ($(COMPILER),main)
    QB64PE := $(HOME)/git/qb64pe/qb64pe
else ifeq ($(COMPILER),v440)
    # Back-compat alias: this checkout is now main (v4.6.0+), not the old v4.4.0.
    QB64PE := $(HOME)/git/qb64pe/qb64pe
else ifeq ($(COMPILER),v450)
    # Legacy: last pre-GLFW release. FAILS on _MOUSECURSOR — testing only.
    QB64PE := $(HOME)/git/qb64pe-450/qb64pe
else ifeq ($(COMPILER),a740g)
    # The *regenerated* GLFW compiler from the standalone a740g test checkout, kept
    # for parity testing. The plain `qb64pe` binary there predates _MOUSECURSOR and
    # rejects it with a bare "Syntax error" (see PLANS/GLFW-PR701-TEST-RESULTS.md,
    # "Build gotcha"); qb64pe-regen was re-transpiled from source and knows it. Now
    # redundant — the default main compiler has _MOUSECURSOR too.
    QB64PE := $(HOME)/git/qb64pe-a740g-test/qb64pe-regen
else
    # Default: the stock main-repo compiler (v4.6.0+, has _MOUSECURSOR).
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
.PHONY: help all dev dev-run run run-logged run-log-bas clean clean-log macos-app \
        main v450 a740g main-run v450-run a740g-run
.DEFAULT_GOAL := all

# `make help` lists every target by scanning this file for TARGET-DEFINITION
# lines tagged with a trailing `#: description`. The scan is anchored so it can
# only match a real rule header (start-of-line name, then `:`), never a recipe
# or printf line. To document a NEW target, add `#: ...` after its prerequisites.
help:  #: Show this help (targets + variable overrides)
	@awk 'BEGIN{FS="[ \t]*#: "} /^[a-zA-Z][a-zA-Z0-9_-]*:([^=]|$$)/ && /#: / {name=$$1; sub(/:.*/,"",name); printf "  \033[36m%-12s\033[0m %s\n", name, $$2}' $(MAKEFILE_LIST) | sort
	@printf '\nVariable overrides (append VAR=value to any target):\n'
	@printf '  COMPILER=main|v450|a740g  alternate qb64pe build (default main)\n'
	@printf '  QB64PE=/full/path     override the compiler path directly\n'
	@printf '  THREADS=N             parallel compiler processes (default 12)\n'

all: $(OUT)  #: Build DRAW (default, C++ optimized) -> DRAW.run / DRAW.run.exe

# Fast DEV build: skip C++ -O (the g++ optimization of qbx.cpp + the giant generated
# .cpp is the bulk of build time). Measured ~13min -> ~7min. NOT for release — the
# binary is unoptimized; use `make all` (or a release build) for anything you ship.
dev: QB64FLAGS += -f:OptimizeCppProgram=false
dev: $(OUT)  #: Fast dev build — skip C++ -O (~2x faster); NOT for release
	@printf '  \033[33m[dev build: C++ optimization OFF — testing only; use `make all` for release]\033[0m\n'

dev-run: dev  #: Fast dev build, then run
	./$(OUT)

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

macos-app: $(OUT)  #: [macOS] Bundle DRAW.run + icon into a self-contained DRAW.app
	./DEV/make-macos-app.sh

# ---------- Compiler shortcuts ------------------------------------------------
# Each shortcut recurses into make with COMPILER=<alias> so the ifeq chain
# above resolves QB64PE to the matching path. Plain `make` already uses main,
# so these select a non-default compiler (or make the default explicit).
main:  #: Build with the main-repo compiler (~/git/qb64pe, v4.6.0+) [default]
	@$(MAKE) --no-print-directory COMPILER=main all

v450:  #: Build with the legacy v4.5.0 compiler (~/git/qb64pe-450; no _MOUSECURSOR)
	@$(MAKE) --no-print-directory COMPILER=v450 all

a740g:  #: Build with the standalone a740g PR compiler (redundant with default)
	@$(MAKE) --no-print-directory COMPILER=a740g all

main-run:  #: Build & run with the main-repo compiler
	@$(MAKE) --no-print-directory COMPILER=main run

v450-run:  #: Build & run with the legacy v4.5.0 compiler
	@$(MAKE) --no-print-directory COMPILER=v450 run

a740g-run:  #: Build & run with the a740g compiler
	@$(MAKE) --no-print-directory COMPILER=a740g run
