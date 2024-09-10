set termout off
-- Variable to hold the PDB name and host name
COLUMN pdb_name NEW_VALUE pdb_name_var
COLUMN host_name NEW_VALUE host_name_var

-- Retrieve the PDB name
SELECT sys_context('USERENV', 'CON_NAME') AS pdb_name FROM dual;

-- Retrieve the host name
--SELECT sys_context('USERENV', 'HOST') AS host_name FROM dual;
SELECT HOST_NAME AS host_name FROM V$INSTANCE;

-- Constructing the file name
COLUMN spool_file_name NEW_VALUE spool_file_name_var
SELECT 'C:\UBS\Dev\dbhc\webapp\backend\Oracle\orahc\reports\report_' || sys_context('USERENV', 'CON_NAME') || '.html' AS spool_file_name FROM dual;
--SELECT 'report_' || sys_context('USERENV', 'CON_NAME') || '.html' AS spool_file_name FROM dual;

-- Spool to the constructed file name
SPOOL &spool_file_name_var
set markup html on spool on entmap off -
HEAD "<TITLE>Database Healthcheck Report</TITLE> -
<STYLE type='text/css'> -
  table { background: #eee; font-size: 90%; } -
  th { background: #ccc; } -
  td { padding: 0px; } -
</STYLE>" -
body 'text=black bgcolor=fffffff align=left' -
table 'align=center width=99% border=3 bordercolor=black bgcolor=white'
-- Display the PDB name in the center of the report
PROMPT <h1 style="text-align: center;">Report for &pdb_name_var</h1>
PROMPT <h2 style="text-align: center;">Server &host_name_var</h2>
--PROMPT <h2 style="text-align: center;">Host: &pdb_name_var</h2>

-- Displays the basic info of the DB
prompt <h2>Basic Info</h2>
set underline "="
set linesize 180
col Database_Name for a20
col "PDB_NAME" for a12
col Database_Role for a15
col Block_size for a10
col DBCharset for a16
col NCharset for a10
col Environment for a12
col "RAC/Single" for a12
col "No. of Standbys" for a16
col "Type of Environment" for a20
set pages 999
col tablespace_name for a30
col "%Used" for a7
col "Free(Gb)" for 999999.999
col "Total(Gb)" for 999999.999
col status for a10
col contents for a10
col "Ext_Mgmt" for a10
col "Aloc_Typ" for a7
col "PDB_NAME" for a10
select (select name from v$database) "DBName",
(SELECT nvl(sys_Context('userenv', 'con_Name'), 'NON-CDB') from dual) "PDB_NAME",
(select database_role from v$database) "DBRole",
(select open_mode from v$database) "Open Mode",
(select version from v$instance) "Version",
(select HOST_NAME from v$instance) "Host",
(select round(sum(bytes/1073741824),0) from dba_data_files) +
(select round(NVL(sum(bytes/1073741824),0),0) from dba_temp_files) +
(select round(sum(bytes/1073741824)*max(members),0) from v$log) "DB Size"
from dual;
-- Displays the tablespace information
prompt <h2>Tablespaces Info</h2>
set pages 1000
SELECT /* + RULE */  df.tablespace_name "Tablespace",
       df.bytes / (1024 * 1024) "Size (Mb)",
       SUM(fs.bytes) / (1024 * 1024) "Free (Mb)",
       Nvl(Round(SUM(fs.bytes) * 100 / df.bytes),1) "% Free",
       Round((df.bytes - SUM(fs.bytes)) * 100 / df.bytes) "% Used"
  FROM dba_free_space fs,
       (SELECT tablespace_name,SUM(bytes) bytes
          FROM dba_data_files
         GROUP BY tablespace_name) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,df.bytes
UNION ALL
SELECT /* + RULE */ df.tablespace_name tspace,
       fs.bytes / (1024 * 1024),
       SUM(df.bytes_free) / (1024 * 1024),
       Nvl(Round((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1),
       Round((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes)
  FROM dba_temp_files fs,
       (SELECT tablespace_name,bytes_free,bytes_used
          FROM v$temp_space_header
         GROUP BY tablespace_name,bytes_free,bytes_used) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
 ORDER BY 4 DESC;
-- Displays the services information
prompt <h2>Services Info</h2>
SELECT NAME, CON_ID FROM v$active_services ORDER BY 1;
SPOOL OFF
-- Clear all variables
UNDEFINE pdb_name_var
UNDEFINE host_name_var
UNDEFINE spool_file_name_var
exit