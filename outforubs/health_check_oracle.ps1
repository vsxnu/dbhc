# health_check_oracle.ps1

param (
    [string[]]$fqdnList
)

# Define the path to the tnsnames.ora file
$tnsnamesPath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\tnsnames.ora"

# Define the path to the SQL file to be executed
$sqlFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\query.sql"

# Define Oracle credentials
$username = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.user.txt"
$password = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.pass.txt"

# Read the content of the tnsnames.ora file
$tnsContent = Get-Content -Path $tnsnamesPath

# Timeout in seconds
$timeout = 30

# Initialize a variable to store the final output
$finalOutput = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Oracle Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .server-report { margin-bottom: 40px; border: 1px solid #ddd; padding: 20px; }
        h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Oracle Health Check Report</h1>
    <p>Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
"@

foreach ($fqdn in $fqdnList) {
    # Initialize an array to store matching TNS entries
    $matchingEntries = @()

    # Use regex to match both fully qualified and non-fully qualified hostnames
    $regexPattern = [regex]::Escape($fqdn).Replace("\.", "\.?").Replace("example.com", "")
    $regexPattern = "($regexPattern)(\..*?)?"

    # Find lines in tnsnames.ora that match the hostname pattern
    $matches = $tnsContent | Select-String -Pattern $regexPattern -Context 0,10

    # Add matching entries to the array
    foreach ($match in $matches) {
        # Extract lines starting from "world="
        $entryStartIndex = ($match.Context.PreContext + $match.Line + $match.Context.PostContext) -split "`n" | Select-String -Pattern "world\s*=" | Select-Object -First 1 | ForEach-Object { $_.LineNumber - 1 }
        if ($null -ne $entryStartIndex) {
            $entryLines = ($match.Context.PreContext + $match.Line + $match.Context.PostContext) -split "`n"
            $entry = $entryLines[$entryStartIndex]
            # Extract everything after the first equal sign after "world"
            $entry = $entry.Substring($entry.IndexOf('=') + 1).Trim()
            # Enclose the entry in double quotes
            $matchingEntries += "`"$entry`""
        }
    }

    $finalOutput += "<div class='server-report'>"
    $finalOutput += "<h2>Server: $fqdn</h2>"

    # Output the matching TNS entries and create sqlplus commands
    if ($matchingEntries.Count -gt 0) {
        foreach ($entry in $matchingEntries) {
            # Extract database name from SERVICE_NAME
            if ($entry -match 'SERVICE_NAME=([^\.]+)') {
                $dbName = $matches[1]
            } else {
                $dbName = "UnknownDB"
            }
            if ($entry -match 'HOST=([^\)]+)') {
                $hostName = $matches[1]
            } else {
                $hostName = "UnknownHost"
            }
            
            Write-Output "Connecting to : $dbName on $hostName"
            
            try {
                $tempFile = [System.IO.Path]::GetTempFileName()
                $process = Start-Process -FilePath "sqlplus" -ArgumentList "$username/$password@$entry @$sqlFilePath $tempFile" -PassThru -NoNewWindow -RedirectStandardOutput "NUL"
                
                # Wait for the process to exit or timeout
                $processExited = $process.WaitForExit($timeout * 1000)
                if ($processExited) {
                    Write-Host "Script executed successfully on database: $dbName"
                    $outputContent = Get-Content -Path $tempFile -Raw
                    $finalOutput += $outputContent
                } else {
                    Write-Host "Execution exceeded timeout of $timeout seconds on database: $dbName. Terminating process."
                    $process | Stop-Process
                    $finalOutput += @"
    <h3>Database: $dbName</h3>
    <p>Host: $hostName</p>
    <p style="color: red;">Error: Execution exceeded timeout of $timeout seconds.</p>
"@
                }
                Remove-Item -Path $tempFile -Force
            } catch {
                Write-Host "Error running SQL*Plus command for database: $dbName"
                $finalOutput += @"
    <h3>Database: $dbName</h3>
    <p>Host: $hostName</p>
    <p style="color: red;">Error: Failed to execute SQL*Plus command.</p>
"@
            }
        }
    } else {
        Write-Output "No matching TNS entries found for $fqdn."
        $finalOutput += "<p>No matching TNS entries found for this server.</p>"
    }

    $finalOutput += "</div>"
}

$finalOutput += @"
</body>
</html>
"@

# Write the output to the file expected by the Python script
$finalOutput | Out-File -FilePath "..\backend\output.html" -Encoding utf8