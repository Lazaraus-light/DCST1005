Import-Module ActiveDirectory

# 1. Set your domain DN
$DomainDN = "DC=RohanIT,DC=sec"

# 2. Function to create OU if it doesn't exist
function New-MyOU {
    param(
        [string]$Name,
        [string]$ParentDN
    )
    $checkOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $ParentDN -ErrorAction SilentlyContinue
    if (-not $checkOU) {
        try {
            New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ErrorAction Stop | Out-Null
            Write-Host "Created OU: $Name in $ParentDN"
        }
        catch {
            Write-Warning "Failed to create OU: $Name. $_"
        }
    }
    else {
        Write-Host "OU '$Name' already exists under $ParentDN. Skipping."
    }
}

# 3. Function to create random password
function New-RandomPassword {
    param([int]$length = 12)
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# --- CREATE THE OU STRUCTURE ---

# 4. Create top-level OUs
New-MyOU -Name "RohanIT_Users" -ParentDN $DomainDN
New-MyOU -Name "RohanIT_Computers" -ParentDN $DomainDN
New-MyOU -Name "RohanIT_Groups" -ParentDN $DomainDN

# Sub-OUs: RohanIT_Users
$usersOU = "OU=RohanIT_Users,$DomainDN"
New-MyOU -Name "Finance" -ParentDN $usersOU
New-MyOU -Name "Sales" -ParentDN $usersOU
New-MyOU -Name "IT" -ParentDN $usersOU
New-MyOU -Name "Consultants" -ParentDN $usersOU
New-MyOU -Name "HR" -ParentDN $usersOU

# Sub-OUs: RohanIT_Computers
$computersOU = "OU=RohanIT_Computers,$DomainDN"
New-MyOU -Name "Workstations" -ParentDN $computersOU
New-MyOU -Name "Servers" -ParentDN $computersOU

$workstationsOU = "OU=Workstations,$computersOU"
New-MyOU -Name "Finance" -ParentDN $workstationsOU
New-MyOU -Name "Sales" -ParentDN $workstationsOU
New-MyOU -Name "IT" -ParentDN $workstationsOU
New-MyOU -Name "Consultants" -ParentDN $workstationsOU
New-MyOU -Name "HR" -ParentDN $workstationsOU

# Sub-OUs: RohanIT_Groups
$groupsOU = "OU=RohanIT_Groups,$DomainDN"
New-MyOU -Name "Global" -ParentDN $groupsOU
New-MyOU -Name "Local" -ParentDN $groupsOU

# --- CREATE GLOBAL GROUPS FOR DEPARTMENTS ---
$globalOU = "OU=Global,$groupsOU"
$departments = @("Finance","Sales","IT","Consultants","HR")

foreach ($dept in $departments) {
    $groupName = "GG_$dept"
    $exists = Get-ADGroup -Filter "Name -eq '$groupName'" -SearchBase $globalOU -ErrorAction SilentlyContinue
    if (-not $exists) {
        try {
            New-ADGroup -Name $groupName -GroupScope Global -Path $globalOU -SamAccountName $groupName
            Write-Host "Created Global Group: $groupName"
        }
        catch {
            Write-Warning "Failed to create group $groupName. $_"
        }
    }
    else {
        Write-Host "Group '$groupName' already exists. Skipping."
    }
}

# --- CREATE USERS & ADD TO GROUPS ---

# Example distribution: 
# Finance: 2 users, HR: 1 user, Sales: 2 users, IT: 2 users, Consultants: 9 users
$usersToCreate = @(
    # Finance (1)
    @{ Department="Finance"; FirstName="Bob";  LastName="Olsen" },
    
    
    # HR (1)
    @{ Department="HR"; FirstName="Harry"; LastName="Hope" },
    
    # Sales (2)
    @{ Department="Sales"; FirstName="Sally";  LastName="Amberlamps" },
    @{ Department="Sales"; FirstName="Sam";    LastName="Brannmann" },
    
    # IT (2)
    @{ Department="IT"; FirstName="Kåre";    LastName="Monsen" },
    @{ Department="IT"; FirstName="Iris";   LastName="Elaiassen" },
    
    # Consultants (9)
    @{ Department="Consultants"; FirstName="Vilfred"; LastName="Williassen" },
    @{ Department="Consultants"; FirstName="May"; LastName="Karstensen" },
    @{ Department="Consultants"; FirstName="Mons"; LastName="Andersen" },
    @{ Department="Consultants"; FirstName="Anders"; LastName="Monsen" },
    @{ Department="Consultants"; FirstName="Ali"; LastName="Muhammed" },
    @{ Department="Consultants"; FirstName="Kristian"; LastName="Kristoffersen" },
    @{ Department="Consultants"; FirstName="Nicolai"; LastName="Stiansen" },
    @{ Department="Consultants"; FirstName="Marita"; LastName="Bruun" },
    @{ Department="Consultants"; FirstName="Ellie"; LastName="Eiliassen" }
)

foreach ($u in $usersToCreate) {
    $dept      = $u.Department
    $fn        = $u.FirstName
    $ln        = $u.LastName
    $fullName  = "$fn $ln"
    # SamAccountName: e.g. "jfin1", "sfin2", etc.
    $sam       = ($fn.Substring(0,1) + $ln).ToLower()
    $upn       = $sam + "@" + ($DomainDN.Replace("DC=", "").Replace(",", "."))
    $userOU    = "OU=$dept,OU=RohanIT_Users,$DomainDN"
    $password  = New-RandomPassword -length 12
    
    # Create user if doesn't exist
    $checkUser = Get-ADUser -Filter "SamAccountName -eq '$sam'" -SearchBase $userOU -ErrorAction SilentlyContinue
    if (-not $checkUser) {
        try {
            New-ADUser -Name $fullName `
                       -SamAccountName $sam `
                       -UserPrincipalName $upn `
                       -Path $userOU `
                       -GivenName $fn `
                       -Surname $ln `
                       -Department $dept `
                       -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                       -ChangePasswordAtLogon $true `
                       -Enabled $true

            Write-Host "Created user: $fullName (SAM=$sam) in $dept. Password=$password"

            # Add user to the correct Global Group
            $groupName = "GG_$dept"
            Add-ADGroupMember -Identity $groupName -Members $sam
            Write-Host "  Added $fullName to $groupName."
        }
        catch {
            Write-Warning "Error creating user $fullName. $_"
        }
    }
    else {
        Write-Host "User $sam already exists in OU=$dept. Skipping."
    }
}

Write-Host "`nDone creating OUs, groups, and users in RohanIT.sec domain."





<# This instance created users; Created user: Bob Olsen (SAM=bolsen) in Finance. Password=CF&TXrJSPJ%m
  Added Bob Olsen to GG_Finance.
  Created user: Harry Hope (SAM=hhope) in HR. Password=Test1234*
    Added Harry Hope to GG_HR.
  Created user: Sally Amberlamps (SAM=samberlamps) in Sales. Password=#G6AiBWvKdL#
    Added Sally Amberlamps to GG_Sales.
  Created user: Sam Brannmann (SAM=sbrannmann) in Sales. Password=4ibXzHoEgSpT
    Added Sam Brannmann to GG_Sales.
  Created user: Kåre Monsen (SAM=kmonsen) in IT. Password=fXLDR!y!a8M7
    Added Kåre Monsen to GG_IT.
  Created user: Iris Elaiassen (SAM=ielaiassen) in IT. Password=XBtY$%6$3A&g
    Added Iris Elaiassen to GG_IT.
  Created user: Vilfred Williassen (SAM=vwilliassen) in Consultants. Password=)yTowvb%y$yX
    Added Vilfred Williassen to GG_Consultants.
  Created user: May Karstensen (SAM=mkarstensen) in Consultants. Password=)#Ht@dunTB2X
    Added May Karstensen to GG_Consultants.
  Created user: Mons Andersen (SAM=mandersen) in Consultants. Password=Gp6ydyD)y)yx
    Added Mons Andersen to GG_Consultants.
  Created user: Anders Monsen (SAM=amonsen) in Consultants. Password=vbL*cj7A^HGy
    Added Anders Monsen to GG_Consultants.
  Created user: Ali Muhammed (SAM=amuhammed) in Consultants. Password=ThXb(JJySU^N
    Added Ali Muhammed to GG_Consultants.
  Created user: Kristian Kristoffersen (SAM=kkristoffersen) in Consultants. Password=UGHy6nDiJjnf
    Added Kristian Kristoffersen to GG_Consultants.
  Created user: Nicolai Stiansen (SAM=nstiansen) in Consultants. Password=*Pwz3U)X(4pF
    Added Nicolai Stiansen to GG_Consultants.
  Created user: Marita Bruun (SAM=mbruun) in Consultants. Password=ngHxu3C3mWKV
    Added Marita Bruun to GG_Consultants.
  Created user: Ellie Eiliassen (SAM=eeiliassen) in Consultants. Password=fh3o1jS5pjDq
    Added Ellie Eiliassen to GG_Consultants.
#> 