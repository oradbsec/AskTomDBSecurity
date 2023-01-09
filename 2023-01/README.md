# AskTom - Oracle Database Security Office Hours


## January 2023: A look back at security in 2022 and a look ahead to 2023

In the first Oracle Database Security Office Hours of 2023, we will look back at the breaches, ransomware, regulations, and security-related events of 2022 and Oracle's database security-related innovations and accomplishments. We will peek at what's to come in 2023 for Oracle Database security features and options, including Oracle Data Safe, Oracle Audit Vault & DB Firewall and Oracle Key Vault.

# Oracle Database Release Updates

Critical Patch Updates (CPU) are collections of security and bug fixes for Oracle products

See MOS note 2118136.2 for patch numbers and more details

CPU Program Oct 2022 Patch Availability Document (DB-only) (Doc ID 2888497.1)	

For Critical Patch Updates, Security Alerts, and Bulletins for all Oracle products please see: https://www.oracle.com/security-alerts

Introducing Monthly Recommended Patches (MRPs) and FAQ (Doc ID 2898740.1): https://support.oracle.com/epmos/faces/DocContentDisplay?id=2898740.1

Patching News: RURs are gone – long live MRPs: https://mikedietrichde.com/2022/10/26/patching-news-rurs-are-gone-long-live-mrps/


# How do I know which feature or option is available in my version?

Navigate to https://apex.oracle.com/database-features

- Features or Licensing type
- Focus Area and Sub Area
- Feature Description
- Feature Business Benefit
- Database Version
- Licensed With
- Available on
- Initial Release Version

# Oracle LiveLabs - Get hands-on with Oracle Database Security

Hundreds of Oracle-related labs, and over 40 security-related labs, available at https://developer.oracle.com/livelabs

## Tales from the Dark Side: Hacking the Database

A hands-on lab dedicated to the features and functionality of Oracle Database security to prevent, detect and mitigate the most common cyberattacks performed on Oracle Databases.

Available at https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=3300

## Securing a legacy application with Oracle Autonomous Database and Oracle Database Vault

Get hands-on experience with Oracle Database Vault on Oracle Autonomous Database to help you understand how to secure your application data when you move to Oracle Autonomous Database. 

Available at: https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=3530

# Oracle 23c Beta

Interested in beta testing Oracle's latest long term release of Oracle Database? Sign up at https://tinyurl.com/OracleBeta


# Oracle Transparent Data Encryption (TDE) enhancements in 2022

In 19.14, per-PDB keystores are available
- Cloud and on-premises databases
- Available 19.11, 19.12, 19.13 with patch 32235513
- Only available with TDE-wallet or Oracle Key Vault

In 19.16, the TDE initialization parameter TABLESPACE_ENCRYPTION supersedes ENCRYPT_NEW_TABLESPACES.

See the Oracle Database 19c Reference Guide for more information: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/TABLESPACE_ENCRYPTION.html

See Glen Hawkin's blog: Introducing Oracle Data Guard Redo Decryption for Hybrid Disaster Recovery Configurations: https://blogs.oracle.com/maa/post/introducing-dg-redo-decrypt-for-hybrid-cloud

# Oracle Key Vault 

Desupport of Oracle Key Vault 18c as of April 2022

2022 saw the release of Oracle Key Vault 21.4 and 21.5

See the documentation for what's new: https://docs.oracle.com/en/database/oracle/key-vault/21.5/okvag/changes-this-release-oracle-key-vault.html


# Oracle Audit Vault & Database Firewall

Release of Oracle AVDF 21.7 and 20.8

See the documentation for what's new: https://docs.oracle.com/en/database/oracle/audit-vault-database-firewall/20/sigrn/index.html

# Oracle Cloud Database Security

Integration with OCI IAM and Azure AD

See Alan's blog for more information: Oracle Autonomous Database users can now be authenticated and managed with Azure Active Directory: https://blogs.oracle.com/cloudsecurity/post/azure-active-directory-can-authenticate-database-users

# Oracle LiveLabs

### Tales from the Dark Side: Hacking an Oracle Database

See Hakim's post on LinkedIn: https://www.linkedin.com/posts/loumihakim_oracle-dbsecurity-livelabs-activity-6965789241897316353-tPhw/

