#!/bin/bash
# =============================================================================
# controls-export-source-guards.sh — QA regression guard (SOURCE-level)
#
# Guards the "Export Customized Controls" feature: the Customize Controls dialog
# can export the LIVE keyboard registry (overrides reflected) to Markdown / HTML
# (and PDF when a converter is present) in the hotkey-reference format, via a
# reused DIALOG dropdown ("Export as…"). MD + HTML are native (no external tools);
# PDF is LAME-style optional.
#
# WHY source-level: the export writes files + drives a dropdown in a scaled modal;
# the CLI half is behaviourally covered by a --export-controls run (see the export
# verification), and the dropdown render is screenshot-verified. THIS test pins the
# implementation so a refactor can't silently break it — including the two QB64
# gotchas that bit during build (`""` non-escape, no-arg parens) and the pandoc
# hang fix.
# =============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/lib/source-guard.sh"

echo "=== Customize Controls export source guards ==="

# Generator: standalone MD/HTML doc + per-format export + PDF probe, all reusing
# the existing SHORTCUTS-DUMP registry walk (DRY).
assert_grep "GEN" "OUTPUT/SHORTCUTS-DUMP.BM" 'FUNCTION SHORTCUTS_controls_doc\$'   "standalone MD/HTML doc builder"
assert_grep "GEN" "OUTPUT/SHORTCUTS-DUMP.BM" 'FUNCTION SHORTCUTS_export_fmt\$'     "per-format export (dialog)"
assert_grep "GEN" "OUTPUT/SHORTCUTS-DUMP.BM" 'FUNCTION SHORTCUTS_export_controls%' "MD+HTML export (CLI)"
assert_grep "GEN" "OUTPUT/SHORTCUTS-DUMP.BM" 'INPUT_BINDS\(i%\)\.userOverridden'   "★ marks customized rows from live registry"

# No external tool REQUIRED: CLI export path has no SHELL; MD+HTML are written natively.
assert_absent "NATIVE" "OUTPUT/SHORTCUTS-DUMP.BM" 'FUNCTION SHORTCUTS_export_controls% .*\n.*SHELL' "CLI export writes natively (no SHELL) — best-effort"

# PDF is LAME-style optional: probe PATH for wkhtmltopdf/weasyprint; pandoc is NOT
# used (its LaTeX PDF path hung the export).
assert_grep  "PDF" "OUTPUT/SHORTCUTS-DUMP.BM" 'FUNCTION SHORTCUTS_pdf_engine\$'      "optional HTML->PDF converter probe"
assert_grep  "PDF" "OUTPUT/SHORTCUTS-DUMP.BM" 'wkhtmltopdf'                          "probes wkhtmltopdf"
assert_absent "PDF" "OUTPUT/SHORTCUTS-DUMP.BM" 'cmd\$ = "pandoc'                     "pandoc NOT used for PDF (LaTeX hang)"

# QB64 gotcha fixes stay: single-quote HTML attrs (not ""), print CSS.
assert_grep  "QB64" "OUTPUT/SHORTCUTS-DUMP.BM" "class='mod'"                         "HTML uses single-quote attrs (QB64 '' non-escape)"
assert_grep  "QB64" "OUTPUT/SHORTCUTS-DUMP.BM" '@media print'                        "HTML carries print-to-PDF CSS"

# CLI + dialog wiring.
assert_grep "CLI" "DRAW.BAS"        'export-controls'                               "--export-controls CLI flag"
assert_grep "UI"  "GUI/CONTROLS.BM" 'DIALOG_dropdown%\(CONTROLS.ctx, CTRL_DD_EXPORT' "reused dropdown widget (Export as)"
assert_grep "UI"  "GUI/CONTROLS.BM" 'SHORTCUTS_export_fmt\$\(fmtSel'                 "dropdown pick exports the chosen format"

guard_footer "an export-controls feature guard was removed"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
