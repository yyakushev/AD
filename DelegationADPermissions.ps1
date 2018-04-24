Import-Module ActiveDirectory
#Bring up an Active Directory command prompt so we can use this later on in the script
cd ad:
#Get a reference to the RootDSE of the current domain
$rootdse = Get-ADRootDSE
#Get a reference to the current domain
$domain = Get-ADDomain

#Create a hashtable to store the GUID value of each schema class and attribute
$guidmap = @{}
Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter `
"(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID | 
% {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID}

#Create a hashtable to store the GUID value of each extended right in the forest
$extendedrightsmap = @{}
Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
"(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName,rightsGuid | 
% {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}

#Get a reference to the OU we want to delegate
$ou = Get-ADOrganizationalUnit -Identity ("OU=Contoso Users,"+$domain.DistinguishedName)
#Get the SID values of each group we wish to delegate access to
$p = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Provisioning Admins").SID
$s = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup "Contoso Service Desk").SID
#Get a copy of the current DACL on the OU
$acl = Get-ACL -Path ($ou.DistinguishedName)
#Create an Access Control Entry for new permission we wish to add
#Allow the group to write all properties of descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"WriteProperty","Allow","Descendents",$guidmap["user"]))
#Allow the group to create and delete user objects in the OU and all sub-OUs that may get created
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"CreateChild,DeleteChild","Allow",$guidmap["user"],"All"))
#Allow the group to reset user passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$p,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$guidmap["user"]))
#Allow the Service Desk group to also reset passwords on all descendent user objects
$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
$s,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$guidmap["user"]))
#Re-apply the modified DACL to the OU
Set-ACL -ACLObject $acl -Path ("AD:\"+($ou.DistinguishedName))