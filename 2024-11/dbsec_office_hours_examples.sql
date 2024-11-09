/* This is an example. This is not production code.    */
/* This example comes with no (zero) warranty.         */
/* Review it before you run it.                        */

-- delete to clean-up
drop role sh1_admin;
drop user sh1 cascade;
drop user sh1_reader;

-- create the test user
create user sh1 identified by WElcome_123#;
grant connect, resource to sh1;
grant unlimited tablespace to sh1;

-- create the role and grant privileges
create role sh1_admin;

GRANT READ ON sys.redaction_policies TO sh1_admin;
GRANT READ ON sys.redaction_columns TO sh1_admin;
GRANT READ ON sys.redaction_expressions TO sh1_admin;
GRANT READ on sys.redaction_values_for_type_full TO sh1_admin;

GRANT EXECUTE ON dbms_redact TO sh1_admin;

GRANT administer redaction policy TO sh1_admin;

-- grant the role to your user
grant sh1_admin to sh1 with admin option;

-- connect and get started

connect sh1/WElcome_123#@localhost:1521/pdb23a

-- Drop the existing table t1
DROP TABLE t1;

-- Re-create table t1 with the specified structure
CREATE TABLE t1 (
  account_number CHAR(12),
  first_name     VARCHAR2(20),
  last_name      VARCHAR2(20),
  email          VARCHAR2(50),
  phone_number   VARCHAR2(20),
  dob            DATE,
  ssn            CHAR(11),
  visa           VARCHAR2(20),
  amex           NUMBER(15)
);

-- Insert statements with random dates in the 20th century for the dob column
INSERT INTO t1 (account_number, first_name, last_name, email, phone_number, dob, ssn, visa, amex) VALUES
('C-000012345', 'John', 'Smith', 'John.Smith@example.com', '(555) 123-4567', TO_DATE('1968-04-04', 'YYYY-MM-DD'), '123-45-6789', '5386-9098-1234-5678', 340740123456789);

INSERT INTO t1 (account_number, first_name, last_name, email, phone_number, dob, ssn, visa, amex) VALUES
('C-000013494', 'Jane', 'Johnson', 'Jane.Johnson@example.com', '(555) 987-6543', TO_DATE('1964-11-17', 'YYYY-MM-DD'), '987-65-4321', '5102-2009-8765-4321', 379049712345678);

INSERT INTO t1 (account_number, first_name, last_name, email, phone_number, dob, ssn, visa, amex) VALUES
('C-000098765', 'Alice', 'Williams', 'Alice.Williams@example.com', '(555) 246-8135', TO_DATE('1983-07-23', 'YYYY-MM-DD'), '246-81-3579', '5197-6271-3579-2468', 346790724681357);

INSERT INTO t1 (account_number, first_name, last_name, email, phone_number, dob, ssn, visa, amex) VALUES
('C-000024681', 'Bob', 'Brown', 'Bob.Brown@example.com', '(555) 369-2580', TO_DATE('1902-11-12', 'YYYY-MM-DD'), '369-25-8024', '5317-3668-0246-8135', 372867235791234);

INSERT INTO t1 (account_number, first_name, last_name, email, phone_number, dob, ssn, visa, amex) VALUES
('C-000013579', 'Emily', 'Jones', 'Emily.Jones@example.com', '(555) 159-7532', TO_DATE('1929-09-09', 'YYYY-MM-DD'), '159-75-3210', '5472-2743-2109-8765', 343315467890123);

COMMIT;

-- query the data
set lines 210
set pages 9999
column account_number format a14
column first_name format a14
column last_name format a14
column email format a30
column phone_number format a14
column amex format 999999999999999
select * from t1;

/* 
-- identify the column data type. references

https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Data-Types.html

1: VARCHAR2
2: NUMBER
12: DATE
96: CHAR
112: CLOB
113: BLOB
*/

SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(account_number), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(last_name), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(phone_number), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(dob), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(ssn), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(visa), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';
SELECT TO_NUMBER(REGEXP_SUBSTR(DUMP(amex), 'Typ=(\d+)', 1, 1, NULL, 1)) AS data_type FROM t1 WHERE last_name = 'Jones';

-- drop the policy
-- not necessary here but you can use this later too
BEGIN
  DBMS_REDACT.DROP_POLICY(
    object_schema       => 'SH1',
    object_name         => 'T1',
    policy_name         => 'REDACT_T1');
END;
/

-- add the policy
BEGIN
 DBMS_REDACT.ADD_POLICY(
  object_schema => 'SH1',
  object_name => 'T1',
  policy_name => 'REDACT_T1',
  expression => '1=1'
 );
END;
/

-- view the results before and after you apply the redaction policy to the first_name column
-- this will NULLIFY the last_name column
select first_name from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema       => 'SH1',
  object_name         => 'T1',
  column_name         => 'FIRST_NAME',
  policy_name         => 'REDACT_T1',
  action 	     => DBMS_REDACT.ADD_COLUMN,
  function_type       => DBMS_REDACT.NULLIFY
 );
END;
/

select first_name from t1 where last_name = 'Jones';

-- view the results before and after you apply the redaction policy to amex column
-- this will randomly redact the column - returns random numbers

