# Title: SQL Injection in Product Category Filter Allowing Retrieval of Hidden Data

# **Description**

The application is vulnerable to SQL Injection in the product category filter parameter. User-supplied input is incorporated directly into a backend SQL query without proper validation or parameterization.

The application executes the following query when a category is selected:

SELECT \* FROM products WHERE category \= 'Gifts' AND released \= 1

By injecting SQL syntax into the catTitlegory parameter, an attacker can modify the logic of the query and retrieve products that are not intended to be visible to users, including unreleased products.

# **Steps to Exploit**

1\. Navigate to the product listing page.  
2\. Select any product category.  
3\. Intercept the request using Burp Suite.  
4\. Locate the category parameter.  
5\. Modify the parameter value to: ' OR 1=1--  
6\. Forward the modified request.  
7\. Observe that the response now displays products from all categories, including unreleased products.

**Proof of Concept** 

Payload:  
' OR 1=1--

Original Query:  
SELECT \* FROM products WHERE category \= 'Gifts' AND released \= 1

Modified Query:  
SELECT \* FROM products WHERE category \= '' OR 1=1--' AND released \= 1

![][image1]

![][image2]

# **Impact**

• Unauthorized access to sensitive information.  
• Exposure of unreleased or restricted products.  
• Potential disclosure of business-sensitive data.  
• May serve as an entry point for more advanced SQL Injection attacks.  
• Loss of confidentiality and trust in the application.

# **Mitigation / Remediation**

1\. Use parameterized queries (prepared statements) for all database interactions.  
2\. Implement strict server-side input validation.  
3\. Apply the principle of least privilege to database accounts.  
4\. Implement secure coding practices and regular code reviews.

# *****

# **CVSS Justification**

Attack Vector: Network (Exploitable remotely through a web request)  
Attack Complexity: Low (No special conditions required)  
Privileges Required: None (Attacker does not need Authentication)  
User Interaction: None (No user action required)  
Scope: Unchanged (Impact remains within the application)  
Confidentiality Impact: Low (Unauthorized access to hidden product data)  
Integrity Impact: None (No modification of data)  
Availability Impact: None (No service disruption observed)
9V