set pagesize 0
set linesize 1000
set feedback off
set verify off
set heading on
set markup csv on delimiter '|' quote off

-- Displays the basic info of the DB
select 
    (select name from v$database) "DBName",
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
SELECT df.tablespace_name "Tablespace",
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
SELECT df.tablespace_name tspace,
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
SELECT NAME, CON_ID FROM v$active_services ORDER BY 1;

exit