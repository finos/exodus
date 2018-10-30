set define off

PROMPT Deploying : aud_generator.sps
@@../code/aud_generator.sps
PROMPT Deploying : pkg_pre_etl_tools.sps
@@../code/pkg_pre_etl_tools.sps
PROMPT Deploying : pkg_pre_etl_utilities.sps
@@../code/pkg_pre_etl_utilities.sps
PROMPT Deploying : migration_run_framework.sps
@@../code/migration_run_framework.sps
PROMPT Deploying : pkg_pre_etl_code_lib.sps
@@../code/pkg_pre_etl_code_lib.sps
PROMPT Deploying : user_backup_restore_steps.sps
@@../code/user_backup_restore_steps.sps

PROMPT Deploying : aud_generator.spb
@@../code/aud_generator.spb
PROMPT Deploying : pkg_pre_etl_tools.spb
@@../code/pkg_pre_etl_tools.spb
PROMPT Deploying : pkg_pre_etl_utilities.spb
@@../code/pkg_pre_etl_utilities.spb
PROMPT Deploying : migration_run_framework.spb
PROMPT Deploying : pkg_pre_etl_code_lib.spb
@@../code/pkg_pre_etl_code_lib.spb
@@../code/migration_run_framework.spb
PROMPT Deploying : user_backup_restore_steps.spb
@@../code/user_backup_restore_steps.spb

PROMPT Deploying : trg_pec_biu.trg
@@../code/trg_pec_biu.trg
PROMPT Deploying : trg_pesv_biu.trg
@@../code/trg_pesv_biu.trg
PROMPT Deploying : trg_pemg_biu.trg
@@../code/trg_pemg_biu.trg


grant execute on pkg_pre_etl_tools TO PRE_ETL_RO;

exit;