# Introduction
This document explains the structure and flow design process of Oracle Healthcheck.
The tool extract information from the Oracle databases on hostnames given by the user.

# Directory Structure:

1. orahc - contains orahc powershell script, tnsnames.ora, SQL query file, hostnames.
2. reports (inside orahc) - contains reports per DB as well as the merged report.

```
└───orahc
    ├───orahc powershell script
    ├───tnsnames.ora
    ├───hostnames.txt
    ├───reports
        ├───merged_report.html
        ├───report_*.html
```

# Process:
1. host list (fully qualified names or not) should be put in the `hostnames.txt`
2. `tnsnames.ora` should be up-to-date.
3. run `orahc` powershell that will do the following:
    * list all the TNS entries that is associated with hosts in the list and generate `sqlplus` commands to connect to the databases and run an SQL script.
    * extract information in the databases and put in an HTML report.
    * merged the HTML files into one consolidated report.

