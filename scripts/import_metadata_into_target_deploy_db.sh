#!/bin/bash
clear

echo "***************************************************************************"
echo "**"
echo "** Import Into Target Env (specified in config file)."
echo "** The STAGED data MUST exist on the target BEFORE this is run."
echo "**"
echo "** NOTE : The work tables will be REBUILT.  If you are fixing a live"
echo "**        migration issue, it is likely you do NOT want to rebuild the"
echo "**        work tables."
echo "**        IF SO USE : import_metadata_into_target_deploy_db_no_rebuild.sh "
echo "**"
echo "***************************************************************************"
echo

RED='\033[0;31m'
NC='\033[0m' # No Color
PROTECT_DB="MCP01PD"

source ./config

function execute_script {
  read -p "Confirm Import Of Metadata (READ THE ABOVE) : Do you wish to continue? " yn
  if [[ $yn =~ ^[Yy]$ ]]
  then
    echo "Stage 1 - Truncate Target Tables..."
    sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @truncate_meta_data.sql
    echo "Stage 2 - Import To Target Tables..."
    imp userid=$deploy_usr/$deploy_pwd@$target_db FILE=../exports/export_pre_etl.DMP TABLES = "(PRE_ETL_COMMENTS, PRE_ETL_FIND_SWAP, PRE_ETL_JSON_DOCUMENT, PRE_ETL_JSON_LINES, PRE_ETL_MAPPED, PRE_ETL_MIGRATION_DETAIL, PRE_ETL_MIGRATION_HEADER, PRE_ETL_MIGRATION_RUN_HINT, PRE_ETL_MIGRATION_SRC, PRE_ETL_MIGRATION_SRC_INLINE_V, PRE_ETL_PARAMS, PRE_ETL_RELATED_JSON_LINES, PRE_ETL_RUN_CONTEXTS, PRE_ETL_SUBSTITUTION_VALUES, PRE_ETL_DOC_VALID_CONTEXTS, PRE_ETL_MR_GROUP, PRE_ETL_MIGRATION_GROUPS, PRE_ETL_MIGRATION_LIBS, PRE_ETL_MIGRATION_CODE_LIB, PRE_ETL_DB2_COLUMNS, PRE_ETL_DB2_TABLES)" DATA_ONLY=Y CONSTRAINTS=N FEEDBACK=1000 BUFFER=1000000
    echo "Stage 3 - Set Target Sequences..."
    sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @set_target_sequences.sql $stg_types
    echo "Stage 4 - Set REAL production substitution values..."
    sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @set_prod_substitution_values.sql $real_prod_yn
    echo "Stage 5 - Rebuild Mig Local..."
    sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @rebuild_mig_local.sql $stg_types $initialiser_name $initialiser_batch

    if [[ "$validate_all_stg_types_yn" -eq Y ]]
    then
      echo "Stage 6 - Validate Migration..."
      sqlplus -L $deploy_usr/$deploy_pwd@$target_db @validate_migration.sql $stg_types $validate_migration_group
    fi

    echo "************************************************************************"
    echo "**"
    echo "** Import Complete."
    echo "**"
    echo "************************************************************************"
  fi  
}

if [[ ${target_db^^} = $PROTECT_DB ]]
then
  echo -e "${RED}********************************************************************************${NC}"
  echo -e "${RED}* CAUTION :${NC} You are executing this script to process against a ${RED}PRODUCTION DB ${NC}"
  echo -e "${RED}* ${NC}          Confirm your intention to proceed!"
  echo -e "${RED}********************************************************************************${NC}"
  read -p "Confirm (Y - proceed / N - stop)? " yn

  if [[ $yn =~ ^[Yy]$ ]]
  then
    execute_script
  fi
else
  execute_script
fi