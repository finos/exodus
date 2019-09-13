REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput off verify off
set termout off

REM *********************************************************************************************
REM ** RUN AS PRE_ETL_OWNER
REM *********************************************************************************************

define tool_ts = '&1'
define stg_types = '&2'

REM *********************************************************************************************
REM ** Create TYPEs TABLEs and other objects.
REM *********************************************************************************************

DECLARE
   PROCEDURE drop_obj
   (
      p_obj_type IN VARCHAR2
     ,p_obj_name IN VARCHAR2
   ) IS
   BEGIN
      dbms_output.put_line('Dropping :' || p_obj_type || ' ' ||
                           p_obj_name);
      EXECUTE IMMEDIATE 'drop ' || p_obj_type || ' ' || p_obj_name;
   EXCEPTION
      WHEN OTHERS THEN
         IF SQLCODE IN (-942, -2289, -4043, -1434)
         THEN
            NULL;
         ELSE
            RAISE;
         END IF;
   END;
BEGIN
   drop_obj('CONTEXT', 'JSON_CONTEXT');
   drop_obj('TYPE', 'T_NV_PAIR_TAB');
   drop_obj('TYPE', 'T_NV_PAIR');
   drop_obj('TYPE', 'T_DOCBYEXAMPLE_TAB');
   drop_obj('TYPE', 'T_DOCBYEXAMPLE_ROW');
   drop_obj('TYPE', 'T_INTROSPECT_TAB');
   drop_obj('TYPE', 'T_INTROSPECT_ROW');
   drop_obj('TYPE', 'T_COL_ATTR_TAB');
   drop_obj('TYPE', 'T_COL_ATTR');
   drop_obj('TYPE', 'T_JSON_REPLACE_TAB');
   drop_obj('TYPE', 'T_JSON_REPLACE_ROW');
   drop_obj('TYPE', 'T_GENERIC_VC500_TAB');
   drop_obj('TYPE', 'T_COL_ATTR_TAB_SHORTFORM');
   drop_obj('TYPE', 'T_COL_ATTR_SHORTFORM');
   drop_obj('TYPE', 'T_SEPARATOR_TAB');
   drop_obj('TYPE', 'T_SEPARATOR_ROW');
   drop_obj('TABLE', 'ON_ETL_DRIVER');
   drop_obj('TABLE', 'ON_ETL_PARAMS');
   drop_obj('TABLE', 'ON_ETL_LOG');
   drop_obj('TABLE', 'ON_ETL_INSTRUCTION');
   drop_obj('TABLE', 'PRE_ETL_DB2_TABLES');
   drop_obj('TABLE', 'PRE_ETL_DB2_COLUMNS');
   drop_obj('TABLE', 'PRE_ETL_JSON_DOCUMENT');
   drop_obj('TABLE', 'PRE_ETL_JSON_LINES');
   drop_obj('TABLE', 'PRE_ETL_RELATED_JSON_LINES');
   drop_obj('TABLE', 'PRE_ETL_MAPPED');
   drop_obj('TABLE', 'PRE_ETL_COMMENTS');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_HEADER');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_DETAIL');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_SRC');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_HINT');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_SRC_INLINE_V');
   drop_obj('TABLE', 'PRE_ETL_FIND_SWAP');
   drop_obj('TABLE', 'PRE_ETL_MR_GROUP');
   drop_obj('TABLE', 'PRE_ETL_PARAMS');
   drop_obj('TABLE', 'PRE_ETL_RUN_CONTEXTS');
   drop_obj('TABLE', 'PRE_ETL_SUBSTITUTION_VALUES');
   drop_obj('TABLE', 'PRE_ETL_DOC_VALID_CONTEXTS');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_GROUPS');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_RUN_HINT');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_LIBS');
   drop_obj('TABLE', 'PRE_ETL_MIGRATION_CODE_LIB');
   drop_obj('TABLE', 'GTT_TOUCH_MIGRATION_STATUS');
   drop_obj('SEQUENCE', 'PRE_ETL_SEQ_RG');
   drop_obj('SEQUENCE', 'PRE_ETL_SEQ_PEJL');
   drop_obj('SEQUENCE', 'PRE_ETL_SEQ_PERJL');
   drop_obj('SEQUENCE', 'ON_ETL_SEQ_OEL');
   drop_obj('SEQUENCE', 'AGL_SEQ_NO_SEQ');
   --
   -- DROP AUDIT TABLES.
   drop_obj('TABLE', 'AUD_GENERATOR_LOG');
   FOR i_buf IN (SELECT *
                   FROM user_tables ut
                  WHERE ut.table_name LIKE 'AUD/_PRE/_ETL/_%' ESCAPE '/')
   LOOP
      drop_obj('TABLE', i_buf.table_name);
   END LOOP;

