#!/usr/bin/env bash
# run_sast.sh — Static analysis harness for a MIT krb5 source tree.
# Runs cppcheck + flawfinder and writes machine-readable reports.
#
#   ./run_sast.sh /path/to/krb5/src ../reports
#
# Requires: cppcheck, flawfinder (pip install flawfinder).
set -euo pipefail
SRC="${1:?usage: run_sast.sh <src-dir> [out-dir]}"
OUT="${2:-../reports}"
mkdir -p "$OUT"

echo "[*] cppcheck -> $OUT/cppcheck.xml"
cppcheck --enable=warning,style,performance,portability \
  --inconclusive --xml --xml-version=2 "$SRC" 2> "$OUT/cppcheck.xml" || true

echo "[*] flawfinder -> $OUT/flawfinder.txt"
flawfinder --minlevel=2 "$SRC" > "$OUT/flawfinder.txt" || true

echo "[*] SAST complete. Reports in $OUT/"
