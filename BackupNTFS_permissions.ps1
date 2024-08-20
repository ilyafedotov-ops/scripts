# ------------------------------------------------------------------------------
# Author: Ilya Fedotov
# Date: 20.08.2024
# Description: This script backs up NTFS permissions for all files and directories
#              within a specified path. It retrieves permissions such as identity
#              references, file system rights, access control types, inheritance, 
#              and propagation flags, and exports this information to a CSV file.
# ------------------------------------------------------------------------------

# Backup NTFS Permissions Script

# Set the path to backup
$sourcePath = "C:\Shared"

# Set the output file path
$outputFile = "C:\temp\NTFSPermissions_Backup.csv"

# Function to get NTFS permissions
function Get-NTFSPermissions {
    param (
        [string]$path
    )
    
    $acl = Get-Acl -Path $path
    $permissions = $acl.Access | ForEach-Object {
        [PSCustomObject]@{
            Path = $path
            IdentityReference = $_.IdentityReference
            FileSystemRights = $_.FileSystemRights
            AccessControlType = $_.AccessControlType
            IsInherited = $_.IsInherited
            InheritanceFlags = $_.InheritanceFlags
            PropagationFlags = $_.PropagationFlags
        }
    }
    return $permissions
}

# Get all folders and files
$items = Get-ChildItem -Path $sourcePath -Recurse -Force | Select-Object -ExpandProperty FullName
$items = @($sourcePath) + $items

# Get permissions for all items and export to CSV
$allPermissions = @()
foreach ($item in $items) {
    $allPermissions += Get-NTFSPermissions -path $item
}

$allPermissions | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "NTFS permissions have been backed up to $outputFile"
