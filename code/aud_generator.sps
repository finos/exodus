CREATE OR REPLACE PACKAGE aud_generator AUTHID CURRENT_USER IS

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

   TYPE table_name_tab_typ IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;

   /*--------------------------------------------------------------------------
   ** Auto build of audit code (triggers and tables).
   **
   ** @param pvi_only_triggers_yn      Only Build Triggers (otherwise build tables too).
   **
   ** @param pvi_owner                 The owner of the table having an audit trigger made.
   **
   ** @param pti_table_names           The name of the table that is having an audit trigger built automatically.
   */

   PROCEDURE create_audit_objs
   (
      pvi_only_triggers_yn IN VARCHAR2 DEFAULT 'N'
     ,pvi_owner            IN VARCHAR
     ,pti_table_names      IN table_name_tab_typ
   );

END aud_generator;
/
