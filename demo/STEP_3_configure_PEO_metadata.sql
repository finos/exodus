INSERT INTO pre_etl_mr_group
   (mr_group
   ,mr_group_description)
VALUES
   ('DEMO'
   ,'Demonstration')
/

INSERT INTO pre_etl_migration_groups
   (group_name
   ,group_title
   ,group_description
   ,display_order)
VALUES
   ('DEMO'
   ,'Migration Demo'
   ,'Demonstrate Migration'
   ,(SELECT nvl(MAX(display_order), 0) + 1
      FROM pre_etl_migration_groups))
/

BEGIN
   INSERT INTO pre_etl_run_contexts
      (context_name
      ,context_description)
   VALUES
      ('DEMO'
      ,'Demonstration Context');
EXCEPTION
   WHEN dup_val_on_index THEN
      NULL;
END;
/

INSERT INTO pre_etl_substitution_values
   (context_name
   ,substitution_key
   ,substitution_value)
VALUES
   ('DEMO'
   ,'${PARALLELISM}'
   ,'8')
/

INSERT INTO pre_etl_substitution_values
   (context_name
   ,substitution_key
   ,substitution_value)
VALUES
   ('DEMO'
   ,'${RUN_CONTEXT}'
   ,'DEMO')
/

INSERT INTO pre_etl_substitution_values
   (context_name
   ,substitution_key
   ,substitution_value)
VALUES
   ('DEMO'
   ,'${STG_ETL_OWNER}'
   ,'DEMO_STG_ETL_OWNER')
/

INSERT INTO pre_etl_substitution_values
   (context_name
   ,substitution_key
   ,substitution_value)
VALUES
   ('DEMO'
   ,'${TARGET_SCHEMA}'
   ,'TARGET_SCOTT_TIGER')
/

COMMIT
/

insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_EMAIL_RECIPIENTS_DEV', 'some.one@yourorg.com,some.one2@yourorg.com', 'Comma seperated list of email addresses to get development emails.');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_EMAIL_RECIPIENTS_MAN', 'man.ager@yourorg.com,boss.man@yourorg.com', 'Comma seperated list of email addresses to get management emails.');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_ETL_CONSUMER_GROUP', 'ETL_GROUP', 'Resource group for ETL tasks');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_SMTP_HOST', 'mailhost', 'The email host.');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_STATUS_EMAIL_SENDER', 'migration@yourorg.com', 'The email address of the sender.  So people can setup rule filters etc.');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_UPDATE_CYCLE_MINS_DEV', '30', 'Frequency of email updates for developers and IT staff.');
insert into ON_ETL_PARAMS (migration_group, param_name, param_value, param_description)
values ('DEMO', 'MIG_UPDATE_CYCLE_MINS_MAN', '120', 'Frequency of email updates for managers.');
COMMIT
/

BEGIN
   DELETE FROM pre_etl_params
     WHERE param_name in ( 'ACCESSIBLE_SCHEMAS', 'INTROSPECTION');

   INSERT INTO pre_etl_params
   VALUES
      ('ACCESSIBLE_SCHEMAS'
      ,'TARGET_SCOTT_TIGER;DEMO_STG_ETL_OWNER'
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

BEGIN
   pkg_pre_etl_tools.pr_add_schema_to_mapping_tool(i_schema_name                 => 'DEMO_STG_ETL_OWNER'
                                                  ,i_tableset_name               => 'DEMO'
                                                  ,i_delete_existing_in_set_bool => TRUE);
END;
/

exit