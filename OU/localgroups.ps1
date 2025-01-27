# ===============================
# 1) CREATE DFS FOLDERS (LINKS)
# ===============================
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Create DFS folders for each department
    $departments = @('Finance','Sales','IT','Consultants','HR')
    foreach ($dept in $departments) {
        # This will create a DFS link under the existing DFS root \\RohanIT.sec\files
        New-DfsnFolder -Path "\\RohanIT.sec\files\$dept" `
                       -TargetPath "\\srv1\$dept" `
                       -EnableTargetFailback $true
    }
}

# ===============================
# 2) VERIFY DFS NAMESPACE CONFIG
# ===============================
Invoke-Command -ComputerName srv1 -ScriptBlock {
    Write-Host "Verifying DFS root..."
    Get-DfsnRoot -Path "\\RohanIT.sec\files"

    Write-Host "`nVerifying DFS folders..."
    Get-DfsnFolder -Path "\\RohanIT.sec\files\*" | 
        Format-Table Path,TargetPath,State -AutoSize
}

# ===============================
# 3) CREATE REQUIRED AD GROUPS
# ===============================
# Import the AD module locally (ensure RSAT AD tools are installed)
Import-Module ActiveDirectory

# Define the OU path (adjust to your AD)
$OUPath = "OU=Groups,DC=RohanIT,DC=sec"

# List of local groups to create
$localGroups = @(
    "l_fullAccess-hr-share",
    "l_fullAccess-it-share",
    "l_fullAccess-sales-share",
    "l_fullAccess-finance-share",
    "l_fullAccess-consultants-share"
)

foreach ($lg in $localGroups) {
    # Check if group already exists
    $groupExists = Get-ADGroup -Filter "Name -eq '$lg'" -ErrorAction SilentlyContinue
    if (-not $groupExists) {
        Write-Host "Creating AD local group: $lg"
        New-ADGroup -Name $lg `
                    -Path $OUPath `
                    -GroupScope DomainLocal `
                    -GroupCategory Security `
                    -SamAccountName $lg `
                    -Description "Full access local group for $lg"
    }
    else {
        Write-Host "Group '$lg' already exists. Skipping creation."
    }
}

# ============================================
# 4) ADD GLOBAL GROUPS AS MEMBERS TO LOCAL
# ============================================
# Mapping: local group -> matching global group
# (Assumes your global groups follow the pattern g_all_<dept>)
$groupMapping = @{
    'l_fullAccess-hr-share'          = 'g_all_hr'
    'l_fullAccess-it-share'          = 'g_all_it'
    'l_fullAccess-sales-share'       = 'g_all_sales'
    'l_fullAccess-finance-share'     = 'g_all_finance'
    'l_fullAccess-consultants-share' = 'g_all_consultants'
}

foreach ($localGroup in $groupMapping.Keys) {
    $globalGroup = $groupMapping[$localGroup]
    
    # Verify both groups exist
    $lgObject = Get-ADGroup -Filter "Name -eq '$localGroup'" -ErrorAction SilentlyContinue
    $ggObject = Get-ADGroup -Filter "Name -eq '$globalGroup'" -ErrorAction SilentlyContinue
    
    if ($lgObject -and $ggObject) {
        Write-Host "`nAdding $globalGroup to $localGroup..."
        try {
            Add-ADGroupMember -Identity $localGroup -Members $globalGroup -ErrorAction Stop
            Write-Host "Successfully added $globalGroup to $localGroup."
        }
        catch {
            Write-Warning "Could not add $globalGroup to $localGroup. `nError: $_"
        }
    }
    else {
        Write-Warning "Either $localGroup or $globalGroup does not exist in AD. Check naming and OU paths."
    }
}

# ======================================
# 5) CONFIGURE NTFS PERMISSIONS
# ======================================
Invoke-Command -ComputerName srv1 -ScriptBlock {
    # Map each folder to its domain local group
    $folderPermissions = @{
        'HR'           = 'l_fullAccess-hr-share'
        'IT'           = 'l_fullAccess-it-share'
        'Sales'        = 'l_fullAccess-sales-share'
        'Finance'      = 'l_fullAccess-finance-share'
        'Consultants'  = 'l_fullAccess-consultants-share'
    }

    foreach ($folder in $folderPermissions.Keys) {
        $path = "C:\shares\$folder"
        $group = $folderPermissions[$folder]

        Write-Host "`nConfiguring NTFS permissions on $path..."
        
        # Create a new, "clean" ACL (removing inheritance)
        $acl = New-Object System.Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance, remove inherited perms

        # Build and add required rules
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Administrators",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "NT AUTHORITY\SYSTEM",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $groupRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $group,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        [void]$acl.AddAccessRule($adminRule)
        [void]$acl.AddAccessRule($systemRule)
        [void]$acl.AddAccessRule($groupRule)

        # Apply new ACL to the folder
        Set-Acl -Path $path -AclObject $acl
        Write-Host "NTFS Permissions set for $folder"
    }

    # Also configure the DFS root folder (C:\dfsroots\files)
    Write-Host "`nConfiguring NTFS permissions on DFS root (C:\dfsroots\files)..."
    $dfsPath = "C:\dfsroots\files"
    $dfsAcl = New-Object System.Security.AccessControl.DirectorySecurity
    $dfsAcl.SetAccessRuleProtection($true, $false)

    # Re-use the base rules
    $dfsAcl.AddAccessRule($adminRule)
    $dfsAcl.AddAccessRule($systemRule)

    # Grant full control to all dept local groups
    foreach ($deptGroup in $folderPermissions.Values) {
        $deptRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $deptGroup,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        [void]$dfsAcl.AddAccessRule($deptRule)
    }

    Set-Acl -Path $dfsPath -AclObject $dfsAcl
    Write-Host "NTFS Permissions set for DFS root."
}

# ====================================
# 6) VERIFY NTFS PERMISSIONS
# ====================================
Invoke-Command -ComputerName srv1 -ScriptBlock {
    $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
    foreach ($folder in $folders) {
        Write-Host "`nPermissions for $folder folder:" -ForegroundColor Yellow
        (Get-Acl -Path "C:\shares\$folder").Access | 
            Select-Object IdentityReference, FileSystemRights
    }

    Write-Host "`nPermissions for DFS root (C:\dfsroots\files):" -ForegroundColor Yellow
    (Get-Acl -Path "C:\dfsroots\files").Access |
        Select-Object IdentityReference, FileSystemRights
}

Write-Host "`nAll steps completed. DFS links, AD groups, membership, and NTFS permissions have been configured."
