# EXODUS : Map > Document > Migrate > JSON & Tables
![alt text](https://github.com/finos/exodus/blob/master/exodus_logo_small.jpg "Exodus")


[![FINOS - Incubating](https://cdn.jsdelivr.net/gh/finos/contrib-toolbox@master/images/badge-incubating.svg)](https://finosfoundation.atlassian.net/wiki/display/FINOS/Incubating)

# EXODUS - Migration Tools

Exodus is a mapping, documenting, and migration tool especially designed with Oracle PL/SQL developers in mind.  If you are comfortable with Oracle PL/SQL then all your mapping and migration code can be constructed here without the need for non-Oracle external tools.  There is no magic “black box” behavior.  All of the auto-generated code (also in PL/SQL) is made available and viewable from within the tool, and because it’s in a language that seasoned Oracle developers are expert in, there will be no unexpected surprises with the technical approach.  
It’s entirely possible to use Exodus to “just” document your mapping efforts (it will certainly be far less stressful and error prone than using a spreadsheet to capture mappings and relationships).  With just a basic understanding of the tool tables you can write your own SQL reports to get information about how much you’ve mapped (in other words, report on SOURCE data that you have understood enough to express a connection to the target end state) in your migration.  
Exodus can be used to do far more than documenting the migration.  Exodus can form the core nucleus of your migration where all of the steps required to take data from a set of source tables to a set of target tables in multiple schemas can be defined and coded.  Exodus can map table-to-table and table-to-JSON documents.  You will be able to capture comments, questions, value translations, functions, and even SQL code to drive your migration.  
There is an extensive run framework (including logging, introspection, and debugging instrumentation) to execute your migration to any level of concurrency that your hardware and licenses can support to maximize your compute resource.



## Installation

Linux:

Verify your Oracle DB is set to EXTENDED data types
Connect with a correctly privileged account.
```sh
SELECT value FROM v$parameter where name = 'max_string_size';
```
Run the SQL above it MUST return "EXTENDED". If it returns "STANDARD" then you CANNOT deploy this migration suite.

Update config file.
Notable things to set are..
```sh
deploy_usr="pre_etl_owner"      * Leave this as pre_etl_owner.
deploy_pwd="pre_etl_owner"      * Whatever password you want pre_etl_owner to have.

admin_usr="admin"               * The high privilege account.  Could be SYS. (on AWS its admin).
admin_pwd="admin1234"           * The password for the high privilege account.
admin_ext=""                    * If you are using SYS in admin_usr then this needs to be "AS SYSDBA".

stg_types="DEMO"                * The staging contexts (might just be PROD).
                                  Comma separated.

temp_ts="TEMP"                  * The Temp TS (most likely left as TEMP).
tool_ts="TS_MIGTOOL"            * The Tools TS.       
                                  (whatever TableSpace you have created for the Tool)
stg_ts="TS_STAGED"              * The staging data TS.
                                  (whatever TableSpace you have created for the Staged Data)

target_db="MYDB"                * The db to connect to for deployment.  Your DB.
```

Run the shell script.

```sh
. deploy_master.sh
```

## Usage example

See the supplied Exodus Manual.docx

## Development setup

You will need an Oracle Database, and an Oracle Forms 11g (or higher) installation.

## Contributing

We welcome contributions in form of request changes, that can be submitted via [GitHub issues](https://github.com/finos/exodus/issues).

## License

Copyright 2018 IHS Markit

Distributed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

SPDX-License-Identifier: [Apache-2.0](https://spdx.org/licenses/Apache-2.0)
