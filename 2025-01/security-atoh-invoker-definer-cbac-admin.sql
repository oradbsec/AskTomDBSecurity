/* Connect as dba_admin */
select user;

create or replace package admin_utils 
  authid definer as

  procedure cancel_sql (
    sid integer, serial# integer
  );
  
  procedure kill_session (
    sid integer, serial# integer
  );
  
  procedure unlock_user (
    username varchar2
  );
end;
/

create or replace package body admin_utils as
  procedure cancel_sql (
    sid integer, serial# integer
  ) as 
  begin 
    execute immediate 
    q'[alter system cancel sql ']' || 
       sid || ',' || serial# || '''';
  end;
  
  procedure kill_session (
    sid integer, serial# integer
  ) as 
  begin 
    execute immediate 
    q'[alter system kill session ']' || 
       sid || ',' || serial# || '''';
  end;
  
  procedure unlock_user (
    username varchar2
  ) as 
  begin 
    execute immediate 
    'alter user ' || 
    dbms_assert.simple_sql_name ( username ) || 
    ' account unlock';
  end;
end;
/

/* Check the settings */
select object_name, procedure_name, authid 
from   user_procedures;




-- I have privileges via a role so this works:
alter system cancel sql '10, 200';

-- But role is inactive in PL/SQL, so this fails!
exec admin_utils.cancel_sql ( 10, 200 );





-- Change to invoker rights; 
-- only need access via role
create or replace package admin_utils 
  authid current_user as

  procedure cancel_sql (
    sid integer, serial# integer
  );
  
  procedure kill_session (
    sid integer, serial# integer
  );
  
  procedure unlock_user (
    username varchar2
  );
end;
/

/* Check the settings */
select object_name, procedure_name, authid 
from   user_procedures;


/* This now works */
exec admin_utils.cancel_sql ( 10, 200 );



-- Give dev users access
grant execute on admin_utils to dev_user;
--> dev_user







/* Allow dev_user access via role */
create role cancel_sql_role;
grant cancel_sql_role to dev_user;
grant alter system to cancel_sql_role;

--> to dev user 

/**************************************/




/**************************************/


-- What to do?
-- Invoker's rights is definitely out 
--  - can bypass 
-- Definer's rights is better 
--  - but still risky
-- Enter code based access control!


-- Revoke dev access
revoke cancel_sql_role from dev_user;


-- Grant role to package/procedure/function
-- Privilege is only active while calling package
grant cancel_sql_role to package admin_utils;
grant cancel_sql_role to dba_admin; -- code owner must have role


/* Check who has the role */
select * from dba_role_privs
where  granted_role = 'CANCEL_SQL_ROLE';

/* See the priv is granted to the package */
select * from dba_code_role_privs
where  owner = user; 

set role all;

-- This works as dev_user and admin/dba
exec admin_utils.cancel_sql ( 10, 200 );
--> dev_user 







-- Want to tighten things up: 
-- only cancel your own sessions!
-- Check session user = current user 
-- Need direct grant to sys.v_$session
select * from user_tab_privs
where  table_name like '%SESS%';


-- Update the package to check v$session in cancel/kill
-- Only proceed if the session belongs to the caller; else raise an exception
create or replace package body admin_utils 
as
  function is_user_session ( 
    sid integer, serial# integer
  ) return boolean as
    user_session boolean;
  begin
    select exists (
      select * from v$session v
      where  v.sid = is_user_session.sid
      and    v.serial# = is_user_session.serial#
      and    v.username = user
    ) into user_session;

    return user_session;

  end;

  procedure cancel_sql (
    sid integer, serial# integer
  ) as 
  begin 
    if is_user_session ( sid, serial# ) then 
      execute immediate 
      q'[alter system cancel sql ']' || 
        sid || ',' || serial# || '''';
    else
      raise_application_error ( -20001, q'[That's not your session!]' );
    end if;
  end;
  
  procedure kill_session (
    sid integer, serial# integer
  ) as 
  begin 
    if is_user_session ( sid, serial# ) then 
      execute immediate 
      q'[alter system kill session ']' || 
        sid || ',' || serial# || '''';
    else 
      raise_application_error ( -20001, q'[That's not your session!]' );
    end if;
  end;
  
  procedure unlock_user (
    username varchar2
  ) as 
  begin 
    execute immediate 
    'alter user ' || 
    dbms_assert.simple_sql_name ( username ) || 
    ' account unlock';
  end;
