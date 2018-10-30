#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Export Staged Data From Dev."
echo "**"
echo "************************************************************************"

# The username/password for staged dev data.
deploy_usr="dev_stg_etl_owner"
deploy_pwd="jLiKwuQF6qZlH5BO6F40"
source_db="dev02mcp_lnp6_01"

exp userid=$deploy_usr/$deploy_pwd@$source_db FILE=dev_stg_export.dmp TABLES = "(tder31_part_brkr, tdtm31_xml_link, tdtm32_xml_msg, tdtmf3_fx_data, tdtmf4_fx_hstry, tdtmf5aclrng_stat, tdtmf5_clrng_stat, tder32_part_fmly, tdtmfc_brkr_stat, tdtmfg_hktr_rprt)" FEEDBACK=1000 BUFFER=1000000

# Some fruity mucking about with .dmp file in binary mode.
# Before you get all high and mighty...I know this is a teeny-tiny bit on the naughty side.
sed -b 's/LOB ("XML_MSG_DATA_PK") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE LOGGING  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g' dev_stg_export.dmp > tmp1.dmp
sed -b 's/LOB ("CLRNG_ERROR_ID_TX") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE LOGGING  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g' tmp1.dmp > tmp2.dmp
sed -b 's/LOB ("BRKR_ERROR_IDEN_TX") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g' tmp2.dmp > tmp3.dmp

mv dev_stg_export.dmp dev_stg_export.orig
mv tmp3.dmp dev_stg_export.dmp
rm tmp2.dmp
rm tmp1.dmp

echo "************************************************************************"
echo "**"
echo "** Export Complete."
echo "**"
echo "************************************************************************"