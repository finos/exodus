CREATE OR REPLACE TRIGGER trg_pesv_biu
   BEFORE INSERT OR UPDATE ON pre_etl_substitution_values
   FOR EACH ROW
DECLARE
   /*=================================================================================================
       Supporting Trigger For ETL / Migration Utilities For Tabular to Tabular+JSON migration.
       
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
   
   l_substitution_key VARCHAR2(50) := :new.substitution_key;
BEGIN
   IF l_substitution_key NOT LIKE '${%}'
   THEN
      raise_application_error(-20000
                             ,'Substitution key must be of the format ${YOUR_KEY}');
   END IF;
   --
   IF instr(substr(l_substitution_key
                  ,3
                  ,length(l_substitution_key) - 3)
           ,'}') > 0
      OR instr(substr(l_substitution_key
                     ,3
                     ,length(l_substitution_key) - 3)
              ,'{') > 0
   THEN
      raise_application_error(-20000
                             ,'Substitution key should not contain {}''s within the main key name. Check you don''t have unnecessary {}''s.');
   END IF;
END trg_pesv_biu;
/
