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

    # Combine the output into a single string
    $output = @"
OracleServer: $fqdn
OracleHostname: $hostname
Date: $date
Current Directory: $pwd
"@

    # Return the output
    return $output
}

# Execute the script block and append the output to a file
& $scriptBlock -fqdn $fqdn | Add-Content -Path "../backend/output.txt"
