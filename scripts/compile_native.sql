set serveroutput on size unlimited verify off

DECLARE
   l_sql VARCHAR2(2000);
BEGIN
   FOR i_buf IN (SELECT *
                   FROM dba_plsql_object_settings
                  WHERE owner = 'PRE_ETL_OWNER'
                    AND TYPE != 'PACKAGE BODY'
                    AND NAME NOT LIKE 'JSON%'
                    AND NAME NOT LIKE 'BIN$%'
                  ORDER BY decode(TYPE, 'TYPE', 1, 'PACKAGE', 2, 3))
   LOOP
      l_sql := 'ALTER ' || i_buf.type || ' ' || i_buf.name ||
               ' compile  plsql_code_type = native';
      dbms_output.put_line(l_sql);
      EXECUTE IMMEDIATE l_sql;
   END LOOP;

   FOR i_buf IN (SELECT dpos.*
                   FROM dba_plsql_object_settings dpos
                   JOIN user_objects uo
                     ON (uo.object_name = dpos.name AND
                        uo.object_type = dpos.type AND
                        uo.status = 'INVALID')
                  WHERE owner = 'PRE_ETL_OWNER'
                    AND TYPE != 'PACKAGE BODY'
                    AND NAME NOT LIKE 'JSON%'
                    AND NAME NOT LIKE 'BIN$%'
                  ORDER BY decode(TYPE, 'TYPE', 1, 'PACKAGE', 2, 3))
   LOOP
      l_sql := 'ALTER ' || i_buf.type || ' ' || i_buf.name ||
               ' compile  plsql_code_type = native';
      dbms_output.put_line(l_sql);
      BEGIN
         EXECUTE IMMEDIATE l_sql;
      EXCEPTION
         WHEN OTHERS THEN
            dbms_output.put_line('Compilation error with :' ||
                                 i_buf.name || ' / ' || i_buf.type);
      END;
   END LOOP;
END;
/


exit
