#!/usr/bin/env python3
"""
align-qb64pe.py — Align inline comments, '=', 'AS', ':', and CASE statements in QB64-PE source files.

Two modes:

  compact (default)
    Strips extra whitespace between code and its inline comment so exactly
    --min-gap spaces (default 1) separate the code from the ' marker.
    Every commented line is handled independently — the alignment of the
    surrounding code (e.g. already-aligned '=' columns) is preserved.

  align
    Section-aware comment alignment. Blank lines and pure-comment lines
    (e.g. ' --- Section ---') delimit sections. Within each section, ALL
    commented lines are aligned to the same column — non-commented code
    lines don't break the group, they just don't participate. This keeps
    a whole file's comments tidy even when some lines have no comment.

Flags:

  --align-eq
    Within each consecutive block of assignment lines, aligns the '=' to
    the same column (pads the LHS). Normalises spacing to exactly one
    space on each side of '='. Runs before the comment pass.

  --align-as
    Within each consecutive block of TYPE/DIM declaration lines, aligns
    the 'AS' keyword to the same column (pads the field name). Runs after
    --align-eq and before the comment pass.

  --align-case
    Within each section of SELECT CASE lines of the form
        CASE "KEY":  assignment = value
    aligns two columns: the assignment start (after ':') and the '='
    within the assignment. Pure comment lines and blank lines break
    sections. Combine with --global for file-wide alignment.

  --global
    Makes --align-as, --align-case, and --mode align work across the
    ENTIRE file rather than section-by-section. Every declaration / CASE
    line shares one column for 'AS' (or ':'), one for '=', and one for
    comments. Implies --mode align.

Usage:
  python3 align-qb64pe.py [OPTIONS] [PATHS...]

  PATHS can be individual .BAS/.BI/.BM files or directories to scan.
  Default: current directory (recursive)

Options:
  --mode compact|align   Processing mode (default: compact)
  --align-eq             Align '=' within assignment groups
  --align-as             Align 'AS' within TYPE/DIM declaration groups
  --align-case           Align CASE "KEY": inline assignments (two columns)
  --global               Align all columns globally (whole file), implies --mode align
  --dry-run              Report changes without modifying files
  --no-backup            Don't create .orig backup files
  --min-gap N            Spaces between code and comment (default: 1)
  --eq-gap N             Spaces before '=' when aligning (default: 1)
  --as-gap N             Spaces before 'AS' when aligning (default: 1)
  --case-gap N           Spaces after ':' before assignment in CASE (default: 1)
  --ext E[,E...]         File extensions to process (default: bas,bi,bm)
  --help                 Show this message

Examples:
  python3 align-qb64pe.py --dry-run CFG/
  python3 align-qb64pe.py --align-eq CFG/BINDINGS-KEYBOARD.BI
  python3 align-qb64pe.py --align-as --global CFG/CONFIG-THEME.BI
  python3 align-qb64pe.py --align-case --global CFG/CONFIG-THEME.BM
  python3 align-qb64pe.py --align-eq --align-as --global CFG/
"""

import argparse
import os
import shutil
import sys


# ---------------------------------------------------------------------------
# QB64 comment parsing
# ---------------------------------------------------------------------------

def find_comment_pos(line: str) -> int:
    """Return the index of the inline comment apostrophe, or -1 if none.

    Handles QB64 string literals (delimited by ") where "" is a literal
    double-quote.  A ' inside a string is NOT a comment marker.

    A line whose very first non-space character is ' is a pure comment line;
    this function returns -1 for those (callers treat them as group breakers).
    """
    stripped = line.lstrip()
    if stripped.startswith("'") or stripped.upper().startswith("REM "):
        return -1  # pure comment / REM line

    in_string = False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == '"':
            if in_string:
                # "" inside a string = escaped quote, skip both
                if i + 1 < len(line) and line[i + 1] == '"':
                    i += 2
                    continue
                in_string = False
            else:
                in_string = True
        elif ch == "'" and not in_string:
            return i
        i += 1
    return -1  # no inline comment


