#--------------------------------------------------------
# To use this script, run the following command in PowerShell:
# .\clean_flutter_projects.ps1

# Notes:
# When running the script, ensure that your current directory is the one containing this script.
# You can change the current directory using the 'cd' command.

# In the first time you need to run the script, run the following command to allow script execution:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# The command is the same name as the script file.
# If you need to change the script file name you must also change the command accordingly.
#--------------------------------------------------------

Write-Host "Detecting available drives ..."

# Get all local drives (C:\, D:\, E:\, ...)
$drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root

Write-Host "Found drives: $($drives -join ', ')"
Write-Host ""

foreach ($drive in $drives) {

    Write-Host "Searching for Flutter projects in $drive ..."

    # Find all pubspec.yaml files in this drive
    $projects = Get-ChildItem -Path $drive -Filter "pubspec.yaml" -Recurse -ErrorAction SilentlyContinue

    if ($projects.Count -eq 0) {
        Write-Host "No Flutter projects found in $drive."
        Write-Host ""
        continue
    }

    Write-Host "`nFound $($projects.Count) Flutter project(s) in $drive. Starting cleanup...`n"

    foreach ($file in $projects) {
        $projectPath = $file.Directory.FullName
        Write-Host "----------------------------------------"
        Write-Host "Cleaning project at: $projectPath"
        Write-Host "----------------------------------------"

        # Run flutter clean inside the project folder
        Push-Location $projectPath
        flutter clean
        Pop-Location

        Write-Host "Done.`n"
    }

    Write-Host "Finished cleaning projects in $drive!"
    Write-Host ""
}

Write-Host "`nAll drives scanned. Cleanup complete!"
