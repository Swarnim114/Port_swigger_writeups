# Title: Unprotected Admin Functionality

# **Description**

The application has an administrative panel that is intended to be accessible only to privileged users. However, the developer has failed to implement proper access controls on this panel, leaving it completely unprotected and accessible to anyone who knows the URL.

The admin panel's path is not directly linked from the main site, but it is inadvertently disclosed through the `robots.txt` file. This file is a standard mechanism used by websites to communicate with web crawlers and search engines, specifying which parts of the site should not be indexed. Unfortunately, it is also publicly accessible and can be viewed by anyone.

By examining the `robots.txt` file, an attacker can discover the hidden admin panel URL. Since the panel lacks any authentication or authorization controls, the attacker can then access it directly and perform administrative actions, such as deleting user accounts.

# **Steps to Exploit**

1. Navigate to the lab's main page.
2. Append `/robots.txt` to the base URL to view the robots.txt file.
3. Observe the `Disallow` directive, which reveals the path to the admin panel.
4. In the URL bar, replace `/robots.txt` with the disclosed admin path (e.g., `/administrator-panel`) to access the admin panel.
5. Locate the option to delete the user `carlos`.
6. Click the delete button or navigate to the delete endpoint to remove the user.
7. The lab is solved when Carlos is successfully deleted.

# **Proof of Concept**

**Step 1 – Access robots.txt:**
```
https://YOUR-LAB-ID.web-security-academy.net/robots.txt
```

**Step 2 – robots.txt content:**
```
User-agent: *
Disallow: /administrator-panel
```

**Step 3 – Access admin panel:**
```
https://YOUR-LAB-ID.web-security-academy.net/administrator-panel
```

**Step 4 – Delete carlos:**
```
https://YOUR-LAB-ID.web-security-academy.net/administrator-panel/delete?username=carlos
```
![[1.png]]
![[2.png]]


![[3.png]]
# **Impact**

The exposure of an unprotected admin panel has severe security implications:

**Unauthorized Administrative Access:**
- Anyone who discovers the admin panel URL can access it without authentication.
- Attackers can perform any administrative action on the application.

**Data Breach:**
- Attackers can view, modify, or delete sensitive user data.
- All user information stored in the system is exposed.

**Account Manipulation:**
- Attackers can create, modify, or delete user accounts at will.
- Users can be locked out of their accounts or impersonated.

**System Compromise:**
- Some admin panels allow configuration changes that could compromise the entire system.
- File uploads, database access, or command execution might be possible.

**Reputational Damage:**
- A successful attack on an unprotected admin panel severely damages user trust.
- Regulatory fines and legal consequences are likely.

# **Mitigation / Remediation**

1. **Implement Proper Access Controls:**
   - Require authentication for all administrative functions.
   - Implement role-based access control (RBAC) to restrict access to authorized users only.
   - Never rely on security through obscurity.

2. **Secure robots.txt:**
   - Do not include sensitive paths in robots.txt.
   - Use robots.txt only for its intended purpose: guiding legitimate crawlers.
   - Consider using authentication for admin panels instead of hiding them.

3. **Implement Defense in Depth:**
   - Use IP whitelisting for administrative access.
   - Require multi-factor authentication (MFA) for admin accounts.
   - Monitor and log all administrative actions.

4. **Regular Security Audits:**
   - Conduct regular penetration testing and vulnerability assessments.
   - Review all administrative endpoints for proper access controls.
   - Use automated scanning tools to identify exposed admin panels.

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via standard HTTP requests |
| Attack Complexity | Low | Only requires accessing a publicly known file |
| Privileges Required | None | No authentication is required |
| User Interaction | None | Exploit works without any user interaction |
| Scope | Changed | Attacker gains administrative privileges |
| Confidentiality Impact | High | All user data and system information is exposed |
| Integrity Impact | High | The attacker can modify or delete any data |
| Availability Impact | High | User accounts can be deleted or modified |

**CVSS Score: 9.8 (Critical)**

`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

This critical score reflects the severe nature of the vulnerability, which allows complete system compromise with minimal effort and no authentication requirements.