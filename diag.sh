#!/bin/bash
# Collects screen saver diagnostics into diag.log (and crash-latest.ips, if any).
# Usage: ./diag.sh [minutes]   (default: 20)
cd "$(dirname "$0")"
MIN="${1:-20}"
{
  echo "== macOS"; sw_vers
  echo; echo "== Screen saver settings"
  defaults -currentHost read com.apple.screensaver 2>&1 | head -40
  echo; echo "== Log of the last $MIN minutes"
  log show --last "${MIN}m" --style compact --predicate \
    'subsystem == "de.wanner-it.wortuhr" OR ((process CONTAINS[c] "screensaver" OR process CONTAINS[c] "ScreenSaver") AND (messageType == error OR messageType == fault))' \
    2>&1 | tail -600
  echo; echo "== Crash reports"
  ls -lt ~/Library/Logs/DiagnosticReports 2>/dev/null | grep -i -E "legacyScreenSaver|Wortuhr|ScreenSaver" | head
} > diag.log 2>&1
newest=$(ls -t ~/Library/Logs/DiagnosticReports/*egacyScreenSaver* 2>/dev/null | head -1)
[ -n "$newest" ] && cp "$newest" ./crash-latest.ips
echo "✓ diag.log written"
