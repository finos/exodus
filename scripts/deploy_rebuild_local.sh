#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Rebuild Migration Local Tables."
echo "** "
echo "** IMPORTANT NOTE : This will only work IF the staged data already"
echo "**                  exists on the migration database where the "
echo "**                  migration will be run from."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying Using :-"
echo $deploy_usr / $deploy_pwd

echo "Stage 1 - Rebuild Mig Local..."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @rebuild_mig_local.sql
