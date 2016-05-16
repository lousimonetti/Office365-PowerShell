# Assigns a Role to an MSOL Portal User 

$GLOBAL:currentMFAVersion = 8808;
Function Begin-MSOLAssignmentViaScript
{
<#
.SYNOPSIS

Assigns a Role to an MSOL Portal User

.DESCRIPTION

The Login-MSOLServices will check to see if you are already logged in. If not, it will establish the authentication token and connect you to the MSOL Services. 
Then the Get-TargetMSOLRole function will get the role for the corresponding keyword parameter. Lastly, the Assign-RoleForMSOLUser function will assign role to the target user.

.PARAMETER RoleName 

Full name of Role, i.e., "Helpdesk Administrator".

.PARAMETER UserPrincipalName

The user principal name, i.e., UserId@Domain.com.


.NOTES

You need to run this function as a member of the Service Admins roles in the O365 vNEXT Portal; Also you need the MSOnline modules that allow MFA auth. 
Download from here: http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185

Author: Louis Simonetti
Date: 5-16-2016

#>
    param($userPrincipalName="empty", [string]$roleName="empty")
    if($userPrincipalName -eq "empty")
   {
        $userPrincipalName = Read-host "Enter a valid UPN (UserId@Domain.com)"
    }
        Login-MSOLServices;
        $role = $null; 
        if($roleName -eq "empty")
        {
            $role = Get-TargetMSOLRole;
        }
        else 
        {
            $role = Get-MsolRole -RoleName $roleName;
        }
        Assign-RoleForMSOLUser -role $role -userPrincipalName $userPrincipalName
    
}
function Inform-UserToUpgrade
{
    write-host "Please go to http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185 to get the Module that supports MFA" -ForegroundColor Yellow

    Read-host "Press enter to exit..." 
    
}
Function Login-MSOLServices
{
    $versionInfo=(get-item C:\Windows\System32\WindowsPowerShell\v1.0\Modules\MSOnline\Microsoft.Online.Administration.Automation.PSModule.dll).VersionInfo.FileVersion -split "\."
    if($versionInfo[0] -lt 1 -or ($versionInfo[0] -eq 1 -and $versionInfo[2] -lt $GLOBAL:currentMFAVersion)){
        Inform-UserToUpgrade
        break;
    }
    else{
        Import-Module MSOnline -ErrorAction SilentlyContinue
        Get-MsolDomain -ErrorAction SilentlyContinue | Out-Null
        if($?)
        {
            return "connected"
        }
            else
        {
            Connect-MsolService
        }
    }
    
}

function Get-TargetMSOLRole
{
    $caption = "Select a MSOL User Role Assignment" 
    $message = "Which MSOL Role assignment would you like to select?"
    $roles = Get-MsolRole
    $ChoiceDescriptions = $null
    $resulthash = @{}
     for ($i = 0; $i -lt $roles.count; $i++)
    {
        $name = $roles[$i]|select -expand Name    
        $ChoiceDescriptions += @(New-Object System.Management.Automation.Host.ChoiceDescription ("&" + $name))
        $resulthash.$i = $name
    }
    $AllChoices = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceDescriptions)
    $result = $Host.UI.PromptForChoice($Caption,$Message, $AllChoices, 0)
    $resulthash.$result -replace "&", ""

    return $roles|?{$_.name -eq $resulthash.$result}
    
}

Function Assign-RoleForMSOLUser
{
    param ($role, $userPrincipalName)
    Add-MsolRoleMember -RoleObjectId $role.Objectid -RoleMemberEmailAddress $userPrincipalName -ErrorAction SilentlyContinue
    if($?)
    {
        Write-Host "USer: $userPrincipalName added" -ForegroundColor Green
        Get-MsolRoleMember -RoleObjectId $role.ObjectId
    }
    else
    {
        Write-Host "USer: $userPrincipalName was either already added or does not exist" -ForegroundColor Yellow
    }
}


Begin-MSOLAssignmentViaScript

