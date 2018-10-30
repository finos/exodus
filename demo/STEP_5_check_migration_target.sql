SELECT t.empno
      ,rtrim(ltrim((SELECT json_query(t.payload
                                    ,'$' RETURNING VARCHAR2(32767)
                                     pretty)
                     FROM dual)
                  ,chr(10))
            ,chr(10)) AS json
      ,t.payload_hash
  FROM target_scott_tiger.employee t
/