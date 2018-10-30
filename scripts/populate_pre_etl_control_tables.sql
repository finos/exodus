REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput on verify off
set termout on

BEGIN
   DELETE FROM on_etl_params;
   COMMIT;
   --
   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_EMAIL_RECIPIENTS_DEV'
      ,'christian.leigh@markit.com,steve.barwood@markit.com'
      ,'Comma seperated list of email addresses to get development emails.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_EMAIL_RECIPIENTS_MAN'
      ,'christian.leigh@markit.com,steve.barwood@markit.com'
      ,'Comma seperated list of email addresses to get management emails.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_STATUS_EMAIL_SENDER'
      ,'migration@markit.com'
      ,'The email address of the sender.  So people can setup rule filters etc.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_SMTP_HOST'
      ,'mailhost'
      ,'The email host.');
   --
   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_UPDATE_CYCLE_MINS_MAN'
      ,'120'
      ,'Frequency of email updates for managers.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_UPDATE_CYCLE_MINS_DEV'
      ,'30'
      ,'Frequency of email updates for developers and IT staff.');
   --
   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_ETL_CONSUMER_GROUP'
      ,'ETL_GROUP'
      ,'Resource group for ETL tasks');
   --
   COMMIT;
END;
/

REM *******************************************************************************************************************************

BEGIN
   DELETE FROM pre_etl_params;
   COMMIT;
   --
   INSERT INTO pre_etl_params
   VALUES
      ('ACCESSIBLE_SCHEMAS'
      ,'PSE2_MCP_TS_OWNER;MCP_TS_OWNER;MCP_RS_OWNER;MCP_RF_OWNER;PRE_ETL_OWNER;STG_ETL_OWNER'
      ,'The schemas that the application will show pickable tables for (seperated by semi-colon.  For example in the create table document json.');

   INSERT INTO pre_etl_params
   VALUES
      ('INTROSPECTION'
      ,'ON'
      ,'Valid values "ON" or "OFF"');
   --
   COMMIT;
END;
/

exit
