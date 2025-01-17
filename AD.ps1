Clear-Host

# GitHub URL for the script
$scriptUrl = "https://raw.githubusercontent.com/Chungmire/2025ActiveDirectoryLab/refs/heads/main/Scripts/AddUsers.ps1"


# Run the script directly from the URL with elevated privileges
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -Command `\"iex (iwr('$scriptUrl'))`\"" -Verb RunAs

Write-Output "Executed script."
