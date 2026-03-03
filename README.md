# IT Automation Scripts

Collection of PowerShell scripts for common IT administration tasks. These scripts help automate user management, reporting, and system monitoring.

## Scripts Included

### 1. New-ADUsersFromCSV.ps1
Bulk create Active Directory users from a CSV file with automatic group assignment.

**Use Case**: Onboarding multiple employees efficiently

**Requirements**: Active Directory module

### 2. Find-InactiveADUsers.ps1
Generate reports of users who haven't logged in within a specified timeframe.

**Use Case**: Security audits, license reclamation, compliance

### 3. Get-ADGroupMembershipReport.ps1
Export detailed membership reports for AD groups.

**Use Case**: Access audits, documentation, compliance reporting

### 4. Monitor-DiskSpace.ps1
Check disk space across multiple servers with configurable alerts.

**Use Case**: Prevent disk full issues, capacity planning

### 5. Get-InstalledSoftware.ps1
Inventory installed software across multiple computers.

**Use Case**: License management, finding outdated software, compliance

## Usage

Each script includes detailed help. Use `Get-Help .\ScriptName.ps1 -Detailed` for usage examples.

## Requirements

- PowerShell 5.1 or higher
- Active Directory module (for AD scripts)
- Appropriate permissions on target systems

## Author

Shea - IT Support & Automation Specialist
