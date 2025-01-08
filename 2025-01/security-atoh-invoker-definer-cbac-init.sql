/* setup */
drop package if exists admin_utils;
drop role if exists cancel_sql_role;
drop role if exists unlock_user_role;
drop role if exists support_role;
drop role if exists dev_role;
drop user if exists dba_admin cascade;
drop user if exists support_user cascade;
grant dba to dba_admin identified by dba_admin;
drop user if exists dev_user cascade;
drop user if exists support_user cascade;
grant create session to dev_user identified by dev_user;
grant create session to support_user identified by support_user;
grant select on sys.v_$session to dba_admin;
grant db_developer_role to dev_user;

-- Do we want to talk about this?
-- revoke inherit privileges on user support_user from public;
-- revoke inherit privileges on user dev_user from public;