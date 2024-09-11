set termout off
SET FEED OFF
set pagesize 0
-- Variable to hold the PDB name and host name
COLUMN pdb_name NEW_VALUE pdb_name_var
COLUMN host_name NEW_VALUE host_name_var

-- Retrieve the PDB name
SELECT sys_context('USERENV', 'CON_NAME') AS pdb_name FROM dual;

-- Retrieve the host name
SELECT HOST_NAME AS host_name FROM V$INSTANCE;

-- Constructing the file name
COLUMN spool_file_name NEW_VALUE spool_file_name_var
SELECT 'P:\hackathon\orahc\reports\report_' || sys_context('USERENV', 'CON_NAME') || '.txt' AS spool_file_name FROM dual;

-- Spool to the constructed file name
SPOOL &spool_file_name_var

PROMPT Report for &pdb_name_var
PROMPT Server &host_name_var

-- Displays the basic info of the DB
PROMPT
PROMPT ==================
PROMPT     Basic Info
PROMPT ==================

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
PROMPT
PROMPT ========================
PROMPT    Tablespaces Info
PROMPT ========================

set pages 1000
SELECT /* + RULE */  
       RPAD(df.tablespace_name, 30) "Tablespace",
       LPAD(TO_CHAR(df.bytes / (1024 * 1024), '999,999.99'), 15) "Size (Mb)",
       LPAD(TO_CHAR(SUM(fs.bytes) / (1024 * 1024), '999,999.99'), 15) "Free (Mb)",
       LPAD(TO_CHAR(Nvl(Round(SUM(fs.bytes) * 100 / df.bytes),1), '999.99'), 10) "% Free",
       LPAD(TO_CHAR(Round((df.bytes - SUM(fs.bytes)) * 100 / df.bytes), '999.99'), 10) "% Used"
  FROM dba_free_space fs,
       (SELECT tablespace_name,SUM(bytes) bytes
          FROM dba_data_files
         GROUP BY tablespace_name) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,df.bytes
UNION ALL
SELECT /* + RULE */ 
       RPAD(df.tablespace_name, 30),
       LPAD(TO_CHAR(fs.bytes / (1024 * 1024), '999,999.99'), 15),
       LPAD(TO_CHAR(SUM(df.bytes_free) / (1024 * 1024), '999,999.99'), 15),
       LPAD(TO_CHAR(Nvl(Round((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1), '999.99'), 10),
       LPAD(TO_CHAR(Round((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes), '999.99'), 10)
  FROM dba_temp_files fs,
       (SELECT tablespace_name,bytes_free,bytes_used
          FROM v$temp_space_header
         GROUP BY tablespace_name,bytes_free,bytes_used) df
 WHERE fs.tablespace_name (+)  = df.tablespace_name
 GROUP BY df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
 ORDER BY 4 DESC;

-- Displays the services information
PROMPT
PROMPT =====================
PROMPT    Services Info
PROMPT =====================

col NAME format a30
col CON_ID format 999999
SELECT NAME, CON_ID FROM v$active_services ORDER BY 1;

SPOOL OFF
exit