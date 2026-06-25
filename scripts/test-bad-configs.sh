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
$layout  = "inline"
' "required variable '\$stats' is not defined"

run_bad "missing \$distros" '
$stats  = []
$layout = "inline"
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

run_bad "invalid \$border_style" '
$stats        = []
$distros      = []
$layout       = "inline"
$border_style = "invalid"
' '$border_style must be one of'

run_bad "\$stats_margin_top not a number" '
$stats            = []
$distros          = []
$layout           = "inline"
$stats_margin_top = "nope"
' "'\$stats_margin_top' has wrong type"

# ------------------------------------------------------------------
# Stat entry validation
# ------------------------------------------------------------------

run_bad "stat missing icon" '
$stats   = [@{id="username" name="user" color=$red}]
$distros = []
$layout  = "inline"
' "missing required field 'icon'"

run_bad "stat missing name" \
$'$stats   = [@{id="username" icon=\'\' color=$red}]\n$distros = []\n$layout  = "inline"' \
"missing required field 'name'"

run_bad "stat missing color" \
$'$stats   = [@{id="username" icon=\'\' name="user"}]\n$distros = []\n$layout  = "inline"' \
"missing required field 'color'"

run_bad "separator enabled wrong type" '
$stats   = [@{id="separator" enabled="yes"}]
$distros = []
$layout  = "inline"
' "field 'enabled' has wrong type"

run_bad "icon is a string not char" '
$stats   = [@{id="username" icon="nf-fa-user" name="user" color=$red}]
$distros = []
$layout  = "inline"
' "field 'icon' has wrong type"

run_bad "symbol is a string not char" \
$'$stats   = [@{id="colors" icon=\'\' name="colors" color=$reset symbol="circle"}]\n$distros = []\n$layout  = "inline"' \
"field 'symbol' has wrong type"

# ------------------------------------------------------------------
# Art block validation
# ------------------------------------------------------------------

run_bad "distro art with no lines" '
$stats   = []
$distros = [%{id="myos" art=[]}]
$layout  = "inline"
' "must have at least one art line"

# ------------------------------------------------------------------
# Variable resolution errors
# ------------------------------------------------------------------

run_bad "undefined variable reference" \
$'$stats   = [@{id="username" icon=\'\' name="user" color=$undefined_color}]\n$distros = []\n$layout  = "inline"' \
"undefined variable"

run_bad "circular variable reference" \
$'$a = $b\n$b = $a\n$stats = []\n$distros = []\n$layout = "inline"' \
"circular variable reference"

run_bad "import non-existent file" \
$'import "does_not_exist.cat"\n$stats = []\n$distros = []\n$layout = "inline"' \
"imported file not found"

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
