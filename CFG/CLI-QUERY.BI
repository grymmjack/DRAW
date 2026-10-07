''
' DRAW - CFG/CLI-QUERY.BI
' =============================================================================
' "Where is it?" command-line queries. Each prints an absolute path and exits
' before any window opens (works headless), so it can feed the shell:
'
'   vim $(DRAW --cfg)            the config file DRAW is using right now
'   DRAW --dirs                  every directory, labeled
'   cd $(DRAW --dir-data)        one directory, bare path (no trailing slash)
'   DRAW --workspaces            the workspaces (built-in + yours), remembered one starred
'
' Runs at include time right after CFG/CONFIG.BI, when CONFIG_FILE_PATH$ is
' final (--config, OS-specific cfg, portable mode, per-instance config all
' applied). Values that live in the config (THEME, TEMPLATE_DIR, the .dset
' files) are read straight from that file - CONFIG_load has not run yet.
' Functions: CORE/CLI.BM (CLIQ_*).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM CLIQ_i%
DIM CLIQ_arg$
FOR CLIQ_i% = 1 TO _COMMANDCOUNT
    CLIQ_arg$ = LCASE$(_TRIM$(COMMAND$(CLIQ_i%)))
    IF CLIQ_arg$ = "--cfg" OR CLIQ_arg$ = "--dirs" OR CLIQ_arg$ = "--workspaces" OR LEFT$(CLIQ_arg$, 6) = "--dir-" THEN
        SYSTEM CLIQ_run%(CLIQ_arg$)
    END IF
NEXT CLIQ_i%
