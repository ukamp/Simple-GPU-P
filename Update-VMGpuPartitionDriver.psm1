﻿Function Update-VMGpuPartitionDriver {
    Param (
    [string]$VMName,
    [string]$GPUName,
    [string]$Hostname = $ENV:Computername
    )

    Import-Module $PSSCriptRoot\Add-VMGpuPartitionAdapterFiles.psm1

    $VM = Get-VM -VMName $VMName
    $VHD = Get-VHD -VMId $VM.VMId

    If ($VM.state -eq "Running") {
        [bool]$state_was_running = $true
        }

    if ($VM.state -ne "Off"){
        "Attemping to shutdown VM..."
        Stop-VM -Name $VMName -Force
        }

    While ($VM.State -ne "Off") {
        Start-Sleep -s 3
        "Waiting for VM to shutdown - make sure there are no unsaved documents..."
        }

    if ($VHD -is [array]) {
        $DiskPath = $VHD.Path[0]
    } else {
        $DiskPath = $VHD.Path
    }

    "Mounting Drive..."
    $DriveLetter = (Mount-VHD -Path $DiskPath -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.DriveLetter  -and $_.FileSystemType -eq "NTFS"} | ForEach-Object DriveLetter)

    if (-Not $DriveLetter) {
        'Drive is not mounted'
        Read-Host -Prompt "Press Enter to Exit"
    }

    "Copying GPU Files - this could take a while..."
    Add-VMGPUPartitionAdapterFiles -hostname $Hostname -DriveLetter $DriveLetter -GPUName $GPUName

    "Dismounting Drive..."
    Dismount-VHD -Path $DiskPath

    If ($state_was_running){
        "Previous State was running so starting VM..."
        Start-VM $VMName
        }

    "Done..."
}
