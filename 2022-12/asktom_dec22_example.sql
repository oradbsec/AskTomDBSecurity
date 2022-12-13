-- asktom_dec22_example.sql
-- 
-- This is an example of several capabilities
-- This is not production code
-- There is no support on this code example
-- 

-- REMEMBER: 
-- YOU CANNOT DELETE IMMUTABLE OR BLOCKCHAIN TABLES UNLESS THEY MEET THE CRITERIA
-- TRY THIS ON A THROW-AWAY DATABASE




-- housekeeping in case you have executed this before
/*
connect sys/Oracle123@pdb1 as sysdba
drop lockdown profile sec_profile;
drop user data_owner cascade;
drop user data_user cascade;
drop role load_data_role;
drop role acl_auth_role;
*/

-- create a lockdown profile to disable alter system, partitioning and network access in the PDB it is applied to
connect / as sysdba
set serveroutput on;

create lockdown profile sec_profile;
alter lockdown profile sec_profile disable statement=('alter system') clause=('set') option all;
alter lockdown profile sec_profile disable option=('Partitioning');
alter lockdown profile sec_profile disable feature=('NETWORK_ACCESS');

alter lockdown profile sec_profile
 DISABLE STATEMENT = ('ALTER SYSTEM')
  CLAUSE = ('SET')
  OPTION ALL EXCEPT = ('plsql_code_type','plsql_debug','plsql_warnings');

alter lockdown profile sec_profile
 DISABLE STATEMENT = ('ALTER SYSTEM')
 CLAUSE = ('SET')
 OPTION = ('CPU_COUNT') MINVALUE = '4' MAXVALUE = '8';

ALTER LOCKDOWN PROFILE sec_profile ENABLE STATEMENT = ('ALTER SYSTEM') clause = ('flush shared_pool');

-- Apply the PDB lockdown profile to PDB1
alter session set container=PDB1;
alter system set pdb_lockdown=sec_profile;

-- as a privileged user
connect sys/Oracle123@pdb1 as sysdba

-- create a tablespace for our testing
create tablespace asktomdemo datafile '/u02/oradata/CDB1/pdb1/asktomdemo.dbf' size 100m;

-- create the user to own the procedure
-- notice the user cannot authenticate
create user data_owner no authentication default tablespace asktomdemo;
-- grant the least privilege possible
grant create procedure to data_owner;
-- this has to be a direct grant so the package will compile
--grant execute on DBMS_NETWORK_ACL_ADMIN to data_owner;
ALTER USER data_owner QUOTA 100M ON asktomdemo;

-- create the user to execute the procedure
create user data_user identified by Oracle123;
-- grant the least privilege possible to our user running the commands
grant create session to data_user;

connect sys/Oracle123@pdb1 as sysdba
-- Grant read on this view to our function owner
grant read on sys.dba_users to data_owner;

-- create the function with invoker rights
create or replace function data_owner.date_created (c_username in varchar2) 
 RETURN date authid current_user 
 IS v_create_date date;
BEGIN
    select created into v_create_date from sys.dba_users where username = c_username;
RETURN v_create_date;
END;
/

-- As DATA_USER, you will get this error
--
-- select data_owner.date_created('SYSTEM') from dual;
connect data_user/Oracle123@pdb1
select data_owner.date_created('SYSTEM') from dual;

-- Grant execute on the function to the user
connect sys/Oracle123@pdb1 as sysdba
grant execute on data_owner.date_created to data_user;

-- Next, we will get another error b/c we have not given 
-- the function the role with the proper privileges
--
-- ORA-00942: table or view does not exist
connect data_user/Oracle123@pdb1
desc data_owner.date_created;
select data_owner.date_created('SYSTEM') from dual;

-- as privileged user, create the role and run the CBAC grant
connect sys/Oracle123@pdb1 as sysdba
create role read_dba_users_role;
grant read on sys.dba_users to read_dba_users_role;
grant read_dba_users_role to data_owner;
-- this is CBAC b/c we are granting a role to a procedure
grant read_dba_users_role to function data_owner.date_created;

-- this should return the value we expect
connect data_user/Oracle123@pdb1
select data_owner.date_created('DATA_USER') from dual;
select data_owner.date_created('SYSTEM') from dual;

-- If you want to prove it is the role granted to the function
-- you can run the following again
connect sys/Oracle123@pdb1 as sysdba
revoke read_dba_users_role from function data_owner.date_created;

