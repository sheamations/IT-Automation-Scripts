<#
.SYNOPSIS
    Compares Active Directory group memberships between two users based on their Employee Number attribute.

.DESCRIPTION
    This script takes two employee numbers, looks up the corresponding Active Directory user accounts,
    retrieves all group memberships for each user, and displays a color-coded comparison:
      - GREEN  = Group exists in BOTH users
      - RED    = Group exists in only ONE of the users

.PARAMETER EmployeeNumber1
    The Employee Number of the first AD user to compare.

.PARAMETER EmployeeNumber2
    The Employee Number of the second AD user to compare.

.EXAMPLE
    .\Compare-ADUsersGroups.ps1 -EmployeeNumber1 "12345" -EmployeeNumber2 "67890"

.EXAMPLE
    .\Compare-ADUsersGroups.ps1
    (Will prompt for Employee Numbers interactively)

.NOTES
    Requires the ActiveDirectory PowerShell module.
    Author: Shea Buckner
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Enter the Employee Number for the first user")]
    [string]$EmployeeNumber1,

    [Parameter(Mandatory = $false, HelpMessage = "Enter the Employee Number for the second user")]
    [string]$EmployeeNumber2
)

#region Functions

function Write-Banner {
    $banner = @"
╔══════════════════════════════════════════════════════════╗
║          AD User Group Membership Comparison             ║
╚══════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host ("─" * 60) -ForegroundColor DarkGray
}

