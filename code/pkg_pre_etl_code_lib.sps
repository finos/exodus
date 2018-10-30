CREATE OR REPLACE PACKAGE pkg_pre_etl_code_lib IS
   /*=================================================================================================
       Supporting Package For ETL / Migration Utilities For Tabular to Tabular+JSON migration.
       
       Developed by Christian Leigh

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

     =================================================================================================  
   */

   /*------------------------------------------------------------------------------------
   ** Check if code comment is the same as one in the library.
   **
   ** @param i_rowid                    The rowid of the pre_etl_comment row.
   **
   ** @param o_match_yn                 Y if match found, else N
   **
   ** @param o_hash_vc                  The hash of the comment for the supplied rowid.
   */
   PROCEDURE pr_code_comment_matches_lib_yn
   (
      i_rowid    IN ROWID
     ,o_match_yn OUT VARCHAR2
     ,o_hash_vc  OUT VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Check if code comment is the same as one in the library.
   **
   ** @param i_code_comment             The text from the pre_etl_comments.
   **
   ** @param o_match_yn                 Y if match found, else N
   **
   ** @param o_hash_vc                  The hash of the comment for the supplied rowid.
   */
   PROCEDURE pr_code_comment_matches_lib_yn
   (
      i_code_comment IN VARCHAR2
     ,o_match_yn     OUT VARCHAR2
     ,o_hash_vc      OUT VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Useful for developers to quickly access the code/comment for an attribute.
   ** NOTE : All values are case INSENSITIVE for ease of use.
   **
   ** @param i_document                 The document name.
   **
   ** @param i_line_number              The line number of the document.
   **
   ** @param i_map_rules_group          The mapping / rules group to use.
   **                                   Leave as NULL to output all.
   **
   ** @param i_context                  The context (leave as NULL for no translation).
   **                                   If this is supplied then contextual variables 
   **                                   surrounded by {} will be converted for the context.
   **
   */

   PROCEDURE pr_dbms_output_code_comment
   (
      i_document        IN VARCHAR2
     ,i_line_number     IN NUMBER
     ,i_map_rules_group IN VARCHAR2 DEFAULT NULL
     ,i_context         IN VARCHAR2 DEFAULT NULL
   );

   /*------------------------------------------------------------------------------------
   **Add to code lib.
   **
   ** @param i_library_name             Library name.
   **
   ** @param i_snippet_name             Snippet name.
   **
   ** @param i_snippet_desc             Description of snippet.
   **
   ** @param i_snippet_code             Textual code.
   **
   ** @param i_overwrite_bool           If hash or Library/snippet exists then overwrite.
   */
   PROCEDURE pr_add_to_lib
   (
      i_library_name   IN VARCHAR2
     ,i_snippet_name   IN VARCHAR2
     ,i_snippet_desc   IN VARCHAR2
     ,i_snippet_code   IN CLOB
     ,i_overwrite_bool IN BOOLEAN DEFAULT FALSE
   );

   /*------------------------------------------------------------------------------------
    **Update code lib.
    **
    ** @param i_snippet_hash             The hash of the snippet textual code.
    **
    ** @param i_snippet_code             Textual code.
    **
    ** @param o_library_name            The library that was updated. 
   */
   PROCEDURE pr_update_lib
   (
      i_snippet_hash IN VARCHAR2
     ,i_snippet_code IN CLOB
     ,o_library_name OUT VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   **Deletes from the library.
   **
   ** @param i_snippet_hash             The hash of the snippet textual code.
   **
   */
   PROCEDURE pr_delete_from_lib(i_snippet_hash IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Add to the standard clipboard.
   **
   ** @param i_snippet_code             Textual code.
   **
   */

   PROCEDURE pr_add_to_clipboard(i_snippet_code IN VARCHAR2);

END pkg_pre_etl_code_lib;
/
