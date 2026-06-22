

# **Description**

The application uses JSON Web Tokens (JWTs) for session management and authentication. JWTs are structured tokens consisting of three parts: a header, a payload, and a signature. The signature is cryptographically generated using a secret key and is designed to prevent tampering with the token's contents.

However, this application contains a critical implementation flaw: the server does not verify the signature of any JWTs it receives. This means that an attacker can modify the contents of the JWT payload without invalidating the token, as the server will accept any token regardless of whether the signature is valid.

By exploiting this vulnerability, an attacker can modify the `sub` (subject) claim within the JWT payload to impersonate any user, including the administrator. This allows unauthorized access to restricted areas of the application, such as the admin panel, and enables privileged actions like deleting user accounts.

# **Steps to Exploit**

1. Log in to your own account (`wiener:peter`) using Burp Suite's browser.
2. In Burp Suite, go to the **Proxy > HTTP history** tab and locate the `GET /my-account` request made after login.
3. Observe that the `session` cookie contains a JWT token.
4. Send this request to Burp Repeater for further manipulation.
5. In Burp Repeater, change the request path from `/my-account` to `/admin` and send the request. Observe that access is denied because you are not logged in as an administrator.
6. Double-click the payload (middle) part of the JWT in the Inspector panel to view its decoded JSON content.
7. In the Inspector panel, locate the `sub` claim which contains your username (`wiener`).
8. Change the value of the `sub` claim from `wiener` to `administrator` and click "Apply changes".
9. The JWT is now modified with the updated payload. The signature remains unchanged.
10. Send the modified request with the updated JWT to `/admin`.
11. Observe that the admin panel is now accessible.
12. In the response, locate the URL for deleting the user `carlos`: `/admin/delete?username=carlos`.
13. Send a request to this endpoint using the same modified JWT to delete the user and solve the lab.

# **Proof of Concept**

**Original JWT (Base64):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIiLCJpYXQiOjE1MTYyMzkwMjJ9.qlgPm23QGHZxV9b0vSZCmR7s0Y5qMG6NQfJt_zplmRw
```

**Decoded Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Decoded Payload (Original):**
```json
{
  "sub": "wiener",
  "iat": 1516239022
}
```

**Decoded Payload (Modified):**
```json
{
  "sub": "administrator",
  "iat": 1516239022
}
```

**Modified JWT (Base64):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbmlzdHJhdG9yIiwiaWF0IjoxNTE2MjM5MDIyfQ.qlgPm23QGHZxV9b0vSZCmR7s0Y5qMG6NQfJt_zplmRw
```

**Step 1 – Original JWT in session cookie:**
![[Screenshots/1_jwt_session_cookie.png]]

**Step 2 – Accessing /admin with original JWT (denied):**
![[Screenshots/2_admin_access_denied.png]]

**Step 3 – Modifying the sub claim in Inspector panel:**
![[Screenshots/3_jwt_modify_sub_claim.png]]

**Step 4 – Accessing /admin with modified JWT (granted):**
![[Screenshots/4_admin_access_granted.png]]

**Step 5 – Deleting carlos via admin panel:**
![[Screenshots/5_delete_carlos.png]]

# **Impact**

The failure to verify JWT signatures has severe security implications:

**Privilege Escalation:**
- An attacker can modify the JWT payload to impersonate any user, including administrators.
- This grants unauthorized access to privileged functions and sensitive data.

**Complete Account Takeover:**
- Any user account can be compromised by simply changing the `sub` claim.
- The attacker can view, modify, or delete any user's data.

**Unauthorized Administrative Access:**
- Full access to the admin panel allows the attacker to perform critical operations.
- User management functions (creating, modifying, deleting users) are exposed.

**Data Breach:**
- All user data, including personal information and potentially financial details, becomes accessible.
- The attacker can export or exfiltrate sensitive information.

**System Compromise:**
- In some cases, admin access could lead to further compromise of the underlying system.
- Additional attacks like file uploads, command execution, or database manipulation become possible.

# **Mitigation / Remediation**

1. **Always Verify JWT Signatures:**
   - Implement proper signature validation using the correct secret key.
   - Use a well-tested JWT library (e.g., PyJWT, jsonwebtoken, jose4j).
   - Never accept tokens with invalid or missing signatures.

2. **Use Strong Cryptographic Algorithms:**
   - Prefer asymmetric algorithms (RS256, ES256) over symmetric (HS256).
   - If using HS256, ensure the secret key is sufficiently long and complex.

3. **Validate All Claims:**
   - Verify the `iss` (issuer), `aud` (audience), and `exp` (expiration) claims.
   - Implement checks to ensure the token is issued by a trusted source.

4. **Secure Key Management:**
   - Store secret keys securely using environment variables or secrets management services.
   - Regularly rotate keys to limit the impact of potential compromises.

5. **Implement Additional Security Controls:**
   - Use short token expiration times.
   - Implement token revocation mechanisms.
   - Monitor for suspicious token usage patterns.

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via standard HTTP requests |
| Attack Complexity | Low | Modifying a JWT requires minimal technical skill |
| Privileges Required | None | Only requires valid credentials for a low-privileged account |
| User Interaction | None | The exploit works without user interaction |
| Scope | Changed | Attacker gains administrative privileges |
| Confidentiality Impact | High | All user data and system information is exposed |
| Integrity Impact | High | The attacker can modify or delete any data |
| Availability Impact | High | User accounts can be deleted or locked |

**CVSS Score: 9.8 (Critical)**

`CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H`

This critical score reflects the severe nature of the vulnerability, which allows complete system compromise with minimal effort and only requires valid credentials for any user account.