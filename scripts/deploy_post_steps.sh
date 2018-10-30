#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Deploy Post Steps."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying Using :-"
echo $deploy_usr / $deploy_pwd

echo "Stage 1 - Create Audit Tables..."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @post_code_install_script.sql
echo "Stage 2 - Compile Native..."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @compile_native.sql