def find_case_colon_pos(line: str) -> int:
    """Return the index of ':' in a 'CASE "KEY":' line with inline code, or -1.

    Only matches lines of the form:
        [whitespace] CASE "STRING_LITERAL" :
    where there is actual non-comment code following the colon on the same line.
    """
    stripped = line.lstrip()
    if not stripped.upper().startswith('CASE '):
        return -1

    i = len(line) - len(stripped)  # start of 'CASE'
    i += 5  # skip 'CASE '

    while i < len(line) and line[i] == ' ':
        i += 1

    if i >= len(line) or line[i] != '"':
        return -1  # not a string-literal CASE

    i += 1  # skip opening "
    while i < len(line) and line[i] != '"':
        i += 1
    if i >= len(line):
        return -1
    i += 1  # skip closing "

    while i < len(line) and line[i] == ' ':
        i += 1
    if i >= len(line) or line[i] != ':':
        return -1

    # Require actual code after the colon
    rest = line[i + 1:].strip()
    if not rest or rest.startswith("'"):
        return -1

    return i


def find_as_pos(line: str) -> int:
    """Return the index of the space before ' AS ' in a TYPE/DIM declaration, or -1.

    Only matches when the LHS (before ' AS ') looks like a simple identifier
    (no parentheses) so SUB/FUNCTION parameter lists are excluded.
    Case-insensitive; stops at the first ' AS ' found outside a string.
    """
    stripped = line.lstrip()
    if not stripped or stripped.startswith("'") or stripped.upper().startswith("REM "):
        return -1

    # Exclude file-I/O and other non-declaration uses of 'AS'
    _su = stripped.upper()
    for _kw in ('OPEN ', 'LOCK ', 'UNLOCK ', 'GET ', 'PUT ', 'SEEK ', 'FOR '):
        if _su.startswith(_kw):
            return -1

    in_string = False
    i = 0
    while i < len(line) - 3:
        ch = line[i]
        if ch == '"':
            if in_string:
                if i + 1 < len(line) and line[i + 1] == '"':
                    i += 2
                    continue
                in_string = False
            else:
                in_string = True
        elif not in_string and line[i:i + 4].upper() == ' AS ':
            lhs = line[:i].strip()
            # Skip parameter-list contexts
            if '(' not in lhs and ')' not in lhs:
                # Skip 'DIM [SHARED] AS TYPE varlist' — type precedes name
                lhs_upper = lhs.upper()
                for _prefix in ('DIM SHARED', 'DIM', 'REDIM SHARED', 'REDIM'):
                    if lhs_upper == _prefix:
                        break  # LHS is keyword-only — no variable name present
                else:
                    return i
        i += 1
    return -1


def find_eq_pos(line: str) -> int:
    """Return the index of the assignment '=' outside strings, or -1.

    Returns -1 for blank lines, pure comment lines, and lines with no '='.
    Skips '=' that is part of <=, >= or <> comparisons.
    """
    stripped = line.lstrip()
    if not stripped or stripped.startswith("'") or stripped.upper().startswith("REM "):
        return -1

    in_string = False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == '"':
            if in_string:
                if i + 1 < len(line) and line[i + 1] == '"':
                    i += 2
                    continue
                in_string = False
            else:
                in_string = True
        elif ch == '=' and not in_string:
            # Skip <=, >=, <>
            if i > 0 and line[i - 1] in '<>!':
                pass
            else:
                return i
        i += 1
    return -1


# ---------------------------------------------------------------------------
# Line ending helper
# ---------------------------------------------------------------------------

def get_ending(line: str) -> str:
    if line.endswith('\r\n'):
        return '\r\n'
    if line.endswith('\n'):
        return '\n'
    if line.endswith('\r'):
        return '\r'
    return ''


# ---------------------------------------------------------------------------
# Compact mode: normalise each commented line independently
# ---------------------------------------------------------------------------

