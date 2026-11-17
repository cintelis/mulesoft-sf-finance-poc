-- Read by the dashboard's Data model page. Describes the FINANCE schema as JSON:
-- one line of tables and columns, one of key constraints, one of row counts.
-- Read-only: it queries the data dictionary and counts rows.
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 32767 LONG 2000000 LONGCHUNKSIZE 32767 TRIMSPOOL ON

SELECT JSON_ARRAYAGG(
         JSON_OBJECT(
           'table' VALUE t.table_name,
           'columns' VALUE (
             SELECT JSON_ARRAYAGG(
                      JSON_OBJECT(
                        'name' VALUE c.column_name,
                        'type' VALUE c.data_type ||
                          CASE
                            WHEN c.data_type IN ('VARCHAR2', 'CHAR') THEN '(' || c.char_length || ')'
                            WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL
                              THEN '(' || c.data_precision || ',' || c.data_scale || ')'
                          END,
                        'nullable' VALUE c.nullable,
                        'virtual' VALUE c.virtual_column
                      ) ORDER BY c.column_id RETURNING CLOB)
               FROM user_tab_cols c
              WHERE c.table_name = t.table_name AND c.hidden_column = 'NO'
           ) FORMAT JSON
         ) ORDER BY t.table_name RETURNING CLOB)
  FROM user_tables t;

SELECT JSON_ARRAYAGG(
         JSON_OBJECT(
           'table' VALUE cc.table_name,
           'column' VALUE cc.column_name,
           'kind' VALUE c.constraint_type,
           'references' VALUE r.table_name
         ) RETURNING CLOB)
  FROM user_constraints c
  JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
  LEFT JOIN user_constraints r ON r.constraint_name = c.r_constraint_name
 WHERE c.constraint_type IN ('P', 'U', 'R');

SELECT JSON_OBJECT(
         'CUSTOMERS' VALUE (SELECT COUNT(*) FROM customers),
         'INVOICES' VALUE (SELECT COUNT(*) FROM invoices),
         'PAYMENTS' VALUE (SELECT COUNT(*) FROM payments),
         'SYNC_WATERMARK' VALUE (SELECT COUNT(*) FROM sync_watermark),
         'INTEGRATION_ERRORS' VALUE (SELECT COUNT(*) FROM integration_errors)
       )
  FROM dual;

EXIT
