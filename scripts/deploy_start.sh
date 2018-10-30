#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Deploy schemas."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying using :-"
echo $admin_usr / $admin_pwd $admin_ext

echo "Stage 1 - Create Schemas..."
sqlplus -S -L $admin_usr/$admin_pwd@$target_db $admin_ext @sys_setup_users.sql $temp_ts $tool_ts $stg_ts $stg_types $deploy_usr $deploy_pwd $ro_usr $ro_pwd
echo "Stage 2 - Create Objects..."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @setup_pre_etl.sql $tool_ts $stg_types
