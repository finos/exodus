CREATE TABLE EMPLOYEE(
   empno        INTEGER NOT NULL,
   payload      CLOB,
   payload_hash RAW(16)
);

create sequence seq_empno start with 1 increment by 1;

exit
