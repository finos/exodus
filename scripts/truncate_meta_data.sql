DECLARE
   TYPE t_tab IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
   l_tab      t_tab;
   l_instance VARCHAR2(30);
   ex_schema_not_exist EXCEPTION;
   ex_ref_by_fk        EXCEPTION;
   PRAGMA EXCEPTION_INIT(ex_schema_not_exist, -1918);
   PRAGMA EXCEPTION_INIT(ex_ref_by_fk, -2266);
BEGIN
   SELECT instance_name INTO l_instance FROM v$instance;
   IF l_instance = 'DEV02MCP_1'
   THEN
      raise_application_error(-20000, 'Defended INSTANCE.');
   END IF;
   --
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_COMMENTS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_FIND_SWAP';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_JSON_DOCUMENT';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_JSON_LINES';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MAPPED';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_DETAIL';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_HEADER';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_RUN_HINT';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_SRC';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_SRC_INLINE_V';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_RELATED_JSON_LINES';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_RUN_CONTEXTS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_SUBSTITUTION_VALUES';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_DOC_VALID_CONTEXTS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_PARAMS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MR_GROUP';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_GROUPS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_CODE_LIB';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_MIGRATION_LIBS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_DB2_COLUMNS';
   l_tab(l_tab.COUNT + 1) := 'PRE_ETL_DB2_TABLES';
   --
   FOR i IN l_tab.FIRST .. l_tab.LAST
   LOOP
      BEGIN
         EXECUTE IMMEDIATE 'truncate table ' || l_tab(i);
      EXCEPTION
         WHEN ex_ref_by_fk THEN
            EXECUTE IMMEDIATE 'delete from ' || l_tab(i);
            COMMIT;
      END;
   END LOOP;
END;
/

EXIT