def process_lines_compact(lines: list[str], min_gap: int) -> tuple[list[str], int]:
    """Strip extra whitespace before each inline comment to exactly min_gap spaces."""
    result = []
    changed = 0
    gap = ' ' * min_gap

    for orig in lines:
        raw = orig.rstrip('\n').rstrip('\r')
        pos = find_comment_pos(raw)
        if pos == -1:
            # No inline comment — strip trailing whitespace only
            stripped = raw.rstrip()
            new_line = stripped + get_ending(orig)
            if new_line != orig:
                changed += 1
            result.append(new_line)
        else:
            code_part = raw[:pos].rstrip()
            comment_part = raw[pos:]
            new_line = code_part + gap + comment_part + get_ending(orig)
            if new_line != orig:
                changed += 1
            result.append(new_line)

    return result, changed


# ---------------------------------------------------------------------------
# Global AS-align pass: single column for entire file
# ---------------------------------------------------------------------------

_BLOCK_BOUNDARY_PREFIXES = (
    'SUB ', 'FUNCTION ', 'TYPE ', 'END SUB', 'END FUNCTION', 'END TYPE',
)


def _is_block_boundary(raw: str) -> bool:
    """Return True if this line is a SUB/FUNCTION/TYPE definition or end marker."""
    s = raw.strip().upper()
    return any(s == kw.rstrip() or s.startswith(kw) for kw in _BLOCK_BOUNDARY_PREFIXES)


def process_lines_align_as_global(lines: list[str], as_gap: int = 1) -> tuple[list[str], int]:
    """Align 'AS' declarations file-wide, but break groups at SUB/FUNCTION/TYPE boundaries.

    Within each SUB, FUNCTION or TYPE block every declaration line shares one
    'AS' column. Block-boundary lines (SUB, END SUB, etc.) start a new group.
    """
    # Build groups: each group is a list of (index, raw, as_pos)
    # Groups break at SUB/FUNCTION/TYPE boundaries AND at indent-level changes.
    # A DIM at a different indentation is in a different code context and should
    # not share a column with DIMs at another level.
    groups = []   # list of groups
    current = []  # current group
    current_indent = None  # indent of the first line in current group

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()

        if _is_block_boundary(raw):
            if current:
                groups.append(current)
                current = []
            current_indent = None
            continue

        # Blank lines break AS groups (but pure-comment lines don't —
        # allows TYPE fields with comment separators to stay in one group)
        if not stripped:
            if current:
                groups.append(current)
                current = []
            current_indent = None
            continue

        pos = find_as_pos(raw)
        if pos != -1:
            indent = len(raw) - len(raw.lstrip())
            if current_indent is None:
                current_indent = indent
            elif indent != current_indent:
                if current:
                    groups.append(current)
                current = []
                current_indent = indent
            current.append((i, raw, pos))

    if current:
        groups.append(current)

    if not groups:
        return list(lines), 0

    result = list(lines)
    changed = 0
    pad = ' ' * as_gap

    for group in groups:
        if not group:
            continue
        max_lhs = max(len(raw[:pos].rstrip()) for _, raw, pos in group)
        for idx, raw, pos in group:
            lhs = raw[:pos].rstrip()
            rest = raw[pos + 4:]  # everything after ' AS '
            new_raw = lhs.ljust(max_lhs) + pad + 'AS ' + rest
            ending = get_ending(lines[idx])
            new_line = new_raw + ending
            if new_line != lines[idx]:
                changed += 1
                result[idx] = new_line

    return result, changed


# ---------------------------------------------------------------------------
# Global comment-align pass: single comment column for entire file
# ---------------------------------------------------------------------------