-- If we have revoked the role, we should get the error again
--
-- ORA-00942: table or view does not exist
connect data_user/Oracle123@pdb1
select data_owner.date_created('DATA_USER') from dual;

-- regrant the role so it works again
connect sys/Oracle123@pdb1 as sysdba
grant read_dba_users_role to function data_owner.date_created;

-- this should return the proper dates
connect data_user/Oracle123@pdb1
select data_owner.date_created('DATA_USER') from dual;
select data_owner.date_created('SYSTEM') from dual;

-- create the objects, procedures, and packages

-- Based on example by Tim Hall: https://oracle-base.com/articles/misc/retrieving-html-and-binaries-into-tables-over-http
CREATE IMMUTABLE TABLE data_owner.http_clob_test (
  id    NUMBER(10),
  url   VARCHAR2(255),
  data  CLOB,
  CONSTRAINT http_clob_test_pk PRIMARY KEY (id)
)
  NO DROP UNTIL 1 DAYS IDLE
  NO DELETE UNTIL 16 DAYS AFTER INSERT;

-- Based on example by Tim Hall: https://oracle-base.com/articles/misc/retrieving-html-and-binaries-into-tables-over-http
CREATE SEQUENCE data_owner.http_clob_test_seq;

-- Based on example by Tim Hall: https://oracle-base.com/articles/misc/retrieving-html-and-binaries-into-tables-over-http
CREATE OR REPLACE PROCEDURE data_owner.load_data (
   p_url              IN  VARCHAR2,
   p_username         IN  VARCHAR2 DEFAULT NULL,
   p_password         IN  VARCHAR2 DEFAULT NULL,
   p_wallet_path      IN  VARCHAR2 DEFAULT NULL,
   p_wallet_password  IN  VARCHAR2 DEFAULT NULL
 )  
 AS 
   l_http_request   UTL_HTTP.req;
   l_http_response  UTL_HTTP.resp;
   l_clob           CLOB;
   l_text           VARCHAR2(32767);
 BEGIN
   -- If using HTTPS, open a wallet containing the trusted root certificate.
   IF p_wallet_path IS NOT NULL AND p_wallet_password IS NOT NULL THEN
     UTL_HTTP.set_wallet('file:' || p_wallet_path, p_wallet_password);
   END IF;
 
   -- Initialize the CLOB.
   DBMS_LOB.createtemporary(l_clob, FALSE);
 
   -- Make a HTTP request and get the response.
   l_http_request  := UTL_HTTP.begin_request(p_url);
 
   -- Use basic authentication if required.
   IF p_username IS NOT NULL AND p_password IS NOT NULL THEN
     UTL_HTTP.set_authentication(l_http_request, p_username, p_password);
   END IF;
 
   l_http_response := UTL_HTTP.get_response(l_http_request);
 
   -- Copy the response into the CLOB.
   BEGIN
     LOOP
       SYS.UTL_HTTP.read_text(l_http_response, l_text, 32766);
       DBMS_LOB.writeappend (l_clob, LENGTH(l_text), l_text);
     END LOOP;
   EXCEPTION
     WHEN UTL_HTTP.end_of_body THEN
       SYS.UTL_HTTP.end_response(l_http_response);
   END;
 
   -- Insert the data into the table.
   INSERT INTO data_owner.http_clob_test (id, url, data)
   VALUES (data_owner.http_clob_test_seq.NEXTVAL, p_url, l_clob);
 
   -- Relase the resources associated with the temporary LOB.
   DBMS_LOB.freetemporary(l_clob);
 EXCEPTION
   WHEN OTHERS THEN
     SYS.UTL_HTTP.end_response(l_http_response);
     DBMS_LOB.freetemporary(l_clob);
     RAISE;
END load_data;
/
show errors;

-- this is what we want "data_user" to execute in order to allow the user 
-- to grant access without having access to the DBMS_NETWORK_ACL_ADMIN package
-- 
-- restrict the c_ip_address range to only private IPs
CREATE OR REPLACE PACKAGE data_owner.acl_auth_pkg 
 AUTHID CURRENT_USER AS 
   PROCEDURE grant_access  (c_ip_address varchar2); 
   PROCEDURE revoke_access (c_ip_address varchar2); 
END acl_auth_pkg; 
/
show errors;

