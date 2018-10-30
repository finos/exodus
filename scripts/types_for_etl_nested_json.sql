REM ** DEBUG THESE STEPS BY turning ON the OUTPUTs **********************************************
set serveroutput on verify off
set termout on

REM *********************************************************************************************
REM **
REM ** User created types to satisfy the migration.
REM **
REM ** AS PRE_ETL_OWNER
REM **
REM *********************************************************************************************

REM *-------------------------------------------------------------------------------------------*
REM *
REM * NOTE : qtd_ at the beginning of the attributes indicates that the JSON created as a result
REM *        will be surrounded with QUOTES.
REM *        IF YOU DO NOT DO THIS THEN THE MIGRATION TOOL WILL CHOOSE HOW TO HANDLE THE VALUE
REM *        AUTOMATICALLY - if its obviously Alpha then it will surround with quotes, but
REM *        if its a purely numeric value it will not... sometimes you want numeric values
REM *        to be surrounded by quotes.  qtd_ will force that behaviour.
REM *        To be fair this is a bit of a (how shall we say..?) kludge?
REM *
REM *-------------------------------------------------------------------------------------------*

DECLARE
   ex_obj_not_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT(ex_obj_not_exist, -4043);
BEGIN
   EXECUTE IMMEDIATE 'drop type t_reg_identifier_tab';
EXCEPTION
   WHEN ex_obj_not_exist THEN
      NULL;
END;
/

DECLARE
   ex_obj_not_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT(ex_obj_not_exist, -4043);
BEGIN
   EXECUTE IMMEDIATE 'drop type t_reg_identifier';
EXCEPTION
   WHEN ex_obj_not_exist THEN
      NULL;
END;
/

CREATE TYPE t_reg_identifier AS OBJECT
(
   qtd_etl_ihsmarkit_prefix          VARCHAR2(50),
   qtd_etl_ihsmarkit_reg_trade_id    VARCHAR(300),
   qtd_etl_ihsmarkit_ident_type      VARCHAR2(20)
)
/

CREATE TYPE t_reg_identifier_tab IS TABLE OF t_reg_identifier
/

set serveroutput off verify on

exit
