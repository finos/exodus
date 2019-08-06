DECLARE
   l_indent       PLS_INTEGER := 0;
   l_mappings     VARCHAR2(2000);
   l_comments     VARCHAR2(32767);
   l_comment_type VARCHAR2(2000);
   l_table_name   VARCHAR2(200);
   l_mr_group     VARCHAR2(200);
BEGIN
   dbms_output.put_line(rpad('=', 200, '='));
   FOR pejd_buf IN (SELECT *
                      FROM pre_etl_json_document pejd
                     WHERE pejd.document_name NOT LIKE 'TEMP/_%'
                     ESCAPE '/'
                     ORDER BY pejd.document_type
                             ,pejd.document_name)
   LOOP
      dbms_output.put_line('TARGET DOCUMENT : ' ||
                           pejd_buf.document_name || '(' ||
                           pejd_buf.document_type || ')');
      dbms_output.put_line(rpad('=', 200, '='));
      dbms_output.put_line(' ');
      l_indent := 3;
      --
      --
      FOR pejl_buf IN (SELECT *
                         FROM pre_etl_json_lines pejl
                        WHERE pejl.document_name =
                              pejd_buf.document_name
                        ORDER BY pejl.line_number)
      LOOP
         -- Get mapped columns.
         l_mappings   := NULL;
         l_table_name := '#NULL#';
         l_mr_group   := '#NULL#';
         FOR pem_buf IN (SELECT pem.table_name
                               ,pem.column_name
                               ,pem.mr_group
                               ,rownum AS rn
                               ,COUNT(*) over() AS cnt
                           FROM pre_etl_related_json_lines perjl
                           JOIN pre_etl_mapped pem
                             ON (perjl.relationship_group_id =
                                pem.relationship_group_id AND
                                perjl.mr_group = pem.mr_group)
                          WHERE perjl.document_name =
                                pejl_buf.document_name
                            AND perjl.line_number =
                                pejl_buf.line_number
                          ORDER BY pem.mr_group
                                  ,pem.table_name
                                  ,pem.column_name)
         LOOP
            IF l_mr_group != pem_buf.mr_group
            THEN
               l_mr_group := pem_buf.mr_group;
               l_mappings := l_mappings || '  (' || pem_buf.mr_group ||
                             ')  (Mapping)     : ';
            END IF;
            --
            IF l_table_name != pem_buf.table_name
            THEN
               l_table_name := pem_buf.table_name;
               l_mappings   := l_mappings || pem_buf.table_name || ':';
            END IF;
            --
            l_mappings := l_mappings || lower(pem_buf.column_name) || (CASE
                             WHEN pem_buf.cnt > 1 THEN
                              ' AS :MAPPED#' || pem_buf.rn
                             ELSE
                              NULL
                          END) || (CASE
                             WHEN pem_buf.cnt = pem_buf.rn THEN
                              NULL
                             ELSE
                              ','
                          END) || (CASE
                             WHEN pem_buf.cnt > 1 THEN
                              chr(10) ||
                              rpad(' ', 120 + length(pem_buf.table_name), ' ')
                             ELSE
                              NULL
                          END);
         END LOOP;
         --
         l_mappings := rtrim(l_mappings, ',');
         --
         ----------------------------------------------------------------------------------------------------
         -- Get commented columns.
         l_comments := NULL;
         l_mr_group := '#NULL#';
         FOR pec_buf IN (SELECT pec.mr_group
                               ,pec.comment_type
                               ,pec.comments
                           FROM pre_etl_related_json_lines perjl
                           LEFT JOIN pre_etl_comments pec
                             ON (pec.relationship_group_id =
                                perjl.relationship_group_id AND
                                pec.mr_group = perjl.mr_group)
                          WHERE perjl.document_name =
                                pejl_buf.document_name
                            AND perjl.line_number =
                                pejl_buf.line_number
                          ORDER BY pec.mr_group
                                  ,pec.comment_type)
         LOOP
            IF pec_buf.comments IS NOT NULL
            THEN
               l_comments := l_comments || chr(10) ||
                             rpad(' ', 92, ' ');
               --
               l_comments := l_comments || '(' || pec_buf.mr_group || ')';
            
               --
               l_comment_type := '  (' || (CASE pec_buf.comment_type
                                    WHEN 'Q' THEN
                                     'Question)    : '
                                    WHEN 'C' THEN
                                     'Comment)     : '
                                    WHEN 'L' THEN
                                     'Lookup)      : '
                                    WHEN 'T' THEN
                                     'Translation) : '
                                    WHEN 'F' THEN
                                     'Function)    : '
                                    WHEN 'D' THEN
                                     'Dictionary)  : '
                                    WHEN 'V' THEN
                                     'List)        : '
                                    WHEN 'A' THEN
                                     'Array)       : '
                                 END);
               l_comments     := l_comments || l_comment_type ||
                                 REPLACE(pec_buf.comments
                                        ,chr(10)
                                        ,chr(10) ||
                                         rpad(' '
                                             ,92 +
                                              length(pec_buf.mr_group) + 2 +
                                              length(l_comment_type)
                                             ,' '));
            
            END IF;
         END LOOP;
         --
         --
         dbms_output.put_line(lpad(pejl_buf.line_number, 4, ' ') || '  ' ||
                              rpad(pejl_buf.json_line, 84, ' ') ||
                              l_mappings || '  ' || l_comments);
         dbms_output.put_line(' ');
      END LOOP;
      --
      dbms_output.put_line(' ');
      dbms_output.put_line(' ');
      dbms_output.put_line(' ');
      dbms_output.put_line(' ');
      dbms_output.put_line(rpad('=', 200, '='));
   END LOOP;
END;
