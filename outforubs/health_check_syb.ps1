param (
    [string]$fqdn
)

# Define the path for sql.ini file
$sqliniFile = "C:\UBS\Dev\dbhc\webapp\scripts\Sybase\sql.ini"

# Define the path to the text file containing the list of hostnames
$hostnamesFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Sybase\hostnames.txt"

# Define the path to the RequestID 
$PathDir = "C:\UBS\Dev\dbhc\webapp\scripts\Sybase\"

# Get credentials
$username = Get-Content -Path (Join-Path -Path $PathDir -ChildPath ".user")
$password = Get-Content -Path (Join-Path -Path $PathDir -ChildPath ".pass")

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

# Run the health check and capture the output
$HCTag = $fqdn + '_' + $PID
$InputFile = $HCTag + "_input.txt"

if (Test-Path $InputFile) { Remove-Item $InputFile }

"exec sasdb..sp_sas_ins_request hcheck, '" + $fqdn + "',null,'-t " + $HCTag +"',now" | Out-File -FilePath $InputFile -Append
"go" | Out-File -FilePath $InputFile -Append

$isqlCmd = "isql -U $username -P $password -S SYBCENTRAL -I $sqliniFile -w500 -i $InputFile"
$outputQuery = Invoke-Expression $isqlCmd | Out-String

# Format the output
$formattedOutput = Format-TableOutput $outputQuery

# Combine the output into a single string
$output = @"
Date: $(Get-Date)
Sybase HC Report for ${fqdn}:
$formattedOutput
"@

# Write the formatted output to a file
$outputPath = "C:\UBS\Dev\dbhc\webapp\backend\output.txt"
Set-Content -Path $outputPath -Value $output

# Clean up temporary files
if (Test-Path $InputFile) { Remove-Item $InputFile }