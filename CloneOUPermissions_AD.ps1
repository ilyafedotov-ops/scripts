# ------------------------------------------------------------------------------
# Author: [Your Name]
# Date: [Current Date]
# Description: This script copies the Active Directory permissions (Access Control 
#              Entries) for a specific group from a source Organizational Unit (OU) 
#              to multiple target OUs. It logs the operations performed, including 
#              backing up existing ACLs and verifying the permissions after applying 
#              them to the target OUs.
# ------------------------------------------------------------------------------

# !! Before running the script, make sure you have the necessary permissions and that the Active Directory module is available in your PowerShell session. Modify the $sourceOU, $groupName, and $target

# Define the Distinguished Name (DN) of your source OU
$sourceOU = "OU=OU1,DC=contoso,DC=com"

# Specify the name of the group whose permissions you want to copy
$groupName = "YourGroupName"

# List of target OUs
$targetOUs = @("OU=OU2,DC=contoso,DC=com", "OU=OU3,DC=contoso,DC=com", "OU=OU4,DC=contoso,DC=com")

# Generate file names with current date
$currentDate = Get-Date -Format "yyyyMMdd"
$logFile = "C:\Path\To\Logs\${currentDate}_PermissionsLog.txt"

# Function to write log
Function Write-Log {
    Param ([string]$logMessage)
    Add-Content $logFile -Value "$(Get-Date) - $logMessage"
}

# Get the ACL from the source OU
$sourceAcl = Get-Acl -Path "AD:$sourceOU"

# Filter the ACEs for the specified group
$groupAces = $sourceAcl.Access | Where-Object { $_.IdentityReference -like "*$groupName" }

foreach ($targetOU in $targetOUs) {
    # Backup current ACL of the target OU
    $backupFile = "C:\Path\To\Backups\${currentDate}_BackupAcl_${targetOU -replace '[,=]',''}.xml"
    $currentAcl = Get-Acl -Path "AD:$targetOU"
    $currentAcl | Export-Clixml -Path $backupFile
    Write-Log "Backup of current ACL for $targetOU created at $backupFile"

    # Get the current ACL from the target OU
    $targetAcl = Get-Acl -Path "AD:$targetOU"

    # Add each ACE to the target OU's ACL
    foreach ($ace in $groupAces) {
        $targetAcl.AddAccessRule($ace)
        Write-Log "Added access rule for $($ace.IdentityReference) to $targetOU"
    }

    # Apply the modified ACL to the target OU
    Set-Acl -Path "AD:$targetOU" -AclObject $targetAcl
    Write-Log "ACL updated for $targetOU"

    # Optional: Verify the ACL has been applied to the target OU
    $updatedAcl = Get-Acl -Path "AD:$targetOU"
    $updatedAcl.Access | Where-Object { $_.IdentityReference -like "*$groupName" } | ForEach-Object {
        Write-Log "Verified access for $($_.IdentityReference) on $targetOU"
    }
}

# Final log entry
Write-Log "Script execution completed"
