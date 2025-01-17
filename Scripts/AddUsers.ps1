# Names list URL
$NAMES_URL = "https://raw.githubusercontent.com/Chungmire/2025ActiveDirectoryLab/main/names.txt"

# Get password
$PASSWORD_FOR_USERS = Read-Host "Enter the default password for new users: "

# Get and validate number of users
do {
    $NUMBER_OF_USERS = Read-Host "Enter number of users to create: "
    
    if (-not ($NUMBER_OF_USERS -match '^\d+$')) {
        Write-Host "Please enter a valid number." -ForegroundColor Red
        continue
    }
    
    break
} while ($true)

# Download and process names list
try {
    Write-Host "Downloading names list..." -ForegroundColor Cyan
    $USER_FIRST_LAST_LIST = (Invoke-WebRequest -Uri $NAMES_URL -UseBasicParsing).Content.Split("`n") |
        Where-Object { $_ -match "^\w+ \w+$" } |  # Filter valid "firstname lastname" entries
        Get-Random -Count ([int]$NUMBER_OF_USERS)

    if ($USER_FIRST_LAST_LIST.Count -eq 0) {
        throw "No valid names were found in the list"
    }
} catch {
    Write-Host "Error downloading or processing names list: $_" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
    Read-Host
    exit 1
}

# Convert password to secure string
$password = ConvertTo-SecureString $PASSWORD_FOR_USERS -AsPlainText -Force

# Create Users OU if it doesn't exist
try {
    $domainDN = (Get-ADDomain).DistinguishedName
    Get-ADOrganizationalUnit -Identity "OU=_USERS,$domainDN" 
    Write-Host "_USERS OU already exists" -ForegroundColor Cyan
} catch {
    Write-Host "Creating _USERS Organizational Unit..." -ForegroundColor Cyan
    try {
        New-ADOrganizationalUnit -Name "_USERS" -Path $domainDN -ProtectedFromAccidentalDeletion $false
    } catch {
        Write-Host "Error creating _USERS OU: $_" -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        Read-Host
        exit 1
    }
}

# Track creation statistics
$successCount = 0
$errorCount = 0

# Create users
foreach ($n in $USER_FIRST_LAST_LIST) {
    $first = $n.Split(" ")[0].Trim().ToLower()
    $last = $n.Split(" ")[1].Trim().ToLower()
    $username = "$($first.Substring(0,1))$($last)".ToLower()
    
    try {
        # Check if user already exists
        if (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue) {
            Write-Host "User $username already exists - skipping" -ForegroundColor Yellow
            $errorCount++
            continue
        }

        Write-Host "Creating user: $($username)" -BackgroundColor Black -ForegroundColor Cyan
        
        New-AdUser -AccountPassword $password `
                   -GivenName $first `
                   -Surname $last `
                   -DisplayName $username `
                   -Name $username `
                   -EmployeeID $username `
                   -PasswordNeverExpires $true `
                   -Path "OU=_USERS,$domainDN" `
                   -Enabled $true
                   
        Write-Host "Successfully created user: $username" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "Error creating user $username : $_" -ForegroundColor Red
        $errorCount++
    }
}

# Display summary
Write-Host "`nUser Creation Summary" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Successfully created: $successCount users" -ForegroundColor Green
Write-Host "Failed to create: $errorCount users" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Total attempted: $($successCount + $errorCount) users" -ForegroundColor Cyan

# Keep window open
Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
Read-Host
