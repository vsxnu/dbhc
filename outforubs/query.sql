SET SERVEROUTPUT ON
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 1000
SET PAGESIZE 0
SET LONG 10000000
SPOOL &1

DECLARE
    v_pdb_name VARCHAR2(30);
    v_host_name VARCHAR2(64);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME') INTO v_pdb_name FROM DUAL;
    SELECT HOST_NAME INTO v_host_name FROM V$INSTANCE;

    DBMS_OUTPUT.PUT_LINE('<!DOCTYPE html>');
    DBMS_OUTPUT.PUT_LINE('<html lang="en">');
    DBMS_OUTPUT.PUT_LINE('<head>');
    DBMS_OUTPUT.PUT_LINE('    <meta charset="UTF-8">');
    DBMS_OUTPUT.PUT_LINE('    <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    DBMS_OUTPUT.PUT_LINE('    <title>Oracle Health Check Report</title>');
    DBMS_OUTPUT.PUT_LINE('    <style>');
    DBMS_OUTPUT.PUT_LINE('        body { font-family: Arial, sans-serif; }');
    DBMS_OUTPUT.PUT_LINE('        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }');
    DBMS_OUTPUT.PUT_LINE('        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    DBMS_OUTPUT.PUT_LINE('        th { background-color: #f2f2f2; }');
    DBMS_OUTPUT.PUT_LINE('        tr:nth-child(even) { background-color: #f9f9f9; }');
    DBMS_OUTPUT.PUT_LINE('    </style>');
    DBMS_OUTPUT.PUT_LINE('</head>');
    DBMS_OUTPUT.PUT_LINE('<body>');
    DBMS_OUTPUT.PUT_LINE('    <h1>Oracle Health Check Report</h1>');
    DBMS_OUTPUT.PUT_LINE('    <p>Date: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || '</p>');
    DBMS_OUTPUT.PUT_LINE('    <p>PDB: ' || v_pdb_name || '</p>');
    DBMS_OUTPUT.PUT_LINE('    <p>Server: ' || v_host_name || '</p>');

    -- Basic Info
    DBMS_OUTPUT.PUT_LINE('    <h2>Basic Info</h2>');
    DBMS_OUTPUT.PUT_LINE('    <table>');
    DBMS_OUTPUT.PUT_LINE('        <tr><th>Attribute</th><th>Value</th></tr>');
    FOR r IN (
        SELECT 'Database Name' AS attr, name AS value FROM v$database
        UNION ALL
        SELECT 'PDB Name', NVL(SYS_CONTEXT('USERENV', 'CON_NAME'), 'NON-CDB') FROM DUAL
        UNION ALL
        SELECT 'Database Role', database_role FROM v$database
        UNION ALL
        SELECT 'Open Mode', open_mode FROM v$database
        UNION ALL
        SELECT 'Version', version FROM v$instance
        UNION ALL
        SELECT 'Host', HOST_NAME FROM v$instance
        UNION ALL
        SELECT 'DB Size (GB)', TO_CHAR(
            (SELECT SUM(bytes)/1024/1024/1024 FROM dba_data_files) +
            (SELECT NVL(SUM(bytes),0)/1024/1024/1024 FROM dba_temp_files) +
            (SELECT SUM(bytes*members)/1024/1024/1024 FROM v$log)
        ) FROM DUAL
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('        <tr><td>' || r.attr || '</td><td>' || r.value || '</td></tr>');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    </table>');

    -- Tablespaces Info
    DBMS_OUTPUT.PUT_LINE('    <h2>Tablespaces Info</h2>');
    DBMS_OUTPUT.PUT_LINE('    <table>');
    DBMS_OUTPUT.PUT_LINE('        <tr><th>Tablespace</th><th>Size (MB)</th><th>Free (MB)</th><th>% Free</th><th>% Used</th></tr>');
    FOR r IN (
        SELECT df.tablespace_name,
               ROUND(df.bytes / 1048576, 2) size_mb,
               ROUND(SUM(fs.bytes) / 1048576, 2) free_mb,
               ROUND(SUM(fs.bytes) * 100 / df.bytes, 2) pct_free,
               ROUND((df.bytes - SUM(fs.bytes)) * 100 / df.bytes, 2) pct_used
        FROM dba_free_space fs,
             (SELECT tablespace_name, SUM(bytes) bytes
              FROM dba_data_files
              GROUP BY tablespace_name) df
        WHERE fs.tablespace_name (+) = df.tablespace_name
        GROUP BY df.tablespace_name, df.bytes
        UNION ALL
        SELECT df.tablespace_name,
               ROUND(fs.bytes / 1048576, 2),
               ROUND(SUM(df.bytes_free) / 1048576, 2),
               ROUND((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes, 2),
               ROUND((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes, 2)
        FROM dba_temp_files fs,
             (SELECT tablespace_name, bytes_free, bytes_used
              FROM v$temp_space_header
              GROUP BY tablespace_name, bytes_free, bytes_used) df
        WHERE fs.tablespace_name (+) = df.tablespace_name
        GROUP BY df.tablespace_name, fs.bytes, df.bytes_free, df.bytes_used
        ORDER BY 4 DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('        <tr>');
        DBMS_OUTPUT.PUT_LINE('            <td>' || r.tablespace_name || '</td>');
        DBMS_OUTPUT.PUT_LINE('            <td>' || r.size_mb || '</td>');
        DBMS_OUTPUT.PUT_LINE('            <td>' || r.free_mb || '</td>');
        DBMS_OUTPUT.PUT_LINE('            <td>' || r.pct_free || '</td>');
        DBMS_OUTPUT.PUT_LINE('            <td>' || r.pct_used || '</td>');
        DBMS_OUTPUT.PUT_LINE('        </tr>');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    </table>');

    -- Services Info
    DBMS_OUTPUT.PUT_LINE('    <h2>Services Info</h2>');
    DBMS_OUTPUT.PUT_LINE('    <table>');
    DBMS_OUTPUT.PUT_LINE('        <tr><th>Name</th><th>CON_ID</th></tr>');
    FOR r IN (SELECT NAME, CON_ID FROM v$active_services ORDER BY 1) LOOP
        DBMS_OUTPUT.PUT_LINE('        <tr><td>' || r.NAME || '</td><td>' || r.CON_ID || '</td></tr>');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    </table>');

    DBMS_OUTPUT.PUT_LINE('</body>');
    DBMS_OUTPUT.PUT_LINE('</html>');
END;
/

SPOOL OFF
EXIT