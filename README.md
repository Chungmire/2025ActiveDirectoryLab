# 2025ActiveDirectoryLab
An updated walkthrough on setting up Windows Server 2022 in a Virtual Machine to run Active Directory to manage Windows 11 clients on separate machines, simulating a modern enterprise network configuration.


Press Win+R, then Ctrl+V the below command into the run box:
```
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Chungmire/2025ActiveDirectoryLab/refs/heads/main/Scripts/AddUsers.ps1')))"
```
