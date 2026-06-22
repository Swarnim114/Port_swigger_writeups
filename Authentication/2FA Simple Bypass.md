

# **Description**

The application implements two-factor authentication (2FA) but fails to enforce it properly on all endpoints. After logging in with valid credentials, the user is prompted for a 2FA verification code. However, the application does not check if the 2FA step has been completed before allowing access to protected pages like `/my-account`. By directly navigating to the account page after login, an attacker can bypass the 2FA requirement entirely.

# **Steps to Exploit**

1. Log in to your own account (`wiener:peter`) to understand the 2FA flow.
2. Navigate to your account page and make a note of the URL structure (e.g., `/my-account`).
3. Log out of your account.
4. Log in using the victim's credentials (`carlos:montoya`).
5. When prompted for the verification code, do not enter anything.
6. Manually change the URL in the browser's address bar to navigate directly to `/my-account` (e.g., `https://YOUR-LAB-ID.web-security-academy.net/my-account`).
7. The lab is solved when the page loads successfully.

# **Proof of Concept**

**Direct Access URL:**
```
https://YOUR-LAB-ID.web-security-academy.net/my-account
```

Simply accessing the protected account page after authentication bypasses the 2FA verification step.

**Screenshot 1 – Logging in with victim's credentials:**
![[img1.png]]

**Screenshot 2 – 2FA verification prompt:**
![[img2.png]]

**Screenshot 3 – Manually changing URL to /my-account:**
![[Screenshots/img3.png]]



# **Impact**

- Complete account takeover of any user with 2FA enabled.
- An attacker with stolen credentials can bypass 2FA entirely.
- Sensitive user data (email, personal info, order history) becomes accessible.
- Can lead to further attacks like account takeover, privilege escalation, or data theft.

# **Mitigation / Remediation**

1. **Enforce 2FA on all protected endpoints.** The server must verify that the 2FA step has been completed before granting access to any authenticated page.
2. **Use server-side session flags** to track 2FA completion status and validate them on every request.
3. **Redirect unauthenticated users** from protected pages to the login/2FA page.
4. **Implement proper access control checks** on every protected route, not just the login endpoint.

---

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via HTTP requests |
| Attack Complexity | Low | Simply changing the URL |
| Privileges Required | None | Victim's credentials are already known |
| User Interaction | None | Exploit works automatically |
| Scope | Changed | Attacker gains access to victim's account |
| Confidentiality Impact | High | Can view all account data |
| Integrity Impact | High | Can change email, password, etc. |
| Availability Impact | None | No impact on availability |

**CVSS Score: 8.1 (High)**
`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N`