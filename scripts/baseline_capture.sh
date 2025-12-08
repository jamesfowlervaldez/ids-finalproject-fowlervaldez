#!/bin/bash

# === Baseline Screenshot Capture ===
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="../screenshots/baseline"
LOG_FILE="../logs/baseline.log"
FILENAME="baseline_$TIMESTAMP.png"

mkdir -p "$OUTPUT_DIR"

echo "[+] Capturing baseline screenshot..."
scrot "$OUTPUT_DIR/$FILENAME"

if [ -f "$OUTPUT_DIR/$FILENAME" ]; then
    echo "$TIMESTAMP : Baseline screenshot saved as $FILENAME" | tee -a "$LOG_FILE"
else
    echo "$TIMESTAMP : ERROR - Baseline screenshot failed." | tee -a "$LOG_FILE"
fi
