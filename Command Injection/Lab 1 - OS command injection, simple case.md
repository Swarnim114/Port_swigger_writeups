# Title: OS Command Injection, Simple Case

# **Description**

The product stock checker feature has a straightforward OS command injection vulnerability. When you check stock, the app takes the product ID and store ID and passes them directly into a shell command on the backend to run a script, returning whatever the script outputs.

Since there's no sanitization, you can just append a shell metacharacter (like `|`, `&`, or `;`) followed by your own command, and the server will run it and hand the output right back to you.

# **Steps to Exploit**

1. Go to any product page and use the "Check stock" feature.
2. Turn on Intercept in Burp Suite and catch the POST request.
3. Look at the `storeId` parameter in the request body.
4. Change the `storeId` value to `1|whoami`.
5. Forward the request.
6. Check the response — instead of just stock numbers, the raw output of the `whoami` command (like `peter-XXXXXX`) will be dumped right there in the response.

# **Proof of Concept**

**Payload:**
```
1|whoami
```

By using the pipe character `|` in the `storeId` parameter, we tell the backend system to run its normal command, and then run our injected command `whoami`. Because the application returns the raw output of the executed sequence, the result of `whoami` gets printed directly in the HTTP response.

**Screenshot 1 – Burp Suite intercepting normal stock check:**
![[Screenshots/1_burp_normal_stock_check.png]]

**Screenshot 2 – Modified storeId with payload in Burp Suite:**
![[Screenshots/2_burp_modified_store_id.png]]

**Screenshot 3 – Response showing the whoami output (lab solved):**
![[Screenshots/3_whoami_output_response.png]]

# **Impact**

- Full Remote Code Execution (RCE) on the backend server.
- The attacker can run any system command with the privileges of the user running the web application.
- This leads to a complete compromise of the server — you can read arbitrary files, pivot to internal networks, install backdoors, or destroy data.

# **Mitigation / Remediation**

1. **Avoid calling out to OS commands entirely.** Use built-in language APIs or libraries instead of shelling out.
2. If you absolutely must use OS commands, **never concatenate user input directly into the command string.**
3. Use robust input validation — strictly validate against an allowlist of expected values (e.g., ensuring IDs are purely numeric).
4. Run the application with the least privilege necessary, so if a command injection happens, the blast radius is contained.

---

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via standard HTTP request |
| Attack Complexity | Low | Trivial to execute with standard shell characters |
| Privileges Required | None | No authentication required to check stock |
| User Interaction | None | Exploit runs immediately on the server |
| Scope | Changed | Allows compromise of the underlying OS, not just the app |
| Confidentiality Impact | High | Full access to server filesystem and secrets |
| Integrity Impact | High | Can modify or delete any file accessible to the app user |
| Availability Impact | High | Can easily crash or wipe the server |

**CVSS Score: 10.0 (Critical)**
`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`
