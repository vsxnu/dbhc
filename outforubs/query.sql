set termout off
set linesize 1000
set pagesize 50000
set feedback off
set verify off
set heading on
set markup csv on delimiter '|' quote off

-- Variable to hold the PDB name and host name
COLUMN pdb_name NEW_VALUE pdb_name_var
COLUMN host_name NEW_VALUE host_name_var

-- Retrieve the PDB name
SELECT sys_context('USERENV', 'CON_NAME') AS pdb_name FROM dual;

-- Retrieve the host name
SELECT HOST_NAME AS host_name FROM V$INSTANCE;

-- Constructing the file name
COLUMN spool_file_name NEW_VALUE spool_file_name_var
SELECT 'C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports\report_' || sys_context('USERENV', 'CON_NAME') || '.txt' AS spool_file_name FROM dual;

-- Spool to the constructed file name
SPOOL &spool_file_name_var

-- Display the PDB name in the center of the report
PROMPT Report for &pdb_name_var
PROMPT Server: &host_name_var

-- Displays the basic info of the DB
PROMPT Basic Info:
SELECT 'DBName' AS Metric, name AS Value FROM v$database
UNION ALL
SELECT 'PDB_NAME', nvl(sys_Context('userenv', 'con_Name'), 'NON-CDB') FROM dual
UNION ALL
SELECT 'DBRole', database_role FROM v$database
UNION ALL
SELECT 'Open Mode', open_mode FROM v$database
UNION ALL
SELECT 'Version', version FROM v$instance
UNION ALL
SELECT 'Host', HOST_NAME FROM v$instance
UNION ALL
SELECT 'DB Size (GB)', TO_CHAR(
  (SELECT ROUND(SUM(bytes/1073741824),2) FROM dba_data_files) +
  (SELECT ROUND(NVL(SUM(bytes/1073741824),0),2) FROM dba_temp_files) +
  (SELECT ROUND(SUM(bytes/1073741824)*MAX(members),2) FROM v$log)
) FROM dual;

-- Displays the tablespace information
PROMPT Tablespace Info:
SELECT 
    df.tablespace_name "Tablespace",
    ROUND(df.bytes / (1024 * 1024), 2) "Size (MB)",
    ROUND(SUM(fs.bytes) / (1024 * 1024), 2) "Free (MB)",
    ROUND(NVL(ROUND(SUM(fs.bytes) * 100 / df.bytes), 0), 2) "% Free",
    ROUND((df.bytes - SUM(fs.bytes)) * 100 / df.bytes, 2) "% Used"
FROM 
    dba_free_space fs,
    (SELECT tablespace_name, SUM(bytes) bytes
     FROM dba_data_files
     GROUP BY tablespace_name) df
WHERE 
    fs.tablespace_name (+) = df.tablespace_name
GROUP BY 
    df.tablespace_name, df.bytes
UNION ALL
SELECT 
    df.tablespace_name,
    ROUND(fs.bytes / (1024 * 1024), 2),
    ROUND(SUM(df.bytes_free) / (1024 * 1024), 2),
    ROUND(NVL((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes, 0), 2),
    ROUND((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes, 2)
FROM 
    dba_temp_files fs,
    (SELECT tablespace_name, bytes_free, bytes_used
     FROM v$temp_space_header
     GROUP BY tablespace_name, bytes_free, bytes_used) df
WHERE 
    fs.tablespace_name (+) = df.tablespace_name
GROUP BY 
    df.tablespace_name, fs.bytes, df.bytes_free, df.bytes_used
ORDER BY 5 DESC;

-- Displays the services information
PROMPT Services Info:
SELECT NAME, CON_ID FROM v$active_services ORDER BY 1;

SPOOL OFF
exit