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
    
    # RUN SQLCMD 
    $sqlOutput = sqlcmd -S $fqdn -Q "EXEC DBServices..usp_healthchk" -s "   " -W -h-1 -w 200
    
    # Convert the SQL output to a table format
    $sqlOutputLines = $sqlOutput | Out-String | ConvertFrom-Csv
    
    # Determine the maximum width for each column
    $columnWidths = @{}
    foreach ($line in $sqlOutputLines) {
        foreach ($property in $line.PSObject.Properties) {
            $name = $property.Name
            $value = $property.Value.ToString()
            if (-not $columnWidths.ContainsKey($name)) {
                $columnWidths[$name] = $name.Length
            }
            if ($value.Length -gt $columnWidths[$name]) {
                $columnWidths[$name] = $value.Length
            }
        }
    }

    # Function to format each row of the table
    function Format-Row {
        param (
            [PSObject]$row,
            [hashtable]$columnWidths
        )
        $formattedRow = @()
        foreach ($property in $row.PSObject.Properties) {
            $name = $property.Name
            $value = $property.Value.ToString()
            $width = $columnWidths[$name]
            $formattedRow += $value.PadRight($width)
        }
        return ($formattedRow -join " | ")
    }

    # Format the header
    $header = $sqlOutputLines[0].PSObject.Properties.Name
    $formattedHeader = @()
    foreach ($name in $header) {
        $width = $columnWidths[$name]
        $formattedHeader += $name.PadRight($width)
    }
    $formattedSqlOutput = @()
    $formattedSqlOutput += ($formattedHeader -join " | ")

    # Format each row
    foreach ($line in $sqlOutputLines) {
        $formattedSqlOutput += Format-Row -row $line -columnWidths $columnWidths
    }

    # Combine the output into a single string
    $output = @"
Date: ${date}
SQL HC Report for ${fqdn}:
$($formattedSqlOutput -join "`n")
"@
    
    # Return the output
    return $output
}

# Execute the script block and append the output to a file
& $scriptBlock -fqdn $fqdn | Add-Content -Path "../backend/output.txt"