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

# Find the matching TNS entry
$matchingEntry = $tnsContent | Select-String -Pattern $fqdn -Context 0,10 | ForEach-Object {
    $_.Context.PostContext -join "`n"
} | Select-String -Pattern '^\s*\S+\s*=' -Raw

if ($matchingEntry) {
    $tnsAlias = ($matchingEntry -split '=')[0].Trim()
    
    # Execute SQL*Plus command
    $sqlplusOutput = sqlplus -S "$username/$password@$tnsAlias" "@$sqlFilePath"
    
    # Process the output
    $formattedOutput = $sqlplusOutput | ForEach-Object {
        $_ -replace '^\s*|\s*$' -replace '\|', ' | '
    } | Where-Object { $_ -match '\S' }
    
    $report = @"
Oracle Health Check Report for $fqdn
Date: $(Get-Date)

$($formattedOutput -join "`n")
"@
    
    # Write the report to the output file
    $report | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}
else {
    "No matching TNS entry found for $fqdn" | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}