def process_lines_align_global(lines: list[str], min_gap: int) -> tuple[list[str], int]:
    """Align inline comments file-wide, grouped by block and indent level.

    Rather than one giant column for the whole file, groups are broken at
    SUB/FUNCTION/TYPE/END boundaries and when the indent level changes.
    Within each group every commented line shares one comment column.
    Pure-comment lines and blank lines are left untouched.
    """
    # Build groups: each is a list of (index, raw, comment_pos)
    groups = []
    current = []
    current_indent = None

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()

        if _is_block_boundary(raw):
            if current:
                groups.append(current)
                current = []
            current_indent = None
            # Block boundary line itself may have an inline comment — add solo
            pos = find_comment_pos(raw)
            if pos != -1:
                groups.append([(i, raw, pos)])
            continue

        if not stripped or stripped.startswith("'"):
            # Pure comment or blank — skip, don't break the group
            continue

        pos = find_comment_pos(raw)
        if pos != -1:
            indent = len(raw) - len(raw.lstrip())
            if current_indent is None:
                current_indent = indent
            elif indent != current_indent:
                if current:
                    groups.append(current)
                current = []
                current_indent = indent
            current.append((i, raw, pos))
        # Lines with no comment don't break the group but don't join it

    if current:
        groups.append(current)

    if not groups:
        return list(lines), 0

    result = list(lines)
    changed = 0
    pad = ' ' * min_gap

    for group in groups:
        if not group:
            continue
        max_code = max(len(raw[:pos].rstrip()) for _, raw, pos in group)
        target = max_code + min_gap
        for idx, raw, pos in group:
            code = raw[:pos].rstrip()
            comment = raw[pos:]
            new_line = code.ljust(target) + comment + get_ending(lines[idx])
            if new_line != lines[idx]:
                changed += 1
                result[idx] = new_line

    return result, changed


# ---------------------------------------------------------------------------
# CASE-align pass: align CASE "KEY": assignment = value
# ---------------------------------------------------------------------------

def _align_case_groups(groups: list, lines: list[str], case_gap: int, eq_gap: int) -> tuple[list[str], int]:
    """Apply two-column alignment to a list of CASE groups.

    Column 1: the assignment start (after ':').
    Column 2: the '=' within the assignment.
    """
    result = list(lines)
    changed = 0

    for group in groups:
        if len(group) < 2:
            continue

        # --- Phase 1: align the ':' / assignment-start column ---
        max_label = max(len(raw[:pos + 1].rstrip()) for _, raw, pos in group)
        target_asgn = max_label + case_gap

        step1 = []  # (idx, rebuilt_raw)
        for idx, raw, pos in group:
            label = raw[:pos + 1].rstrip()       # '    CASE "KEY":'
            assignment = raw[pos + 1:].lstrip()  # 'THEME.field = val'
            new_raw = label.ljust(target_asgn) + assignment
            step1.append((idx, new_raw))

        # --- Phase 2: align '=' inside the assignment portion ---
        eq_info = []  # (idx, new_raw, eq_pos_local, asgn_lhs_len)
        for idx, new_raw in step1:
            asgn = new_raw[target_asgn:]
            eq_pos_local = find_eq_pos(asgn)
            if eq_pos_local != -1:
                asgn_lhs = asgn[:eq_pos_local].rstrip()
                eq_info.append((idx, new_raw, eq_pos_local, len(asgn_lhs)))
            else:
                eq_info.append((idx, new_raw, -1, 0))

        has_eq = [x for x in eq_info if x[2] != -1]
        if has_eq:
            max_asgn_lhs = max(x[3] for x in has_eq)
            eq_target = target_asgn + max_asgn_lhs + eq_gap
        else:
            eq_target = None

        for idx, new_raw, eq_pos_local, _ in eq_info:
            if eq_target is not None and eq_pos_local != -1:
                before_eq = new_raw[:target_asgn] + new_raw[target_asgn:target_asgn + eq_pos_local].rstrip()
                after_eq = new_raw[target_asgn + eq_pos_local + 1:].lstrip()
                final_raw = before_eq.ljust(eq_target) + '= ' + after_eq
            else:
                final_raw = new_raw

            ending = get_ending(lines[idx])
            new_line = final_raw + ending
            if new_line != lines[idx]:
                changed += 1
                result[idx] = new_line

    return result, changed


def process_lines_align_case(lines: list[str], case_gap: int = 1, eq_gap: int = 1) -> tuple[list[str], int]:
    """Section-aware CASE alignment: group by pure-comment / blank-line boundaries."""
    groups = []
    current = []

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()
        if not stripped or stripped.startswith("'"):
            if current:
                groups.append(current)
                current = []
        else:
            pos = find_case_colon_pos(raw)
            if pos != -1:
                current.append((i, raw, pos))
            elif current:
                groups.append(current)
                current = []
    if current:
        groups.append(current)

    return _align_case_groups(groups, lines, case_gap, eq_gap)


