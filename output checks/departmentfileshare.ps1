Invoke-Command -ComputerName srv1 -ScriptBlock {
    $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
    foreach ($folder in $folders) {
        Write-Host "`nPermissions for $folder folder:" -ForegroundColor Yellow
        (Get-Acl -Path "C:\shares\$folder").Access | Format-Table IdentityReference,FileSystemRights
    }

    Write-Host "`nPermissions for DFS root:" -ForegroundColor Yellow
    (Get-Acl -Path "C:\dfsroots\files").Access | Format-Table IdentityReference,FileSystemRights
}

<# 
PS C:\Users\Wormtongue> Invoke-Command -ComputerName srv1 -ScriptBlock {
>>     $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
>>     foreach ($folder in $folders) {
>>         Write-Host "`nPermissions for $folder folder:" -ForegroundColor Yellow
>>         (Get-Acl -Path "C:\shares\$folder").Access | Format-Table IdentityReference,FileSystemRights
>>     }
>>
>>     Write-Host "`nPermissions for DFS root:" -ForegroundColor Yellow
>>     (Get-Acl -Path "C:\dfsroots\files").Access | Format-Table IdentityReference,FileSystemRights
>> }
>>
>>

Permissions for HR folder:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_HR          ReadAndExecute, Synchronize


Permissions for IT folder:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_IT          ReadAndExecute, Synchronize


Permissions for Sales folder:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_Sales       ReadAndExecute, Synchronize


Permissions for Finance folder:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_Finance     ReadAndExecute, Synchronize


Permissions for Consultants folder:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_Consultants ReadAndExecute, Synchronize


Permissions for DFS root:

IdentityReference                 FileSystemRights
-----------------                 ----------------
NT AUTHORITY\SYSTEM                    FullControl
BUILTIN\Administrators                 FullControl
RohanIT\GG_Finance     ReadAndExecute, Synchronize
RohanIT\GG_Sales       ReadAndExecute, Synchronize
RohanIT\GG_IT          ReadAndExecute, Synchronize
RohanIT\GG_Consultants ReadAndExecute, Synchronize
RohanIT\GG_HR          ReadAndExecute, Synchronize

#>