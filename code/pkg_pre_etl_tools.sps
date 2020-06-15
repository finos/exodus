CREATE OR REPLACE PACKAGE pkg_pre_etl_tools IS
   /*=================================================================================================
   
       ETL / Migration Utilities For Tabular to Tabular+JSON migration.
   
       Developed by Christian Leigh
       
       ***********************************************************************************************
       
       Copyright 2018 IHS Markit
   
       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at
   
           http://www.apache.org/licenses/LICENSE-2.0
   
       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
       
       ************************************************************************************************
                
       PORTIONS OF THIS CODE - Specifically code, variables and constants relating to :-
       
                               fn_get_xml_to_json_stylesheet
                               fn_ref_cursor_to_json
                               fn_sql_to_json 
   
                 Are Copyright (c) 2006-2007, Doeke Zanstra
             
                 All rights reserved.
             
                 Redistribution and use in source and binary forms, with or without modification, 
                 are permitted provided that the following conditions are met:
             
                   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
                   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
                   * Neither the name of xml2json-xslt nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
                   
                   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
                   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
                   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
                   IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
                   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
                   BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
                   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
                   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
                   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
                   THE POSSIBILITY OF SUCH DAMAGE.
   
       ************************************************************************************************
   
       Notes
       -----
       Package is stateful, but has no need for hot deployment and could benefit from custom caching.
       
                  
     =================================================================================================                  
   */

   TYPE search_buf IS RECORD(
       TYPE            VARCHAR2(30)
      ,content         VARCHAR2(2000)
      ,found_at        VARCHAR2(2000)
      ,comment_type    VARCHAR2(2)
      ,document_type   VARCHAR2(50)
      ,document_name   VARCHAR2(50)
      ,line_number     VARCHAR2(50)
      ,map_rules_group VARCHAR2(50)
      ,hash_value      VARCHAR2(100));
   -- Because forms can't handle clobs we need to send big chunks back
   -- and forth using this clunky pl/sql collection.
   -- Intentionally not the maximum 32767 (SEE : g_const_vc_tab_length)
   TYPE t_vc_tab IS TABLE OF VARCHAR2(30000) INDEX BY BINARY_INTEGER;

   --
   --
   CURSOR cur_pedc2
   (
      c_search IN VARCHAR2
     ,c_next   IN NUMBER
   ) IS
      SELECT res.*
            ,COUNT(*) over() cnt
            ,row_number() over(ORDER BY col1, col2) AS search_item
        FROM (SELECT pedct.col1
                    ,pedct.col2
                    ,pedct.col4
                    ,row_number() over(ORDER BY pedct.col1, pedct.col4, pedct.col2) rn
                FROM (SELECT pedt.table_name AS col1
                            ,pedt.table_name AS col2
                            ,upper(pedt.description) AS col3
                            ,'T' AS col4
                        FROM pre_etl_db2_tables pedt
                      UNION ALL
                      SELECT pedc.table_name AS col1
                            ,pedc.column_name AS col2
                            ,upper(pedc.comments) AS col3
                            ,'C' AS col4
                        FROM pre_etl_db2_columns pedc) pedct
               WHERE pedct.col1 LIKE '%' || c_search || '%' ESCAPE
               '/'
                  OR pedct.col2 LIKE '%' || c_search || '%'
               ESCAPE '/'
                  OR pedct.col3 LIKE '%' || c_search || '%'
               ESCAPE '/') res
       WHERE (CASE
                WHEN col1 LIKE '%' || c_search || '%' ESCAPE '/' THEN
                 CASE
                    WHEN col2 LIKE '%' || c_search || '%' ESCAPE '/' THEN
                     1
                    ELSE
                     0
                 END
                ELSE
                 1
             END) = 1
         AND rn > c_next
       ORDER BY 1
               ,2;

   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':MAPPED'
   */
   FUNCTION fn_mapped RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':LOOKUP'
   */
   FUNCTION fn_lookup RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':FUNCTION'
   */
   FUNCTION fn_function RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':SRC'
   */
   FUNCTION fn_src RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':JSON'
   */
   FUNCTION fn_json RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':UTILITY_FIELD#'
   */
   FUNCTION fn_uf RETURN VARCHAR2 result_cache;
   /*------------------------------------------------------------------------------------
   ** HELPER function (could be a computed property): returns ':BATCH'
   */
   FUNCTION fn_batch RETURN VARCHAR2 result_cache;

   /*------------------------------------------------------------------------------------
   ** Gets a contextual value from the MIGRATION_CONTEXT
   **
   ** @param i_attr                        Attribute name in the context.          
   **
   ** @param i_fail_if_no_run_context_yn   If Y and the attribute : MGCTX_RUN_CONTEXT
   **                                      is not setup with a value then fail.
   **                                      This prevents running with incomplete or 
   **                                      context setup.
   **
   ** @return                              Returns the context value.                             
   */
   FUNCTION fn_get_context_value
   (
      i_attr                      IN VARCHAR2
     ,i_fail_if_no_run_context_yn IN VARCHAR2 DEFAULT 'Y'
   ) RETURN VARCHAR2
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Clears a specific attribue within the MIGRATION_CONTEXT.
   **
   ** @param i_attr                         The attribute name in the context to clear.
   */
   PROCEDURE pr_destroy_context_attr(i_attr IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Clears the MIGRATION_CONTEXT.
   */
   PROCEDURE pr_destroy_context;

   /*------------------------------------------------------------------------------------
   ** Sets a context attribute with a value.
   **
   ** @param i_attr                         The attribute name.
   **
   ** @param i_value                        The value for the attribute.
   */
   PROCEDURE pr_set_context
   (
      i_attr  IN VARCHAR2
     ,i_value IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Sets a context value, and passes the value being set back.
   **
   ** @param i_attr                        The name of the attribute being setup.          
   **
   ** @param i_value                       The value for the context attribute.
   **
   ** @return                              Returns the i_value.                             
   */
   FUNCTION fn_set_context_and_passthru
   (
      i_attr  IN VARCHAR2
     ,i_value IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Gets a hash value for a specified migration.
   **
   ** @param i_migration_group          A migration group.
   **
   ** @param i_migration_name           A migration step name.
   ** 
   ** @return                           A hash for the specified migration step.
   */
   FUNCTION fn_get_hash_for_mig_name
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
   ) RETURN RAW;

   /*------------------------------------------------------------------------------------
   ** Gets a hash value for a supplied clob.
   **
   ** @param i_clob      Any string (could be generated code for example).
   ** 
   ** @return            A hash for the supplied clob.
   */
   FUNCTION fn_get_hash_for_clob(i_clob IN CLOB) RETURN RAW
      PARALLEL_ENABLE;

   /*------------------------------------------------------------------------------------
   ** Used by FORM.
   ** Searches columns and tables for string matches (for searching in the form).
   **
   ** @param i_search    The value to search for
   **
   ** @param i_next      The search position (pagination).
   ** 
   ** @return            A row from the search cursor.
   */
   FUNCTION fn_get_pedc2
   (
      i_search IN VARCHAR2
     ,i_next   IN NUMBER
   ) RETURN cur_pedc2%ROWTYPE;

   /*------------------------------------------------------------------------------------
   ** Returns a stylesheet to convert XML to JSON.
   ** Need to expose this because I needed to use in a SQL select from dual
   ** to get around the ampersand problem. 
   ** 
   ** @return            A stylesheet string.
   */
   FUNCTION fn_get_xml_to_json_stylesheet RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Gets the attribute name from a single line of JSON.
   **
   ** @param i_line                        A line of JSON (only one attr per line).
   **
   ** @param i_suppress_get_col_name_bool  If used on a Table Document then setting this to FALSE
   **                                      will return the Table Column Name.
   **                                      eg.    "COLUMN_NAME" : "trade_party",
   **                                      would return trade_party otherwise it would return COLUMN_NAME.
   **
   ** @return                              The attribute name, or real column name if used on a table document.
   */
   FUNCTION fn_get_attribute
   (
      i_line                       IN VARCHAR2
     ,i_suppress_get_col_name_bool IN BOOLEAN DEFAULT FALSE
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Gets the attribute name from a single line of JSON.
   **
   ** See the counterpart function of the same name.  
   ** This function performs the same action, but can be used in SQL as it 
   ** has a non-boolean parameter.
   */
   FUNCTION fn_get_attribute
   (
      i_line                     IN VARCHAR2
     ,i_suppress_get_col_name_vc IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2 result_cache;

   /*------------------------------------------------------------------------------------
   ** Uppers a passed in keyword in the statement, and returns it.
   **
   ** @param i_statement         The statement (clob) that potentially contains one or more of
   **                            a keyword that needs to be uppercased.
   **
   ** @param i_keyword           The keyword that needs to be converted to uppercase.
   **
   ** @return                    The statement passed in with any specified keyword converted to uppercase.
   */
   FUNCTION fn_upper_keyword_clob
   (
      i_statement IN CLOB
     ,i_keyword   IN VARCHAR2
   ) RETURN CLOB;

   /*------------------------------------------------------------------------------------
   ** Uppers a passed in keyword in the statement, and returns it.
   **
   ** @param i_statement         The statement (varchar2) that potentially contains one or more of
   **                            a keyword that needs to be uppercased.
   **
   ** @param i_keyword           The keyword that needs to be converted to uppercase.
   **
   ** @return                    The statement passed in with any specified keyword converted to uppercase.
   */
   FUNCTION fn_upper_keyword_varchar2
   (
      i_statement IN VARCHAR2
     ,i_keyword   IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used in the FORM.
   ** Returns TRUE is the line directly after the supplied information is the start of 
   ** an array.  This is used to correctly colour the lines in the form, and to setup the
   ** correct way to tell if the array has ended.
   **
   ** @param i_document          The JSON document being inspected.
   **
   ** @param i_line_number       The line number after which we are detecting array start.
   **
   ** @return                    TRUE or FALSE.   TRUE if the very next line is an array start.
   */
   FUNCTION fn_is_next_line_array_start
   (
      i_document    IN VARCHAR2
     ,i_line_number IN NUMBER
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Returns a BOOLEAN TRUE or FALSE.
   ** If the target mapping JSON document/line related to a STORED FRAGMENT (a piece of JSON)
   ** then this returns TRUE.
   **
   ** @param i_mr_group                  The mapping rules group.
   **
   ** @param i_document_name             The target JSON document name.
   **
   ** @param i_line_number               The line number of the target JSON document.
   **
   ** @return                            Either TRUE or FALSE
   */
   FUNCTION fn_is_sub_doc_related_to_frag
   (
      i_mr_group      IN VARCHAR2
     ,i_document_name IN VARCHAR2
     ,i_line_number   IN NUMBER
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Returns a BOOLEAN TRUE or FALSE.
   ** This returns the same value as fn_is_sub_doc_related_to_frag but is not usable by
   ** FORMS because FORMS does not like result cached functions.
   **
   */
   FUNCTION fn_is_sub_doc_rel_to_frag_rs
   (
      i_mr_group      IN VARCHAR2
     ,i_document_name IN VARCHAR2
     ,i_line_number   IN NUMBER
   ) RETURN BOOLEAN result_cache;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Returns a varchar 'TRUE' or 'FALSE'.
   ** If the mapping of a JSON attribute in a target document uses code then this returns 'TRUE'
   **
   ** @param i_mr_group                  The mapping rules group.
   **
   ** @param i_document_name             The target JSON document name.
   **
   ** @param i_line_number               The line number of the target JSON document.
   **
   ** @return                            Either 'TRUE' or 'FALSE'
   */
   FUNCTION fn_has_code_in_comment
   (
      i_mr_group      IN VARCHAR2
     ,i_document_name IN VARCHAR2
     ,i_line_number   IN NUMBER
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Returns a number indicating the maximum mapped count in a comment.
   ** For example if a FUNCTION comment read: 
   **
   **    =decode(:MAPPED#1,'A',decode(:MAPPED#2, 1, 'Alpha1'
   **                                          , 2, 'Alpha2'
   **                                          , 'AlphaBig')
   **           ,'B','Beta'
   **           ,'?')
   **
   ** Then this function would return 2 (because : :MAPPED#2)
   **
   ** @param i_comment                   The code comment.
   **
   ** @return                            A number indicating the largest MAPPED#
   */
   FUNCTION fn_max_mapped(i_comment IN VARCHAR2) RETURN NUMBER;

   /*------------------------------------------------------------------------------------
   ** Used in FORMS.
   ** Validates ALL mappings for a given context.
   ** Checks syntax of any code comment.
   **
   ** @param i_context                   A context name.
   **
   ** @return                            A report detailing any mapping problems.
   */
   FUNCTION fn_validate_mapping(i_context IN VARCHAR2) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** This function recases (makes uppercase) any special : (colon) commands.
   **
   ** ANY OF THE COMMAND as below...
   **
   **    pkg_pre_etl_tools.fn_mapped
   **    pkg_pre_etl_tools.fn_lookup
   **    pkg_pre_etl_tools.fn_function
   **    pkg_pre_etl_tools.fn_src
   **    pkg_pre_etl_tools.fn_json
   **    pkg_pre_etl_tools.fn_batch
   **    pkg_pre_etl_tools.fn_uf
   **       
   ** @param i_string       The string that contains a functional comment that might have 
   **                       commands to be uppercased.
   */
   FUNCTION fn_recase_colon_commands(i_string IN VARCHAR2)
      RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** When editing a mapping there could be increases or decreases in the number of mapped
   ** source fields.  This helper function can automatically adjust the mappings in the 
   ** Function / SQL / Comments.
   **
   ** @param i_string                    The code comment to be adjusted
   **
   ** @param i_direction                 UP or DOWN (depending if the parameter is being added or removed).
   **
   ** @param i_start_point               The parameter number to start from.
   **
   ** @param i_previously_single_bool    Boolean TRUE/FALSE. TRUE if the string was mapped to a single source column.
   **
   ** @return                            A new string with the :MAPPED / :MAPPED#x numbers adjusted.
   */
   FUNCTION fn_bump_mapped_numbers
   (
      i_string                 IN VARCHAR2
     ,i_direction              IN VARCHAR2
     ,i_start_point            IN NUMBER
     ,i_previously_single_bool IN BOOLEAN
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Used to execute simple one column SELECT statements.
   ** 
   ** @param i_statement                The SELECT statment.
   **
   ** @return                           A value from the SELECT statement.
   */
   FUNCTION pre_etl_fn_exec(i_statement IN VARCHAR2) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Used to determine how to colour the steps in the migration definition window.
   ** As of writing : ERROR = red, CODE = green, UNKNOWN = dark blue
   ** 
   ** @param i_migration_group          The migration group (from the define migration window)
   **
   ** @param i_migration_name           The migration step name.
   **
   ** @return                           UKNOWN / ERROR / CODE  
   */
   FUNCTION fn_code_state
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Used to detect if a migration step has materially altered, and requires re-compilation.
   ** 
   ** @param i_migration_group          The migration group (from the define migration window)
   **
   ** @param i_migration_name           The migration step name.
   ** 
   ** @param i_context                  The context group.
   **
   ** @return                           TRUE / FALSE
   */
   FUNCTION fn_def_change_bool
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
     ,i_context         IN VARCHAR2
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Returns a collection (because CLOBs are not handled properly by FORMS when they get 
   ** over a certain size).  The collection contains the code that the migration would 
   ** execute for the specified group/step.
   ** 
   ** @param i_migration_group          The migration group.
   **
   ** @param i_migration_name           The migration step name.
   **
   ** @return                           A collection containing the code.
   */
   FUNCTION fn_get_executable_statement
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
   ) RETURN t_vc_tab;

   /*------------------------------------------------------------------------------------
   ** Prettify the JSON.  This formats the JSON into single attribute per line basis.
   ** Much of the system
   ** 
   ** @param i_json_text         Typically a piece of JSON.
   **
   ** @return                           A modified string based on the i_find_swap_string.
   */
   FUNCTION fn_pretty_json(i_json_text IN VARCHAR2) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Find / Swap is a search and replace for the JSON thats generated.
   ** Some JSON needs post creation manipulation before being returned for persistence.
   ** 
   ** @param i_find_swap_string         Typically a piece of JSON.
   **
   ** @param i_mig_group                The migration group (different migrations will have
   **                                   diffenent search replace requirements).
   **
   ** @return                           A modified string based on the i_find_swap_string.
   */
   FUNCTION fn_find_and_swap
   (
      i_find_swap_string IN VARCHAR2
     ,i_mig_group        IN VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used in the construction of some JSON.
   ** Takes a ref cursor and responds with a JSON representation of the SQL.
   ** Under the covers its creating and XML of the SQL, and running the 
   ** result through a stylesheet.
   ** 
   ** @param p_ref_cursor               A ref cursor.
   **
   ** @param p_max_rows                 Max Rows (dbms_xmlgen).
   **
   ** @param p_skip_rows                Skip Rows (dbms_xmlgen).
   **
   ** @return                           A fragment of JSON to be used in the final JSON doc.
   */
   FUNCTION fn_ref_cursor_to_json
   (
      p_ref_cursor IN SYS_REFCURSOR
     ,p_max_rows   IN NUMBER := NULL
     ,p_skip_rows  IN NUMBER := NULL
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used in the construction of some JSON simple array (simple comma separated values)
   ** Takes a sql string and responds with a JSON representation of the SQL.
   ** 
   ** @param i_sql                      Some SQL to be used to generate a fragment of JSON.
   **
   ** @param i_mig_group                The migration group.
   **                                   Different migration groups can have different find/swap handling.
   **
   ** @return                           A fragment of JSON array to be used in the final JSON doc.
   */
   FUNCTION fn_sql_to_vanilla_array
   (
      i_sql       IN VARCHAR2
     ,i_mig_group IN VARCHAR2
   ) RETURN VARCHAR2 result_cache;

   /*------------------------------------------------------------------------------------
   ** Used in the construction of some JSON based on SQL.
   ** Takes a piece of SQL and generates the JSON representation of it.
   ** Under the covers its creating and XML of the SQL, and running the 
   ** result through a stylesheet.
   ** 
   ** @param i_sql                      Some SQL to be used to generate a fragment of JSON.
   **
   ** @param p_max_rows                 Max Rows (dbms_xmlgen).
   **
   ** @param p_skip_rows                Skip Rows (dbms_xmlgen).
   **
   ** @param i_mig_group                The migration group.
   **                                   Different migration groups can have different find/swap handling.
   **
   ** @param i_find_swap_yn             Y/N - Y = perform a find/swap (search/replace of JSON pieces).
   **
   ** @return                           A fragment of JSON to be used in the final JSON doc.
   */
   FUNCTION fn_sql_to_json
   (
      i_sql          IN VARCHAR2
     ,i_max_rows     IN NUMBER := NULL
     ,i_skip_rows    IN NUMBER := NULL
     ,i_mig_group    IN VARCHAR2
     ,i_find_swap_yn IN VARCHAR2 DEFAULT 'Y'
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used in the construction of some JSON array based on SQL.
   ** Takes a piece of SQL and generates the JSON representation of it.
   ** Under the covers its creating and XML of the SQL, and running the 
   ** result through a stylesheet.
   ** 
   ** @param i_sql                      Some SQL to be used to generate a fragment of JSON array.
   **
   ** @param i_mig_group                The migration group.
   **                                   Different migration groups can have different find/swap handling.
   **
   ** @param i_find_swap_yn             Y/N - Y = perform a find/swap (search/replace of JSON pieces).
   **
   ** @return                           A fragment of JSON to be used in the final JSON doc.
   */
   FUNCTION fn_sql_to_json_array
   (
      i_sql          IN VARCHAR2
     ,i_mig_group    IN VARCHAR2
     ,i_find_swap_yn IN VARCHAR2 DEFAULT 'Y'
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Check for first open bracket.  If found return position if any other non space 
   ** char found then fail.
   **
   ** @param i_string                The String to search.
   **
   ** @param i_after_string          Start checking after this string.
   **
   ** @return                        The position of the open bracket.
   */
   FUNCTION fn_check_for_ob
   (
      i_string       IN VARCHAR2
     ,i_after_string IN VARCHAR2
   ) RETURN NUMBER;

   /*------------------------------------------------------------------------------------
   ** Returns a string which is used in the assembly of the auto generate code.
   **
   ** @param i_value                 The function/comment with the :JSON command.
   **
   ** @param i_mr_group              The map/rules group. From the header of the migration step.
   **
   ** @param i_mig_group             The migration group.
   **
   ** @param i_introspect_step       The name of the step to be included in the instrumentation.
   **
   ** @param i_use_driver_bool       Indicates if a driver is used (if true then utility fields can be included).
   **
   ** @param i_smart_cache_attrs     Smart cache attribues.  If smart caching is enabled (only makes sense on repeating rows),
   **                                then we only rebuild the JSON for the attributes indicated.
   **
   ** @return                        The autogenerated code to be included into the migration step.
   ** 
   */
   FUNCTION fn_set_json_handler
   (
      i_value             IN VARCHAR2
     ,i_mr_group          IN VARCHAR2
     ,i_mig_group         IN VARCHAR2
     ,i_introspect_step   IN VARCHAR2
     ,i_use_driver_bool   IN BOOLEAN DEFAULT FALSE
     ,i_smart_cache_attrs IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Returns a TRUE, FALSE.  If the SOURCE table has a mapping to a target JSON then 
   ** this will return TRUE.
   **
   ** @param i_table_name     The SOURCE table name.
   **   
   ** @param i_column_name    The SOURCE table column.
   **   
   ** @param i_mr_group       The mapping/rules group to use.
   **
   ** @return                 TRUE or FALSE.  TRUE if the source column is used in a mapping.
   ** 
   */
   FUNCTION fn_is_src_col_is_mapped
   (
      i_table_name  IN VARCHAR2
     ,i_column_name IN VARCHAR2
     ,i_mr_group    IN VARCHAR2
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Used in the FORM.
   ** Returns a TRUE, FALSE.  If the SOURCE table has a mapping to a target JSON then 
   ** this will return TRUE.
   **
   ** @param i_table_name     The SOURCE table name.
   **   
   ** @param i_column_name    The SOURCE table column.
   **   
   ** @param i_mr_group       The mapping/rules group to use.
   **
   ** @return                 VARCHAR2 'TRUE' or 'FALSE'.  
   **                         'TRUE' if the source column is used in a mapping.
   ** 
   */
   FUNCTION fn_is_src_col_is_mapped_vc
   (
      i_table_name  IN VARCHAR2
     ,i_column_name IN VARCHAR2
     ,i_mr_group    IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used during the construction of the migration target JSON.
   ** Returns a JSON line with populated values.
   ** 
   ** @param i_batch                     Batch ID. 
   **
   ** @param i_document                  The name of the document being assembled (only used for debug instrumentation).
   **
   ** @param i_relationship_group_id     The relationship group. Any code function/sql will have a rg_id.
   **
   ** @param i_mr_group                  The mapping rules group being used.
   **
   ** @param i_nv_pair_tab               A collection with values for the column names.
   **
   ** @param i_staged_schema             The schema that has the staged data.
   **
   ** @param i_utility_field_1           Utility Field#1 if passed in.
   **
   ** @param i_utility_field_2           Utility Field#2 if passed in.
   **
   ** @param i_utility_field_3           Utility Field#3 if passed in.
   **
   ** @param i_utility_field_4           Utility Field#4 if passed in.
   **
   ** @param i_utility_field_5           Utility Field#5 if passed in.
   **
   ** @param i_introspect_step           Used for instrumentation.
   **
   ** @param i_debug_mode                'TRUE' / 'FALSE' varchar : For instrumentation.
   **
   ** @param i_json_line                 The JSON line being constructed.
   **
   ** @return                            The constructed JSON line.
   */
   FUNCTION fn_get_mapping_col_or_value
   (
      i_batch                 IN NUMBER
     ,i_document              IN VARCHAR2
     ,i_relationship_group_id IN NUMBER
     ,i_mr_group              IN VARCHAR2
     ,i_nv_pair_tab           IN t_nv_pair_tab
     ,i_staged_schema         IN VARCHAR2
     ,i_utility_field_1       IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_2       IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_3       IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_4       IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_5       IN VARCHAR2 DEFAULT NULL
     ,i_introspect_step       IN VARCHAR2 DEFAULT NULL
     ,i_debug_mode            IN VARCHAR2 DEFAULT 'FALSE'
     ,i_json_line             IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** This function is used as a table.  It's part of the core JSON construction code.
   **
   **************************************************************************************
   **
   ** @param i_batch                    The batch ID.  Migrations are grouped by numbered batches.
   **
   ** @param i_document                 The document to be constructed.
   **   
   ** @param i_mr_group                 The map rules group to use for the JSON construction.
   **
   ** @param i_mig_group                The migration group (the group of steps being used).
   **
   ** @param i_nv_pair_tab              Constructed collection, generated by the tool.
   **
   ** @param i_replace_values_tab       Contains the tablename.column replacement values.
   **
   ** @param i_staged_schema            The staging schema (contextually aware value).
   **
   ** @param i_skip_mapping             String of 'TRUE' or 'FALSE'.  
   **
   ** @param i_use_smart_cache          String of 'TRUE' or 'FALSE'.
   **
   ** @param i_smart_cache_index        The index to lookup values from the smart cache.
   **
   ** @param i_smart_cache_attrs        The attibutes that are NOT in the cache.
   **
   ** @param i_smart_cache_usecase      The usecase for the smart cache (we have 3).
   **
   ** @param i_fragment_insertion       Indicates if this is a recursive call for fragment insertion.
   **
   ** @param i_origin                   Used in the key of the cache.
   **
   ** @param i_utility_field_1          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_2          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_3          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_4          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_5          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_introspect_step          Used for instrumentation.
   **
   ** @param i_debug_mode               This flag can be used to switch on DEBUGGING, something that a developer 
   **                                   may do by cutting a pasting code from the tool into another SQL editor.
   **                                   This is a VARCHAR2 'TRUE' or 'FALSE'
   **                                   It is STRONGLY suggested that only small sets (preferably single rows) are
   **                                   debugged in this manner because the debug option DBMS_OUTPUTs the result, 
   **                                   and if the output is BIG then the SQL tool might take a very long time to respond.
   **
   ** @return                           A fully populated JSON document based on the rules defined in the tools.
   */
   FUNCTION fn_tab_func_doc_by_example
   (
      i_batch               IN NUMBER
     ,i_document            IN VARCHAR2
     ,i_mr_group            IN VARCHAR2
     ,i_mig_group           IN VARCHAR2
     ,i_nv_pair_tab         IN t_nv_pair_tab
     ,i_replace_values_tab  IN t_json_replace_tab
     ,i_staged_schema       IN VARCHAR2
     ,i_skip_mapping        IN VARCHAR2 DEFAULT 'FALSE'
     ,i_use_smart_cache     IN VARCHAR2
     ,i_smart_cache_index   IN VARCHAR2
     ,i_smart_cache_attrs   IN VARCHAR2
     ,i_smart_cache_usecase IN NUMBER
     ,i_fragment_insertion  IN VARCHAR2
     ,i_origin              IN NUMBER
     ,i_utility_field_1     IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_2     IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_3     IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_4     IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_5     IN VARCHAR2 DEFAULT NULL
     ,i_introspect_step     IN VARCHAR2 DEFAULT NULL
     ,i_debug_mode          IN VARCHAR2 DEFAULT 'FALSE'
     ,i_docbyexample_tab    IN t_docbyexample_tab DEFAULT t_docbyexample_tab()
   ) RETURN t_docbyexample_tab;

   /*------------------------------------------------------------------------------------
   ** This function is the heart of the JSON migration tool.
   ** The function constructs and returns a JSON document based upon the mapping and rules
   ** defined in the FORM.  Look at any AUTO generated code in the tool, and if that code
   ** is writing to a table that has a JSON payload, then this function will be used to 
   ** populate the column that has that payload.
   **
   ** A normal user of this tool would never call this function explicitly, its for auto
   ** generated code only.
   **
   ** A JSON document is used by defining the mapping and applying the :JSON tag in a 
   ** function comment. For example in the target table column :
   **
   **    = :JSON((CASE 
   **               WHEN :mapped#1 = 'Terminate' THEN
   **                 'FX Termination'
   **               WHEN :mapped#1 = 'Expiry' THEN
   **                 'FX Expiry'
   **               WHEN :mapped#1 = 'Exercise' THEN
   **                 'FX Exercise'
   **             END))
   ** 
   ** The above example shows three possible JSON targets depending on the 
   ** SOURCE data mapping.
   **
   **************************************************************************************
   **
   ** @param i_batch                    The batch ID.  Migrations are grouped by numbered batches.
   **
   ** @param i_document                 The document to be constructed.
   **   
   ** @param i_mr_group                 The map rules group to use for the JSON construction.
   **
   ** @param i_mig_group                The migration group (the group of steps being used).
   **
   ** @param i_nv_pair_tab              Constructed collection, generated by the tool.
   **
   ** @param i_staged_schema            The staging schema (contextually aware value).
   **
   ** @param i_cache_key                A caching key (useful for multiple uses within the same row).
   **
   ** @param i_smart_cache_key          Smart caching for repeating rows that only need pieces of the JSON reconstructed.
   **
   ** @param i_smart_cache_attrs        The attributes that need recomputation.
   **
   ** @param i_utility_field_1          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_2          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_3          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_4          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_utility_field_5          Utility field, useful for passing in data that can be more efficiently captured in the driver table.
   **
   ** @param i_introspect_step          Used for instrumentation.
   **
   ** @param i_validate_json            Used to indicate if the JSON should be validated.
   **
   ** @param i_fragment_insertion       Indicates if this function is being used for fragment insertion.
   **
   ** @param i_origin                   The origin of the call.
   **
   ** @param i_debug_mode               This flag can be used to switch on DEBUGGING, something that a developer 
   **                                   may do by cutting a pasting code from the tool into another SQL editor.
   **                                   This is a VARCHAR2 'TRUE' or 'FALSE'
   **                                   It is STRONGLY suggested that only small sets (preferably single rows) are
   **                                   debugged in this manner because the debug option DBMS_OUTPUTs the result, 
   **                                   and if the output is BIG then the SQL tool might take a very long time to respond.
   **
   ** @return                           A fully populated JSON document based on the rules defined in the tools.
   */
   FUNCTION fn_make_json
   (
      i_batch              IN NUMBER
     ,i_document           IN VARCHAR2
     ,i_mr_group           IN VARCHAR2
     ,i_mig_group          IN VARCHAR2
     ,i_nv_pair_tab        IN t_nv_pair_tab
     ,i_staged_schema      IN VARCHAR2
     ,i_cache_key          IN VARCHAR2 DEFAULT NULL
     ,i_smart_cache_key    IN VARCHAR2 DEFAULT NULL
     ,i_smart_cache_attrs  IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_1    IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_2    IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_3    IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_4    IN VARCHAR2 DEFAULT NULL
     ,i_utility_field_5    IN VARCHAR2 DEFAULT NULL
     ,i_introspect_step    IN VARCHAR2 DEFAULT NULL
     ,i_validate_json      IN VARCHAR2 DEFAULT 'TRUE'
     ,i_fragment_insertion IN VARCHAR2 DEFAULT 'FALSE'
     ,i_origin             IN NUMBER DEFAULT NULL
     ,i_debug_mode         IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Gets a hash for all "actionable comments".  In other word comments that control
   ** how the data is used in the migration. 
   ** This generates a "fingerprint". See Action Fingerprint in the generated code.
   **
   ** @param i_using_src_table_name   The SOURCE table.
   **
   ** @param i_mr_group               The mapping rules group.
   **
   ** @return                         A raw value for the fingerprint.
   */
   FUNCTION fn_get_action_comments_hash
   (
      i_using_src_table_name IN VARCHAR2
     ,i_mr_group             IN VARCHAR2
   ) RETURN RAW;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** Used when creating a commonality between 2 json targets.
   ** Returns TRUE / FALSE.   If the relationship is permissible then it returns TRUE.
   **
   ** @param i_mr_group                    The map/rules group.
   **
   ** @param i_adding_to_document          The document the user is focussed on in the editor.
   **
   ** @param i_adding_to_line_number       The line number the user is focussed on in the editor.
   **
   ** @param i_mr_group                    The document that the user wants to relate to the focussed document.
   **
   ** @param i_relate_to_line_number       The line number that the user wants to relate to the focussed line.
   **
   ** @return                              TRUE / FALSE.
   */
   FUNCTION fn_allow_relationship
   (
      i_mr_group              IN VARCHAR2
     ,i_adding_to_document    IN VARCHAR2
     ,i_adding_to_line_number IN NUMBER
     ,i_relate_to_document    IN VARCHAR2
     ,i_relate_to_line_number IN NUMBER
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** The function returns a boolean to say if the supplied table is locally defined
   ** (i.e. not a staged table, a table in the PRE_ETL_OWNER schema).
   **
   ** @param i_table_name               The local table name.
   ** 
   ** @return                           TRUE or FALSE.  TRUE if the table is LOCAL.  
   */
   FUNCTION fn_is_mig_local(i_table_name IN VARCHAR2) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** The function returns a boolean to say if a locally defined table has changed in definition
   ** (i.e. not a staged table, a table in the PRE_ETL_OWNER schema).
   ** 
   ** If it has changed, then the FORM needs to rebuild its representation 
   ** of that table.
   **
   ** @param i_table_name               The local table name.
   ** 
   ** @return                           TRUE or FALSE.  TRUE if the definition has changed.
   */
   FUNCTION fn_has_mig_local_def_changed(i_table_name IN VARCHAR2)
      RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** FORM uses this function.
   ** The function returns a boolean to say if a locally defined table exists.
   ** (i.e. not a staged table, a table in the PRE_ETL_OWNER schema).
   **
   ** @param i_table_name               The local table name.
   ** 
   ** @return                           TRUE or FALSE.  TRUE if the local table exists.
   */
   FUNCTION fn_mig_local_exist(i_table_name IN VARCHAR2) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Used in FORMS.
   ** Checks that a target JSON document has valid mappings to real SOURCE columns.
   **
   ** @param i_relationship_group_id     The relationship group.
   **                                    Any mapped to JSON (target) or target that
   **                                    has a comment will have a relationship group.
   **
   ** @param i_mr_group                  The map/rules group to use.
   **
   ** @return                            TRUE or FALSE. 
   */
   FUNCTION fn_mapping_is_valid
   (
      i_relationship_group_id IN NUMBER
     ,i_mr_group              IN VARCHAR2
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Used in FORMS.
   ** Its possible to use json comments as a value for a functional comment.
   ** These ONLY work for table JSON (the JSON document that describes a table).
   ** These are defined as $$json_document_name.column_name$$
   ** They can be convienient places to share a definition.  Especially if a payload 
   ** has a complex rule to setup the :JSON ( doc_name )
   **
   ** @param i_string                         The function/comment string.
   **
   ** @param i_remove_external_reftags_bool   Some code can have reftags, this is a special
   **                                         use case where a value can be gotten freom outside  
   **                                         of the table being used as the source table.
   **                                         (For example from an "inline view")
   */
   FUNCTION fn_replace_dollar_dollar
   (
      i_string                       IN VARCHAR2
     ,i_remove_external_reftags_bool IN BOOLEAN DEFAULT TRUE
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Returns a collection of VARCHAR2 (because returning CLOBs isn't useful in forms,
   ** annoyingly big clobs cannot be handled correctly in the version of forms used at 
   ** time of writing).
   **
   ** The collection will return the JSON representation of a table.
   ** For example.
   **
   **     {
   **       "TABLE_NAME" : "PRE_ETL_PARAMS",
   **       "SCHEMA_NAME" : "PRE_ETL_OWNER",
   **       "COLUMNS" :
   **       [
   **         {
   **           "COLUMN_NAME" : "param_name"
   **         },
   **         {
   **           "COLUMN_NAME" : "param_value"
   **         },
   **         {
   **           "COLUMN_NAME" : "param_description"
   **         }
   **       ]
   **     }
   **
   ** @param i_table_name                    The table to be returned as a JSON representation.
   **
   ** @param i_schema_name                   The schema for the i_table_name.
   **
   ** @param i_included_extended_data_bool   If TRUE then additional information about the 
   **                                        table definition is returned (type/size).
   **
   ** @return                                A collection containing the JSON.
   */
   FUNCTION fn_get_json_for_table
   (
      i_table_name                  IN VARCHAR2
     ,i_schema_name                 IN VARCHAR2
     ,i_included_extended_data_bool IN BOOLEAN DEFAULT TRUE
   ) RETURN t_vc_tab;

   /*------------------------------------------------------------------------------------
   ** Takes any string (CLOB) and replaces the contextual values with real values.
   ** Eg. ${STG_ETL-OWNER} could become PROD_STG_ETL_OWNER.
   **
   ** @param i_subject     The string to have the contextual values replaced.
   **
   ** @param i_context     Contextual values can be assigned context groups.
   **                      (see PRE_ETL_SUBSTITUTION_VALUES / PRE_ETL_RUN_CONTEXTS).
   **
   ** @return              The adjusted subject string.
   */
   FUNCTION fn_contextualize
   (
      i_subject IN CLOB
     ,i_context IN VARCHAR2
   ) RETURN CLOB;

   /*------------------------------------------------------------------------------------
   ** Takes any string (VARCHAR2) and replaces the contextual values with real values.
   ** Eg. ${STG_ETL-OWNER} could become PROD_STG_ETL_OWNER.
   **
   ** @param i_subject     The string to have the contextual values replaced.
   **
   ** @param i_context     Contextual values can be assigned context groups.
   **                      (see PRE_ETL_SUBSTITUTION_VALUES / PRE_ETL_RUN_CONTEXTS).
   **
   ** @return              The adjusted subject string.   
   */
   FUNCTION fn_contextualize
   (
      i_subject IN VARCHAR2
     ,i_context IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used in many places including FORMS.
   ** Takes any string (VARCHAR2) and replaces the contextual values with real values.
   ** Eg. ${STG_ETL-OWNER} could become PROD_STG_ETL_OWNER.
   **
   ** @param i_subject     The string to have the contextual values replaced.
   **
   ** @param i_context     Contextual values can be assigned context groups.
   **                      (see PRE_ETL_SUBSTITUTION_VALUES / PRE_ETL_RUN_CONTEXTS).
   **
   ** @return              The adjusted subject string.   
   */
   FUNCTION fn_forms_contextualize
   (
      i_subject IN VARCHAR2
     ,i_context IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Get the instance name for this DB.
   **
   ** @return              An instance name.  
   */
   FUNCTION fn_get_instance RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Used by FORMS.
   ** Gets the code/comment based on a ROWID.
   **
   ** @param i_rowid       The rowid of the code / comment.
   **  
   ** @return              The code/comment.
   */
   FUNCTION fn_get_vc2_pec_comments(i_rowid IN ROWID) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Returns a boolean TRUE/FALSE.
   ** TRUE if the relationship group id has a SQL comment (:LOOKUP) that uses a WITH clause.
   ** We cannot allow relationships to be made from a JSON document to a table representation (in JSON)
   ** if the JSON document has a WITH clause for its lookup code/comment.
   **
   ** @param i_mr_group                      A map/rules group.
   **
   ** @param i_relationship_group_id         The relationship id.
   **
   ** @return                                TRUE/FALSE : TRUE if the comment for the JSON document line
   **                                        uses a WITH clause. 
   */
   FUNCTION fn_tab_doc_incl_with_clause
   (
      i_mr_group              IN VARCHAR2
     ,i_relationship_group_id IN NUMBER
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Returns a Y or and N
   ** If this returns a Y then it means that the source table for the migration has a field 
   ** that can be set to a migration status indicator to show that its been migrated.
   ** Only SOURCE staged tables with a migration status fields can have this.
   ** A column of : MIGRATION_STATUS
   ** 
   ** @param i_context               The context.  Needed because schema names can be substitutions variables.
   **
   ** @param i_migration_group       The migration group.
   **
   ** @param i_migration_name        The name of the migration step within the group.
   **
   ** @return                        Y or N - Y means that yes the source table can be "touched" with a migration status.
   */
   FUNCTION fn_touch_possible_yn
   (
      i_context         IN VARCHAR2
     ,i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
   ) RETURN VARCHAR2;

   /*------------------------------------------------------------------------------------
   ** Returns a boolean TRUE or FALSE
   ** Validates if a change to the JSON is valid.
   ** 
   ** @param i_document_name         The document being altered.
   **
   ** @param i_line_number           The line number of JSON being altered.
   **
   ** @param i_changed_line          The new line (replacing the text of the line number given above).
   **
   ** @return                        TRUE = valid json overall, FALSE = Invalid overall.
   */
   FUNCTION fn_is_json_change_valid
   (
      i_document_name IN VARCHAR2
     ,i_line_number   IN NUMBER
     ,i_changed_line  IN VARCHAR2
   ) RETURN BOOLEAN;

   /*------------------------------------------------------------------------------------
   ** Used by FORM.
   ** Searches columns and tables for string matches (for searching in the form).
   **
   ** @param i_search                 Search for this text.
   ** @param i_next                   The position within the search set.  1) = first item, 2) second item etc..
   ** @param o_col1                   The table name containing the searched for item
   ** @param o_col2                   The table or column name containing the searched for item
   ** @param o_col4                   T or C . If T then o_col2 is a table, if C then o_col2 is a column.
   ** @param o_rn                     The position.
   ** @param o_cnt                    The count of the found items.
   ** @param o_search_item            The position within o_col1 and o_col2
   */
   PROCEDURE pr_get_pedc2
   (
      i_search      IN VARCHAR2
     ,i_next        IN NUMBER
     ,o_col1        OUT VARCHAR2
     ,o_col2        OUT VARCHAR2
     ,o_col4        OUT VARCHAR2
     ,o_rn          OUT NUMBER
     ,o_cnt         OUT NUMBER
     ,o_search_item OUT NUMBER
   );

   /*------------------------------------------------------------------------------------
   ** Recreates the specifed table name if its a LOCAL table.
   ** This is sometimes necessary if the real definition of the table has changed.
   ** 
   ** @param i_table_name              The table name of the local table to be recreated.
   **   
   */
   PROCEDURE pr_recreate_mig_local(i_table_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Removes any mappings to a LOCAL table (not a staging table, but a table withing the 
   ** ETL tool schema).
   ** 
   ** @param i_table_name              The LOCAL table name.
   */
   PROCEDURE pr_cleanup_local_mappings(i_table_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Gets code to be used in the auto generated code for touching migration_status.
   ** 
   ** @param i_context                 A context (for substitution variables).
   **
   ** @param i_migration_group         A migration Group.
   **
   ** @param i_migration_name          The migration step within the migration group.
   **
   ** @param o_touch                   The code to be included into the auto generated code.
   */

   PROCEDURE pr_get_touch
   (
      i_context         IN VARCHAR2
     ,i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
     ,o_touch           OUT VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Loads the supplied JSON clob into the migation tool.
   **
   ** @param i_document                 The JSON document name (sometimes known as a document by example).
   **
   ** @param i_document_type            Either a ('STORED DOCUMENT', 'TABLE DOCUMENT', 'STORED FRAGMENT' )
   **
   ** @param i_clob                     A clob containing the JSON to be loaded.
   **
   ** @param i_replace_bool             If TRUE then delete the existing JSON document of the same name 
   **                                   before loading this one.
   */
   PROCEDURE pr_load_json_document
   (
      i_document      IN VARCHAR2
     ,i_document_type IN VARCHAR2
     ,i_clob          IN VARCHAR2
     ,i_replace_bool  IN BOOLEAN DEFAULT FALSE
   );

   /*------------------------------------------------------------------------------------
   ** Creates the executable statement.  This is the AUTO generation of code for
   ** a migration step
   ** 
   ** @param i_migration_group           The migration group name.
   **
   ** @param i_migration_name            The step within the migration group name.
   **
   ** @param i_compile_test_bool         A boolean.  TRUE if you want to attempt compilation validation.
   **
   ** @param i_context                   The context the compilation validation will be carried out under.
   **
   ** @param o_tab_executable_statement  A collection of VARCHAR2 (Clobs don't work particularly well in the version 
   **                                    of forms this was originally written for).  Contains the executable code.
   **
   ** @param o_hash                      A hash value (based on the executable code)
   **
   ** @param o_tab_errors                A collection of VARCHAR2 (Clobs don't work particularly well in the version 
   **                                    of forms this was originally written for).  Contains any compilation errors etc.
   **
   ** @param o_errors_bool               A boolean TRUE / FALSE.  If there are compilation problems this will be TRUE.
   */
   PROCEDURE pr_create_executable_statement
   (
      i_migration_group          IN VARCHAR2
     ,i_migration_name           IN VARCHAR2
     ,i_compile_test_bool        IN BOOLEAN
     ,i_context                  IN VARCHAR2
     ,o_tab_executable_statement OUT t_vc_tab
     ,o_hash                     OUT RAW
     ,o_tab_errors               OUT t_vc_tab
     ,o_errors_bool              OUT BOOLEAN
   );

   /*------------------------------------------------------------------------------------
   ** Used by the FORM
   ** Sets a manual step with a statement that needs to be executed during the migration.
   ** 
   ** @param i_migration_group            The migration group name.
   **
   ** @param i_migration_name             The migration step within the migration group.
   **
   ** @param i_statement                  The code to be executed.
   */
   PROCEDURE pr_set_executable_statement
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
     ,i_statement       IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Used by the FORM
   ** Validates the code in the migration step.
   ** 
   ** @param i_migration_group            The migration group name.
   **
   ** @param i_migration_name             The migration name.
   **
   ** @param i_context                    The context the validation will take place under.
   **
   ** @param o_tab_errors                 A collection containing errors (if any).
   **
   ** @param o_errors_bool                Boolean TRUE or FALSE.  TRUE if there are errors.
   */
   PROCEDURE pr_validate_statement
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
     ,i_context         IN VARCHAR2
     ,o_tab_errors      OUT t_vc_tab
     ,o_errors_bool     OUT BOOLEAN
   );

   /*------------------------------------------------------------------------------------
   ** Used by the FORM
   ** Updates the migration header with new code (possibly auto generated code).
   ** 
   ** @param i_migration_group            The migration group name.
   **
   ** @param i_migration_name             The migration step within the migration group.
   **
   ** @param i_has_errors_ynu             (Y)es, (N)o, (U)nknown.
   **
   ** @param i_tab_statement              A collection of VARCHAR2 containing the code.
   */
   PROCEDURE pr_update_pemh_statement
   (
      i_migration_group IN VARCHAR2
     ,i_migration_name  IN VARCHAR2
     ,i_has_errors_ynu  IN VARCHAR2
     ,i_tab_statement   IN t_vc_tab
   );

   /*------------------------------------------------------------------------------------
   ** Used by FORMS.
   ** Copy or move a migration step from one group to another.
   **
   ** @param i_migration_group           The source migration group.
   **
   ** @param i_migration_name            The migration step name.
   **
   ** @param i_target_migration_group    The target migration group.
   **
   ** @param i_mode                      COPY or MOVE.  Copy makes a copy in the target.
   **                                    MOVE changes the source group name to a target group name.
   */
   PROCEDURE pr_copy_move_group
   (
      i_migration_group        IN VARCHAR2
     ,i_migration_name         IN VARCHAR2
     ,i_target_migration_group IN VARCHAR2
     ,i_mode                   IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Clears any mapping, relationship, and code comment for a given JSON document name
   ** and map/rule group.
   **
   ** @param i_document_name            The "document by example" JSON document.
   **
   ** @param i_mr_group                 A map rules group.
   */
   PROCEDURE pr_clear_mappings_for_doc
   (
      i_document_name IN VARCHAR2
     ,i_mr_group      IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Clears the cache (package state).
   */
   PROCEDURE pr_clear_json_cache;

   /*------------------------------------------------------------------------------------
   ** Populates the find swap cache for performance.
   */
   PROCEDURE pr_populate_find_swap_cache(i_introspect_step IN VARCHAR2 DEFAULT NULL);

   /*------------------------------------------------------------------------------------
   ** Resets sequences based on max surrogate IDs from specified tables.
   ** Handy routine to reset a sequence (possibly for a surrogate key column) to the value
   ** of the highest amount in the associated table +1.
   **
   ** @param i_sequence_name                  The sequence name.
   **
   ** @param i_sequence_owner                 The sequence schema name.
   **
   ** @param i_based_on_table                 The table which contains the column upon which the 
   **                                         sequence will be reset to + 1.
   **
   ** @param i_based_on_schema                The schema in which the table resides.
   **
   ** @param i_based_on_column                The column we will use to get the highest number from.
   */
   PROCEDURE pr_reset_seq
   (
      i_sequence_name   IN VARCHAR2
     ,i_sequence_owner  IN VARCHAR2 DEFAULT USER
     ,i_based_on_table  IN VARCHAR2
     ,i_based_on_schema IN VARCHAR2 DEFAULT USER
     ,i_based_on_column IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Gets a response (ref cursor) for the form search of target json/comments.
   **
   ** @param i_search_string       The searched for string.
   **
   ** @param o_ref_cursor          The ref cursor containing the response.
   */
   PROCEDURE pr_get_search_results
   (
      i_search_string IN VARCHAR2
     ,o_ref_cursor    OUT SYS_REFCURSOR
   );

   /*------------------------------------------------------------------------------------
   ** Used by FORMS.
   ** UPDATE / INSERT / DELETE relationship comments.
   **
   ** @param i_mode                             INSERT / UPDATE / DELETE.
   **
   ** @param i_mr_group                         The map/rules group the comment maintenance is for.
   **
   ** @param i_relationship_group_id            The relationship group id being maintained.
   **
   ** @param i_comment_type                     ('Q', 'C', 'L', 'T', 'F', 'A', 'D', 'V' )
   **
   ** @param i_comments                         The code/comment.
   **
   ** @param o_sqlrowcount                      The number of affected rows.
   */
   PROCEDURE pr_write_relationship_comment
   (
      i_mode                  IN VARCHAR2
     ,i_mr_group              IN VARCHAR2
     ,i_relationship_group_id IN NUMBER
     ,i_comment_type          IN VARCHAR2
     ,i_comments              IN VARCHAR2
     ,o_sqlrowcount           OUT NUMBER
   );

   /*------------------------------------------------------------------------------------
   ** Associates a context with a JSON document.
   ** Users can optionally associate (and disassociate) JSON document targets with a context.
   ** Validation of mappings is based on context and if a JSON document has nothing to do with
   ** a specific context users can unconnect them.  Equally if a JSON target IS related to 
   ** a context, then they can be associated.
   **
   ** @param i_json_document 
   **
   ** @param i_context_name 
   */
   PROCEDURE pr_add_context_association
   (
      i_json_document IN VARCHAR2
     ,i_context_name  IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Disassociate a context with a JSON document.
   ** Users can optionally associate (and disassociate) JSON document targets with a context.
   ** Validation of mappings is based on context and if a JSON document has nothing to do with
   ** a specific context users can unconnect them.  Equally if a JSON target IS related to 
   ** a context, then they can be associated.
   **
   ** @param i_json_document 
   **
   ** @param i_context_name 
   */
   PROCEDURE pr_remove_context_association
   (
      i_json_document IN VARCHAR2
     ,i_context_name  IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Handle special popups for the form.
   ** These look like normal forms poplists but allow a greater level of control.
   ** These popups also don't have the odd scrolling behaviour when used on certain 
   ** operating systems or through Remote Desktop.
   **
   ** @param i_sql      The SQL to populate the poplist.
   ** 
   ** @param i_handle   A handle to retrieve the data without requerying it.  
   */
   PROCEDURE pr_open_popup_cur
   (
      i_sql    IN VARCHAR2
     ,i_handle IN NUMBER
   );

   /*------------------------------------------------------------------------------------
   ** Handle special popups for the form.
   ** Fetch the data acquired in pr_open_popup_cur.
   **
   ** @param i_index        The row to retrieve
   ** 
   ** @param i_handle       The handle given to the pr_open_popup_cur when setup.  
   ** 
   ** @param o_shown        The value shown to the user.
   ** 
   ** @param o_actual       The value that will be used if chosen.
   ** 
   ** @param o_no_data_bool TRUE if no more data at index.
   */
   PROCEDURE pr_fetch_popup_cur
   (
      i_index        IN NUMBER
     ,i_handle       IN NUMBER
     ,o_shown        OUT VARCHAR2
     ,o_actual       OUT VARCHAR2
     ,o_no_data_bool OUT BOOLEAN
   );

   /*------------------------------------------------------------------------------------
   ** Handle special popups for the form.
   ** Clear the cache.
   **
   */
   PROCEDURE pr_clear_cached_popups;

   /*------------------------------------------------------------------------------------
   ** Add the tables and columns to the fixed set of tables and columns that can 
   ** be used in the mapping tool.
   ** This is just one way of adding tables, you can always insert yout own values
   ** into PRE_ETL_DB2_COLUMNS and PRE_ETL_DB2_TABLES, but just remember to use this
   ** rule : column_pos of -1 is for <Not Mapped> and the column_pos  starting at 0 
   ** for all the other real columns.
   **
   ** @param i_schema_name                     The schema name containing tables that you want to make
   **                                          available in the mapping tool.
   **
   ** @param i_tableset_name                   A name to group your schema tables together with.
   **
   ** @param i_delete_existing_in_set_bool     TRUE or FALSE. If TRUE then the definitions (if there are any)
   **                                          for the i_tableset_name will be deleted BEFORE the ones for the 
   **                                          specified schema are added.
   */
   PROCEDURE pr_add_schema_to_mapping_tool
   (
      i_schema_name                 IN VARCHAR2
     ,i_tableset_name               IN VARCHAR2
     ,i_delete_existing_in_set_bool IN BOOLEAN DEFAULT FALSE
   );

   /*------------------------------------------------------------------------------------
   ** Add single tables and associated columns to the fixed set of tables and columns
   ** that can be used in the mapping tool.
   ** This is just one way of adding  a table, you can always insert yout own values
   ** into PRE_ETL_DB2_COLUMNS and PRE_ETL_DB2_TABLES, but just remember to use this
   ** rule : column_pos of -1 is for <Not Mapped> and the column_pos  starting at 0 
   ** for all the other real columns.
   **
   ** @param i_owner_name                     The schema name of the table being added to the mapping tool.
   **
   ** @param i_table_name                     The table name that you want to make availble to the mapping tool.
   **
   ** @param i_tableset_name                  A name to group your table(s) together with.
   **
   ** @param i_delete_existing_in_set_bool    TRUE or FALSE.  If the table already exists in the i_tableset_name
   **                                         then it will be deleted.
   */
   PROCEDURE pr_add_table_to_mapping_tool
   (
      i_owner_name                  IN VARCHAR2
     ,i_table_name                  IN VARCHAR2
     ,i_tableset_name               IN VARCHAR2
     ,i_delete_existing_in_set_bool IN BOOLEAN DEFAULT FALSE
   );
END pkg_pre_etl_tools;
/
