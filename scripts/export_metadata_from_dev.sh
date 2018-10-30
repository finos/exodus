#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Export PRE ETL METADATA From Dev."
echo "**"
echo "************************************************************************"

# The username/password for pre_etl_owner (aka - The Migration Definition Schema).
deploy_usr="pre_etl_owner"
deploy_pwd="bszq4wl1lToLPz5ghE10"

source_db="dev02mcp_lnp6_01"

exp userid=$deploy_usr/$deploy_pwd@$source_db FILE=dev_meta_export.dmp TABLES = "(PRE_ETL_COMMENTS, PRE_ETL_FIND_SWAP, PRE_ETL_JSON_DOCUMENT, PRE_ETL_JSON_LINES, PRE_ETL_MAPPED, PRE_ETL_MIGRATION_DETAIL, PRE_ETL_MIGRATION_HEADER, PRE_ETL_MIGRATION_RUN_HINT, PRE_ETL_MIGRATION_SRC, PRE_ETL_MIGRATION_SRC_INLINE_V, PRE_ETL_PARAMS, PRE_ETL_RELATED_JSON_LINES, PRE_ETL_RUN_CONTEXTS, PRE_ETL_SUBSTITUTION_VALUES, PRE_ETL_DOC_VALID_CONTEXTS, PRE_ETL_MR_GROUP, PRE_ETL_MIGRATION_GROUPS, PRE_ETL_MIGRATION_LIBS, PRE_ETL_MIGRATION_CODE_LIB, PRE_ETL_DB2_COLUMNS, PRE_ETL_DB2_TABLES )" FEEDBACK=1000 BUFFER=1000000

echo "************************************************************************"
echo "**"
echo "** Export Complete."
echo "**"
echo "************************************************************************"