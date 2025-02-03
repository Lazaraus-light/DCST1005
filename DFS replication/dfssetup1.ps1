$session = New-PSSession -ComputerName "DC1"

Invoke-Command -Session $session -ScriptBlock {
    Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication -IncludeManagementTools
}


Invoke-Command -Session $session -ScriptBlock {
    $basePath = "C:\DFSRoots"
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    
    # Create base directory
    New-Item -Path $basePath -ItemType Directory -Force

    # Create individual folders
    foreach ($folder in $folders) {
        New-Item -Path "$basePath\$folder" -ItemType Directory -Force
        
    }
}

Invoke-Command -Session $session -ScriptBlock {
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    foreach ($folder in $folders) {
        New-SmbShare -Name $folder -Path "C:\DFSRoots\$folder" -FullAccess "Everyone"
        # Adjust share permissions according to your security requirements
    }
}

