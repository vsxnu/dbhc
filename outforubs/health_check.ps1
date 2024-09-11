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

    # Process the output to create an HTML table
    $lines = $sqlOutput -split "`n"
    $header = $lines[0] -split "\s{2,}"
    
    $htmlOutput = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MSSQL Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>MSSQL Health Check Report</h1>
    <p>Date: $date</p>
    <p>Server: $fqdn</p>
    <table>
        <tr>
"@

    # Add table headers
    foreach ($column in $header) {
        $htmlOutput += "            <th>$column</th>`n"
    }

    $htmlOutput += "        </tr>`n"

    # Add table rows
    for ($i = 1; $i -lt $lines.Length; $i++) {
        $columns = $lines[$i] -split "\s{2,}"
        $htmlOutput += "        <tr>`n"
        foreach ($column in $columns) {
            $htmlOutput += "            <td>$column</td>`n"
        }
        $htmlOutput += "        </tr>`n"
    }

    $htmlOutput += @"
    </table>
</body>
</html>
"@
    
    # Return the HTML output
    return $htmlOutput
}

# Execute the script block and write the output to a file
& $scriptBlock -fqdn $fqdn | Out-File -FilePath "..\backend\output.html" -Encoding utf8