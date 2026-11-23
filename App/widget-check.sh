#!/bin/bash
# Checks the Wortuhr widgets on this Mac: which app provides them, which timelines macOS accepted
# or rejected (with size and number of entries), and when the Mac slept and woke up.
# Writes App/widget-check.log.   Usage: App/widget-check.sh [hours]   (default: 3)
cd "$(dirname "$0")"
H="${1:-3}"
RELOADS=$(log show --last "${H}h" --style compact --predicate \
  'process == "chronod" AND eventMessage CONTAINS "wordclock" AND eventMessage CONTAINS "on local reload"' 2>&1 \
  | grep -E "succeeded|too large" \
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
  echo; echo "== Sleep and wake (last 30)"
  pmset -g log | grep -E " (Sleep|Wake|DarkWake) " | tail -30
} > widget-check.log 2>&1
echo "✓ App/widget-check.log written"
