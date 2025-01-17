# Launch AddUsers script as administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command & ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Chungmire/2025ActiveDirectoryLab/main/Scripts/AddUsers.ps1')))"
    Exit
}
