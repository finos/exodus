REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off

REM *********************************************************************************************
REM ** RUN AS migration tool user
REM *********************************************************************************************

REM **
REM ** Create Audit Tables.
REM **

DECLARE
   -- Non-scalar parameters require additional processing
   pti_table_names aud_generator.table_name_tab_typ;
BEGIN
   EXECUTE IMMEDIATE 'truncate table aud_generator_log ';
   FOR rec IN (SELECT rownum
                     ,table_name
                 FROM user_tables
                WHERE table_name LIKE 'PRE_ET%'
                ORDER BY 2)
   LOOP
      pti_table_names(rec.rownum) := rec.table_name;
   END LOOP;
   -- Call the procedure
   aud_generator.create_audit_objs(pvi_owner       => 'PRE_ETL_OWNER'
                                  ,pti_table_names => pti_table_names);
END;
/

REM **
REM ** Create Introspection Tables.
REM **

BEGIN
  pkg_pre_etl_utilities.pr_create_intro_table;
END;
/

exit
