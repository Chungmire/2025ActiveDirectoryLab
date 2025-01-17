# Names list URL
$NAMES_URL = "https://raw.githubusercontent.com/Chungmire/2025ActiveDirectoryLab/main/names.txt"

# Get OU name
$OU_NAME = Read-Host "Enter the name of the OU to create for users"

# Get password
$PASSWORD_FOR_USERS = Read-Host "Enter default password for new users"

# Get and validate number of users
do {
    $NUMBER_OF_USERS = Read-Host "Enter number of users to create"
    
    if (-not ($NUMBER_OF_USERS -match '^\d+$')) {
        Write-Host "Please enter a valid number." -ForegroundColor Red
        continue
    }
    
    break
} while ($true)

# Download and process names list
try {
    Write-Host "Downloading names list..." -ForegroundColor Cyan
    $content = (Invoke-WebRequest -Uri $NAMES_URL -UseBasicParsing).Content
    Write-Host "Content length: $($content.Length)"
    $names = $content.Split("`n")
    Write-Host "Names array length: $($names.Length)"
    Write-Host "First few names:"
    $names | Select-Object -First 3 | ForEach-Object { Write-Host "`"$_`"" }
    $USER_FIRST_LAST_LIST = $names | Get-Random -Count ([int]$NUMBER_OF_USERS)
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
$domainDN = (Get-ADDomain).DistinguishedName
try {
    Get-ADOrganizationalUnit -Identity "OU=$OU_NAME,$domainDN" 
    Write-Host "$OU_NAME OU already exists, will use _$OU_NAME instead" -ForegroundColor Yellow
    $OU_NAME = "_$OU_NAME"
    
    # Check if the _OU exists
    try {
        Get-ADOrganizationalUnit -Identity "OU=$OU_NAME,$domainDN"
        Write-Host "$OU_NAME also exists. Please use a different name." -ForegroundColor Red
        Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
        Read-Host
        exit 1
    } catch {
        Write-Host "Creating $OU_NAME Organizational Unit..." -ForegroundColor Cyan
        New-ADOrganizationalUnit -Name $OU_NAME -Path $domainDN -ProtectedFromAccidentalDeletion $false
    }
} catch {
    Write-Host "Creating $OU_NAME Organizational Unit..." -ForegroundColor Cyan
    try {
        New-ADOrganizationalUnit -Name $OU_NAME -Path $domainDN -ProtectedFromAccidentalDeletion $false
    } catch {
        Write-Host "Error creating $OU_NAME OU: $_" -ForegroundColor Red
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
                   -Path "OU=$OU_NAME,$domainDN" `
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
