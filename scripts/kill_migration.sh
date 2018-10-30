#!/bin/bash
echo "***********************************************************************************"
echo "**"
echo "** Killing the migration run.  You will need to confirm your request."
echo "**"
echo "** You may need to do this before restarting a migration even if the migration"
echo "** has terminated itself due to a run error."
echo "**"
echo "***********************************************************************************"
echo
RED='\033[0;31m'
NC='\033[0m' # No Color
PROTECT_DB="MCP01PD"

source ./config

function execute_script {
  read -p "ALERT : KILL The migration  Do you wish to continue? " yn

  if [[ $yn =~ ^[Yy]$ ]]
  then
    sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @kill_migration.sql
    echo "************************************************************************"
    echo "**"
    echo "** Migration Killed.  Check the ON_ETL_LOG."
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



