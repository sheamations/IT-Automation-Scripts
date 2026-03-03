<#
.SYNOPSIS
    Creates Active Directory users from a CSV file
.DESCRIPTION
    Reads user data from CSV and creates AD accounts with proper OU placement,
    group membership, and email attributes
.PARAMETER CSVPath
    Path to CSV file containing user data
.EXAMPLE
    .\New-ADUsersFromCSV.ps1 -CSVPath "C:\Users\NewHires.csv"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$CSVPath
)

# Import required module
Import-Module ActiveDirectory

# Import CSV
$Users = Import-Csv -Path $CSVPath

foreach ($User in $Users) {
    $UserParams = @{
        Name = "$($User.FirstName) $($User.LastName)"
        GivenName = $User.FirstName
        Surname = $User.LastName
        SamAccountName = $User.Username
        UserPrincipalName = "$($User.Username)@$($User.Domain)"
        Path = $User.OU
        AccountPassword = (ConvertTo-SecureString $User.TempPassword -AsPlainText -Force)
        Enabled = $true
        ChangePasswordAtLogon = $true
        EmailAddress = $User.Email
        Title = $User.JobTitle
        Department = $User.Department
    }
    
    try {
        New-ADUser @UserParams
        Write-Host "Created user: $($User.Username)" -ForegroundColor Green
        
        # Add to groups if specified
        if ($User.Groups) {
            $Groups = $User.Groups -split ';'
            foreach ($Group in $Groups) {
                Add-ADGroupMember -Identity $Group -Members $User.Username
                Write-Host "  Added to group: $Group" -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Host "Failed to create user: $($User.Username) - $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

**Sample CSV format** (create this as `sample_users.csv`):
```
FirstName,LastName,Username,Domain,OU,TempPassword,Email,JobTitle,Department,Groups
John,Smith,jsmith,company.com,"OU=Users,DC=company,DC=com",TempPass123!,jsmith@company.com,Developer,IT,Domain Users;Developers
