#!/bin/bash
# Sammelt Diagnose zum Bildschirmschoner in diag.log (und ggf. crash-latest.ips).
# Aufruf: ./diag.sh [Minuten]   (Standard: 20)
cd "$(dirname "$0")"
MIN="${1:-20}"
{
  echo "== macOS"; sw_vers
  echo; echo "== Bildschirmschoner-Einstellungen"
  defaults -currentHost read com.apple.screensaver 2>&1 | head -40
  echo; echo "== Protokoll der letzten $MIN Minuten"
  log show --last "${MIN}m" --style compact --predicate \
    'subsystem == "de.wanner-it.wortuhr" OR ((process CONTAINS[c] "screensaver" OR process CONTAINS[c] "ScreenSaver") AND (messageType == error OR messageType == fault))' \
    2>&1 | tail -600
  echo; echo "== Absturzberichte"
  ls -lt ~/Library/Logs/DiagnosticReports 2>/dev/null | grep -i -E "legacyScreenSaver|Wortuhr|ScreenSaver" | head
} > diag.log 2>&1
newest=$(ls -t ~/Library/Logs/DiagnosticReports/*egacyScreenSaver* 2>/dev/null | head -1)
[ -n "$newest" ] && cp "$newest" ./crash-latest.ips
echo "✓ diag.log geschrieben"