column amex format 999999999999999
select amex from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema       	=> 'SH1',
  object_name         	=> 'T1',
  policy_name         	=> 'REDACT_T1',
  action                  => DBMS_REDACT.ADD_COLUMN,
  column_name             => 'AMEX',
  function_type           => DBMS_REDACT.RANDOM
);
END;
/
select amex from t1 where last_name = 'Jones';

-- view the results before and after you apply the redaction policy to the account_number column
-- this will PARTIALLY the account_number column, turning the last 4 into XXXX

select account_number from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema       => 'SH1',
  object_name         => 'T1',
  column_name         => 'ACCOUNT_NUMBER',
  policy_name         => 'REDACT_T1',
  action 	     => DBMS_REDACT.ADD_COLUMN,
  function_type       => DBMS_REDACT.PARTIAL,
  function_parameters => 'VVVVVVVVVVVV,VVVVVVVVVVVV,X,9,12'
 );
END;
/

select account_number from t1 where last_name = 'Jones';

-- view the results before and after you apply the redaction policy to the visa column
-- this will PARTIALLY the visa column using the built-in partial redaction parameter REDACT_CCN16_F12

select visa from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema       	=> 'SH1',
  object_name         	=> 'T1',
  policy_name         	=> 'REDACT_T1',
  action                  => DBMS_REDACT.ADD_COLUMN,
  column_name             => 'VISA',
  function_type           => DBMS_REDACT.PARTIAL,
  function_parameters     => DBMS_REDACT.REDACT_CCN16_F12
 );
END;
/

select visa from t1 where last_name = 'Jones';

-- view the results before and after you apply the redaction policy to the visa column
-- You can use the CCN16 formatted too

select visa from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema       	=> 'SH1',
  object_name         	=> 'T1',
  policy_name         	=> 'REDACT_T1',
  action                  => DBMS_REDACT.MODIFY_COLUMN,
  column_name             => 'VISA',
  function_type           => DBMS_REDACT.PARTIAL,
  function_parameters     => DBMS_REDACT.REDACT_CCN16_F12
 );
END;
/

select visa from t1 where last_name = 'Jones';


-- view the results before and after you apply the redaction policy to the EMAIL column
-- this is an example where you build your regular expression

select email from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema     => 'SH1',
  object_name       => 'T1',
  policy_name       => 'REDACT_T1',
  action 	   => DBMS_REDACT.ADD_COLUMN,
  column_name 	   => 'EMAIL',
  function_type 	   => DBMS_REDACT.REGEXP,
  regexp_pattern    => '(.+)@(.+\.[A-Za-z]{2,4})' ,
  regexp_replace_string => '[redacted]@\2'	
  );
END;
/

select email from t1 where last_name = 'Jones';


-- this is an example where you use a BUILT-IN function for regular expression
-- you redact the EMAIL_NAME, the first half of the email address before the "@"

select email from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema     => 'SH1',
  object_name       => 'T1',
  policy_name       => 'REDACT_T1',
  action 	   => DBMS_REDACT.MODIFY_COLUMN,
  column_name 	   => 'EMAIL',
  function_type     => DBMS_REDACT.REGEXP,
  regexp_pattern    => DBMS_REDACT.RE_PATTERN_EMAIL_ADDRESS,
  regexp_replace_string => DBMS_REDACT.RE_REDACT_EMAIL_NAME
 );
END;
/


-- this is an example where you use a BUILT-IN function for regular expression
-- instead of redacting the EMAIL_NAME, you redact the EMAIL_DOMAIN

select email from t1 where last_name = 'Jones';

BEGIN
 DBMS_REDACT.ALTER_POLICY(
  object_schema     => 'SH1',
  object_name       => 'T1',
  policy_name       => 'REDACT_T1',
  action 	   => DBMS_REDACT.MODIFY_COLUMN,
  column_name 	   => 'EMAIL',
  function_type     => DBMS_REDACT.REGEXP,
  regexp_pattern    => DBMS_REDACT.RE_PATTERN_EMAIL_ADDRESS,
  regexp_replace_string => DBMS_REDACT.RE_REDACT_EMAIL_NAME
 );
END;
/

select email from t1 where last_name = 'Jones';

--
-- create the named redaction expression to use on one or more column

BEGIN
 DBMS_REDACT.CREATE_POLICY_EXPRESSION(
  policy_expression_name => 'REDACT_UNLESS_ANALYTICS',
  expression => 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') != ''SH1''');
END;
/

select policy_expression_name, expression, object_owner from redaction_expressions;


-- apply the named policy to the visa column to override the existing policy expression (1=1)
-- query before and after the change
-- as SH1, you should now see the visa column data

select account_number, first_name, last_name, email, visa from t1 where last_name = 'Jones';

BEGIN
  DBMS_REDACT.APPLY_POLICY_EXPR_TO_COL(
    object_schema => 'SH1',
    object_name => 'T1',
    column_name => 'VISA',
    policy_expression_name => 'REDACT_UNLESS_SH1'
  );
END;
/

select account_number, first_name, last_name, email, visa from t1 where last_name = 'Jones';

--
-- query the redacted columns and named policy expression
column column_name format a20
column function_type format a20
column function_parameters format a50
column policy_expression_name format a24

select a.column_name, a.function_type, a.function_parameters, b.policy_expression_name
  from redaction_columns a left join redaction_expressions b
    on (a.object_name = b.object_name 
       and a.object_owner = b.object_owner
       and a.column_name = b.column_name);



