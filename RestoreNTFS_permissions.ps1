# ------------------------------------------------------------------------------
# Author: Ilya Fedotov
# Date: 20.08.2024
# Description: This script restores NTFS permissions for file paths based on 
#              data imported from a CSV file. The CSV file should contain 
#              the paths and their associated permissions. The script reads 
#              the CSV, groups permissions by path, and then applies those 
#              permissions to the corresponding paths.
# ------------------------------------------------------------------------------

# Restore NTFS Permissions Script

# Set the input file path
$inputFile = "C:\NTFSPermissions_Backup.csv"

# Import the CSV file
$permissions = Import-Csv -Path $inputFile

# Group permissions by path
$groupedPermissions = $permissions | Group-Object -Property Path

# Function to set NTFS permissions
function Set-NTFSPermissions {
    param (
        [string]$path,
        [array]$perms
    )
    
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)

    foreach ($perm in $perms) {
        $identity = $perm.IdentityReference
        $rights = [System.Security.AccessControl.FileSystemRights]$perm.FileSystemRights
        $type = [System.Security.AccessControl.AccessControlType]$perm.AccessControlType
        $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]$perm.InheritanceFlags
        $propagationFlags = [System.Security.AccessControl.PropagationFlags]$perm.PropagationFlags

        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $rights, $inheritanceFlags, $propagationFlags, $type)
        $acl.AddAccessRule($rule)
    }

    Set-Acl -Path $path -AclObject $acl
}

# Restore permissions for each path
foreach ($group in $groupedPermissions) {
    $path = $group.Name
    $perms = $group.Group

    if (Test-Path -Path $path) {
        Set-NTFSPermissions -path $path -perms $perms
        Write-Host "Restored permissions for: $path"
    } else {
        Write-Host "Path not found, skipping: $path" -ForegroundColor Yellow
    }
}

Write-Host "NTFS permissions restoration completed."
