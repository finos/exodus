REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set verify off
set serveroutput on size unlimited
define stg_types = '&1'
define validate_mig_group = '&2'

DECLARE
   /*----------------------------------------------------------------------------------------------
    *
    *  COMPILE AND VALIDATE MIGRATION.
    *
    *----------------------------------------------------------------------------------------------
   */
   l_executable_statement pkg_pre_etl_tools.t_vc_tab;
   l_errors_c_tab         pkg_pre_etl_tools.t_vc_tab;
   TYPE t_error_tab IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;
   l_error_tab                t_error_tab;
   l_errors_bool              BOOLEAN;
   l_errors_count             PLS_INTEGER := 0;
   l_dummy                    RAW(16);
   l_fail_on_first_error_bool BOOLEAN := TRUE;
   l_mig_group                VARCHAR2(200) := REPLACE('&validate_mig_group'
                                                      ,'_'
                                                      ,' ');
BEGIN
   dbms_output.put_line('Validating ' || l_mig_group ||
                        ' for &stg_types');
   FOR i_buf IN (SELECT regexp_substr('&stg_types', '[^,]+', 1, rownum) AS context_name
                   FROM dual
                 CONNECT BY LEVEL <=
                            regexp_count('&stg_types', '[^,]+'))
   LOOP
      FOR pemh_buf IN (SELECT *
                         FROM pre_etl_migration_header pemh
                        WHERE pemh.migration_group = l_mig_group)
      LOOP
         IF pemh_buf.header_type = 'P'
         THEN
            pkg_pre_etl_tools.pr_validate_statement(i_migration_group => pemh_buf.migration_group
                                                   ,i_migration_name  => pemh_buf.migration_name
                                                   ,i_context         => i_buf.context_name
                                                   ,o_tab_errors      => l_errors_c_tab
                                                   ,o_errors_bool     => l_errors_bool);
            IF l_errors_bool
            THEN
               UPDATE pre_etl_migration_header pemh
                  SET pemh.statement_has_errors_ynu = 'Y'
                WHERE pemh.migration_group = pemh_buf.migration_group
                  AND pemh.migration_name = pemh_buf.migration_name;
               COMMIT;
               l_errors_count := l_errors_count + 1;
               l_error_tab(l_errors_count) := 'Error in ' ||
                                              pemh_buf.migration_group ||
                                              ' / ' ||
                                              pemh_buf.migration_name;
            ELSE
               UPDATE pre_etl_migration_header pemh
                  SET pemh.statement_has_errors_ynu = 'N'
                WHERE pemh.migration_group = pemh_buf.migration_group
                  AND pemh.migration_name = pemh_buf.migration_name;
               COMMIT;
            END IF;
         ELSE
            pkg_pre_etl_tools.pr_create_executable_statement(i_migration_group          => pemh_buf.migration_group
                                                            ,i_migration_name           => pemh_buf.migration_name
                                                            ,i_context                  => i_buf.context_name
                                                            ,i_compile_test_bool        => TRUE
                                                            ,o_tab_executable_statement => l_executable_statement
                                                            ,o_hash                     => l_dummy
                                                            ,o_tab_errors               => l_errors_c_tab
                                                            ,o_errors_bool              => l_errors_bool);

            IF l_errors_bool
            THEN
               --
               IF l_errors_c_tab.COUNT > 0
               THEN
                  FOR i IN l_errors_c_tab.FIRST .. l_errors_c_tab.LAST
                  LOOP
                     dbms_output.put_line(l_errors_c_tab(i));
                  END LOOP;
               END IF;
               --
               pkg_pre_etl_tools.pr_update_pemh_statement(i_migration_group => pemh_buf.migration_group
                                                         ,i_migration_name  => pemh_buf.migration_name
                                                         ,i_has_errors_ynu  => 'Y'
                                                         ,i_tab_statement   => l_executable_statement);
               l_errors_count := l_errors_count + 1;
               l_error_tab(l_errors_count) := 'Error in ' ||
                                              pemh_buf.migration_group ||
                                              ' / ' ||
                                              pemh_buf.migration_name;
            ELSE
               pkg_pre_etl_tools.pr_update_pemh_statement(i_migration_group => pemh_buf.migration_group
                                                         ,i_migration_name  => pemh_buf.migration_name
                                                         ,i_has_errors_ynu  => 'N'
                                                         ,i_tab_statement   => l_executable_statement);
            END IF;
         END IF;
         --
         IF l_fail_on_first_error_bool
            AND l_errors_count > 0
         THEN
            raise_application_error(-20000
                                   ,'An error was encountered validating the migration : ' ||
                                    pemh_buf.migration_group ||
                                    ' : ' || pemh_buf.migration_name ||
                                    ' - Context :' ||
                                    i_buf.context_name);
         END IF;
      END LOOP;
      --
      IF NOT l_fail_on_first_error_bool
         AND l_errors_count > 0
      THEN
         raise_application_error(-20000
                                ,'(' || i_buf.context_name ||
                                 ') : One or more errors were encountered during validation.  Error Count (' ||
                                 l_errors_count || ').');
      END IF;
   END LOOP;
   --
   --
   dbms_output.put_line('Migration Meta Data has passed validation.');
   dbms_output.put_line('._____                       _ _  ');
   dbms_output.put_line('|  __ \                     | | | ');
   dbms_output.put_line('| |__) |_ _ ___ ___  ___  __| | | ');
   dbms_output.put_line('|  ___/ _` / __/ __|/ _ \/ _` | | ');
   dbms_output.put_line('| |  | (_| \__ \__ \  __/ (_| |_| ');
   dbms_output.put_line('|_|   \__,_|___/___/\___|\__,_(_) ');
   dbms_output.put_line('                                  ');

EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line(chr(10));
      dbms_output.put_line('.______    _ _          _ _  ');
      dbms_output.put_line('|  ____|  (_) |        | | | ');
      dbms_output.put_line('| |__ __ _ _| | ___  __| | | ');
      dbms_output.put_line('|  __/ _` | | |/ _ \/ _` | | ');
      dbms_output.put_line('| | | (_| | | |  __/ (_| |_| ');
      dbms_output.put_line('|_|  \__,_|_|_|\___|\__,_(_) ');
      dbms_output.put_line('                             ');
      --
      dbms_output.put_line(SQLERRM);
      IF l_error_tab.COUNT > 0
      THEN
         dbms_output.put_line(chr(10) || 'Summary of Errors');
         dbms_output.put_line('=================');
         FOR i IN l_error_tab.FIRST .. l_error_tab.LAST
         LOOP
            dbms_output.put_line(l_error_tab(i));
         END LOOP;
      END IF;
      RAISE;
END;
/

exit

