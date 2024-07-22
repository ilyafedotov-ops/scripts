# Import the Azure module
Import-Module Az

# List of VMs to process
$vmList = @("VM1", "VM2", "VM3") # Replace with your VM names

# Name for the temporary VM
$tempVMName = "TempVM-CrowdStrikeRemoval"

# Resource Group name (assuming all VMs are in the same resource group)
$resourceGroupName = "YourResourceGroupName" # Replace with your resource group name

# Create the temporary VM
New-AzVM -ResourceGroupName $resourceGroupName -Name $tempVMName -Location "EastUS" -Image "Win2019Datacenter" -Size "Standard_D2s_v3"

foreach ($vmName in $vmList) {
    # Get the VM
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

    # Create a snapshot of the OS disk
    $snapshotConfig = New-AzSnapshotConfig -Location $vm.Location -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -CreateOption Copy
    $snapshotName = "$vmName-OSDisk-Snapshot-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig

    # Stop the VM
    Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force

    # Get the OS disk
    $disk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name

    # Detach the OS disk from the original VM
    Remove-AzVMDataDisk -VM $vm -DataDiskNames $disk.Name
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm

    # Attach the disk to the temporary VM
    $tempVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name $tempVMName
    Add-AzVMDataDisk -VM $tempVM -Name $disk.Name -CreateOption Attach -ManagedDiskId $disk.Id -Lun 0
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $tempVM

    # Use Azure VM Run Command to remove the CrowdStrike file
    $script = @"
    `$attachedDisk = Get-Disk | Where-Object { `$_.FriendlyName -eq '$($disk.Name)' }
    `$driveLetter = (`$attachedDisk | Get-Partition | Get-Volume).DriveLetter
    Remove-Item -Path "`${driveLetter}:\Windows\System32\Drivers\CrowdStrike\C000000291*.sys" -Force
"@

    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $tempVMName -CommandId 'RunPowerShellScript' -ScriptString $script

    # Detach the disk from the temporary VM
    Remove-AzVMDataDisk -VM $tempVM -DataDiskNames $disk.Name
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $tempVM

    # Reattach the disk to the original VM
    Set-AzVMOsDisk -VM $vm -ManagedDiskId $disk.Id -Name $disk.Name
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm

    # Start the original VM
    Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
}

# Clean up: Delete the temporary VM
Remove-AzVM -ResourceGroupName $resourceGroupName -Name $tempVMName -Force