def process_lines_align_case_global(lines: list[str], case_gap: int = 1, eq_gap: int = 1) -> tuple[list[str], int]:
    """CASE alignment file-wide, but break groups at SUB/FUNCTION and SELECT CASE boundaries."""
    _CASE_BOUNDARY_PREFIXES = ('SELECT CASE', 'END SELECT', 'SUB ', 'FUNCTION ', 'END SUB', 'END FUNCTION')

    def _is_case_boundary(raw: str) -> bool:
        s = raw.strip().upper()
        return any(s == kw.rstrip() or s.startswith(kw) for kw in _CASE_BOUNDARY_PREFIXES)

    groups = []
    current = []
    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        if _is_case_boundary(raw):
            if current:
                groups.append(current)
                current = []
            continue
        pos = find_case_colon_pos(raw)
        if pos != -1:
            current.append((i, raw, pos))
        elif current:
            groups.append(current)
            current = []
    if current:
        groups.append(current)

    return _align_case_groups(groups, lines, case_gap, eq_gap)


# ---------------------------------------------------------------------------
# Colon (multi-statement) alignment
# ---------------------------------------------------------------------------

def find_all_colon_positions(line: str) -> list[int]:
    """Return positions of all ':' statement separators outside strings.

    Only returns positions where there is actual non-empty, non-comment
    content after the colon (ignores trailing bare ':').
    """
    positions: list[int] = []
    in_string = False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == '"':
            if in_string:
                if i + 1 < len(line) and line[i + 1] == '"':
                    i += 2
                    continue
                in_string = False
            else:
                in_string = True
        elif ch == ':' and not in_string:
            rest = line[i + 1:].strip()
            if rest and not rest.startswith("'"):
                positions.append(i)
        i += 1
    return positions


def _align_colon_groups(
    groups: list[list[tuple[int, str, list[int]]]],
    lines: list[str],
    colon_gap: int,
) -> tuple[list[str], int]:
    """Align ':' statement separators within each group."""
    result = list(lines)
    changed = 0

    for group in groups:
        if len(group) < 2:
            continue

        # Split each line into segments around ':' separators
        all_segs: list[tuple[int, list[str]]] = []
        for idx, raw, positions in group:
            segs: list[str] = []
            prev = 0
            for pos in positions:
                segs.append(raw[prev:pos])
                prev = pos + 1
            segs.append(raw[prev:])
            all_segs.append((idx, segs))

        max_colons = max(len(g[2]) for g in group)

        # Normalize segments for width measurement:
        #   slot 0: rstrip (preserves indentation)
        #   slot 1+: ' ' + stripped (normalise to 1 leading space)
        def _norm(s_idx: int, seg: str) -> str:
            if s_idx == 0:
                return seg.rstrip()
            stripped = seg.strip()
            return (' ' + stripped) if stripped else ''

        # Find max width of each colon slot
        slot_maxes: list[int] = []
        for s in range(max_colons):
            w = 0
            for _idx, segs in all_segs:
                if s < len(segs) - 1:
                    w = max(w, len(_norm(s, segs[s])))
            slot_maxes.append(w)

        # Rebuild each line
        for idx, segs in all_segs:
            parts: list[str] = []
            for s, seg in enumerate(segs):
                if s < len(segs) - 1:
                    n = _norm(s, seg)
                    if s < len(slot_maxes):
                        n = n.ljust(slot_maxes[s] + colon_gap)
                    parts.append(n + ':')
                else:
                    # Last segment — normalise leading space
                    stripped = seg.lstrip()
                    parts.append((' ' + stripped) if stripped else seg)
            new_raw = ''.join(parts)
            ending = get_ending(lines[idx])
            new_line = new_raw + ending
            if new_line != lines[idx]:
                changed += 1
                result[idx] = new_line

    return result, changed


