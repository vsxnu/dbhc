# Placeholder for PowerShell script to run health check
# For testing, create an output.txt file with some content

# Define the script block
param (
    [string]$fqdn
)

$scriptBlock = {
    param (
        [string]$fqdn
    )
    
    # Get the hostname
    $hostname = hostname
    
    # Get the current date and time
    $date = Get-Date
    
    # Get the current working directory
    $pwd = Get-Location
    
    # Commented out SQLCMD section
    <#
    # RUN SQLCMD 
    $sqlOutput = sqlcmd -S $fqdn -Q "EXEC DBServices..usp_healthchk" -s "   " -W -h-1 -w 200
    
    # Convert the SQL output to a table format
    $sqlOutputLines = $sqlOutput | Out-String | ConvertFrom-Csv
    #>

    # Instead of SQL output, we'll create a simple report
    $report = @"
Hostname: $hostname
FQDN: $fqdn
Date: $date
Current Directory: $pwd

This is a simulated health check report.
No actual database queries were performed.
"@

    # Combine the output into a single string
    $output = @"
Date: ${date}
Simulated Health Check Report for ${fqdn}:
$report
"@
    
    # Return the output
    return $output
}

# Execute the script block and append the output to a file
& $scriptBlock -fqdn $fqdn | Add-Content -Path "../backend/output.txt"
# At the end of the script
$output | Out-File -FilePath $output_file_path -Encoding utf8
Write-Host "Output written to: $output_file_path"