end;
/

-- > dev_user



-- we're still invoker's rights 
-- => dev needs access to v$session too!
select object_name, procedure_name, authid 
from   user_procedures;





-- Could grant that to cancel_sql_role too; 
-- but as we have direct access anyway
-- go back to definer's rights
create or replace package admin_utils 
  authid definer as

  procedure cancel_sql (
    sid integer, serial# integer
  );
  
  procedure kill_session (
    sid integer, serial# integer
  );
  
  procedure unlock_user (
    username varchar2
  );
end;
/

/* Recompiling package spec -> CBAC revoked! */
select * from dba_code_role_privs
where  owner = user; 

/* Regrant */
grant cancel_sql_role to package admin_utils;

exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
--> dev user; now works








/* So which user are you running as and roles do you have? */
select 
    sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ),
    sys_context ( 'userenv', 'current_user' ),
    sys_context ( 'userenv', 'session_user' );



/* The current_user changes for definers vs invokers 
   As do the active roles; use sys_context ( 'sys_session_roles' ) 
   to see this
   Create the four combinations of procedures, see how these values 
   change depending on context and user calling them
*/
create or replace procedure definers 
  authid definer as 
begin
  dbms_output.put_line ( 
    'Definers rights ' || chr(10) || 
    'Has role ' || sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ) || chr(10) || 
    'Current user ' || sys_context ( 'userenv', 'current_user' ) || chr(10) || 
    'Session user ' || sys_context ( 'userenv', 'session_user' ) 
  ) ;
end;
/

create or replace procedure invokers
  authid current_user as 
begin
  dbms_output.put_line ( 
    'Invokers rights ' || chr(10) || 
    'Has role ' || sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ) || chr(10) || 
    'Current user ' || sys_context ( 'userenv', 'current_user' ) || chr(10) || 
    'Session user ' || sys_context ( 'userenv', 'session_user' ) 
  ) ;
end;
/

create or replace procedure definers_cbac
  authid definer as 
begin
  dbms_output.put_line ( 
    'CBAC definers rights' || chr(10) ||
    'Has role ' || sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ) || chr(10) || 
    'Current user ' || sys_context ( 'userenv', 'current_user' ) || chr(10) || 
    'Session user ' || sys_context ( 'userenv', 'session_user' ) 
  ) ;
end;
/


create or replace procedure invokers_cbac
  authid current_user as 
begin
  dbms_output.put_line ( 
    'CBAC invokers rights' || chr(10) ||
    'Has role ' || sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ) || chr(10) || 
    'Current user ' || sys_context ( 'userenv', 'current_user' ) || chr(10) || 
    'Session user ' || sys_context ( 'userenv', 'session_user' ) 
  ) ;
end;
/


/* Grant permissions to new procs */
grant cancel_sql_role to procedure invokers_cbac;
grant cancel_sql_role to procedure definers_cbac;

grant execute on invokers to dev_user;
grant execute on definers to dev_user;
grant execute on invokers_cbac to dev_user;
grant execute on definers_cbac to dev_user;


select object_name, procedure_name, authid 
from   user_procedures;
/* Check CBAC */
select * from dba_code_role_privs
where  owner = user; 

select 
    sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ),
    sys_context ( 'userenv', 'current_user' ),
    sys_context ( 'userenv', 'session_user' );

begin
  definers;
  invokers;
  definers_cbac;
  invokers_cbac;
end;
/
--> dev_user



/********************************************/




/********************************************/

