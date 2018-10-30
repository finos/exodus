#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Compile Code."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying Using :-"
echo $deploy_usr / $deploy_pwd

echo "Stage 1 - Compiling Code.."
sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @compile_native.sql
