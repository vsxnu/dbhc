# health_check_oracle.ps1

param (
    [string]$fqdn
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
$timeout = 10

# Initialize an array to store matching TNS entries
$matchingEntries = @()

# Use regex to match both fully qualified and non-fully qualified hostnames
$regexPattern = [regex]::Escape($fqdn) + "(\.[a-zA-Z0-9\-]+)*"

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

# Initialize a variable to store the final output
$finalOutput = @()

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
            $process = Start-Process -FilePath "sqlplus" -ArgumentList "$username/$password@$entry @$sqlFilePath" -PassThru -NoNewWindow
            
            # Wait for the process to exit or timeout
            $processExited = $process.WaitForExit($timeout * 1000)
            if ($processExited) {
                Write-Host "Script executed successfully on database: $dbName"
                $outputContent = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\reports\report_$dbName.txt" -Raw
                $finalOutput += @"
=============================================
Database: $dbName
Host: $hostName
Status: Success
=============================================
$outputContent
"@
            } else {
                Write-Host "Execution exceeded timeout of $timeout seconds on database: $dbName. Terminating process."
                $process | Stop-Process
                $finalOutput += @"
=============================================
Database: $dbName
Host: $hostName
Status: Timeout
Error: Execution exceeded timeout of $timeout seconds.
=============================================
"@
            }
        } catch {
            Write-Host "Error running SQL*Plus command for database: $dbName"
            $finalOutput += @"
=============================================
Database: $dbName
Host: $hostName
Status: Error
Error: Failed to execute SQL*Plus command.
=============================================
"@
        }
    }
} else {
    Write-Output "No matching TNS entries found for $fqdn."
    $finalOutput += "No matching TNS entries found for $fqdn."
}

# Combine the output into a single string
$output = @"
Date: $(Get-Date)
Oracle HC Report for ${fqdn}:
$($finalOutput -join "`n`n")
"@

# Write the output to the file expected by the Python script
$output | Out-File -FilePath "..\backend\output.txt" -Encoding utf8