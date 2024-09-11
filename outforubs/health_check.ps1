param (
    [string]$fqdn
)

# Function to format output as a table
function Format-TableOutput {
    param ([string]$input)
    $lines = $input -split "`n"
    $header = $lines[0]
    $data = $lines[1..$lines.Length]

    $columns = $header -split '\s+'
    $columnWidths = @()
    foreach ($col in 0..($columns.Length - 1)) {
        $columnWidths += ($data | ForEach-Object { ($_ -split '\s+')[$col].Length } | Measure-Object -Maximum).Maximum
        $columnWidths[$col] = [Math]::Max($columnWidths[$col], $columns[$col].Length)
    }

    $formattedOutput = ($columns | ForEach-Object { $_.PadRight($columnWidths[$columns.IndexOf($_)]) }) -join " | "
    $formattedOutput += "`n" + ("-" * $formattedOutput.Length)
    foreach ($row in $data) {
        $rowData = $row -split '\s+'
        $formattedOutput += "`n" + ($rowData | ForEach-Object { $_.PadRight($columnWidths[$rowData.IndexOf($_)]) }) -join " | "
    }
    return $formattedOutput
}

# Get the hostname
$hostname = hostname

# Get the current date and time
$date = Get-Date

# Get the current working directory
$pwd = Get-Location

# RUN SQLCMD 
$sqlOutput = sqlcmd -S $fqdn -Q "EXEC DBServices..usp_healthchk" -s "   " -W -h-1 -w 200 | Out-String

# Format the output
$formattedOutput = Format-TableOutput $sqlOutput

# Combine the output into a single string
$output = @"
Date: ${date}
SQL HC Report for ${fqdn}:
$formattedOutput
"@

# Write the output to a file
$outputPath = "C:\UBS\Dev\dbhc\webapp\backend\output.txt"
Set-Content -Path $outputPath -Value $output