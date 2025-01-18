# Script to Add Firewall Rules to Domain Profile in Default Domain Policy

Import-Module GroupPolicy

# Define the firewall rule groups to enable
$FirewallGroups = @(
    "Windows Management Instrumentation (WMI)",
    "Remote Service Management", 
    "Remote Desktop"
)

function Add-DomainProfileFirewallRules {
    param (
        [switch]$Backup = $true
    )

    try {
        # Backup Default Domain Policy
        if ($Backup) {
            $backupPath = "C:\GPolicyBackups\DefaultDomainPolicy_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Backup-Gpo -Name "Default Domain Policy" -Path $backupPath
            Write-Host "Backup of Default Domain Policy created at: $backupPath" -ForegroundColor Green
        }

        # Enable firewall rules specifically for Domain profile
        foreach ($group in $FirewallGroups) {
            try {
                # Enable the firewall rule group specifically for Domain profile
                Set-NetFirewallRule -DisplayGroup "$group" -Profile Domain -Enabled True

                Write-Host "Successfully enabled $group for Domain profile" -ForegroundColor Green
            }
            catch {
                Write-Host "Error enabling $group for Domain profile" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }

        # Force Group Policy update
        gpupdate /force

        Write-Host "Domain Profile Firewall Rules configuration complete." -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred while configuring Domain Profile Firewall Rules" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Run the function
Add-DomainProfileFirewallRules