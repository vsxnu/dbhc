# health_check.ps1

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
    
    # RUN SQLCMD with increased column width
    $sqlOutput = sqlcmd -S $fqdn -Q "EXEC DBServices..usp_healthchk" -W -h-1 -w 1000

    # Process the output to create a formatted table
    $lines = $sqlOutput -split "`n"
    $header = $lines[0] -split "\s{2,}"
    $columnWidths = @{}
    
    # Calculate column widths
    foreach ($line in $lines) {
        $columns = $line -split "\s{2,}"
        for ($i = 0; $i -lt $columns.Length; $i++) {
            $width = $columns[$i].Length
            if (-not $columnWidths.ContainsKey($i) -or $width -gt $columnWidths[$i]) {
                $columnWidths[$i] = $width
            }
        }
    }

    # Format the table
    $formattedOutput = @()
    $formattedOutput += $header | ForEach-Object { $_.PadRight($columnWidths[$header.IndexOf($_)]) } | Join-String -Separator " | "
    $formattedOutput += "-" * $formattedOutput[0].Length

    for ($i = 1; $i -lt $lines.Length; $i++) {
        $columns = $lines[$i] -split "\s{2,}"
        $formattedLine = $columns | ForEach-Object { 
            $index = [array]::IndexOf($columns, $_)
            $_.PadRight($columnWidths[$index])
        } | Join-String -Separator " | "
        $formattedOutput += $formattedLine
    }

    # Combine the output into a single string
    $output = @"
Date: ${date}
SQL HC Report for ${fqdn}:
$($formattedOutput -join "`n")
"@
    
    # Return the output
    return $output
}

# Execute the script block and append the output to a file
& $scriptBlock -fqdn $fqdn | Out-File -FilePath "..\backend\output.txt" -Encoding utf8