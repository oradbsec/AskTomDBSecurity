

/* Connect as support user */
select user;

/* We can unlock accounts ... */
exec dba_admin.admin_utils.unlock_user ( 'TEST' );






/* ...but also cancel/kill sessions */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
exec dba_admin.admin_utils.kill_session ( 10, 200 );

-- < dba








set role all;
/* Can't call packaged procs */
exec dba_admin.admin_utils.cancel_sql ( 10, 200 );
exec dba_admin.admin_utils.kill_session ( 10, 200 );


/* We can now only call unlock_user as support_user */
exec dba_admin.unlock_user ( 'TEST' );
exec dba_admin.cancel_sql ( 10, 200 );

/* And we can't bypass the proc! */
alter user test account unlock;

-- < dev_user