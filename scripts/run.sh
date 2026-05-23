#!/usr/bin/env bash
# =============================================================================
# Compile + run the m_fifo simulation. Optionally open GTKWave.
#
# Usage:
#   run.sh                       # compile + run
#   run.sh --gtk                 # compile + run + open GTKWave
#   run.sh --clean               # wipe sim/ before building
#   run.sh --help                # show this help
#
# Layout this script assumes:
#   m-fifo/rtl/      -> RTL sources (m_fifo.v)
#   m-fifo/tb/       -> testbenches (fifo_tb.v)
#   m-fifo/sim/      -> output dir (simv binary + *.vcd) — gitignored
#   m-fifo/waves/    -> GTKWave save files (.gtkw)
#
# Dependencies on sibling repos (expected layout under the parent dir):
#   ../m-ff/rtl/m_ff.v
#   ../m-assert/m_assert.v
# =============================================================================

set -euo pipefail

# Resolve paths relative to this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
REPO_ROOT="$( cd "$MODULE_DIR/.." && pwd )"

SIM_DIR="$MODULE_DIR/sim"
RTL_DIR="$MODULE_DIR/rtl"
TB_DIR="$MODULE_DIR/tb"
WAVES_DIR="$MODULE_DIR/waves"

# Defaults
OPEN_GTK=0
CLEAN=0

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gtk)   OPEN_GTK=1; shift ;;
        --clean) CLEAN=1; shift ;;
        --help|-h) usage ;;
        *) echo "ERROR: unknown flag '$1' (try --help)" >&2; exit 2 ;;
    esac
done

TB_FILE="$TB_DIR/fifo_tb.v"
GTKW_FILE="$WAVES_DIR/fifo.gtkw"
VCD_FILE="$SIM_DIR/tb.vcd"

SOURCES=(
    "$REPO_ROOT/m-ff/rtl/m_ff.v"
    "$REPO_ROOT/m-assert/m_assert.v"
    "$RTL_DIR/m_fifo.v"
    "$TB_FILE"
)

mkdir -p "$SIM_DIR"

if (( CLEAN )); then
    echo "[run.sh] cleaning $SIM_DIR"
    rm -f "$SIM_DIR"/simv "$SIM_DIR"/*.vcd
fi

SIMV="$SIM_DIR/simv"

echo "[run.sh] compiling iverilog -> $SIMV"
( cd "$SIM_DIR" && iverilog -g2012 -o "$SIMV" "${SOURCES[@]}" )

echo "[run.sh] running vvp"
( cd "$SIM_DIR" && vvp "$SIMV" )

if (( OPEN_GTK )); then
    if [[ ! -f "$VCD_FILE" ]]; then
        echo "[run.sh] WARNING: expected VCD not found at $VCD_FILE — opening gtkwave without it"
        gtkwave "$GTKW_FILE" >/dev/null 2>&1 &
    elif [[ ! -f "$GTKW_FILE" ]]; then
        echo "[run.sh] NOTE: no save file at $GTKW_FILE — opening gtkwave with VCD only"
        gtkwave "$VCD_FILE" >/dev/null 2>&1 &
    else
        echo "[run.sh] opening gtkwave with $(basename "$GTKW_FILE") and $(basename "$VCD_FILE")"
        gtkwave "$VCD_FILE" "$GTKW_FILE" >/dev/null 2>&1 &
    fi
fi
