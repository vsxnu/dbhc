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

    # Process the content to improve formatting
    $lines = $content -split "`n"
    $formattedLines = @()
    $inTable = $false
    $columnWidths = @{}

    foreach ($line in $lines) {
        if ($line -match "^\s*-+\s*$") {
            # Table separator line
            $inTable = !$inTable
            if ($inTable) {
                $formattedLines += $line
            } else {
                $formattedLines += ("-" * $line.Length)
            }
        } elseif ($inTable) {
            # Table content
            $columns = $line -split "\s{2,}"
            for ($i = 0; $i -lt $columns.Length; $i++) {
                $columnWidth = $columns[$i].Length
                if (-not $columnWidths.ContainsKey($i) -or $columnWidth -gt $columnWidths[$i]) {
                    $columnWidths[$i] = $columnWidth
                }
            }
            $formattedColumns = @()
            for ($i = 0; $i -lt $columns.Length; $i++) {
                $formattedColumns += $columns[$i].PadRight($columnWidths[$i])
            }
            $formattedLines += ($formattedColumns -join " | ")
        } else {
            # Non-table content
            $formattedLines += $line
        }
    }

    $formattedContent = $formattedLines -join "`n"

    $output = @"
SybaseServer: $fqdn
Date: $(Get-Date)
Health Check Report:
$formattedContent
"@
    # Write the output to the file expected by the Python script
    $output | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
} else {
    "No health check report found for $fqdn" | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}