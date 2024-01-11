# DB Security Office Hours
# Maximize security and minimize headaches with Oracle Database proxy users

### I have a question I don't want to ask in the pubic forum. 

If you'd like to ask your question privately, please email me at richard c evans _at_ that oracle company that makes amazing database software dot com 

## Where do I find the recordings? 

After the session, they will be posted to AskTom DB Security Office Hours: bit.ly/asktomdbsec

## Critical Patches and Updates

- For Critical Patch Updates, Security Alerts, and Bulletins for all Oracle products please see: https://www.oracle.com/security-alerts
- For patch numbers and more details see My Oracle Support (MOS) Note: 2118136.2 
- Fleet Patching and Provisioning: https://docs.oracle.com/en/database/oracle/oracle-database/19/cwadd/rapid-home-provisioning.html
- CPU Program Oct 2022 Patch Availability Document (DB-only) (Doc ID 2888497.1)	

## Support Notes

-  Doc ID 782078.1: Proxy Users and Auditing Proxy Users

## Documentation 

- Oracle JDBC Developer Guide, proxy authentication: https://docs.oracle.com/en/database/oracle/oracle-database/19/jjdbc/proxy-authentication.html
- Oracle Database Security Guide: https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/configuring-authentication.html
  
## Recent posts on our Oracle Security blog

- Database Security Assessment Tool 3.0 is now available: https://blogs.oracle.com/cloudsecurity/post/database-security-assessment-tool-3-0-now-available

## Oracle Tech Lounge 

- Upcoming (and recorded) technical presentations here: https://go.oracle.com/LP=137345?elqCampaignId=468926

## Oracle 23c FREE Developer Release

- Download Oracle 23c FREE from https://www.oracle.com/database/free/

## Next steps to learn more about Oracle Database proxy authentication

- Oracle LiveLabs, How Developers Could Use Oracle Database Proxy Authentication: https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/view-workshop?wid=3785

## Example commands and code
```

SELECT authentication_type FROM dba_users WHERE username = 'HR';
ALTER USER hr NO AUTHENTICATION;

CREATE ROLE hradmin;
GRANT create session TO hradmin;
GRANT select, insert, update, delete ON hr.employees TO hradmin;

CREATE ROLE hruser;
GRANT create session TO hruser;
GRANT read, insert ON hr.employee TO hruser;

CREATE ROLE readonly;
GRANT create session TO readonly;
GRANT read TO readonly TO readonly;

CREATE USER privbroker NO AUTHENTICATION TEMPORARY TABLESPACE temp;
GRANT hradmin, hruser, readonly TO privbroker;

CREATE USER proxy_dan IDENTIFIED BY pd;
CREATE USER proxy_rich IDENTIFIED BY pr;
CREATE USER proxy_larry IDENTIFIED BY pl;

ALTER USER privbroker GRANT CONNECT THROUGH proxy_dan WITH ROLE hradmin AUTHENTICATION REQUIRED;
ALTER USER privbroker GRANT CONNECT THROUGH proxy_rich WITH ROLE hruser AUTHENTICATION REQUIRED;
ALTER USER privbroker GRANT CONNECT THROUGH proxy_larry WITH ROLE readonly AUTHENTICATION REQUIRED;

-- traditional audit policy (19c and older)
AUDIT CONNECT BY proxy_dan ON BEHALF OF privbroker;
AUDIT CONNECT BY proxy_rich ON BEHALF OF privbroker;
AUDIT CONNECT BY proxy_larry ON BEHALF OF privbroker;

column proxy_user format a20
column current_user format a12
column session_user format a12
column current_schema format a14
column enterprise_identity format a61
column proxy_enterprise_identity format a61

set lines 140

SELECT SYS_CONTEXT('USERENV', 'PROXY_USER')  proxy_user
     , SYS_CONTEXT('USERENV', 'CURRENT_USER') current_user
     , SYS_CONTEXT('USERENV', 'SESSION_USER') session_user
     , SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') current_schema 
     , sys_context('userenv','enterprise_identity') enterprise_identity
     , sys_context('userenv','proxy_enterprise_identity') proxy_enterprise_identity
  FROM dual;

select * From session_roles;

```

### Kerberos authentication and proxy users
### This assumes you have Kerberos authentication configured on the client and database

```
create user rcevans identified externally as 'rcevans@DBSECLABS.COM';
ALTER USER privbroker GRANT CONNECT THROUGH rcevans;
sqlplus [privbroker]/@pdb1
SELECT SYS_CONTEXT('USERENV', 'PROXY_USER')  proxy_user
     , SYS_CONTEXT('USERENV', 'CURRENT_USER') current_user
     , SYS_CONTEXT('USERENV', 'SESSION_USER') session_user
     , SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') current_schema 
     , sys_context('userenv','enterprise_identity') enterprise_identity
  FROM dual;
PROXY_USER CURRENT_USER SESSION_USER CURRENT_SCHEMA ENTERPRISE_IDENTITY
---------- ------------ ------------ -------------- ---------------------
RCEVANS    PRIVBROKER   PRIVBROKER   PRIVBROKER     rcevans@DBSECLABS.COM

```

### Kerberos, Centrally Managed Users (CMU), and proxy users
### This assumes you have Kerberos and CMU as shared schema configured on the client and database

```

drop user rcevans;
ALTER USER privbroker GRANT CONNECT THROUGH cmu_shared_schema;
sqlplus [privbroker]/@pdb1

SELECT SYS_CONTEXT('USERENV', 'PROXY_USER')  proxy_user
     , SYS_CONTEXT('USERENV', 'CURRENT_USER') current_user
     , SYS_CONTEXT('USERENV', 'SESSION_USER') session_user
     , SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') current_schema 
     , sys_context('userenv','enterprise_identity') enterprise_identity
  FROM dual;

PROXY_USER         CURRENT_USER SESSION_USER CURRENT_SCHEMA ENTERPRISE_IDENTITY
------------------ ------------ ------------ -------------- ------------------------------------------------
CMU_SHARED_SCHEMA  PRIVBROKER   PRIVBROKER   PRIVBROKER     cn=Richard C. Evans,cn=Users,dc=DBSECLABS,dc=COM

```
### Unified Audit policies for proxy users (12c and newer)

```

create audit policy ua_proxy_hr_emp
actions all on hr.employees
when 'SYS_CONTEXT(''USERENV'', ''PROXY_USER'') IS NOT NULL'
evaluate per statement;

audit policy ua_proxy_hr_emp;

select dbusername, dbproxy_username, sql_text   from unified_audit_trail  where regexp_like(unified_audit_policies,'ua_proxy_hr_emp','i')  order by event_timestamp;

```




