#!/bin/bash

# Load IDS configuration (thresholds, capture duration)
CONFIG_FILE="../ids_config.conf"

if [ -f "$CONFIG_FILE" ]; then
    # Load variables: CAPTURE_DURATION, SYN_THRESHOLD, HTTP_THRESHOLD, SSH_THRESHOLD
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
else
    # Fallback defaults if config file is missing
    CAPTURE_DURATION=10
    SYN_THRESHOLD=20
    HTTP_THRESHOLD=5
    SSH_THRESHOLD=5
fi

# === Unified Host-Based IDS Analyzer ===

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_DIR="../reports"
LOG_FILE="../logs/unified.log"
REPORT_FILE="$REPORT_DIR/report_$TIMESTAMP.txt"

mkdir -p "$REPORT_DIR"

echo "===== IDS Analysis Report ($TIMESTAMP) =====" | tee "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# ---------- 1. SYN scan detection ----------
echo "[1] Checking for SYN scan attempts (${CAPTURE_DURATION}-second capture)..." | tee -a "$REPORT_FILE"

SYN_COUNT=$(sudo tshark -i any -Y "tcp.flags.syn==1 && tcp.flags.ack==0" -a duration:$CAPTURE_DURATION 2>/dev/null | wc -l)

if [ "$SYN_COUNT" -gt "$SYN_THRESHOLD" ]; then
    echo "ALERT: Possible SYN scan detected ($SYN_COUNT SYN packets in ${CAPTURE_DURATION} seconds)." | tee -a "$REPORT_FILE"
else
    echo "OK: No evidence of SYN scan (only $SYN_COUNT SYN packets in ${CAPTURE_DURATION} seconds)." | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

# ---------- 2. Suspicious HTTP POST activity ----------
echo "[2] Checking for suspicious HTTP POST requests (${CAPTURE_DURATION}-second capture)..." | tee -a "$REPORT_FILE"

HTTP_COUNT=$(sudo tshark -i any -Y "http.request.method == \"POST\"" -a duration:$CAPTURE_DURATION 2>/dev/null | wc -l)

if [ "$HTTP_COUNT" -gt "$HTTP_THRESHOLD" ]; then
    echo "ALERT: High number of HTTP POST requests detected ($HTTP_COUNT in ${CAPTURE_DURATION} seconds)." | tee -a "$REPORT_FILE"
else
    echo "OK: HTTP POST activity within normal range ($HTTP_COUNT in ${CAPTURE_DURATION} seconds)." | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

# ---------- 3. Screenshot comparison ----------
echo "[3] Running visual integrity check (baseline vs current)..." | tee -a "$REPORT_FILE"

COMPARE_OUTPUT=$(./compare_screenshot.sh 2>&1 | tail -n 1)
echo "$COMPARE_OUTPUT" | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"

# ------- 4. SSH brute-force attempts --------------
echo "[4] Checking for possible SSH brute-force attempts..." | tee -a "$REPORT_FILE"

AUTH_LOG="/var/log/auth.log"

# Count 'Failed password' in the last 100 lines of auth.log
SSH_COUNT=$(sudo tail -n 100 "$AUTH_LOG" 2>/dev/null | grep "Failed password" | wc -l)

if [ "$SSH_COUNT" -gt "$SSH_THRESHOLD" ]; then
    echo "ALERT: Possible SSH brute-force detected ($SSH_COUNT failed logins in last 100 lines of auth.log)." | tee -a "$REPORT_FILE"
else
    echo "OK: SSH login failures within normal range ($SSH_COUNT in last 100 lines)." | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"


# ---------- Summary ----------
echo "===== Summary =====" | tee -a "$REPORT_FILE"
echo "SYN packets in ${CAPTURE_DURATION}s: $SYN_COUNT (threshold: $SYN_THRESHOLD)" | tee -a "$REPORT_FILE"
echo "HTTP POST in ${CAPTURE_DURATION}s : $HTTP_COUNT (threshold: $HTTP_THRESHOLD)" | tee -a "$REPORT_FILE"
echo "SSH failures (last 100 lines) : $SSH_COUNT (threshold: $SSH_THRESHOLD)" | tee -a "$REPORT_FILE"
echo "Visual check      : $COMPARE_OUTPUT" | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "[+] IDS analysis complete. Report saved to $REPORT_FILE" | tee -a "$LOG_FILE"
