# ------------------------------------------------------------------------------
# Author: Ilya Fedotov
# Date: 20.08.2024
# Description: This script creates Active Directory (AD) security groups for each 
#              department and subfolder within a specified directory structure. 
#              It assigns Read-Write (RW) and Read-Only (RO) permissions to the 
#              corresponding folders, ensuring proper access control for each 
#              organizational unit in the construction company.
#              The script also ensures that group names do not exceed the 64-character 
#              limit in AD and handles potential errors during group creation.
# ------------------------------------------------------------------------------

# Import the Active Directory module
Import-Module ActiveDirectory

# Set the base path
$basePath = "C:\Shared\Construction Company"

# Define the department structure with three levels
$departments = @{
    "Administration" = @{
        "Human Resources" = @("Recruitment", "Employee Relations", "Payroll")
        "Finance" = @("Accounting", "Budgeting", "Financial Planning")
        "Legal" = @("Contracts", "Compliance", "Dispute Resolution")
    }
    # ... (rest of the department structure)
}

# Function to create AD groups and set folder permissions
function Create-ADGroupsAndSetPermissions {
    param (
        [string]$FolderPath,
        [string]$GroupNamePrefix
    )
    
    $folderName = Split-Path $FolderPath -Leaf
    $rwGroupName = ($GroupNamePrefix + "-" + $folderName + "-RW").Substring(0, [Math]::Min(64, ($GroupNamePrefix + "-" + $folderName + "-RW").Length))
    $roGroupName = ($GroupNamePrefix + "-" + $folderName + "-RO").Substring(0, [Math]::Min(64, ($GroupNamePrefix + "-" + $folderName + "-RO").Length))
    
    # Create RW group
    New-ADGroup -Name $rwGroupName -GroupScope Global -GroupCategory Security -ErrorAction SilentlyContinue

    # Create RO group
    New-ADGroup -Name $roGroupName -GroupScope Global -GroupCategory Security -ErrorAction SilentlyContinue

    # Wait for AD replication
    Start-Sleep -Seconds 5

    # Set folder permissions
    $acl = Get-Acl $FolderPath
    
    # Set Read-Write permissions for RW group
    $identity = New-Object System.Security.Principal.NTAccount($rwGroupName)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    
    # Set Read-Only permissions for RO group
    $identity = New-Object System.Security.Principal.NTAccount($roGroupName)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    
    Set-Acl $FolderPath $acl
    
    Write-Host "Created groups and set permissions for: $FolderPath"
}

# Create groups and set permissions for the base folder
Create-ADGroupsAndSetPermissions -FolderPath $basePath -GroupNamePrefix "ConstCo"

# Create groups and set permissions for all subfolders
Get-ChildItem $basePath -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Substring($basePath.Length + 1)
    $groupNamePrefix = "ConstCo-" + ($relativePath -replace "\\", "-")
    Create-ADGroupsAndSetPermissions -FolderPath $_.FullName -GroupNamePrefix $groupNamePrefix
}

Write-Host "AD groups created and permissions set for all folders."
