# Check if Active Directory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "The Active Directory PowerShell module is not installed." -ForegroundColor Red
    Write-Host "This script requires a Domain Controller or RSAT tools installed." -ForegroundColor Yellow
    Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
    Read-Host
    exit 1
}

# Names list URL
$NAMES_URL = "https://raw.githubusercontent.com/dominictarr/random-name/master/names.txt"

# Get password
$PASSWORD_FOR_USERS = Read-Host "Enter the default password for new users"

# Get and validate number of users
do {
    $NUMBER_OF_USERS = Read-Host "How many users would you like to create?"
    
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

Write-Host "`nNames selected for user creation:" -ForegroundColor Cyan
foreach ($n in $USER_FIRST_LAST_LIST) {
    $first = $n.Split(" ")[0].Trim().ToLower()
    $last = $n.Split(" ")[1].Trim().ToLower()
    $username = "$($first.Substring(0,1))$($last)".ToLower()
    
    Write-Host "Would create user: $username ($first $last)" -ForegroundColor Green
}

Write-Host "`nNote: This is a preview mode since Active Directory is not available." -ForegroundColor Yellow
Write-Host "To actually create users, run this on a machine with Active Directory." -ForegroundColor Yellow

# Keep window open
Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
Read-Host
