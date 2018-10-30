#!/bin/bash
echo "************************************************************************"
echo "**"
echo "** Export Staged Data From DEV02MCP1_LNP6_01."
echo "**"
echo "************************************************************************"

# The username/password for staged dev data.
conn_usr="prod_stg_etl_owner"
conn_pwd="iqo4V1GkBJxxrU0zsb57"
source_db="dev02mcp_lnp6_01"

exp userid=$conn_usr/$conn_pwd@$source_db FILE=dev_batch1000_stg_export.dmp TABLES = "(tder31_part_brkr, tdtm31_xml_link_fx, tdtm32_xml_msg_fx, tdtmf3_fx_data, tdtmf4_fx_hstry, tdtmf5aclrng_stat, tdtmf5_clrng_stat, tder32_part_fmly, tdtmfc_brkr_stat, tdtmfg_hktr_rprt)"  QUERY=\"WHERE migration_batch_id = 1000\" FEEDBACK=50000 BUFFER=5000000

# Some fruity mucking about with .dmp file in binary mode.
# Before you get all high and mighty...I know this is a teeny-tiny bit on the naughty side.
sed -b 's/LOB ("XML_MSG_DATA_PK") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g; s/LOB ("CLRNG_ERROR_ID_TX") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g; s/LOB ("BRKR_ERROR_IDEN_TX") STORE AS SECUREFILE  (TABLESPACE "MCP_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION AUTO CACHE  NOCOMPRESS KEEP_DUPLICATES STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 BUFFER_POOL DEFAULT))//g' dev_batch1000_stg_export.dmp > tmp1.dmp
rm dev_batch1000_stg_export.dmp
mv tmp1.dmp dev_batch1000_stg_export.dmp

echo "************************************************************************"
echo "**"
echo "** Export Complete."
echo "**"
echo "************************************************************************"