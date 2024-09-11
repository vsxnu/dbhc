param (
    [string]$fqdn
)

# Define the path for sql.ini file
$sqliniFile = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\tnsnames.ora"

# Define the path to the SQL file to be executed
$sqlFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\query.sql"

# Define Oracle credentials
$username = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.user.txt"
$password = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.pass.txt"

# Execute the SQL*Plus command
$env:ORACLE_HOME = "C:\oracle\product\19.0.0\client_1"
$env:PATH = "$env:ORACLE_HOME\bin;$env:PATH"
$env:TNS_ADMIN = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc"

sqlplus -S "$username/$password@$fqdn" "@$sqlFilePath"

# Read the output file
$outputFile = Get-ChildItem -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports" -Filter "report_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($outputFile) {
    $content = Get-Content -Path $outputFile.FullName -Raw
    $output = @"
Oracle Health Check Report for $fqdn
Date: $(Get-Date)
$content
"@
    # Write the output to the file expected by the Python script
    $output | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
} else {
    "No health check report found for $fqdn" | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}