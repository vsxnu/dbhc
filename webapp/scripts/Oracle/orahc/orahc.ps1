# Define the path to the tnsnames.ora file
$tnsnamesPath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\tnsnames.ora"

# Define the path to the text file containing the list of hostnames
$hostnamesFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\hostnames.txt"

# Define the path to the SQL file to be executed
$sqlFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\query.sql"

# Define Oracle credentials
$username = cat C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.user.txt
$password = cat C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.pass.txt

# Read the list of hostnames from the text file
$hostnames = Get-Content -Path $hostnamesFilePath

# Read the content of the tnsnames.ora file
$tnsContent = Get-Content -Path $tnsnamesPath

# Timeout in seconds
$timeout = 10

# Define the path for the HTML and merged output file
$mergedHTMLOutputFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports\*report*.html"

# Deleting the HTML reports before every run
Write-Output "Deleting past reports."
Remove-Item -Path $mergedHTMLOutputFilePath -ErrorAction SilentlyContinue

# Directory to save HTML error reports
$errorReportDir = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports"

# Ensure the error report directory exists
if (-not (Test-Path -Path $errorReportDir)) {
    New-Item -ItemType Directory -Path $errorReportDir
}

# Initialize an array to store matching TNS entries
$matchingEntries = @()

# Loop through each hostname and search for matching TNS entries
foreach ($hostname in $hostnames) {
    # Use regex to match both fully qualified and non-fully qualified hostnames
    $regexPattern = [regex]::Escape($hostname) + "(\.[a-zA-Z0-9\-]+)*"
    
    # Find lines in tnsnames.ora that match the hostname pattern
    $matches = $tnsContent | Select-String -Pattern $regexPattern -Context 0,10
    
    # Add matching entries to the array
    foreach ($match in $matches) {
        # Extract lines starting from "world="
        $entryStartIndex = ($match.Context.PreContext + $match.Line + $match.Context.PostContext) -split "`n" | Select-String -Pattern "world\s*=" | Select-Object -First 1 | ForEach-Object { $_.LineNumber - 1 }
        if ($entryStartIndex -ne $null) {
            $entryLines = ($match.Context.PreContext + $match.Line + $match.Context.PostContext) -split "`n"
            $entry = $entryLines[$entryStartIndex]
            # Extract everything after the first equal sign after "world"
            $entry = $entry.Substring($entry.IndexOf('=') + 1).Trim()
            # Enclose the entry in double quotes
            $matchingEntries += "`"$entry`""
        }
    }
}

# Output the matching TNS entries and create sqlplus commands
if ($matchingEntries.Count -gt 0) {
    #Write-Output "Matching TNS Entries:"
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

        #Write-Output "Connect String: $entry"
        $sqlplusCommand = "sqlplus -S $username/$password@$entry @$sqlFilePath"
        #Write-Output "SQL*Plus Command: $sqlplusCommand"
        Write-Output "Connecting to : $dbName on $hostName"
        
        # Execute the SQL*Plus command stored in sqlplusCommand variable
#        Invoke-Expression $sqlplusCommand
        $process = Start-Process -FilePath "sqlplus" -ArgumentList "$username/$password@$entry @$sqlFilePath" -PassThru -NoNewWindow
            
        # Wait for the process to exit or timeout
        $processExited = $process.WaitForExit($timeout * 1000)




        if ($processExited) {
            Write-Host "Script executed successfully on database: $dbName"
        } else {
            Write-Host "Execution exceeded timeout of $timeout seconds on database: $dbName. Terminating process."
            $process | Stop-Process


        # Generate HTML error report
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Error Report</title>
<!--     <style>
       body { font-family: Arial, sans-serif; text-align: center;
        .error { color: red; }
    </style> -->
</head>
<body>
    <h1><center>Report for $dbName on $hostName</center></h1>
    <p class="error"><center>Error connecting to ORA-database.</center></p>
    <p class="error"><center>Execution exceeded timeout of $timeout seconds.</center></p>
</body>
</html>
"@

        # Save HTML content to file
        $htmlFilePath = Join-Path -Path $errorReportDir -ChildPath "report_$dbName.html"
        $htmlContent | Out-File -FilePath $htmlFilePath -Encoding UTF8

        Write-Host "Error report generated: $htmlFilePath"
    }
    }
} else {
    Write-Output "No matching TNS entries found."
}

# Define the directory containing the HTML files
$directoryPath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports"

# Define the path for the merged output file
$mergedOutputFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports\merged_report.html"

# Initialize or clear the merged output file
Clear-Content -Path $mergedOutputFilePath -ErrorAction SilentlyContinue
New-Item -Path $mergedOutputFilePath -ItemType File -Force | Out-Null

# Start the merged HTML file with basic HTML structure
Add-Content -Path $mergedOutputFilePath -Value "<html><body>"

# Get all HTML files in the directory that start with "report_"
$htmlFiles = Get-ChildItem -Path $directoryPath -Filter report_*.html

# Loop through each HTML file
foreach ($file in $htmlFiles) {
    # Read the content of the file
    $content = Get-Content -Path $file.FullName -Raw

    # Check for keywords "ERROR" and "ORA-"
    if ($content -match "ERROR" -and $content -match "ORA-") {
        $message = '<p><b><span style="color:red;">DB Status: RED</span></b></p>'
    } else {
        $message = '<p><b><span style="color:green;">DB Status: GREEN</span></b></p>'
    }

    # Append the message to the HTML content
    $content += $message

    # Write the updated content back to the file
    Set-Content -Path $file.FullName -Value $content

    # Append the updated content to the merged output file
    Add-Content -Path $mergedOutputFilePath -Value "<div>"
    Add-Content -Path $mergedOutputFilePath -Value $content
    Add-Content -Path $mergedOutputFilePath -Value "</div><hr>"

    # Sleep for 1 second
    Start-Sleep -Seconds 1
}

# Close the HTML structure in the merged output file
Add-Content -Path $mergedOutputFilePath -Value "</body></html>"

# Display a message indicating that the merge is complete
Write-Output "All reports have been merged into $mergedOutputFilePath"