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

# ---------- Source / output ---------------------------------------------------
SRC       := DRAW.BAS
BASENAME  := DRAW
LOGFILE   := $(BASENAME).log

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
ifeq ($(OS),Windows_NT)
    EXT     := .exe
    RM      := del /f /q
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        EXT := .run
    else
        EXT := .run
    endif
    RM      := rm -f
endif

OUT := $(BASENAME)$(EXT)

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
.PHONY: all run run-logged run-log-bas clean clean-log \
        a740g v450 a740g-run v450-run

all: $(OUT)

$(OUT): $(SRC)
	$(RM) $(OUT)
	$(QB64PE) $(QB64FLAGS) $(SRC) -o $(OUT)

run: $(OUT)
	./$(OUT)

run-logged: clean-log $(OUT)
	$(LOG_ENV_FULL) ./$(OUT)

run-log-bas: clean-log $(OUT)
	$(LOG_ENV_BASIC) ./$(OUT)

clean:
	$(RM) $(OUT)
	$(RM) $(LOGFILE)

clean-log:
	$(RM) $(LOGFILE)

# ---------- Compiler shortcuts ------------------------------------------------
# Each shortcut recurses into make with COMPILER=<alias> so the ifeq chain
# above resolves QB64PE to the matching path.
a740g:
	@$(MAKE) --no-print-directory COMPILER=a740g all

v450:
	@$(MAKE) --no-print-directory COMPILER=v450 all

a740g-run:
	@$(MAKE) --no-print-directory COMPILER=a740g run

v450-run:
	@$(MAKE) --no-print-directory COMPILER=v450 run
