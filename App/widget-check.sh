#!/bin/bash
# Checks the Wortuhr widgets on this Mac: which app provides them and which timelines macOS accepted
# or rejected (with size and number of entries). A rejection ("too large") is always logged; the line
# with the number of accepted entries is sometimes missing from the log.
# Writes App/widget-check.log.   Usage: bash App/widget-check.sh [hours]   (default: 12)
cd "$(dirname "$0")"
H="${1:-12}"
RAW=$(log show --info --last "${H}h" --style compact --predicate \
  'process == "chronod" AND eventMessage CONTAINS[c] "wordclock" AND eventMessage CONTAINS "local reload"' 2>&1)
RELOADS=$(grep -E "succeeded|too large" <<< "$RAW" \
  | sed -E 's/\[de\.wanner-it\.wordclock::de\.wanner-it\.wordclock\.widget:Wortuhr:([A-Za-z]+):[-0-9]+:([0-9.]+)\/([0-9.]+)[^]]*\]/\1 \2x\3/; s/ Df chronod\[[^]]*\]//; s/ E  chronod\[[^]]*\]//; s/\[com\.apple\.chrono:timeline\.store\] //')
{
  echo "== macOS"; sw_vers
  echo; echo "== Wortuhr apps on this Mac"
  mdfind "kMDItemCFBundleIdentifier == 'de.wanner-it.wordclock'" 2>/dev/null | while read -r p; do
    v=$(defaults read "$p/Contents/Info" CFBundleShortVersionString 2>/dev/null)
    b=$(defaults read "$p/Contents/Info" CFBundleVersion 2>/dev/null)
    echo "$p  –  $v ($b)"
  done
  echo; echo "== Running widget process"
  pgrep -lf WortuhrWidget || echo "none"
  echo; echo "== Timelines in the last $H hours"
  echo "accepted: $(grep -c succeeded <<< "$RELOADS")   rejected as too large: $(grep -c 'too large' <<< "$RELOADS")"
  echo
  echo "$RELOADS"
  echo; echo "== Raw log lines found: $(grep -c . <<< "$RAW") (first 5)"
  head -5 <<< "$RAW" | cut -c1-200
} > widget-check.log 2>&1
echo "✓ App/widget-check.log written"
