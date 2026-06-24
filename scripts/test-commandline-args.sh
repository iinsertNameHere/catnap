#!/usr/bin/env bash
# Tests all CLI flags against test_config.cat.
# Run from the scripts/ directory: ./test-commandline-args.sh

set -euo pipefail

CATNAP="./../bin/catnap"
CFG="./test_config.cat"
PASS=0
FAIL=0

run() {
    local desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        echo "OK    $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL  $desc"
        echo "      command: $*"
        FAIL=$((FAIL + 1))
    fi
}

run "Normal run"            $CATNAP -c $CFG -n
run "Help"                  $CATNAP -c $CFG -h -n
run "Version"               $CATNAP -c $CFG -v
run "DistroId (arch)"       $CATNAP -c $CFG -d arch -n
run "DistroId (void)"       $CATNAP -c $CFG -d void -n
run "Grep: kernel"          $CATNAP -c $CFG -g kernel
run "Grep: memory"          $CATNAP -c $CFG -g memory
run "Grep: disk_0"          $CATNAP -c $CFG -g disk_0
run "Grep: disks"           $CATNAP -c $CFG -g disks
run "Margin"                $CATNAP -c $CFG -m 1,2,3 -n
run "Layout: ArtOnTop"      $CATNAP -c $CFG -l ArtOnTop -n
run "Layout: StatsOnTop"    $CATNAP -c $CFG -l StatsOnTop -n
run "Layout: Inline"        $CATNAP -c $CFG -l Inline -n
run "Default config"        $CATNAP -c ../config/config.cat -n

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