### Securing a legacy application with Oracle Autonomous Database and Oracle Database Vault

Give the lab a try in your Oracle Cloud free tier: https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=3530

# Oracle Security Blog

Some of the 2022 blog posts available at https://blogs.oracle.com/cloudsecurity

January:

- Accessing Autonomous Database with IAM token using Java blog announcement: https://blogs.oracle.com/developers/post/accessing-autonomous-database-with-iam-token-using-java
- Getting Database Security in Shape: https://blogs.oracle.com/cloudsecurity/post/getting-database-security-in-shape

February:

- Banking on Data - Oracle Database Security in Financial Services: https://blogs.oracle.com/cloudsecurity/post/database-security-in-financial-services

March:

- Oracle Data Safe Update Delivers a New Look and Enhanced Capabilities: https://blogs.oracle.com/cloudsecurity/post/oracle-data-safe-enhanced-capabilities
- Announcing New Oracle Data Safe Alert Capabilities and Reporting:  https://blogs.oracle.com/cloudsecurity/post/new-data-safe-alert-capabilities-and-reporting
- Oracle Autonomous Database Dedicated is now Integrated with OCI Identity and Access Management: https://blogs.oracle.com/cloudsecurity/post/autonomous-database-dedicated-integrated-with-oci-iam

April: 

- How to Guide: Configuring SQL*Plus for Single Sign-on to Oracle Autonomous Database using OCI IAM: https://blogs.oracle.com/cloudsecurity/post/sqlplus-to-autonomous-database-using-oci-iam
- Introducing Oracle Audit Vault and Database Firewall release update 7 – now includes the Shadow Audit Server: https://blogs.oracle.com/cloudsecurity/post/audit-vault-and-database-firewall-20-release-update-7

May:

- Announcing Oracle Key Vault 21.4 with Enhanced Operational Security and More: https://blogs.oracle.com/cloudsecurity/post/oracle-key-vault-214-with-enhanced-operational-security
- Unified Auditing Certified with EBS 12.2 – Parts I: https://blogs.oracle.com/cloudsecurity/post/unified-auditing-certified-with-ebs-122---part-i
- Unified Auditing Certified with EBS 12.2 – Parts II: https://blogs.oracle.com/cloudsecurity/post/unified-auditing-certified-with-ebs-122---part-ii
- World Password Day – 3 Ways to Improve Your Password Strategy: https://blogs.oracle.com/cloudsecurity/post/world-password-day-improve-your-password-strategy

June: 

- Five reasons to upgrade to Oracle Audit Vault and Database Firewall (AVDF) 20: https://blogs.oracle.com/cloudsecurity/post/five-reasons-to-upgrade-oracle-audit-vault-db-firewall
- Oracle Autonomous Database users can now be authenticated and managed with Azure Active Directory: https://blogs.oracle.com/cloudsecurity/post/azure-active-directory-can-authenticate-database-users
- Password-free authentication to Autonomous Database using SQLcl with Cloud Shell: https://blogs.oracle.com/cloudsecurity/post/password-free-authentication-to-autonomous-database-using-sqlcl-with-cloud-shell

July:

- Defense in Depth, Layering using OCI Network Firewall: https://blogs.oracle.com/cloudsecurity/post/defense-in-depth-layering-using-oci-network-firewall

August:

- Adopt automation to help reduce the risk of data loss: https://blogs.oracle.com/cloudsecurity/post/adopt-automation-to-help-reduce-the-risk-of-data-loss

September:

- Introducing Read-only Auditor Role with Audit Vault and Database Firewall 20.8: https://blogs.oracle.com/cloudsecurity/post/intro-rd-only-auditor-rl-w-audit-vault-database-fw-208 

October:

- Oracle Cloud World: https://www.oracle.com/cloudworld/

November: 

- Oracle Key Vault 21.5 is now available with simplified secrets management and administration: https://blogs.oracle.com/cloudsecurity/post/okv-215-avail-w-simplif-secrets-mgmt-administration

December:

- Automate compliance reports with Oracle Data Safe: https://blogs.oracle.com/cloudsecurity/post/automate-compliance-reporting-with-oracle-data-safe

# Oracle CloudWorld 

OCW'22 Security Sessions are available at https://youtu.be/KvfoPBdTYBE