END;
/



REM ***************************************************************************************************************************************

BEGIN
   dbms_output.put_line ( 'Create : migration_context' );
   EXECUTE IMMEDIATE 'CREATE OR REPLACE CONTEXT migration_context USING  pre_etl_owner.pkg_pre_etl_tools ACCESSED GLOBALLY';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line('Context already exists');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_NV_PAIR';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> as object ( name varchar2(61), value varchar(32000) ) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_NV_PAIR_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> is table of T_NV_PAIR ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/
REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_DOCBYEXAMPLE_ROW';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> as object ( json_line               VARCHAR2(500)
                                                              , verbatim_yn             VARCHAR2(1)
                                                              , mr_group                VARCHAR2(50)
                                                              , relationship_group_id   NUMBER
                                                              , mapping                 VARCHAR2(32000 BYTE) ) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_DOCBYEXAMPLE_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> is table of T_DOCBYEXAMPLE_ROW ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_INTROSPECT_ROW';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create or replace type <TYPE> as object
                                                  ( intro_step       VARCHAR2(500)
                                                  , intro_context    VARCHAR2(500)
                                                  , intro_aspect     VARCHAR2(500)
                                                  , processed        NUMBER
                                                  , min_runtime_secs NUMBER(10,2)
                                                  , max_runtime_secs NUMBER(10,2)
                                                  , avg_time_secs    NUMBER(10,2)
                                                  , total_time_secs  NUMBER(10,2)
                                                  )  ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_INTROSPECT_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> is table of T_INTROSPECT_ROW ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_SEPARATOR_ROW';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> as object ( rn   NUMBER
                                                              , text VARCHAR2(500) ) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_SEPARATOR_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create type <TYPE> is table of T_SEPARATOR_ROW ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_COL_ATTR';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS OBJECT
                                (
                                   column_name VARCHAR2(128),
                                   data_type   VARCHAR2(128),
                                   data_length NUMBER
                                ) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_COL_ATTR_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS TABLE OF t_col_attr ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_COL_ATTR_SHORTFORM';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS OBJECT
                                (
                                   column_name VARCHAR2(128)
                                ) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_COL_ATTR_TAB_SHORTFORM';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS TABLE OF t_col_attr_shortform ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_JSON_REPLACE_ROW';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS OBJECT
                                (field_type   VARCHAR2(30)
                                ,char_value   VARCHAR2(2000)
                                ,char_length  NUMBER
                                ,number_value NUMBER) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_JSON_REPLACE_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS TABLE OF t_json_replace_row ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/
REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'T_GENERIC_VC500_TAB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE OR REPLACE TYPE <TYPE> AS TABLE OF VARCHAR2(500) ]'
                            ,'<TYPE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/


REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'ON_ETL_DRIVER';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE> ( source_schema         VARCHAR2(30)
                                                      , source_table_name     VARCHAR2(30)
                                                      , grouping_code         VARCHAR2(200)
                                                      , order_within_grouping NUMBER
                                                      , partitions_in_set     NUMBER
                                                      , staged_rowid          ROWID
                                                      , utility_field_1       VARCHAR2(500)
                                                      , utility_field_2       VARCHAR2(500)
                                                      , utility_field_3       VARCHAR2(500)
                                                      , utility_field_4       VARCHAR2(500)
                                                      , utility_field_5       VARCHAR2(500)
                                                      , primary key ( source_schema
                                                                    , source_table_name
                                                                    , grouping_code
                                                                    , order_within_grouping ) )
                                                        ORGANIZATION INDEX
                                                        OVERFLOW TABLESPACE &tool_ts ]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'OED_IDX_1';
   l_objname2 VARCHAR2(30) := 'ON_ETL_DRIVER';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ CREATE INDEX <INDEX> ON <TABLE> ( source_schema
                                                                         , source_table_name
                                                                         , decode(partitions_in_set,NULL,NULL,ora_hash(grouping_code, partitions_in_set))
                                                                         ) initrans 10 ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'ON_ETL_PARAMS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE> ( migration_group    VARCHAR2(100)
                                                      , param_name         VARCHAR2(100)
                                                      , param_value        VARCHAR2(2000)
                                                      , param_description  VARCHAR2(2000)
                                                      , CONSTRAINT oep_pk PRIMARY KEY (migration_group, param_name) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'ON_ETL_LOG';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE> ( log_id                NUMBER
                                                      , log_type              VARCHAR2(10)
                                                      , log_batch             NUMBER
                                                      , log_context           VARCHAR2(50)
                                                      , log_migration_group   VARCHAR2(100)
                                                      , log_activity_group    VARCHAR2(100)
                                                      , log_entry             VARCHAR2(2000)
                                                      , log_ts                TIMESTAMP default systimestamp
                                                      , log_extended_info     CLOB
                                                      , CONSTRAINT oel_pk     PRIMARY KEY (log_id) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'ON_ETL_INSTRUCTION';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE> ( action_name  VARCHAR2(30)
                                                      , action_item  VARCHAR2(30)
                                                      , primary key ( action_name
                                                                    , action_item ) ) ORGANIZATION INDEX ]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_SEQ_RG';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create sequence <SEQ> start with 1 increment by 1 ]'
                            ,'<SEQ>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_GROUPS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE> ( group_name          VARCHAR2(100)
                                                       , group_title         VARCHAR2(100)
                                                       , group_description   VARCHAR2(2000)
                                                       , display_order       NUMBER
                                                       , CONSTRAINT pk_pemg PRIMARY KEY (group_name) )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_DB2_TABLES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     table_name            VARCHAR2(50)       NOT NULL,
     markit_comment        VARCHAR2(2000),
     description           VARCHAR2(2000),
     local_hash            VARCHAR2(50),
     tableset_name         VARCHAR2(50)       NOT NULL,
     CONSTRAINT pedt_pk PRIMARY KEY (table_name)
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_DB2_COLUMNS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     table_name            VARCHAR2(50)       NOT NULL,
     column_pos            NUMBER             NOT NULL,
     column_name           VARCHAR2(50)       NOT NULL,
     column_type           VARCHAR2(50)       NOT NULL,
     column_length         NUMBER             NOT NULL,
     comments              VARCHAR2(2000),
     tableset_name         VARCHAR2(50)       NOT NULL,
     CONSTRAINT pedc_ck_ct check (column_type IN ('RAW', 'CHARACTER','TIMESTAMP','VARCHAR','SMALLINT','TIME','TIMESTAMP(6)','TIMESTAMP(6) WITH TIME ZONE','INTEGER','NUMBER','CHAR','0','DATE','DECIMAL','VARCHAR2','ROWID','CLOB')),
     CONSTRAINT pedc_pk PRIMARY KEY (table_name, column_name)
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_JSON_DOCUMENT';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     document_name         VARCHAR2(50)       NOT NULL,
     comments              VARCHAR2(2000),
     document_type         VARCHAR2(30)       NOT NULL CONSTRAINT CHK_PEJD_DT check (document_type IN ('STORED DOCUMENT', 'TABLE DOCUMENT', 'STORED FRAGMENT' )),
     CONSTRAINT pejd_pk PRIMARY KEY (document_name)
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_SEQ_PEJL';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create sequence <SEQ> start with 1 increment by 1 ]'
                            ,'<SEQ>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_JSON_LINES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     id                    NUMBER             NOT NULL,
     document_name         VARCHAR2(50)       NOT NULL,
     line_number           NUMBER             NOT NULL,
     json_line             VARCHAR2(500)      NOT NULL,
     comments              VARCHAR2(2000)
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PEJL_UNQ_IDX_1';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_JSON_LINES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ create unique index <INDEX> ON <TABLE> (document_name, line_number) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_SEQ_PERJL';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create sequence <SEQ> start with 1 increment by 1 ]'
                            ,'<SEQ>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'ON_ETL_SEQ_OEL';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create sequence <SEQ> start with 1 increment by 1 ]'
                            ,'<SEQ>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'AGL_SEQ_NO_SEQ';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create sequence <SEQ> start with 1 increment by 1 ]'
                            ,'<SEQ>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_RELATED_JSON_LINES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     id                        NUMBER             NOT NULL,
     document_name             VARCHAR2(50)       NOT NULL,
     line_number               NUMBER             NOT NULL,
     mr_group                  VARCHAR2(50)       NOT NULL,
     relationship_group_id     NUMBER             NOT NULL,
     relationship_comment      VARCHAR2(500)      NOT NULL
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PERJL_IDX_1';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_RELATED_JSON_LINES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ create index <INDEX> ON <TABLE> (mr_group, relationship_group_id) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PERJL_IDX_2';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_RELATED_JSON_LINES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ create unique index <INDEX> ON <TABLE> (mr_group, document_name, line_number) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MAPPED';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     table_name            VARCHAR2(50)       NOT NULL,
     column_name           VARCHAR2(50)       NOT NULL,
     mr_group              VARCHAR2(50)       NOT NULL,
     relationship_group_id NUMBER             NOT NULL
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PEM_UNQ_IDX_1';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_MAPPED';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ create unique index <INDEX> ON <TABLE> (mr_group, relationship_group_id, table_name, column_name) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_COMMENTS';
BEGIN
   --
   -- CHK_PEC_CT (Q)uestion / (C)omment / (L)ookup / (T)ranslation / (F)unction / (A)rray / (D)ictionary
   --
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ create table <TABLE>
   (
     mr_group              VARCHAR2(50)       NOT NULL,
     relationship_group_id NUMBER             NOT NULL,
     comment_type          VARCHAR2(1)        NOT NULL CONSTRAINT CHK_PEC_CT CHECK (comment_type IN ('Q', 'C', 'L', 'T', 'F', 'A', 'D', 'V' )),
     comments              CLOB
   )
   ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PEC_UNQ_IDX_1';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_COMMENTS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ create unique index <INDEX> ON <TABLE> (mr_group, relationship_group_id, comment_type) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_HEADER';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE> ( migration_group          VARCHAR2(100) NOT NULL
                                                       , migration_name           VARCHAR2(100) NOT NULL
                                                       , migration_description    VARCHAR2(2000)
                                                       , staged_schema            VARCHAR2(50)
                                                       , mr_group_to_use          VARCHAR2(50)  NOT NULL
                                                       , order_of_exec            NUMBER
                                                       , executable_statement     CLOB
                                                       , statement_has_errors_ynu VARCHAR2(1) DEFAULT 'U' NOT NULL CONSTRAINT CHK_PEMH_SHEY check (statement_has_errors_ynu IN ('Y','N','U'))
                                                       , header_type              VARCHAR2(1) DEFAULT 'M' NOT NULL  CONSTRAINT CHK_PEMH_HT   check (header_type IN ('M','P'))
                                                       , CONSTRAINT pk_pemh PRIMARY KEY (migration_group, migration_name)
                                                       ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'UNQ_IDX_PEMH';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_MIGRATION_HEADER';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ CREATE UNIQUE INDEX <INDEX> ON  <TABLE> ( migration_group, order_of_exec ) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_DETAIL';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE> ( migration_group           VARCHAR2(100) NOT NULL
                                                       , migration_name            VARCHAR2(100) NOT NULL
                                                       , migration_document        VARCHAR2(50)
                                                       , order_of_exec             NUMBER
                                                       , trigger_sql               VARCHAR2(2000) DEFAULT '1=1'
                                                       , smart_cache_attrs         VARCHAR2(2000)
                                                       , touch_migration_status_yn VARCHAR2(1) DEFAULT 'N'
                                                         CONSTRAINT chk_tms_yn check (touch_migration_status_yn IN ('Y','N'))
                                                       , mr_group_to_use_for_json  VARCHAR2(50)  NOT NULL
                                                       , smart_cache_key           VARCHAR2(4000)
                                                       , CONSTRAINT pk_pemd PRIMARY KEY ( migration_group
                                                                                        , migration_name
                                                                                        , migration_document)
                                                       ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'UNQ_IDX_PEMD';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_MIGRATION_DETAIL';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ CREATE UNIQUE INDEX <INDEX> ON  <TABLE> ( migration_group, migration_name, order_of_exec ) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_SRC';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( migration_group              VARCHAR2(100) NOT NULL
                                                        , migration_name               VARCHAR2(100) NOT NULL
                                                        , table_name                   VARCHAR2(50)  NOT NULL
                                                        , join_type                    VARCHAR2(10)
                                                        , is_inline_view_yn            VARCHAR2(1)   NOT NULL
                                                                                       CONSTRAINT chk_iiv_yn  CHECK ( is_inline_view_yn IN ('Y','N') )
                                                        , where_or_join_predicates     VARCHAR2(2000)
                                                        , use_with_on_etl_driver_yn    VARCHAR2(1) DEFAULT 'N' NOT NULL
                                                                                       CONSTRAINT CHK_PEMS_UWOED_YN CHECK ( use_with_on_etl_driver_yn IN ('Y','N') )
                                                        , order_by                     NUMBER not null
                                                        , CONSTRAINT pk_pems PRIMARY KEY ( migration_group
                                                                                         , migration_name
                                                                                         , table_name)
                                                        ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_RUN_HINT';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( migration_group              VARCHAR2(100)  NOT NULL
                                                        , migration_name               VARCHAR2(100)  NOT NULL
                                                        , hint                         VARCHAR2(1000) NOT NULL
                                                        , CONSTRAINT pk_pemhi PRIMARY KEY ( migration_group
                                                                                         , migration_name
                                                                                         )
                                                        ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_CODE_LIB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( library_name                 VARCHAR2(100)  NOT NULL
                                                        , snippet_name                 VARCHAR2(100)  NOT NULL
                                                        , snippet_desc                 VARCHAR2(1000) NOT NULL
                                                        , snippet_code                 CLOB
                                                        , snippet_hash                 RAW(16) NOT NULL
                                                        , last_changed                 TIMESTAMP(6)
                                                        , CONSTRAINT pk_pemcl PRIMARY KEY ( library_name
                                                                                          , snippet_name
                                                                                          )
                                                        ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname  VARCHAR2(30) := 'PEMCL_IDX_1';
   l_objname2 VARCHAR2(30) := 'PRE_ETL_MIGRATION_CODE_LIB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(REPLACE(q'[ CREATE UNIQUE INDEX <INDEX> ON <TABLE> (snippet_hash) ]'
                                    ,'<TABLE>'
                                    ,l_objname2)
                            ,'<INDEX>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_LIBS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( library_name                 VARCHAR2(100)  NOT NULL
                                                        , library_desc                 VARCHAR2(1000) NOT NULL
                                                        , CONSTRAINT pk_peml PRIMARY KEY ( library_name
                                                                                          )
                                                        ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_CODE_LIB';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ ALTER TABLE pre_etl_migration_code_lib
                                    ADD CONSTRAINT fk_pemcl FOREIGN KEY (library_name)
                                        REFERENCES pre_etl_migration_libs (library_name)
                                ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -2275
      THEN
         dbms_output.put_line(l_objname||' FK already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MIGRATION_SRC_INLINE_V';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( inline_view_name VARCHAR2(30)
                                                        , source_code      CLOB
                                                        , view_description CLOB,
                                                          CONSTRAINT PK_PEMSIV primary key (inline_view_name)
                                                        )
                                            ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_FIND_SWAP';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( find_value               VARCHAR2(500)
                                                        , swap_value               VARCHAR2(500)
                                                        , use_case                 VARCHAR2(500)
                                                        ) ]', '<TABLE>', l_objname);

EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_MR_GROUP';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE replace (q'[ CREATE TABLE <TABLE>  ( mr_group                    VARCHAR2(50)
                                                        , mr_group_description        VARCHAR2(500)
                                                        , CONSTRAINT pk_pemr PRIMARY KEY ( mr_group )
                                                        ) ]', '<TABLE>', l_objname);
EXCEPTION
WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname||' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_PARAMS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE>
                                        ( param_name            VARCHAR2(100)
                                        , param_value           VARCHAR2(2000)
                                        , param_description     VARCHAR2(2000)
                                        , CONSTRAINT pep_pk PRIMARY KEY (param_name) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_RUN_CONTEXTS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE>
                                        ( context_name          VARCHAR2(50)
                                        , context_description   VARCHAR2(2000)
                                        , CONSTRAINT perc_pk PRIMARY KEY (context_name) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_SUBSTITUTION_VALUES';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE>
                                        ( context_name          VARCHAR2(50)
                                        , substitution_key      VARCHAR2(50)
                                        , substitution_value    VARCHAR2(500)
                                        , CONSTRAINT pesv_pk PRIMARY KEY (context_name, substitution_key ) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'PRE_ETL_DOC_VALID_CONTEXTS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ create table <TABLE>
                                        ( document_name       VARCHAR2(50)
                                        , context_name        VARCHAR2(50)
                                        , CONSTRAINT pedvc_pk PRIMARY KEY (document_name, context_name ) )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/


REM ***************************************************************************************************************************************

DECLARE
   l_objname VARCHAR2(30) := 'GTT_TOUCH_MIGRATION_STATUS';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[ CREATE GLOBAL TEMPORARY TABLE <TABLE>
                                      ( rid         ROWID
                                      )]'
                            ,'<TABLE>'
                            ,l_objname);

EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/

REM ***************************************************************************************************************************************

DECLARE
  l_objname VARCHAR2(30) := 'AUD_GENERATOR_LOG';
BEGIN
   dbms_output.put_line ( 'Create :'||l_objname );
   EXECUTE IMMEDIATE REPLACE(q'[CREATE TABLE <TABLE>
                                        ( seq_no        NUMBER
                                        , owner         VARCHAR2(50)
                                        , table_name    VARCHAR2(50)
                                        , sql_text      CLOB
                                        , processed_ts  TIMESTAMP(6)
                                        , CONSTRAINT agl_pk PRIMARY KEY ( seq_no ) )]'
                            ,'<TABLE>'
                            ,l_objname);
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = -955
      THEN
         dbms_output.put_line(l_objname || ' already exists.');
      ELSE
         RAISE;
      END IF;
END;
/


REM ***************************************************************************************************************************************
REM ** Permissions granted to *_stg_etl_owner
REM ***************************************************************************************************************************************

DECLARE
   PROCEDURE pr_exec
   (
      i_command     IN VARCHAR2
     ,i_ignore_fail IN BOOLEAN DEFAULT FALSE
   ) IS
   BEGIN
      EXECUTE IMMEDIATE i_command;
   EXCEPTION
      WHEN OTHERS THEN
         IF NOT i_ignore_fail
         THEN
            dbms_output.put_line(i_command);
            dbms_output.put_line(SQLERRM);
         END IF;
         -- never fail - don't re-raise.
   END pr_exec;
BEGIN
   FOR i_buf IN (SELECT regexp_substr('&stg_types', '[^,]+', 1, rownum) AS prefix
                   FROM dual
                 CONNECT BY LEVEL <=
                            regexp_count('&stg_types', '[^,]+'))
   LOOP

      pr_exec(i_command => 'GRANT SELECT, REFERENCES ON pre_etl_db2_tables TO ' ||
                               i_buf.prefix || '_stg_etl_owner' );

      pr_exec(i_command => 'GRANT SELECT, REFERENCES ON pre_etl_db2_columns TO ' ||
                               i_buf.prefix || '_stg_etl_owner' );

   END LOOP;
END;
/

REM ***************************************************************************
REM **
REM ** Basic selection of migration groups...
REM **
REM ** The minimum required are INITIAL / INCREMENTAL / EXCEPTION
REM ** The rest are optional but useful for scratchpads etc...
REM **
REM ***************************************************************************

BEGIN
   INSERT INTO pre_etl_migration_groups values ( 'INITIAL',             'Initial',              'The Initial Migration .',1);
   INSERT INTO pre_etl_migration_groups values ( 'INCREMENTAL',         'Incremental',          'The Incremental Migration.',2);
   INSERT INTO pre_etl_migration_groups values ( 'INITIALISER',         'Initialiser',          'Initialise Objects',3);
   INSERT INTO pre_etl_migration_groups values ( 'GROUP ONE',           'Group One',            'Group One',4);
   INSERT INTO pre_etl_migration_groups values ( 'GROUP TWO',           'Group Two',            'Group Two',5);
   INSERT INTO pre_etl_migration_groups values ( 'GROUP THREE',         'Group Three',          'Group Three',6);
   INSERT INTO pre_etl_migration_groups values ( 'POST MIGRATION ONE',  'Post Migration One',   'Post Migration One',7);
   INSERT INTO pre_etl_migration_groups values ( 'POST MIGRATION TWO',  'Post Migration Two',   'Post Migration Two',8);
   INSERT INTO pre_etl_migration_groups values ( 'POST MIGRATION THREE','Post Migration Three', 'Post Migration Three',9);
   INSERT INTO pre_etl_migration_groups values ( 'EXCEPTION',           'Exception Handler',    'Exception Handler',10);
   --
   COMMIT;
END;
/

REM ***************************************************************************
REM **
REM ** Basic selection of params...
REM **
REM ***************************************************************************

BEGIN
   --
   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_EMAIL_RECIPIENTS_DEV'
      ,'me@myorg.com,them@myorg.com,others@myorg.com'
      ,'Comma seperated list of email addresses to get development emails.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_EMAIL_RECIPIENTS_MAN'
      ,'manager1@myorg.com,manager2@myorg.com,manager3@myorg.com'
      ,'Comma seperated list of email addresses to get management emails.');

   INSERT INTO on_etl_params
      (migration_group
      ,param_name
      ,param_value
      ,param_description)
   VALUES
      ('FX INITIAL'
      ,'MIG_STATUS_EMAIL_SENDER'
      ,'migration@myorg.com'
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

REM ***************************************************************************
REM **
REM ** Basic selection of Mapping Rules Groups.
REM **
REM ***************************************************************************

BEGIN
   INSERT INTO pre_etl_mr_group
      (mr_group
      ,mr_group_description)
   VALUES
      ('DEFAULT'
      ,'Default Group');

   INSERT INTO pre_etl_mr_group
      (mr_group
      ,mr_group_description)
   VALUES
      ('HISTORICAL'
      ,'Historical - For Mappings and Rules that are for almost identical mappings as DEFAULT but sourced from history tables');
   --
   COMMIT;
END;
/

REM ***************************************************************************
REM **
REM ** Basic Libraries for code snippets
REM **
REM ***************************************************************************

BEGIN
   INSERT INTO pre_etl_migration_libs
      (library_name
      ,library_desc)
   VALUES
      ('Code Library'
      ,'Library of code snippets.');
   COMMIT;
END;
/


REM ***************************************************************************
REM **
REM ** Basic selection of ETL tool params.
REM **
REM ***************************************************************************

BEGIN
   -- Definitely include PRE_ETL_OWNER...
   INSERT INTO pre_etl_params
   VALUES
      ('ACCESSIBLE_SCHEMAS'
      ,'PRE_ETL_OWNER;TARGET_SCHEMA1;TARGET_SCHEMA2;TARGET_SCHEMA3'
      ,'The schemas that the application will show pickable tables for (seperated by semi-colon.  For example in the create table document json.');

   -- If you want to know whats going on inside the migration...
   INSERT INTO pre_etl_params
   VALUES
      ('INTROSPECTION'
      ,'ON'
      ,'Valid values "ON" or "OFF"');
   --
   COMMIT;
END;
/

REM ***************************************************************************************************************************************
REM ** Setup the Run Contexts
REM ***************************************************************************************************************************************

DECLARE
   PROCEDURE pr_exec
   (
      i_command     IN VARCHAR2
     ,i_ignore_fail IN BOOLEAN DEFAULT FALSE
   ) IS
   BEGIN
      EXECUTE IMMEDIATE i_command;
   EXCEPTION
      WHEN OTHERS THEN
         IF NOT i_ignore_fail
         THEN
            dbms_output.put_line(i_command);
            dbms_output.put_line(SQLERRM);
         END IF;
         -- never fail - don't re-raise.
   END pr_exec;
BEGIN
   FOR i_buf IN (SELECT regexp_substr('&stg_types', '[^,]+', 1, rownum) AS prefix
                   FROM dual
                 CONNECT BY LEVEL <= regexp_count('&stg_types', '[^,]+'))
   LOOP

      pr_exec(i_command => 'INSERT INTO pre_etl_run_contexts (context_name,context_description) ' ||
                           'VALUES (''' || i_buf.prefix ||
                           ''',''Context (So using schemas ' ||
                           i_buf.prefix || '_...)'')');
   END LOOP;
   --
   COMMIT;
END;
/

REM ***************************************************************************

GRANT SELECT ON pre_etl_comments                TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_db2_columns             TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_db2_tables              TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_find_swap               TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_json_document           TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_json_lines              TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_mapped                  TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_detail        TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_groups        TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_header        TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_src           TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_src_inline_v  TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_mr_group                TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_params                  TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_related_json_lines      TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_run_contexts            TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_substitution_values     TO PRE_ETL_RO;
GRANT SELECT ON pre_etl_migration_run_hint      TO PRE_ETL_RO;

SET VERIFY ON

exit