CREATE OR REPLACE PACKAGE BODY data_owner.acl_auth_pkg AS 
 -- Based on example by Tim Hall: https://oracle-base.com/articles/misc/retrieving-html-and-binaries-into-tables-over-http
 PROCEDURE grant_access (c_ip_address varchar2) IS 
   v_string varchar2(1000);
  BEGIN 
      begin 
	v_string := 'dbms_network_acl_admin.append_host_ace(host => '||dbms_assert.enquote_literal(c_ip_address)||',ace => xs$ace_type(privilege_list => xs$name_list(''http'',''http_proxy''),principal_name => DBMS_ASSERT.SIMPLE_SQL_NAME(''DATA_OWNER''),principal_type => xs_acl.ptype_db));';
	execute immediate('begin '||v_string||' end;');
/*        -- Allow all hosts for HTTP/HTTP_PROXY privileges
        dbms_network_acl_admin.append_host_ace(
      	host => c_ip_address,
      	ace => xs$ace_type(privilege_list => xs$name_list('http', 'http_proxy'),
      					   principal_name => DBMS_ASSERT.SIMPLE_SQL_NAME(c_username),
      					   principal_type => xs_acl.ptype_db));
*/

      end;
  END grant_access; 
 PROCEDURE revoke_access (c_ip_address varchar2) IS 
   v_string varchar2(1000);
  BEGIN 
      begin 
	v_string := 'dbms_network_acl_admin.remove_host_ace(host => '||dbms_assert.enquote_literal(c_ip_address)||',ace => xs$ace_type(privilege_list => xs$name_list(''http'',''http_proxy''),principal_name => DBMS_ASSERT.SIMPLE_SQL_NAME(''DATA_OWNER''),principal_type => xs_acl.ptype_db));';
	execute immediate('begin '||v_string||' end;');
     end;
  END revoke_access; 
END acl_auth_pkg;
/
show errors;

-- verify we are a privileged user who can create roles and grant privileges
connect sys/Oracle123@pdb1 as sysdba

-- Check the output
column table_name format a20
column tablespace_name format a25
select table_name, tablespace_name from dba_tables where owner = 'DATA_OWNER';

-- Check the output
column object_name format a29
select object_name, object_type, status from dba_objects where owner = 'DATA_OWNER' order by 1,2;

-- the user should not even know the package exists yet
-- the error should be
-- PLS-00201: identifier 'DATA_OWNER.ACL_AUTH_PKG' must be declared
connect data_user/Oracle123@pdb1
EXEC data_owner.load_data('http://10.0.0.150/daily.csv');
-- error
-- ORA-04043: object data_owner.acl_auth_pkg does not exist
desc data_owner.acl_auth_pkg;

-- grant execute on the procedure to data_user
connect sys/Oracle123@pdb1 as sysdba
grant execute on data_owner.load_data to data_user;

-- This error is due to the pdb lockdown profile not allowing UTL_HTTP access
-- 
-- ORA-29273: HTTP request failed
-- ORA-06512: at "DATA_OWNER.ACL_AUTH_PKG", line 55
-- ORA-01031: insufficient privileges
connect data_user/Oracle123@pdb1
EXEC data_owner.load_data('http://10.0.0.150/daily.csv');

-- Allow UTL_HTTP to be used by PDBs with sec_profile lockdown profile. 
connect / as sysdba
ALTER LOCKDOWN PROFILE sec_profile ENABLE FEATURE = ('UTL_HTTP');

set pages 9999
set lines 210
column profile_name format a25
column rule_type format a20
column rule format a20
column clause format a20
column clause_option format a20
select profile_name, rule_type, rule, clause, status, users from DBA_LOCKDOWN_PROFILES;

-- This error is related to Network ACLs to protect the DB
-- 
-- ORA-29273: HTTP request failed
-- ORA-06512: at "DATA_OWNER.load_data", line 33
-- ORA-24247: network access denied by access control list (ACL)
connect data_user/Oracle123@pdb1
EXEC data_owner.load_data('http://10.0.0.150/daily.csv');

-- As the user, if we try to run the DBMS_NETWORK_ACL_ADMIN ourself, it errors
-- 
-- PLS-00201: identifier 'DBMS_NETWORK_ACL_ADMIN' must be declared
-- 
connect data_user/Oracle123@pdb1
begin 
  -- Allow all hosts for HTTP/HTTP_PROXY privileges
  dbms_network_acl_admin.append_host_ace(
	host => '10.0.0.150',
	ace => xs$ace_type(privilege_list => xs$name_list('http', 'http_proxy'),
    principal_name => 'DATA_OWNER',
    principal_type => xs_acl.ptype_db));