def process_lines_align_colon(lines: list[str], colon_gap: int = 1) -> tuple[list[str], int]:
    """Section-aware colon alignment.

    Groups consecutive lines that each contain at least one ':' statement
    separator.  Blank lines and pure-comment lines break the current group.
    """
    groups: list[list[tuple[int, str, list[int]]]] = []
    current: list[tuple[int, str, list[int]]] = []

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()
        if not stripped or stripped.startswith("'"):
            if current:
                groups.append(current)
                current = []
            continue
        positions = find_all_colon_positions(raw)
        if positions:
            current.append((i, raw, positions))
        elif current:
            groups.append(current)
            current = []

    if current:
        groups.append(current)

    return _align_colon_groups(groups, lines, colon_gap)


def process_lines_align_colon_global(lines: list[str], colon_gap: int = 1) -> tuple[list[str], int]:
    """Block-boundary + indent-aware global colon alignment.

    Groups break at: block boundaries (SUB/FUNCTION/TYPE/END *),
    blank lines, and indentation-level changes.  Pure-comment lines are
    skipped but do NOT break the current group.
    """
    groups: list[list[tuple[int, str, list[int]]]] = []
    current: list[tuple[int, str, list[int]]] = []
    current_indent: int | None = None

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()

        if _is_block_boundary(raw):
            if current:
                groups.append(current)
                current = []
            current_indent = None
            continue

        if not stripped:
            if current:
                groups.append(current)
                current = []
            current_indent = None
            continue

        if stripped.startswith("'"):
            continue  # pure comment — skip but don't break group

        positions = find_all_colon_positions(raw)
        if positions:
            indent = len(raw) - len(raw.lstrip())
            if current_indent is None:
                current_indent = indent
            elif indent != current_indent:
                if current:
                    groups.append(current)
                current = []
                current_indent = indent
            current.append((i, raw, positions))
        elif current:
            groups.append(current)
            current = []
            current_indent = None

    if current:
        groups.append(current)

    return _align_colon_groups(groups, lines, colon_gap)


# ---------------------------------------------------------------------------
# Align mode: section-aware comment alignment
# ---------------------------------------------------------------------------

def process_lines_align(lines: list[str], min_gap: int) -> tuple[list[str], int]:
    """Section-aware comment alignment.

    Blank lines and pure-comment lines (e.g. ' --- Section ---') delimit
    sections.  Within each section, ALL commented lines are aligned to the
    same column — non-commented code lines don't break a section, they just
    don't participate in the alignment.
    """
    result = list(lines)  # mutable copy; we update by index
    changed = 0

    sections = []   # list of [(idx, raw, comment_pos), ...]
    current = []

    for i, orig in enumerate(lines):
        raw = orig.rstrip('\n').rstrip('\r')
        stripped = raw.strip()

        if not stripped or stripped.startswith("'"):
            # Section boundary
            if current:
                sections.append(current)
                current = []
        else:
            pos = find_comment_pos(raw)
            if pos != -1:
                current.append((i, raw, pos))
            # Non-commented code lines stay in the section but don't participate

    if current:
        sections.append(current)

    for section in sections:
        if len(section) < 2:
            continue
        max_code = max(len(raw[:pos].rstrip()) for _, raw, pos in section)
        target = max_code + min_gap
        for idx, raw, pos in section:
            code = raw[:pos].rstrip()
            comment = raw[pos:]
            new_line = code.ljust(target) + comment + get_ending(lines[idx])
            if new_line != lines[idx]:
                changed += 1
                result[idx] = new_line

    return result, changed


# ---------------------------------------------------------------------------
# Eq-align pass: align '=' within consecutive assignment groups
# ---------------------------------------------------------------------------

def process_lines_align_eq(lines: list[str], eq_gap: int = 1) -> tuple[list[str], int]:
    """Align '=' signs within consecutive assignment groups.

    Within each group, pads the LHS so all '=' land on the same column.
    Normalises spacing to eq_gap spaces before '=' and 1 space after.
    Lines that are blank, pure comments, or have no '=' break a group.
    """
    result = []
    changed = 0
    i = 0
    n = len(lines)

    while i < n:
        group = []  # (index, raw_stripped, eq_pos)

        while i < n:
            raw = lines[i].rstrip('\n').rstrip('\r')
            pos = find_eq_pos(raw)
            if pos == -1:
                break
            group.append((i, raw, pos))
            i += 1

        if not group:
            result.append(lines[i])
            i += 1
            continue

        max_lhs = max(len(raw[:pos].rstrip()) for _, raw, pos in group)
        pad = ' ' * eq_gap

        for idx, raw, pos in group:
            lhs = raw[:pos].rstrip()
            rhs = raw[pos + 1:].lstrip()
            new_raw = lhs.ljust(max_lhs) + pad + '= ' + rhs
            ending = get_ending(lines[idx])
            new_line = new_raw + ending
            if new_line != lines[idx]:
                changed += 1
            result.append(new_line)

    return result, changed


