REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off
REM set serveroutput on verify on
REM set termout on


REM *********************************************************************************************
REM ** RUN AS SYS (or ADMIN if cloud based)....
REM *********************************************************************************************

define temp_ts   = '&1'
define tool_ts   = '&2'
define stg_ts    = '&3'
define stg_types = '&4'
define pet_usr   = '&5'
define pet_pwd   = '&6'
define ro_usr    = '&7'
define ro_pwd    = '&8'

REM *********************************************************************************************
REM ** CREATE THE &pet_usr SCHEMA
REM *********************************************************************************************

create user &pet_usr identified by "&pet_pwd"
  DEFAULT   TABLESPACE &tool_ts
  TEMPORARY TABLESPACE &temp_ts
  QUOTA UNLIMITED   ON &tool_ts
/

alter user pre_etl_owner profile application_user
/

grant connect, resource to &pet_usr
/

grant execute on dbms_crypto to &pet_usr
/

grant select any table to &pet_usr
/

grant insert any table to &pet_usr
/

grant delete any table to &pet_usr
/

grant update any table to &pet_usr
/

grant select any sequence to &pet_usr
/

grant alter any sequence to &pet_usr
/

grant alter any table to &pet_usr
/

grant analyze any to &pet_usr
/

grant drop any table to &pet_usr
/

grant create any procedure to &pet_usr
/

grant execute any procedure to &pet_usr
/

grant create any index to &pet_usr
/

grant create any context to &pet_usr
/

grant drop any context to &pet_usr
/

grant select any dictionary to &pet_usr
/

grant execute on dbms_lock to &pet_usr
/

grant execute on dbms_scheduler to &pet_usr
/

grant create job to &pet_usr
/

grant manage scheduler to &pet_usr
/

REM ** Might not be possible to grant this on some Instances (ignore failure to grant) **
grant select on dba_scheduler_job_classes to &pet_usr
/

BEGIN
  DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SYSTEM_PRIVILEGE(
   GRANTEE_NAME   => upper('&pet_usr'),
   PRIVILEGE_NAME => 'ADMINISTER_RESOURCE_MANAGER',
   ADMIN_OPTION   => FALSE);
END;
/

REM *********************************************************************************************
REM ** CREATE THE pre_etl_ro READONLY SCHEMA.
REM *********************************************************************************************

-- AS sys
CREATE USER &ro_usr identified by "&ro_pwd"
  DEFAULT   TABLESPACE &tool_ts
  TEMPORARY TABLESPACE &temp_ts
  QUOTA UNLIMITED   ON &tool_ts
/

GRANT CREATE SESSION TO &ro_usr
/

CREATE OR REPLACE TRIGGER on_logon_user_pero
   AFTER logon ON DATABASE
   WHEN ( ora_login_user = upper( '&ro_usr' ) )
BEGIN
   EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = &pet_usr';
END;
/

REM *********************************************************************************************
REM ** CREATE THE *_stg_etl_owner SCHEMA(s) (RUNS AFTER THE PRE_ETL_SCHEMA IS CREATED)
REM *********************************************************************************************

DECLARE
   PROCEDURE pr_exec
   (
      i_command     IN VARCHAR2
     ,i_ignore_fail IN BOOLEAN DEFAULT FALSE
   ) IS
   BEGIN
      EXECUTE IMMEDIATE i_command;
   EXCEPTION
      WHEN OTHERS THEN
         IF NOT i_ignore_fail
         THEN
            dbms_output.put_line(SQLERRM);
         END IF;
         -- never fail - don't re-raise.
   END pr_exec;
BEGIN
   FOR i_buf IN (SELECT regexp_substr('&stg_types', '[^,]+', 1, rownum) AS prefix
                   FROM dual
                 CONNECT BY LEVEL <=
                            regexp_count('&stg_types', '[^,]+'))
   LOOP

      pr_exec(i_command => 'CREATE USER ' || lower(i_buf.prefix) ||
                           '_stg_etl_owner identified by ' ||
                           lower(i_buf.prefix) || '_stg_etl_owner' ||
                           ' DEFAULT   TABLESPACE &stg_ts' ||
                           ' TEMPORARY TABLESPACE &temp_ts' ||
                           ' QUOTA UNLIMITED   ON &stg_ts');

      pr_exec(i_command => 'grant connect, resource to ' ||
                           i_buf.prefix || '_stg_etl_owner');

      -- Might not be possible to grant this on some Instances (ignore failure to grant).
      pr_exec(i_command     => 'grant select on dba_directories to ' ||
                               i_buf.prefix || '_stg_etl_owner'
             ,i_ignore_fail => TRUE);

      pr_exec(i_command => 'grant create any table to ' ||
                           i_buf.prefix || '_stg_etl_owner');

      -- Might not be possible to grant this on some Instances (ignore failure to grant) **
      pr_exec(i_command     => 'grant create any directory to ' ||
                               i_buf.prefix || '_stg_etl_owner'
             ,i_ignore_fail => TRUE);

      pr_exec(i_command => 'grant drop any directory to ' ||
                           i_buf.prefix || '_stg_etl_owner');

      pr_exec(i_command => 'grant execute on dbms_lock to ' ||
                           i_buf.prefix || '_stg_etl_owner');

      pr_exec(i_command => 'grant create job, manage scheduler to ' ||
                           i_buf.prefix || '_stg_etl_owner');

   END LOOP;
END;
/

exit

