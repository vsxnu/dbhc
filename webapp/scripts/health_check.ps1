# Placeholder for PowerShell script to run health check
# For testing, create an output.txt file with some content
# Define the script block
$scriptBlock = {
    # Get the hostname
    $hostname = hostname

    # Get the current date and time
    $date = Get-Date

    # Get the current working directory
    $pwd = Get-Location

    # Combine the output into a single string
    $output = @"
Hostname: $hostname
Date: $date
Current Directory: $pwd
"@

    # Return the output
    return $output
}

# Execute the script block and write the output to a file
& $scriptBlock | Out-File -FilePath "../backend/output.txt"
