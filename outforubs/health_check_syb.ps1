# health_check_syb.ps1

param (
    [string]$fqdn
)

# Get the current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sybaseDir = Join-Path -Path $scriptDir -ChildPath "Sybase"

# Path to the hackathon.ps1 script
$hackathonScript = Join-Path -Path $sybaseDir -ChildPath "hackathon.ps1"

# Run the hackathon.ps1 script
& $hackathonScript

# Read the output file
$outputFile = Get-ChildItem -Path $sybaseDir -Filter "*_HealthCheck.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($outputFile) {
    $content = Get-Content -Path $outputFile.FullName -Raw
    
    # Process the content to create a formatted table
    $lines = $content -split "`n" | Where-Object { $_ -match '\S' }
    $header = $lines[0] -split '\s+'
    $data = $lines[1..$lines.Count] | ForEach-Object { $_ -split '\s+' }

    # Calculate column widths
    $colWidths = @()
    for ($i = 0; $i -lt $header.Count; $i++) {
        $maxWidth = ($data | ForEach-Object { $_[$i].Length } | Measure-Object -Maximum).Maximum
        $colWidths += [Math]::Max($header[$i].Length, $maxWidth)
    }

    # Create the formatted table
    $table = @()
    $separator = $colWidths | ForEach-Object { '-' * $_ } | Join-String -Separator '+'
    $table += $separator

    $headerRow = for ($i = 0; $i -lt $header.Count; $i++) {
        $header[$i].PadRight($colWidths[$i])
    }
    $table += '|' + ($headerRow -join '|') + '|'
    $table += $separator

    foreach ($row in $data) {
        $formattedRow = for ($i = 0; $i -lt $row.Count; $i++) {
            $row[$i].PadRight($colWidths[$i])
        }
        $table += '|' + ($formattedRow -join '|') + '|'
    }
    $table += $separator

    $output = @"
SybaseServer: $fqdn
Date: $(Get-Date)
Health Check Report:

$($table -join "`n")
"@
    # Write the output to the file expected by the Python script
    $output | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
} else {
    "No health check report found for $fqdn" | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}