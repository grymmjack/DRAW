#!/usr/bin/env bash
set -e

WIKI_DIR="/home/grymmjack/git/DRAW.wiki"
DOCS_DIR="$(cd "$(dirname "$0")/../docs/MANUAL" && pwd)"
REPO="grymmjack/DRAW"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}/docs/MANUAL/images"
RAW_ASSETS="https://raw.githubusercontent.com/${REPO}/${BRANCH}/ASSETS"
RAW_DOCS="https://raw.githubusercontent.com/${REPO}/${BRANCH}/docs"
CHEATSHEET_URL="https://github.com/${REPO}/blob/${BRANCH}/CHEATSHEET.md"

APP_VERSION=$(grep -m1 'APP_VERSION\$' "$(dirname "$0")/../_COMMON.BI" | sed 's/.*"\(.*\)".*/\1/')
TODAY=$(date +%Y-%m-%d)

cd "$WIKI_DIR"
git pull

# Convert filename slug to "01 - Proper Case Title"
# e.g. "03-color-palette" → "03 - Color Palette"
format_title() {
    local name="$1"
    local num="${name%%-*}"
    local rest="${name#*-}"
    local title
    title=$(echo "$rest" | sed 's/-/ /g' | \
        awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')
    echo "${num} - ${title}"
}

# Build sed expressions to rewrite slug-style links to URL-encoded formatted titles.
# Handles both bare slugs (Next/Back links) and MANUAL/-prefixed slugs (Home.md ToC).
# e.g. ](03-color-palette.md)      → ](03%20-%20Color%20Palette)
#      ](MANUAL/03-color-palette.md) → ](03%20-%20Color%20Palette)
build_link_rewrites() {
    for f in "$DOCS_DIR"/[0-9]*.md; do
        local old_slug
        old_slug=$(basename "$f" .md)
        local new_title encoded_title
        new_title=$(format_title "$old_slug")
        encoded_title="${new_title// /%20}"
        # bare slug (with or without .md)
        echo "-e s|]($old_slug\\.md)|]($encoded_title)|g"
        echo "-e s|]($old_slug)|]($encoded_title)|g"
        # MANUAL/-prefixed slug (Home.md ToC)
        echo "-e s|](MANUAL/$old_slug\\.md)|]($encoded_title)|g"
    done
}

# Collect link-rewrite args into an array
mapfile -t LINK_REWRITES < <(build_link_rewrites)

# Rewrite a source .md for GitHub wiki:
#   - images/foo.png        → raw GitHub URL
#   - MANUAL/images/foo.png → raw GitHub URL (used in MANUAL.md / Home)
#   - ../ASSETS/foo.png     → raw GitHub URL
#   - ../../CHEATSHEET.md   → absolute GitHub URL
#   - ../MANUAL.md          → Home
#   - foo.md links          → foo  (no .md extension in wiki)
#   - old slug links        → new formatted title links
rewrite_for_wiki() {
    local src="$1"
    local dst="$2"
    sed \
        -e "s|](images/\([^)]*\))|](${RAW_BASE}/\1)|g" \
        -e "s|src=\"images/\([^\"]*\)\"|src=\"${RAW_BASE}/\1\"|g" \
        -e "s|](MANUAL/images/\([^)]*\))|](${RAW_DOCS}/MANUAL/images/\1)|g" \
        -e "s|src=\"MANUAL/images/\([^\"]*\)\"|src=\"${RAW_DOCS}/MANUAL/images/\1\"|g" \
        -e "s|](../ASSETS/\([^)]*\))|](${RAW_ASSETS}/\1)|g" \
        -e "s|src=\"\.\./ASSETS/\([^\"]*\)\"|src=\"${RAW_ASSETS}/\1\"|g" \
        -e "s|](../../CHEATSHEET\.md)|](${CHEATSHEET_URL})|g" \
        -e 's|](../MANUAL\.md)|](Home)|g' \
        "${LINK_REWRITES[@]}" \
        -e 's|](\([^):]*\)\.md)|](\1)|g' \
        "$src" | \
    sed \
        -e "s|{{VERSION}}|${APP_VERSION}|g" \
        -e "s|{{DATE}}|${TODAY}|g" \
        > "$dst"
}

# Remove old slug-named chapter files so renamed ones don't accumulate
rm -f "$WIKI_DIR"/[0-9]*.md

# Copy and rewrite chapter files, named with the formatted title
for f in "$DOCS_DIR"/[0-9]*.md; do
    slug=$(basename "$f" .md)
    title=$(format_title "$slug")
    rewrite_for_wiki "$f" "$WIKI_DIR/${title}.md"
done

# Home page from MANUAL.md
rewrite_for_wiki "$(dirname "$DOCS_DIR")/MANUAL.md" "$WIKI_DIR/Home.md"

# Generate _Sidebar.md
{
    echo "## DRAW Manual"
    echo ""
    for f in "$WIKI_DIR"/[0-9]*.md; do
        title=$(basename "$f" .md)
        echo "- [[$title]]"
    done
} > "$WIKI_DIR/_Sidebar.md"

git add -A
git commit -m "Sync manual v${APP_VERSION} from docs/ [${TODAY}]" || echo "Nothing to commit"
git push