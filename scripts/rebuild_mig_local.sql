REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off

define stg_types = '&1'
define initialiser_name = '&2'
define initialiser_batch = '&3'

REM Initialise work tables.
REM ** IMPORTANT NOTE : Some of the initialisation will ONLY work if the SOURCE (staged data) already
REM                     exists.

BEGIN
   IF '&initialiser_name' IS NOT NULL
   THEN
      FOR i_buf IN (SELECT regexp_substr('&stg_types'
                                        ,'[^,]+'
                                        ,1
                                        ,rownum) AS context_name
                      FROM dual
                    CONNECT BY LEVEL <=
                               regexp_count('&stg_types', '[^,]+'))
      LOOP
         pkg_pre_etl_tools.pr_destroy_context;
         pkg_pre_etl_tools.pr_set_context(i_attr  => migration_run_framework.fn_ctx_run_context
                                         ,i_value => upper(i_buf.context_name));
         migration_run_framework.pr_master_job(i_batch                => to_number(nvl('&initialiser_batch'
                                                                                      ,'0'))
                                              ,i_migration_group      => REPLACE('&initialiser_name'
                                                                                ,'_'
                                                                                ,' ')
                                              ,i_suppress_emails_bool => TRUE);
         pkg_pre_etl_tools.pr_destroy_context;
      END LOOP;
   END IF;
END;
/


REM Use this to rebuild tables that have been used in a migration from a locally built table
REM for example a user table that is built as a result of the migration setup procedures.
REM
REM *********************************************************************************************
REM ** RUN AS PRE_ETL_OWNER
REM *********************************************************************************************

BEGIN
   FOR i_buf IN (SELECT DISTINCT pem.table_name
                   FROM (SELECT check_set.mr_group
                               ,check_set.relationship_group_id
                               ,(SELECT MIN(CASE
                                               WHEN pedc.column_name IS NULL
                                                    OR
                                                    (utc.column_name IS NULL AND
                                                    pedt.table_name IS NOT NULL) THEN
                                                'FALSE'
                                               ELSE
                                                'TRUE'
                                            END) is_mapping_valid
                                   FROM pre_etl_mapped pem
                                   LEFT JOIN pre_etl_db2_columns pedc
                                     ON (pedc.table_name =
                                        pem.table_name AND
                                        pedc.column_name =
                                        pem.column_name)
                                   LEFT JOIN user_tab_cols utc
                                     ON (utc.table_name =
                                        pem.table_name AND
                                        utc.column_name =
                                        pem.column_name)
                                   LEFT JOIN pre_etl_db2_tables pedt
                                     ON (pedt.table_name =
                                        pem.table_name AND
                                        pedt.local_hash IS NOT NULL)
                                  WHERE pem.relationship_group_id =
                                        check_set.relationship_group_id
                                    AND pem.mr_group =
                                        check_set.mr_group) AS is_mapping_valid
                           FROM (SELECT DISTINCT mr_group
                                                ,relationship_group_id
                                   FROM pre_etl_mapped) check_set) chk_valid
                   JOIN pre_etl_mapped pem
                     ON (pem.relationship_group_id =
                        chk_valid.relationship_group_id)
                  WHERE chk_valid.is_mapping_valid = 'FALSE')
   LOOP
      pkg_pre_etl_tools.pr_recreate_mig_local(i_table_name => i_buf.table_name);
   END LOOP;
END;
/

exit
