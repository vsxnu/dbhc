# health_check.ps1

param (
    [string]$fqdn
)

$scriptBlock = {
    param (
        [string]$fqdn
    )
    
    # Get the current date and time
    $date = Get-Date
    
    # RUN SQLCMD with increased column width
    $sqlOutput = sqlcmd -S $fqdn -Q "EXEC DBServices..usp_healthchk" -W -h-1 -w 1000

    $htmlOutput = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MSSQL Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        pre { background-color: #f4f4f4; padding: 10px; border-radius: 5px; white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <h1>MSSQL Health Check Report</h1>
    <p>Date: $date</p>
    <p>Server: $fqdn</p>
    <pre>$sqlOutput</pre>
</body>
</html>
"@
    
    # Return the HTML output
    return $htmlOutput
}

# Execute the script block and write the output to a file
& $scriptBlock -fqdn $fqdn | Out-File -FilePath "..\backend\output.html" -Encoding utf8