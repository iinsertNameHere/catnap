#!/usr/bin/env bash
# Tests that bad config files exit with an error instead of crashing.
# Run from project root: cd scripts && ./test-bad-configs.sh

set -euo pipefail

CATNAP="${1:-./../bin/catnap}"
TMPDIR="$(mktemp -d)"
PASS=0
FAIL=0

trap 'rm -rf "$TMPDIR"' EXIT

run_bad() {
    local desc="$1"
    local cfg="$2"
    local expect_msg="$3"

    printf '%s' "$cfg" > "$TMPDIR/test.cat"

    local output exit_code
    output=$("$CATNAP" -c "$TMPDIR/test.cat" 2>&1) && exit_code=0 || exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        echo "FAIL  $desc"
        echo "      expected non-zero exit, got 0"
        [ -n "$output" ] && echo "$output" | sed 's/^/      | /'
        FAIL=$((FAIL + 1))
        return
    fi

    if [ -n "$expect_msg" ] && ! echo "$output" | grep -qF "$expect_msg"; then
        echo "FAIL  $desc"
        echo "      expected: $expect_msg"
        [ -n "$output" ] && echo "$output" | sed 's/^/      | /'
        FAIL=$((FAIL + 1))
        return
    fi

    echo "OK    $desc"
    PASS=$((PASS + 1))
}

# ------------------------------------------------------------------
# Missing required top-level variables
# ------------------------------------------------------------------

run_bad "missing \$stats" '
$distros = []
$layout  = "Inline"
' "required variable '\$stats' is not defined"

run_bad "missing \$distros" '
$stats  = []
$layout = "Inline"
' "required variable '\$distros' is not defined"

run_bad "missing \$layout" '
$stats   = []
$distros = []
' "required variable '\$layout' is not defined"

# ------------------------------------------------------------------
# Invalid top-level values
# ------------------------------------------------------------------

run_bad "empty \$layout" '
$stats   = []
$distros = []
$layout  = ""
' '$layout must be one of'

run_bad "invalid \$layout value" '
$stats   = []
$distros = []
$layout  = "Bogus"
' '$layout must be one of'

run_bad "invalid \$borderstyle" '
$stats       = []
$distros     = []
$layout      = "Inline"
$borderstyle = "invalid"
' '$borderstyle must be one of'

run_bad "\$stats_margin_top not a number" '
$stats            = []
$distros          = []
$layout           = "Inline"
$stats_margin_top = "nope"
' '$stats_margin_top must be a number'

# ------------------------------------------------------------------
# Stat entry validation
# ------------------------------------------------------------------

run_bad "stat missing icon" '
$stats   = [{@username name="user" color=$red}]
$distros = []
$layout  = "Inline"
' "missing required field: icon"

run_bad "stat missing name" '
$stats   = [{@username icon='"'"''"'"' color=$red}]
$distros = []
$layout  = "Inline"
' "missing required field: name"

run_bad "stat missing color" '
$stats   = [{@username icon='"'"''"'"' name="user"}]
$distros = []
$layout  = "Inline"
' "missing required field: color"

run_bad "separator missing color" '
$stats   = [{@separator}]
$distros = []
$layout  = "Inline"
' "missing required field: color"

run_bad "icon is a string not char" \
$'$stats   = [{@username icon="nf-fa-user" name="user" color=$red}]\n$distros = []\n$layout  = "Inline"' \
"'icon' must be a char literal"

run_bad "symbol is a string not char" \
$'$stats   = [{@colors icon=\'\' name="colors" color=$reset symbol="circle"}]\n$distros = []\n$layout  = "Inline"' \
"'symbol' must be a char literal"

# ------------------------------------------------------------------
# Art block validation
# ------------------------------------------------------------------

run_bad "distro art with no lines" \
$'$stats   = []\n$distros = [{%myos []}]\n$layout  = "Inline"' \
"must have at least one art line"

# ------------------------------------------------------------------
# Variable resolution errors
# ------------------------------------------------------------------

run_bad "undefined variable reference" \
$'$stats   = [{@username icon=\'\' name="user" color=$undefined_color}]\n$distros = []\n$layout  = "Inline"' \
"undefined variable"

run_bad "circular variable reference" \
$'$a = $b\n$b = $a\n$stats = []\n$distros = []\n$layout = "Inline"' \
"circular variable reference"

run_bad "import non-existent file" \
$'import "does_not_exist.cat"\n$stats = []\n$distros = []\n$layout = "Inline"' \
"imported file not found"

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
