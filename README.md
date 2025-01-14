# Dcst1005pub


#OPPGAVE 1

Første obligatorisk øving – Del 1 forts.
• Verify that DC1, MGR, SRV1 and CL1 has the following settings. (MarkDown How-to: Pre AD Install Check)
• Correct time zone
• Correct language on keyboard
• EXTRA: Try to make a small PowerShell script for later use.

To-do’s - Part 1 (Friday 10.01)
OpenStack ( skyhigh.iik.ntnu.no):

    Deploy VM’s from template (RAW Template URL).
    Get access VM’s through RDP
        Username: Admin
        Password: Found in OpenStack (retrieve password)
    Create a Github Repo for DCST1005

        Private, not visible for others
        Public, easy for studass and teacher to view and help

    Verify that DC1, MGR, SRV1 and CL1 has the following settings. (MarkDown How-to: Pre AD Install Check)

        Correct time zone
        Correct language on keyboard
            EXTRA: Try to make a small PowerShell script for later use.

To-do’s - Part 2 (Monday 13.01)
Active Directory on DC1

    Use PowerShell to install Active Directory on DC1
    Give it a suitable startup Domain Name.
        NB! When AD is installed, you need to change login credentials when you want to RDP into that machine with an Domain Administrator.
        Create your own domain admin user (adm_<yourUserName>). Username can be whatever you like, but make one that you remember.
            Add user to Domain Admins group

Configure VM’s and join domain

    SRV1, CLI1 and MGR needs to join the domain for proper administration and management. Make sure they are configured as needed and joined the domain (configure DNS). Use newly created adm user to authenticate for the domain join.

Configure MGR: - Make sure to login to the MGR with your adm_<username> user account.

    Install Chocolatey, PowerShell 7, Git and VS Code (with PowerShell extension). Make sure that it is possible to run PSRemote from MGR against all machines in the domain. Both PowerShell 5.1 and 7.x. NB! You need to be logged in as a doman admin on MGR.
    Install RSAT on MGR (Remote Server Administrative Tools)

Install software on doman computers

    Use MGR to remote install PowerShell 7 on all domain computers and domain controller.


What should the assignment delivery look like
Show TA the following:

    VM's up and running in OpenStack
    Show remote desktop login to MGR with a domain admin.
    List all machines that are members of the domain
    List all domain users.


*********************************************