# ---------------------------------------------------------------------------
# AS-align pass: align 'AS' within consecutive TYPE/DIM declaration groups
# ---------------------------------------------------------------------------

def process_lines_align_as(lines: list[str], as_gap: int = 1) -> tuple[list[str], int]:
    """Align the 'AS' keyword within consecutive TYPE/DIM declaration groups.

    Within each group, pads the field/variable name so all 'AS' keywords
    land on the same column. Blank lines, pure comments, and lines with no
    ' AS ' break a group.
    """
    result = []
    changed = 0
    i = 0
    n = len(lines)

    while i < n:
        group = []  # (index, raw, as_pos)

        while i < n:
            raw = lines[i].rstrip('\n').rstrip('\r')
            pos = find_as_pos(raw)
            if pos == -1:
                break
            group.append((i, raw, pos))
            i += 1

        if not group:
            if i < n:
                result.append(lines[i])
                i += 1
            continue

        max_lhs = max(len(raw[:pos].rstrip()) for _, raw, pos in group)
        pad = ' ' * as_gap

        for idx, raw, pos in group:
            lhs = raw[:pos].rstrip()
            rest = raw[pos + 4:]  # everything after ' AS '
            new_raw = lhs.ljust(max_lhs) + pad + 'AS ' + rest
            ending = get_ending(lines[idx])
            new_line = new_raw + ending
            if new_line != lines[idx]:
                changed += 1
            result.append(new_line)

    return result, changed


def process_lines(
    lines: list[str],
    min_gap: int,
    mode: str = 'compact',
    align_eq: bool = False,
    eq_gap: int = 1,
    align_as: bool = False,
    as_gap: int = 1,
    align_case: bool = False,
    case_gap: int = 1,
    align_colon: bool = False,
    colon_gap: int = 1,
    global_align: bool = False,
) -> tuple[list[str], int]:
    total_changed = 0

    if align_eq:
        lines, c = process_lines_align_eq(lines, eq_gap)
        total_changed += c

    if align_as:
        if global_align:
            lines, c = process_lines_align_as_global(lines, as_gap)
        else:
            lines, c = process_lines_align_as(lines, as_gap)
        total_changed += c

    if align_case:
        if global_align:
            lines, c = process_lines_align_case_global(lines, case_gap, eq_gap)
        else:
            lines, c = process_lines_align_case(lines, case_gap, eq_gap)
        total_changed += c

    if align_colon:
        if global_align:
            lines, c = process_lines_align_colon_global(lines, colon_gap)
        else:
            lines, c = process_lines_align_colon(lines, colon_gap)
        total_changed += c

    if global_align:
        lines, c = process_lines_align_global(lines, min_gap)
    elif mode == 'align':
        lines, c = process_lines_align(lines, min_gap)
    else:
        lines, c = process_lines_compact(lines, min_gap)
    total_changed += c

    return lines, total_changed


# ---------------------------------------------------------------------------
# File handling
# ---------------------------------------------------------------------------

