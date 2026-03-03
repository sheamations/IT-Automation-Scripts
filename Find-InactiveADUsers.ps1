<#
.SYNOPSIS
    Finds inactive Active Directory users
.DESCRIPTION
    Generates a report of users who haven't logged in within specified days
.PARAMETER DaysInactive
    Number of days of inactivity to check for (default: 90)
.PARAMETER ExportPath
    Path to export CSV report
.EXAMPLE
    .\Find-InactiveADUsers.ps1 -DaysInactive 90 -ExportPath "C:\Reports\InactiveUsers.csv"
#>

param(
    [int]$DaysInactive = 90,
    [string]$ExportPath = ".\InactiveUsers_$(Get-Date -Format 'yyyyMMdd').csv"
)

Import-Module ActiveDirectory

$InactiveDate = (Get-Date).AddDays(-$DaysInactive)

$InactiveUsers = Get-ADUser -Filter {
    Enabled -eq $true -and 
    LastLogonDate -lt $InactiveDate
} -Properties LastLogonDate, EmailAddress, Department, Title, WhenCreated |
Select-Object Name, SamAccountName, EmailAddress, Department, Title, 
              LastLogonDate, WhenCreated, 
              @{Name='DaysInactive';Expression={(New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).Days}}

# Export to CSV
$InactiveUsers | Export-Csv -Path $ExportPath -NoTypeInformation

# Display summary
Write-Host "`nInactive User Report" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
Write-Host "Search Criteria: Users inactive for $DaysInactive days or more"
Write-Host "Total Inactive Users: $($InactiveUsers.Count)" -ForegroundColor Cyan
Write-Host "Report saved to: $ExportPath`n" -ForegroundColor Green

# Display top 10
$InactiveUsers | Select-Object -First 10 | Format-Table -AutoSize
