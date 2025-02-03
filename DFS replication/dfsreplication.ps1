# Check if DFSN module is installed
Get-Module -ListAvailable -Name DFSN

# Check if DFSR module is installed
Get-Module -ListAvailable -Name DFSR

# If not installed, install the modules (requires admin privileges)
Add-WindowsFeature -Name RSAT-DFS-Mgmt-Con


# Create a new replication group
New-DfsReplicationGroup -GroupName "FileServerGroup" -Description "Replication between SRV1 and DC1"


# Add both servers to the replication group
Add-DfsrMember -GroupName "FileServerGroup" -ComputerName "SRV1"
Add-DfsrMember -GroupName "FileServerGroup" -ComputerName "DC1"


# Create replication folders for each shared directory
$folders = @("finance", "sales", "hr", "it", "consultants")

foreach ($folder in $folders) {
    # Create the replicated folder
    New-DfsReplicatedFolder -GroupName "FileServerGroup" `
        -FolderName $folder `
        -DfsnPath "\\rohanit\files\$folder"

    # Set up replication members for the folder
    Set-DfsrMembership -GroupName "FileServerGroup" `
        -FolderName $folder `
        -ContentPath "c:\shares\$folder" `
        -ComputerName "SRV1" `
        -PrimaryMember $true

    Set-DfsrMembership -GroupName "FileServerGroup" `
        -FolderName $folder `
        -ContentPath "c:\dfsroots\$folder" `
        -ComputerName "DC1" `
        -PrimaryMember $false
}


# Set up bidirectional replication between servers
Add-DfsrConnection -GroupName "FileServerGroup" `
    -SourceComputerName "SRV1" `
    -DestinationComputerName "DC1"


    # Check replication group status
Get-DfsReplicationGroup -GroupName "FileServerGroup" | Format-List

# Check connection status
Get-DfsrConnection -GroupName "FileServerGroup"

# Check folder configuration
Get-DfsReplicatedFolder -GroupName "FileServerGroup"



# View replication backlog
Get-DfsrBacklog -GroupName "FileServerGroup" `
    -SourceComputerName "SRV1" `
    -DestinationComputerName "DC1" `
    -FolderName "finance"

# Check replication health
Write-DfsrHealth -SourceComputerName "SRV1" -DestinationComputerName "DC1"



# Reset replication if needed
Update-DfsrConfigurationFromAD -ComputerName "SRV1"
Update-DfsrConfigurationFromAD -ComputerName "DC1"

# Check DFS service status
Get-Service DFSR -ComputerName "SRV1"
Get-Service DFSR -ComputerName "DC1"



Get-Help *dfsr*
Get-Help Add-DfsrConnection -Detailed



