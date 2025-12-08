#!/bin/bash

# === Compare Current Screenshot Against Baseline ===

BASELINE_DIR="../screenshots/baseline"
CURRENT_DIR="../screenshots/current"
LOG_FILE="../logs/comparison.log"

mkdir -p "$CURRENT_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CURRENT_FILE="$CURRENT_DIR/current_$TIMESTAMP.png"

echo "[+] Capturing current screenshot..."
scrot "$CURRENT_FILE"

# Get the most recent baseline screenshot
LATEST_BASELINE=$(ls -t "$BASELINE_DIR"/*.png 2>/dev/null | head -1)

if [ -z "$LATEST_BASELINE" ]; then
    echo "$TIMESTAMP : ERROR - No baseline screenshot found." | tee -a "$LOG_FILE"
    exit 1
fi

BASE_HASH=$(md5sum "$LATEST_BASELINE" | awk '{print $1}')
CURR_HASH=$(md5sum "$CURRENT_FILE" | awk '{print $1}')

echo "[+] Comparing baseline and current images..."

if [ "$BASE_HASH" = "$CURR_HASH" ]; then
    echo "$TIMESTAMP : MATCH - No visual changes detected." | tee -a "$LOG_FILE"
else
    echo "$TIMESTAMP : ALERT - Visual system change detected!" | tee -a "$LOG_FILE"
fi