def process_file(
    path: str,
    min_gap: int,
    mode: str,
    align_eq: bool,
    eq_gap: int,
    align_as: bool,
    as_gap: int,
    align_case: bool,
    case_gap: int,
    align_colon: bool,
    colon_gap: int,
    global_align: bool,
    dry_run: bool,
    backup: bool,
) -> int:
    """Process one file. Returns number of lines changed."""
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except OSError as e:
        print(f"  ERROR reading {path}: {e}", file=sys.stderr)
        return 0

    new_lines, changed = process_lines(
        lines, min_gap, mode, align_eq, eq_gap, align_as, as_gap, align_case, case_gap,
        align_colon, colon_gap, global_align
    )

    if changed == 0:
        return 0

    if dry_run:
        print(f"  [dry-run] {path}: {changed} line(s) would change")
        return changed

    if backup:
        shutil.copy2(path, path + '.orig')

    try:
        with open(path, 'w', encoding='utf-8', errors='replace') as f:
            f.writelines(new_lines)
    except OSError as e:
        print(f"  ERROR writing {path}: {e}", file=sys.stderr)
        return 0

    print(f"  {path}: {changed} line(s) updated")
    return changed


# ---------------------------------------------------------------------------
# Directory scanning
# ---------------------------------------------------------------------------

def collect_files(paths: list[str], extensions: set[str]) -> list[str]:
    """Expand paths to individual files, recursing into directories."""
    result = []
    for p in paths:
        if os.path.isfile(p):
            result.append(p)
        elif os.path.isdir(p):
            for root, dirs, files in os.walk(p):
                # Skip hidden directories and common non-source dirs
                dirs[:] = [d for d in dirs if not d.startswith('.')]
                for fname in files:
                    ext = os.path.splitext(fname)[1].lstrip('.').lower()
                    if ext in extensions:
                        result.append(os.path.join(root, fname))
        else:
            print(f"Warning: {p!r} not found, skipping", file=sys.stderr)
    return result


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Align inline QB64 comments to a common column per block.",
        add_help=False,
    )
    parser.add_argument('paths', nargs='*', default=[])
    parser.add_argument('--mode', default='align', choices=['compact', 'align'])
    parser.add_argument('--align-eq', action='store_true', default=True)
    parser.add_argument('--no-align-eq', dest='align_eq', action='store_false')
    parser.add_argument('--align-as', action='store_true', default=True)
    parser.add_argument('--no-align-as', dest='align_as', action='store_false')
    parser.add_argument('--align-case', action='store_true', default=True)
    parser.add_argument('--no-align-case', dest='align_case', action='store_false')
    parser.add_argument('--align-colon', action='store_true', default=True)
    parser.add_argument('--no-align-colon', dest='align_colon', action='store_false')
    parser.add_argument('--global', dest='global_align', action='store_true', default=True)
    parser.add_argument('--no-global', dest='global_align', action='store_false')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--no-backup', action='store_true', default=True)
    parser.add_argument('--backup', dest='no_backup', action='store_false')
    parser.add_argument('--min-gap', type=int, default=1, metavar='N')
    parser.add_argument('--eq-gap', type=int, default=1, metavar='N')
    parser.add_argument('--as-gap', type=int, default=1, metavar='N')
    parser.add_argument('--case-gap', type=int, default=1, metavar='N')
    parser.add_argument('--colon-gap', type=int, default=1, metavar='N')
    parser.add_argument('--ext', default='bas,bi,bm', metavar='E[,E...]')
    parser.add_argument('--help', '-h', action='store_true')
    args = parser.parse_args()

    if args.help or not args.paths:
        print(__doc__)
        sys.exit(0)

    extensions = {e.strip().lower() for e in args.ext.split(',')}
    files = collect_files(args.paths, extensions)

    if not files:
        print("No matching files found.")
        sys.exit(0)

    total_files = 0
    total_lines = 0

    for path in sorted(files):
        changed = process_file(
            path,
            min_gap=args.min_gap,
            mode=args.mode,
            align_eq=args.align_eq,
            eq_gap=args.eq_gap,
            align_as=args.align_as,
            as_gap=args.as_gap,
            align_case=args.align_case,
            case_gap=args.case_gap,
            align_colon=args.align_colon,
            colon_gap=args.colon_gap,
            global_align=args.global_align,
            dry_run=args.dry_run,
            backup=not args.no_backup,
        )
        if changed:
            total_files += 1
            total_lines += changed

    label = "would change" if args.dry_run else "changed"
    print(f"\nDone: {total_files} file(s), {total_lines} line(s) {label}.")


if __name__ == '__main__':
    main()
