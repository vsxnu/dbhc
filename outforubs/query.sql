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