/* Support user needs to be able to unlock accounts */
/* Use CBAC to enable this */
create role unlock_user_role;
grant alter user to unlock_user_role;

grant unlock_user_role to dba_admin;
grant unlock_user_role to package admin_utils;

grant execute on admin_utils to support_user;
set role all;

exec admin_utils.unlock_user ( 'TEST' );
-- > support user 






/* ADMIN_UTILS is a powerful package! 
   But exec grant is for the whole thing 
   How to allow only part of the package to be used?   

   Define accessor lists!   
   
   Each procedure in the package will be limited to a 
   standalone procedure of the same name */
create or replace package admin_utils 
  authid definer as
  procedure cancel_sql (
    sid integer, serial# integer
  ) accessible by ( cancel_sql );
  
  procedure kill_session (
    sid integer, serial# integer
  ) accessible by ( kill_session );
  
  procedure unlock_user (
    username varchar2
  ) accessible by ( unlock_user );
end;
/

create or replace package body admin_utils 
as
  function is_user_session ( 
    sid integer, serial# integer
  ) return boolean as
    user_session boolean;
  begin
    select exists (
      select * from v$session v
      where  v.sid = is_user_session.sid
      and    v.serial# = is_user_session.serial#
      and    v.username = user
    ) into user_session;

    return user_session;

  end;

  procedure cancel_sql (
    sid integer, serial# integer
  ) accessible by ( cancel_sql ) as 
  begin 
    if is_user_session ( sid, serial# ) then 
      execute immediate 
      q'[alter system cancel sql ']' || 
        sid || ',' || serial# || '''';
    else
      raise_application_error ( -20001, q'[That's not your session!]' );
    end if;
  end;
  
  procedure kill_session (
    sid integer, serial# integer
  ) accessible by ( kill_session ) as 
  begin 
    if is_user_session ( sid, serial# ) then 
      execute immediate 
      q'[alter system kill session ']' || 
        sid || ',' || serial# || '''';
    else 
      raise_application_error ( -20001, q'[That's not your session!]' );
    end if;
  end;
  
  procedure unlock_user (
    username varchar2
  ) accessible by ( unlock_user ) as 
  begin 
    execute immediate 
    'alter user ' || 
    dbms_assert.simple_sql_name ( username ) || 
    ' account unlock';
  end;
end;
/


-- Now nobody can call these directly: not even the code owner!
exec admin_utils.cancel_sql ( 10, 200 );
exec admin_utils.kill_session ( 10, 200 );
exec admin_utils.unlock_user ( 'TEST' );



/* Doing this has revoked CBAC access */
select * from dba_code_role_privs
where  owner = user; 




/* Regrant CBAC */
grant unlock_user_role, cancel_sql_role
  to package admin_utils;



/* Create accessible by procs */
create or replace procedure cancel_sql (
  sid integer, serial# integer
) as 
begin 
  admin_utils.cancel_sql ( sid, serial# );
end;
/

/* Can only cancel via proc */
exec cancel_sql ( 10, 200 );

create or replace procedure unlock_user (
  username varchar2
) as 
begin 
  admin_utils.unlock_user ( username );
end;
/

/* Can only cancel via proc */
exec unlock_user ( 'TEST' );

/* Give access as needed */
grant execute on unlock_user to support_user;
grant execute on unlock_user to dev_user;
grant execute on cancel_sql to dev_user; 
--> support_user






/* Revoke all package access */
revoke execute on admin_utils
  from support_user;
revoke execute on admin_utils
  from dev_user;



/**************************************/




/**************************************/



create or replace function f return int accessible by ( blah ) as 
begin
  return 1;
end;
/

select f;
create or REPLACE function blah ( p int ) return int as
  l int;
begin
  if p = 1 then 
    select f into l;
  elsif p = 2 then
    execute immediate 'select f' into l;
  else 
    l := f;
  end if;
  return l;
end;
/
select blah(1);
select blah(2);
select blah(3);