end;
/

-- This will error because the user does not have execute yet
connect data_user/Oracle123@pdb1
exec data_owner.acl_auth_pkg.grant_access ('10.0.0.150');

-- Grant the user execute on the package
connect sys/Oracle123@pdb1 as sysdba
grant execute on data_owner.acl_auth_pkg to data_user;

-- This will error becuase the PACKAGE does not have the privileges required
-- 
-- PLS-00201: identifier 'DBMS_NETWORK_ACL_ADMIN' must be declared
-- 
connect data_user/Oracle123@pdb1
exec data_owner.acl_auth_pkg.grant_access ('10.0.0.150');

-- Here is where we start the CBAC process
connect sys/Oracle123@pdb1 as sysdba
-- create a role for the package to use
create role acl_auth_role;
-- grant that role to the package owner, this is a requirement
grant acl_auth_role to data_owner;
-- populate the role with the necessary privileges
grant execute on DBMS_NETWORK_ACL_ADMIN to acl_auth_role;
-- grant the role to the package so the role grants can be used by AUTHID CURRENT_USER
-- This is CBAC here, granting the role to the package
grant acl_auth_role to package data_owner.acl_auth_pkg;

-- This will work now becuase the package has the proper privileges
-- 
connect data_user/Oracle123@pdb1
exec data_owner.acl_auth_pkg.grant_access ('10.0.0.150');

-- verify the ACL
connect sys/Oracle123@pdb1 as sysdba

column host format a25
column PRINCIPAL format a10
column PRIVILEGE format a10
select e.HOST, PRINCIPAL, PRIVILEGE, e.LOWER_PORT, ACLID
  from dba_host_acls l, dba_host_aces e
  where e.host = l.host and principal = 'DATA_OWNER' order by aclid;

-- This should should work now
--
-- PL/SQL procedure successfully completed.
-- 
connect data_user/Oracle123@pdb1
EXEC data_owner.load_data('http://10.0.0.150/daily.csv');

connect sys/Oracle123@pdb1 as sysdba
-- see the log data
COLUMN url FORMAT A40
SELECT id,
       url,
       DBMS_LOB.getlength(data) AS length
FROM   data_owner.http_clob_test;

-- to prove that it is because of the grant to the package, revoke it and then try it again
connect sys/Oracle123@pdb1 as sysdba
revoke acl_auth_role from package data_owner.acl_auth_pkg;

-- This should error becuase the role has been revoked from the package
--
-- PLS-00201: identifier 'DBMS_NETWORK_ACL_ADMIN' must be declared
-- 
connect data_user/Oracle123@pdb1
exec data_owner.acl_auth_pkg.revoke_access ('10.0.0.150');

-- regrant the role so the package works again
connect sys/Oracle123@pdb1 as sysdba
grant acl_auth_role to package data_owner.acl_auth_pkg;

-- revoke the ACL to stop the DATA_OWNER from accessing the server
connect data_user/Oracle123@pdb1
exec data_owner.acl_auth_pkg.revoke_access ('10.0.0.150');

-- verify the ACL is gone
connect sys/Oracle123@pdb1 as sysdba
-- verify the ACL is gone
column host format a25
column PRINCIPAL format a10
column PRIVILEGE format a10
select e.HOST, PRINCIPAL, PRIVILEGE, e.LOWER_PORT, ACLID
  from dba_host_acls l, dba_host_aces e
  where e.host = l.host and principal = 'DATA_OWNER' order by aclid;


-- almost no privileges or roles! 
connect data_user/Oracle123@pdb1
column owner format a25
column table_name format a25
column privilege format a25
select owner, table_name, privilege from user_tab_privs order by 1;
select * from session_roles; 


connect sys/Oracle123@pdb1 as sysdba
show user;

-- attempt to alter the table, this will fail
delete from data_owner.http_clob_test;

-- attempt to alter the table, this will fail
connect sys/Oracle123@pdb1 as sysdba
show user;
alter table data_owner.http_clob_test id NUMBER(8);
alter table data_owner.http_clob_test rename id to clob_id;
alter table data_owner.http_clob_test add test number;

-- attempt to delete as sys, this will fail
connect sys/Oracle123@pdb1 as sysdba
show user;
delete from data_owner.http_clob_test;

-- attempt to drop the tablespace, this will fail
connect sys/Oracle123@pdb1 as sysdba
show user;
