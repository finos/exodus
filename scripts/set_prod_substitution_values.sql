REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off

define real_prod_yn = '&1'

REM *********************************************************************************************
REM ** RUN AS PRE_ETL_OWNER
REM *********************************************************************************************

UPDATE pre_etl_substitution_values pesv
   SET pesv.substitution_value = (select value from v$parameter where name = 'cpu_count')
 WHERE pesv.context_name = 'PROD'
   AND upper(pesv.substitution_key)= '${PARALLELISM}'
   AND '&real_prod_yn' = 'Y'
/

UPDATE pre_etl_substitution_values pesv
   SET pesv.substitution_value = 'PROD_STG_ETL_OWNER'
 WHERE pesv.context_name = 'PROD'
   AND pesv.substitution_key = '${STG_ETL_OWNER}'
   AND '&real_prod_yn' = 'Y'
/

UPDATE pre_etl_substitution_values pesv
   SET pesv.substitution_value = NULL
 WHERE pesv.context_name = 'PROD'
   AND upper(pesv.substitution_key)= '${TARGET_PREFIX}'
   AND '&real_prod_yn' = 'Y'
/

COMMIT
/

exit