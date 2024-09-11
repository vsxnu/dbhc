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
    $output = @"
SybaseServer: $fqdn
Date: $(Get-Date)
Health Check Report:
$content
"@
    # Write the output to the file expected by the Python script
    $output | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
} else {
    "No health check report found for $fqdn" | Out-File -FilePath "..\backend\output.txt" -Encoding utf8
}