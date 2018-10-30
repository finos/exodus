#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Deploy Specifics script.  Things that matter for your migration ONLY."
echo "**"
echo "************************************************************************"

source ./config

echo "Deploying Specifics Using :-"
echo $deploy_usr / $deploy_pwd

##  FOR A DEPLOYMENT OF YOUR META DATA (Any data that is unique
##  to your migration.  For example YOUR METADATA FOR YOUR 
##  TABLES AND COLUMNS SHOULD GO BELOW (Steps 1,2)
##  ===========================================================
##  
##  echo "Stage 1 - Populate Tables..."
##  sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @populate_tables.sql
##  echo "Stage 2 - Populate Columns..."
##  sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @populate_columns.sql 
##
##  Any preferences for the emission of emails etc..(Step 3)
##  Any special types for nested JSON injection  (Step 4)
##  Any code you might need to support functions/sql in the 
##  migration metadata. (Step 5)
##  ===========================================================
##
##  echo "Stage 3 - Populate Control Tables..."
##  sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @populate_pre_etl_control_tables.sql
##  echo "Stage 4 - Types for nested JSON..."
##  sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @types_for_etl_nested_json.sql 
##  echo "Stage 5 - Migration specific code..."
##  sqlplus -S -L $deploy_usr/$deploy_pwd@$target_db @deploy_code_specifics.sql 