  __  __ _                 _   _
 |  \/  (_)               | | (_)
 | \  / |_  __ _ _ __ __ _| |_ _  ___  _ __
 | |\/| | |/ _` | '__/ _` | __| |/ _ \| '_ \
 | |  | | | (_| | | | (_| | |_| | (_) | | | |
 |_|  |_|_|\__, |_|  \__,_|\__|_|\___/|_| |_|      READ ME....
            __/ |                                                    __
           |___/				    _____ _____  ___/ /_ _____
						   / -_) \ / _ \/ _  / // (_-<         (c) IHS Markit 2018
===================================================\__/_\_\\___/\_,_/\_,_/___/============================

Developed By : Christian Leigh.

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

PORTIONS OF THE CODE - Specifically code, variables and constants relating to :-

                       pkg_pre_etl_tools.fn_get_xml_to_json_stylesheet
                       pkg_pre_etl_tools.fn_ref_cursor_to_json
                       pkg_pre_etl_tools.fn_sql_to_json

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

  _____           _        _ _       _   _                 _____           _                   _   _
 |_   _|         | |      | | |     | | (_)               |_   _|         | |                 | | (_)
   | |  _ __  ___| |_ __ _| | | __ _| |_ _  ___  _ __       | |  _ __  ___| |_ _ __ _   _  ___| |_ _  ___  _ __  ___
   | | | '_ \/ __| __/ _` | | |/ _` | __| |/ _ \| '_ \      | | | '_ \/ __| __| '__| | | |/ __| __| |/ _ \| '_ \/ __|
  _| |_| | | \__ \ || (_| | | | (_| | |_| | (_) | | | |    _| |_| | | \__ \ |_| |  | |_| | (__| |_| | (_) | | | \__ \
 |_____|_| |_|___/\__\__,_|_|_|\__,_|\__|_|\___/|_| |_|   |_____|_| |_|___/\__|_|   \__,_|\___|\__|_|\___/|_| |_|___/

NOTE : Errors such as : $'\r': command not found
       Indicate the files are not in a UNIX format.
       You may need to : dos2unix *

1.  Run this SQL it MUST return "EXTENDED". If it returns "STANDARD" then
    you CANNOT deploy this migration suite.  You may need to be connected as a privileged user to do this.

    SELECT value FROM v$parameter where name = 'max_string_size';


2.  Update the config file BEFORE running this script.
    Things to set are...

        deploy_usr="pre_etl_owner"                             * Leave this as pre_etl_owner.
        deploy_pwd="pre_etl_owner"                             * Whatever password you want pre_etl_owner to have.

        admin_usr="admin"                                      * The high privilege account.  Could be SYS. (AWS its admin).
        admin_pwd="admin1234"                                  * The password for the high privilege account.
        admin_ext=""                                           * If you are using SYS then this needs to be "AS SYSDBA".

        stg_types="DEMO"                                       * The staging contexts (might just be PROD).
                                                                 Comma separated.

        temp_ts="TEMP"                                         * The Temp TS (most likely left as TEMP).
        tool_ts="TS_MIGTOOL"                                   * The Tools TS.       (whatever TableSpace you have created for the Tool)
        stg_ts="TS_STAGED"                                     * The staging data TS.(whatever TableSpace you have created for the Staged Data)

        target_db="MYDB"                                       * The db to connect to for deployment.  Your DB.


3.  Run the deploy

      . deploy_master.sh

4.  Deploy the demo Staging schema and Demo Target Schema (see Demo directory)

5.  If you are importing the metadata from another system, for
    example you are importing the metadata from a development
    system.    See Note 3 - The import may need to run certain
    steps that will require the staging data to be in place.

      . import_metadata_into_target_deploy_db.sh

6.  That's it!


To use the web based interface you will need to install Oracle Forms.
Oracle Forms is NOT a free product (it licenced and sold by Oracle), although Oracle do allow evaluation downloads.
If your organisation already has Oracle Forms you can compile and run the forms distributed with Exodus.
You will need to install Oracle forms.  Other resources on the internet can be referenced to aid you in this task.
Some helpful pointers are shown in the : Exodus Manual.docx (see documentation).

