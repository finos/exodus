REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off

define stg_types = '&1'

REM *********************************************************************************************
REM ** RUN AS PRE_ETL_OWNER
REM *********************************************************************************************

BEGIN
   FOR i_buf IN (SELECT regexp_substr('&stg_types', '[^,]+', 1, rownum) AS context_name
                   FROM dual
                 CONNECT BY LEVEL <=
                            regexp_count('&stg_types', '[^,]+'))
   LOOP
      pkg_pre_etl_tools.pr_destroy_context;
      pkg_pre_etl_tools.pr_set_context(i_attr  => migration_run_framework.fn_ctx_run_context
                                      ,i_value => upper(i_buf.context_name));
      pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'PRE_ETL_SEQ_PEJL'
                                    ,i_sequence_owner  => 'PRE_ETL_OWNER'
                                    ,i_based_on_table  => 'PRE_ETL_JSON_LINES'
                                    ,i_based_on_schema => 'PRE_ETL_OWNER'
                                    ,i_based_on_column => 'ID');
      pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'PRE_ETL_SEQ_PERJL'
                                    ,i_sequence_owner  => 'PRE_ETL_OWNER'
                                    ,i_based_on_table  => 'PRE_ETL_RELATED_JSON_LINES'
                                    ,i_based_on_schema => 'PRE_ETL_OWNER'
                                    ,i_based_on_column => 'ID');
      pkg_pre_etl_tools.pr_reset_seq(i_sequence_name   => 'PRE_ETL_SEQ_RG'
                                    ,i_sequence_owner  => 'PRE_ETL_OWNER'
                                    ,i_based_on_table  => 'PRE_ETL_RELATED_JSON_LINES'
                                    ,i_based_on_schema => 'PRE_ETL_OWNER'
                                    ,i_based_on_column => 'RELATIONSHIP_GROUP_ID');
      pkg_pre_etl_tools.pr_destroy_context;
   END LOOP;
END;
/


exit
