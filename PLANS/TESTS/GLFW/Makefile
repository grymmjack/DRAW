# GLFW cross-platform keyword tests — build & run with the a740g PR compiler.
#
# These standalone QB64-PE programs verify the windowing/input keywords that
# a740g's GLFW-backend PR makes work on Linux/macOS/Windows. Each .BAS is
# independent (no DRAW sources) so it isolates exactly one keyword.
#
# Usage:
#   make a740g                     Build ALL GLFW_*_TEST programs
#   make a740g TEST=CAPSLOCK       Build just GLFW_CAPSLOCK_TEST
#   make a740g-run TEST=CAPSLOCK   Build & run GLFW_CAPSLOCK_TEST
#   make list                      List valid TEST= names
#   make clean                     Remove built binaries
#
# A/B comparison vs the stable SDL2 (v450) build — override the compiler path:
#   make a740g-run TEST=KEYCODE QB64PE=$HOME/git/qb64pe-450/qb64pe
#
# (Some keywords were "not supported" on Linux/macOS pre-a740g and may not even
#  COMPILE under v450 there — that failure is itself an informative result.)

SHELL := /bin/bash

# Compiler: default to the a740g PR build; override QB64PE=/path for comparison.
QB64PE    ?= $(HOME)/git/qb64pe-a740g-test/qb64pe
QB64FLAGS ?= -w -x

# OS-aware binary extension (matches the root DRAW Makefile: .run / .run.exe).
RM := rm -f
ifeq ($(OS),Windows_NT)
    EXT := .run.exe
else
    EXT := .run
endif

# All test sources and their target binaries.
SRCS := $(wildcard GLFW_*_TEST.BAS)
BINS := $(SRCS:.BAS=$(EXT))

# TEST=<NAME> selects GLFW_<NAME>_TEST; empty selects everything.
TEST ?=
ifeq ($(strip $(TEST)),)
    SELECTED := $(BINS)
else
    SELECTED := GLFW_$(TEST)_TEST$(EXT)
endif

.PHONY: a740g a740g-run all clean list help
.DEFAULT_GOAL := help

a740g: $(SELECTED)  #: Build all tests (or one with TEST=<NAME>) using the a740g compiler

all: $(BINS)  #: Build every test program

# Pattern rule: compile one standalone test with the selected compiler.
GLFW_%_TEST$(EXT): GLFW_%_TEST.BAS
	@printf '\n=== %s %s %s -o %s ===\n' "$(QB64PE)" "$(QB64FLAGS)" "$<" "$@"
	$(QB64PE) $(QB64FLAGS) $< -o $@

# Build (via a sub-make so the pattern rule fires) then run the chosen test.
a740g-run:  #: Build & run one test — needs TEST=<NAME> (try: make list)
	@if [ -z "$(strip $(TEST))" ]; then \
	    echo "ERROR: a740g-run needs TEST=<NAME>.  Run 'make list' for names."; \
	    exit 1; \
	fi
	@$(MAKE) --no-print-directory GLFW_$(TEST)_TEST$(EXT) QB64PE='$(QB64PE)'
	./GLFW_$(TEST)_TEST$(EXT)

list:  #: List valid TEST= names
	@for f in $(SRCS); do n=$${f#GLFW_}; n=$${n%_TEST.BAS}; echo "  $$n"; done

clean:  #: Remove built test binaries
	$(RM) $(BINS)

help:  #: Show this help
	@awk 'BEGIN{FS="[ \t]*#: "} /^[a-zA-Z][a-zA-Z0-9_-]*:.*#: / {name=$$1; sub(/:.*/,"",name); printf "  \033[36m%-12s\033[0m %s\n", name, $$2}' $(MAKEFILE_LIST)
	@printf '\n  Variable overrides:\n'
	@printf '    TEST=<NAME>     pick one test (see: make list)\n'
	@printf '    QB64PE=/path    compiler to use (default: a740g PR build)\n'
