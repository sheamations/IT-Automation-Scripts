<#
.SYNOPSIS
    Generates software inventory report
.DESCRIPTION
    Retrieves installed software from one or more computers
.PARAMETER ComputerNames
    Array of computer names to inventory
.EXAMPLE
    .\Get-InstalledSoftware.ps1 -ComputerNames "PC01","PC02"
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$ComputerNames,
    [string]$ExportPath = ".\SoftwareInventory_$(Get-Date -Format 'yyyyMMdd').csv"
)

$AllSoftware = @()

foreach ($Computer in $ComputerNames) {
    Write-Host "Scanning $Computer..." -ForegroundColor Yellow
    
    try {
        $Software = Invoke-Command -ComputerName $Computer -ScriptBlock {
            $Apps = @()
            
            # 64-bit software
            $Apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                     Where-Object { $_.DisplayName } |
                     Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
            
            # 32-bit software on 64-bit system
            $Apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                     Where-Object { $_.DisplayName } |
                     Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
            
            $Apps | Select-Object -Unique DisplayName, DisplayVersion, Publisher, InstallDate
        }
        
        foreach ($App in $Software) {
            $AllSoftware += [PSCustomObject]@{
                ComputerName = $Computer
                Software = $App.DisplayName
                Version = $App.DisplayVersion
                Publisher = $App.Publisher
                InstallDate = $App.InstallDate
            }
        }
        
        Write-Host "  Found $($Software.Count) applications" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to scan $Computer - $($_.Exception.Message)" -ForegroundColor Red
    }
}

$AllSoftware | Export-Csv -Path $ExportPath -NoTypeInformation

Write-Host "`nTotal applications found: $($AllSoftware.Count)" -ForegroundColor Cyan
Write-Host "Report saved to: $ExportPath" -ForegroundColor Green

# Show summary by software
$AllSoftware | Group-Object Software | 
    Sort-Object Count -Descending | 
    Select-Object Count, Name -First 20 |
    Format-Table -AutoSize
