<#
.SYNOPSIS
    Generates Active Directory group membership report
.DESCRIPTION
    Creates detailed report of all members in specified AD groups
.PARAMETER GroupNames
    Array of group names to report on
.PARAMETER ExportPath
    Path to export CSV report
.EXAMPLE
    .\Get-ADGroupMembershipReport.ps1 -GroupNames "Domain Admins","IT Department"
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$GroupNames,
    [string]$ExportPath = ".\GroupMembership_$(Get-Date -Format 'yyyyMMdd').csv"
)

Import-Module ActiveDirectory

$Report = @()

foreach ($GroupName in $GroupNames) {
    try {
        $Members = Get-ADGroupMember -Identity $GroupName -Recursive |
                   Get-ADUser -Properties EmailAddress, Department, Title, Enabled
        
        foreach ($Member in $Members) {
            $Report += [PSCustomObject]@{
                GroupName = $GroupName
                Name = $Member.Name
                Username = $Member.SamAccountName
                Email = $Member.EmailAddress
                Department = $Member.Department
                Title = $Member.Title
                Enabled = $Member.Enabled
            }
        }
        
        Write-Host "Processed group: $GroupName ($($Members.Count) members)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error processing group: $GroupName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

$Report | Export-Csv -Path $ExportPath -NoTypeInformation
Write-Host "`nReport exported to: $ExportPath" -ForegroundColor Cyan
Write-Host "Total members across all groups: $($Report.Count)" -ForegroundColor Yellow
