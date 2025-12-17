#--------------------------------------------------------
# To use this script, run the following command in PowerShell:
# .\clean_flutter_projects.ps1
#
# Notes:
# - The script will ONLY search inside the current directory
#   (the directory where you run the script from).
#
# First time only:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#--------------------------------------------------------

# Get current directory
$rootPath = Get-Location

Write-Host "Searching for Flutter projects in:"
Write-Host $rootPath
Write-Host ""

# Find all pubspec.yaml files under the current directory
$projects = Get-ChildItem `
    -Path $rootPath `
    -Filter "pubspec.yaml" `
    -Recurse `
    -ErrorAction SilentlyContinue

if ($projects.Count -eq 0) {
    Write-Host "No Flutter projects found in this directory."
    exit
}

Write-Host "Found $($projects.Count) Flutter project(s). Starting cleanup...`n"

foreach ($file in $projects) {
    $projectPath = $file.Directory.FullName

    Write-Host "----------------------------------------"
    Write-Host "Cleaning project at:"
    Write-Host $projectPath
    Write-Host "----------------------------------------"

    Push-Location $projectPath
    flutter clean
    Pop-Location

    Write-Host "Done.`n"
}

Write-Host "Cleanup complete!"
