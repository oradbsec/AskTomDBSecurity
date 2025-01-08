
















/* Connect as dev user */
select user;




exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
-- Still need privileges!

--< admin






/* Reset the roles */
set role all;
/* Have privileges via role => works! */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );







-- ...but they can also run it directly!
alter system cancel sql '100, 200';


/**************************************/





/**************************************/



/* Reset roles */
set role all;
/* Dev user can now cancel sql... */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );

/* ...but only via the package */
alter system cancel sql '10, 200';
--< Back to admin






/* dev user has no v$session privs! */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
-- < admin







/* Now it works */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
-- < admin




select 
    sys_context ( 'sys_session_roles', 'CANCEL_SQL_ROLE' ),
    sys_context ( 'userenv', 'current_user' ),
    sys_context ( 'userenv', 'session_user' );

begin
  dba_admin.definers;
  dba_admin.invokers;
  dba_admin.definers_cbac;
  dba_admin.invokers_cbac;
end;
/

/***************************************/




/***************************************/

set role all;
/* Can't call packaged procs */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
exec dba_admin.admin_utils.kill_session ( 10, 200 );
/* Only stand-alone procs */
exec dba_admin.unlock_user ( 'TEST' );
exec dba_admin.cancel_sql ( 10, 200 );


/* And we can't bypass the procs! */
alter user test account unlock;
alter system cancel sql '10, 100';

