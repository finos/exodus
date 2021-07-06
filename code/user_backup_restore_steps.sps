CREATE OR REPLACE PACKAGE user_backup_restore_steps AUTHID CURRENT_USER IS

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
   ** Backup a target schema into the PRE_ETL_OWNER as BK_
   ** Limitation in  the table being backed up. It cannot have a table name longer than
   ** 27 chars because we prefix with BK_
   **
   ** @param i_schema_name            The schema being backed up.
   **
   ** @param i_context                The context (used to get the parallelism variable).
   **
   ** @param i_overwrite_bool         TRUE or FALSE.  If TRUE then the Backup Table is 
   **                                 dropped if it already exists.
   **
   */
   PROCEDURE pr_backup_schema
   (
      i_schema_name    IN VARCHAR2
     ,i_context        IN VARCHAR2
     ,i_overwrite_bool IN BOOLEAN
   );

   /*------------------------------------------------------------------------------------
   ** Disable and Enable Constraints for a given schema.
   **
   ** @param i_schema_name            The schema being backed up.
   **
   ** @param i_mode                   Either : DISABLE or ENABLE
   **
   */   
   PROCEDURE pr_handle_constraint
   (
      i_schema_name IN VARCHAR2
     ,i_mode        IN VARCHAR2
   );   

   /*------------------------------------------------------------------------------------
   ** Restores the backup.
   **
   ** @param i_schema_name            The schema being backed up.
   **
   ** @param i_context                The context (used to get the parallelism variable).
   **
   */
   PROCEDURE pr_restore_schema
   (
      i_schema_name IN VARCHAR2
     ,i_context     IN VARCHAR2
   );

   /*------------------------------------------------------------------------------------
   ** Truncates the target schema.  Can be used as a manual step to clear down the 
   ** target before starting a migration.
   **
   ** @param i_schema_name            The schema in which the tables will be truncated.
   **
   */
   PROCEDURE pr_truncate_schema(i_schema_name IN VARCHAR2);

   /*------------------------------------------------------------------------------------
   ** Drops the backups that might exist for a particular target schema.
   **
   ** @param i_schema_name            Remove these backup tables (for the specified schema).
   **                                 I.e. the tables that were backed up based upon the 
   **                                 schema given.
   **
   */
   PROCEDURE pr_remove_backups(i_schema_name IN VARCHAR2);

END user_backup_restore_steps;
/
