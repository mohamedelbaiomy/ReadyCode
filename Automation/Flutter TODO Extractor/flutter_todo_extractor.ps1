# Flutter TODO/FIXME Report Generator
# PowerShell Script

# Get the script's directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

$libDir = "lib"
$outputFile = "TODO_REPORT.md"

# Check if lib folder exists
if (-not (Test-Path -Path $libDir -PathType Container)) {
    Write-Host "❌ lib folder not found" -ForegroundColor Red
    Write-Host "Current location: $(Get-Location)" -ForegroundColor Yellow
    exit
}

# Initialize output buffer
$buffer = New-Object System.Text.StringBuilder
[void]$buffer.AppendLine("# 📝 TODO / FIXME Report`n")
[void]$buffer.AppendLine("Generated at: $(Get-Date)`n")

$total = 0

# Get all .dart files recursively
Get-ChildItem -Path $libDir -Filter "*.dart" -Recurse -File | ForEach-Object {
    $file = $_
    $lines = Get-Content -Path $file.FullName
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        if ($line -cmatch "TODO|FIXME") {
            $total++
            
            $relativePath = $file.FullName -replace "\\", "/"
            [void]$buffer.AppendLine("### 📄 $relativePath")
            [void]$buffer.AppendLine("- Line $($i + 1): ``$($line.Trim())```n")
        }
    }
}

# Add summary
[void]$buffer.AppendLine("---")
[void]$buffer.AppendLine("🔢 Total TODOs: $total")

# Write to file
$buffer.ToString() | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "✅ TODO report generated: TODO_REPORT.md" -ForegroundColor Green
Write-Host "🔢 Total TODOs found: $total" -ForegroundColor Cyan