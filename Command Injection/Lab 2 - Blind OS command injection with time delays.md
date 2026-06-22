# Title: Blind OS Command Injection with Time Delays

# **Description**

The application's feedback function has a blind OS command injection vulnerability. When you submit feedback, the app takes the details you provide (like the email address) and executes them as part of a backend shell command. 

Because it's a "blind" vulnerability, the output of the command isn't returned in the HTTP response. You won't see the results of commands like `whoami` or `ls`. However, you can still confirm the injection works by injecting a command that takes a specific amount of time to execute (like `ping`), causing the application to hang before it sends a response.

# **Steps to Exploit**

1. Navigate to the "Submit feedback" page on the application.
2. Fill out the feedback form with any dummy data and make sure Intercept is turned on in Burp Suite.
3. Submit the form and catch the POST request in Burp.
4. Locate the `email` parameter in the request body.
5. Modify the value of the `email` parameter to include the payload:
   ```
   email=x||ping+-c+10+127.0.0.1||
   ```
6. Forward the request and look at the response time in Burp. You'll notice that the application takes exactly 10 seconds to respond, confirming the command injection.

# **Proof of Concept**

**Payload:**
```
x||ping -c 10 127.0.0.1||
```

By using the `||` (OR) operators, we are telling the backend server: run the first command, and if it fails or finishes, run the next command. The `ping -c 10 127.0.0.1` command tells the server to ping itself 10 times, which takes exactly 10 seconds. The trailing `||` ensures that any remaining parts of the original backend command are treated as a separate execution block, preventing syntax errors from breaking the execution. Since the server waits for the ping to finish before returning the HTTP response, we see a 10-second delay in Burp Suite.

**Screenshot 1 – Normal feedback submission form:**
![[Screenshots/4_normal_feedback_form.png]]

**Screenshot 2 – Burp Suite intercepting the feedback POST request:**
![[Screenshots/5_burp_intercept_feedback.png]]

**Screenshot 3 – Modified email parameter with ping payload in Burp:**
![[Screenshots/6_burp_modified_email_ping.png]]

**Screenshot 4 – Burp response showing the 10-second execution time (lab solved):**
![[Screenshots/7_burp_response_time_delay.png]]

# **Impact**

- Full Remote Code Execution (RCE), even though it is blind.
- An attacker can still execute arbitrary commands, download malware, or exfiltrate data (e.g., via Out-Of-Band techniques like DNS lookups or curl requests to an attacker-controlled server).
- Complete compromise of the backend server and potentially the internal network.

# **Mitigation / Remediation**

1. **Do not use OS commands.** Rely on built-in language libraries to handle tasks like sending emails or processing feedback.
2. If OS commands are unavoidable, **strictly validate all user input.** Only allow expected characters (e.g., alphanumeric) and reject any shell metacharacters like `|`, `&`, `;`, `$`, etc.
3. Parameterize the input if the API supports it, ensuring user input is treated strictly as data and not as executable code.

---

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via standard HTTP request |
| Attack Complexity | Low | Standard ping payload works reliably |
| Privileges Required | None | No authentication required to submit feedback |
| User Interaction | None | Exploit runs immediately upon submission |
| Scope | Changed | Allows compromise of the underlying OS |
| Confidentiality Impact | High | Can exfiltrate data via OOB methods |
| Integrity Impact | High | Can blindly modify or delete files |
| Availability Impact | High | Can crash the server or consume resources |

**CVSS Score: 10.0 (Critical)**
`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

