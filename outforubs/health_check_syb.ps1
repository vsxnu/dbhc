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

    # Process the content to create HTML
    $lines = $content -split "`n"
    $htmlOutput = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sybase Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Sybase Health Check Report</h1>
    <p>Date: $(Get-Date)</p>
    <p>Server: $fqdn</p>
"@

    $inTable = $false
    foreach ($line in $lines) {
        if ($line -match "^\s*-+\s*$") {
            if ($inTable) {
                $htmlOutput += "    </table>`n"
            } else {
                $htmlOutput += "    <table>`n"
            }
            $inTable = !$inTable
        } elseif ($inTable) {
            $columns = $line -split "\s{2,}"
            $htmlOutput += "        <tr>`n"
            foreach ($column in $columns) {
                $htmlOutput += "            <td>$column</td>`n"
            }
            $htmlOutput += "        </tr>`n"
        } else {
            $htmlOutput += "    <p>$line</p>`n"
        }
    }

    $htmlOutput += @"
</body>
</html>
"@

    # Write the HTML output to the file expected by the Python script
    $htmlOutput | Out-File -FilePath "..\backend\output.html" -Encoding utf8
} else {
    "<html><body><h1>Error</h1><p>No health check report found for $fqdn</p></body></html>" | Out-File -FilePath "..\backend\output.html" -Encoding utf8
}