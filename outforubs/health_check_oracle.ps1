param (
    [string]$fqdn
)

# Define the path for sql.ini file
$sqliniFile = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\tnsnames.ora"

# Define the path to the SQL file to be executed
$sqlFilePath = "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\query.sql"

# Define Oracle credentials
$username = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.user.txt"
$password = Get-Content -Path "C:\UBS\Dev\dbhc\webapp\scripts\Oracle\orahc\.pass.txt"

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

# Run SQL*Plus command and capture the output
$sqlplusOutput = sqlplus -S "$username/$password@$fqdn" "@$sqlFilePath" | Out-String

# Process and format the output
$sections = $sqlplusOutput -split '(?=\n\w+\s+Info:)'
$formattedOutput = ""

foreach ($section in $sections) {
    if ($section.Trim() -ne "") {
        $sectionLines = $section -split "`n"
        $sectionTitle = $sectionLines[0]
        $sectionContent = $sectionLines[1..($sectionLines.Length-1)] | Out-String
        
        $formattedOutput += "$sectionTitle`n"
        $formattedOutput += "=" * $sectionTitle.Length + "`n"
        $formattedOutput += Format-TableOutput $sectionContent
        $formattedOutput += "`n`n"
    }
}

# Write the formatted output to a file
$outputPath = "C:\UBS\Dev\dbhc\webapp\backend\output.txt"
Set-Content -Path $outputPath -Value $formattedOutput