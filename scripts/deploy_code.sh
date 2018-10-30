#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Deploy Code."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying Using :-"
echo $deploy_usr / $deploy_pwd

echo "Stage 1 - Deploy Code.."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @deploy_code.sql