function Get-ADUserByEmployeeNumber {
    param([string]$EmpNumber)

    try {
        $user = Get-ADUser -Filter "EmployeeNumber -eq '$EmpNumber'" `
                           -Properties DisplayName, SamAccountName, EmployeeNumber, `
                                       Department, Title, Enabled, MemberOf `
                           -ErrorAction Stop

        if ($null -eq $user) {
            Write-Host "[ERROR] No user found with Employee Number: $EmpNumber" -ForegroundColor Red
            return $null
        }

        # Handle multiple results (shouldn't happen but be safe)
        if ($user -is [array]) {
            Write-Host "[WARNING] Multiple users found with Employee Number '$EmpNumber'. Using the first result." -ForegroundColor Yellow
            $user = $user[0]
        }

        return $user
    }
    catch {
        Write-Host "[ERROR] Failed to query Active Directory for Employee Number '$EmpNumber'." -ForegroundColor Red
        Write-Host "        Details: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-AllGroupMemberships {
    param (
        [Microsoft.ActiveDirectory.Management.ADUser]$User
    )

    try {
        # Get all groups recursively (nested group memberships included)
        $groups = Get-ADPrincipalGroupMembership -Identity $User.SamAccountName -ErrorAction Stop |
                  Select-Object -ExpandProperty Name |
                  Sort-Object

        return $groups
    }
    catch {
        Write-Host "[ERROR] Could not retrieve group memberships for '$($User.SamAccountName)'." -ForegroundColor Red
        Write-Host "        Details: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Write-UserSummary {
    param (
        [Microsoft.ActiveDirectory.Management.ADUser]$User,
        [string]$Label
    )

    $status      = if ($User.Enabled) { "Enabled" } else { "Disabled" }
    $statusColor = if ($User.Enabled) { "Green" }   else { "Red" }

    Write-Host ""
    Write-Host "  $Label" -ForegroundColor Cyan
    Write-Host "  $("─" * 40)" -ForegroundColor DarkGray
    Write-Host ("  {0,-18} {1}" -f "Display Name:",    $User.DisplayName)
    Write-Host ("  {0,-18} {1}" -f "SAM Account:",     $User.SamAccountName)
    Write-Host ("  {0,-18} {1}" -f "Employee Number:", $User.EmployeeNumber)
    Write-Host ("  {0,-18} {1}" -f "Department:",      $User.Department)
    Write-Host ("  {0,-18} {1}" -f "Title:",           $User.Title)
    Write-Host -NoNewline ("  {0,-18} " -f "Account Status:")
    Write-Host $status -ForegroundColor $statusColor
}

function Write-ComparisonTable {
    param (
        [string[]]$Groups1,
        [string[]]$Groups2,
        [string]$User1Name,
        [string]$User2Name
    )

    # Build combined unique sorted group list
    $allGroups = ($Groups1 + $Groups2) | Sort-Object -Unique

    $colWidth   = 42
    $checkMark  = " [YES]"
    $crossMark  = "  [NO]"

    # Header
    Write-Host ""
    Write-Host ("  {0,-$colWidth} {1,-8} {2,-8}" -f "Group Name", $User1Name.PadRight(8).Substring(0,8), $User2Name.PadRight(8).Substring(0,8)) -ForegroundColor White
    Write-Host ("  {0}" -f ("─" * ($colWidth + 20))) -ForegroundColor DarkGray

    $sharedCount  = 0
    $uniqueCount  = 0

    foreach ($group in $allGroups) {
        $inUser1 = $Groups1 -contains $group
        $inUser2 = $Groups2 -contains $group

        $col1 = if ($inUser1) { $checkMark } else { $crossMark }
        $col2 = if ($inUser2) { $checkMark } else { $crossMark }

        # Truncate long group names for display
        $displayName = if ($group.Length -gt ($colWidth - 2)) {
            $group.Substring(0, $colWidth - 5) + "..."
        } else {
            $group
        }

        $line = "  {0,-$colWidth} {1,-8} {2,-8}" -f $displayName, $col1, $col2

        if ($inUser1 -and $inUser2) {
            Write-Host $line -ForegroundColor Green
            $sharedCount++
        }
        else {
            Write-Host $line -ForegroundColor Red
            $uniqueCount++
        }
    }

    return [PSCustomObject]@{
        TotalGroups  = $allGroups.Count
        SharedGroups = $sharedCount
        UniqueGroups = $uniqueCount
    }
}

#endregion

#region Main Script

# Check for ActiveDirectory module
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "[ERROR] The ActiveDirectory PowerShell module is not installed or unavailable." -ForegroundColor Red
    Write-Host "        Please install RSAT (Remote Server Administration Tools) and try again." -ForegroundColor Yellow
    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

Write-Banner

# Prompt for Employee Numbers if not provided as parameters
if (-not $EmployeeNumber1) {
    Write-Host ""
    $EmployeeNumber1 = Read-Host "  Enter Employee Number for User 1"
}

if (-not $EmployeeNumber2) {
    $EmployeeNumber2 = Read-Host "  Enter Employee Number for User 2"
}

Write-Host ""
Write-Host "  Searching Active Directory..." -ForegroundColor DarkGray

# Lookup both users
$user1 = Get-ADUserByEmployeeNumber -EmpNumber $EmployeeNumber1
$user2 = Get-ADUserByEmployeeNumber -EmpNumber $EmployeeNumber2

# Abort if either user was not found
if ($null -eq $user1 -or $null -eq $user2) {
    Write-Host ""
    Write-Host "[ABORTED] One or both users could not be found. Please verify the Employee Numbers." -ForegroundColor Red
    exit 1
}

# Display user summaries
Write-SectionHeader "User Account Details"
Write-UserSummary -User $user1 -Label "User 1  (EmpNo: $EmployeeNumber1)"
Write-UserSummary -User $user2 -Label "User 2  (EmpNo: $EmployeeNumber2)"

# Retrieve group memberships
Write-SectionHeader "Retrieving Group Memberships"
Write-Host "  Fetching groups for: $($user1.DisplayName) ..." -ForegroundColor DarkGray
$groups1 = Get-AllGroupMemberships -User $user1

Write-Host "  Fetching groups for: $($user2.DisplayName) ..." -ForegroundColor DarkGray
$groups2 = Get-AllGroupMemberships -User $user2

Write-Host "  Done." -ForegroundColor DarkGray

# Shorten display names for column headers (max 8 chars)
$header1 = if ($user1.SamAccountName.Length -gt 8) { $user1.SamAccountName.Substring(0,8) } else { $user1.SamAccountName }
$header2 = if ($user2.SamAccountName.Length -gt 8) { $user2.SamAccountName.Substring(0,8) } else { $user2.SamAccountName }

# Display comparison
Write-SectionHeader "Group Membership Comparison"
Write-Host ""
Write-Host "  Color Legend:" -ForegroundColor White
Write-Host "  " -NoNewline; Write-Host "GREEN " -ForegroundColor Green -NoNewline; Write-Host "= Group shared by BOTH users"
Write-Host "  " -NoNewline; Write-Host "RED   " -ForegroundColor Red   -NoNewline; Write-Host "= Group unique to ONE user only"

$stats = Write-ComparisonTable -Groups1 $groups1 `
                                -Groups2 $groups2 `
                                -User1Name $header1 `
                                -User2Name $header2

# Summary statistics
Write-SectionHeader "Summary"
Write-Host ""
Write-Host ("  {0,-30} {1}" -f "Total Unique Groups:",    $stats.TotalGroups)  -ForegroundColor White
Write-Host ("  {0,-30} " -f "Shared Groups (both):") -NoNewline
Write-Host $stats.SharedGroups -ForegroundColor Green
Write-Host ("  {0,-30} " -f "Differing Groups (one only):") -NoNewline
Write-Host $stats.UniqueGroups -ForegroundColor Red
Write-Host ""
Write-Host ("  User 1 - {0,-20} Total Groups: {1}" -f $user1.DisplayName, $groups1.Count) -ForegroundColor Cyan
Write-Host ("  User 2 - {0,-20} Total Groups: {1}" -f $user2.DisplayName, $groups2.Count) -ForegroundColor Cyan
Write-Host ""

#endregion
