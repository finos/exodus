1)  IF NEEDED (there may already be one here).
    The deployment of the main exodus tool might create a DEMO_STG_ETL_OWNER
    (password is the same as username)

    Create a (source of migration) schema called DEMO_STG_ETL_OWNER
    EG.

    GRANT CONNECT,RESOURCE,UNLIMITED TABLESPACE TO DEMO_STG_ETL_OWNER IDENTIFIED BY DSEO_PW_1;
    ALTER USER DEMO_STG_ETL_OWNER DEFAULT TABLESPACE USERS;
    ALTER USER DEMO_STG_ETL_OWNER TEMPORARY TABLESPACE TEMP;


2)  Create a target schema TARGET_SCOTT_TIGER
    EG.

    GRANT CONNECT,RESOURCE,UNLIMITED TABLESPACE TO TARGET_SCOTT_TIGER IDENTIFIED BY TST_PW_1;
    ALTER USER TARGET_SCOTT_TIGER DEFAULT TABLESPACE USERS;
    ALTER USER TARGET_SCOTT_TIGER TEMPORARY TABLESPACE TEMP;


3)  IN SQL*PLUS Logged on as : DEMO_STG_ETL_OWNER
    execute : @STEP_1_create_demo_stg_schema.sql

    i.e. : sqlplus -L DEMO_STG_ETL_OWNER/DSEO_PW_1@<your db>@STEP_1_create_demo_stg_schema.sql


3)  IN SQL*PLUS Logged on as : TARGET_SCOTT_TIGER  (password as defined above : eg. TST_PW_1)
    execute : @STEP_2_target_demo_schema.sql

    i.e. : sqlplus -L TARGET_SCOTT_TIGER/TST_PW_1@<your db> @STEP_2_target_demo_schema.sql


4)  IN SQL*PLUS Logged on as : PRE_ETL_OWNER    (the Exodus MetaData Schema)
    execute : @STEP_3_configure_PEO_metadata.sql

    i.e. : sqlplus -L pre_etl_owner/pre_etl_owner@<your db> @STEP_3_configure_PEO_metadata.sql


5)  Setup a document to map to.
    Open the EmployeeDocument.txt in a text editor of your choice, and Select All and Ctrl-C (copy)
    Press the "manage JSON" button in the Exodus Tool.
    Choose Stored Document from the pulldown (to the right of the document name).
    Type a document name (eg. Employee Document) and then paste the copied document into the Document Area.
    Press "Load JSON"
    Press "Install JSON"

    Accept the load dialog.

    Now press the "manage JSON" button AGAIN  in the Exodus Tool.
    Press the "Add Table Document" button.
    Using the pulldown, choose "target_scott_tiger.employee"
    Press "ok"
    Press "Install JSON"

    You now have 2 documents in the "Target Mapping JSON Document" list.

    You are now ready to begin mapping your document.

    See on-line for youTube examples of these documents being mapped.


6)  Backup your mappings using the export_etl_owner.cmd (in the commands directory)
    You can store the resultant DMP files in your source control system.
    Restoration can be achieved with import_etl_owner.cmd (in the commands directory)
    (You will need to edit thses files to choose another instance to backup to/restore from - by default they are set to mydb)
