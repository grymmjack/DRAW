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
# Override the compiler path:
#   make QB64PE=/path/to/qb64pe

# ---------- Source / output ---------------------------------------------------
SRC       := DRAW.BAS
BASENAME  := DRAW
LOGFILE   := $(BASENAME).log

# ---------- Compiler ----------------------------------------------------------
#QB64PE    ?= $(HOME)/git/qb64pe-a740g-test/qb64pe
QB64PE    ?= $(HOME)/git/qb64pe/qb64pe
#QB64PE    ?= $(HOME)/git/qb64pe-450/qb64pe
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
.PHONY: all run run-logged run-log-bas clean clean-log

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
