DECLARE
   ex_fk_refs EXCEPTION;
   PRAGMA EXCEPTION_INIT(ex_fk_refs, -02266);
BEGIN
   FOR i_buf IN (SELECT table_name
                   FROM user_tables a
                  WHERE a.table_name LIKE '%/_ETL/_%' ESCAPE '/')
   LOOP
      BEGIN
         EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || i_buf.table_name;
      EXCEPTION
         WHEN ex_fk_refs THEN
            EXECUTE IMMEDIATE 'DELETE FROM ' || i_buf.table_name;
            COMMIT;
      END;
   END LOOP;
   --
   EXECUTE IMMEDIATE 'TRUNCATE TABLE aud_generator_log';
END;
/

exit


