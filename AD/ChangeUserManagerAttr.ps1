#
# ChangeUserManagerAttr
#
[cmdletbinding(SupportsShouldProcess=$True)]

param (
	[ValidateScript({Test-Path $_ -PathType Leaf})]
	[string] $HRWorksCSV = 'C:\temp\Copy of 2018-03-23 Mitarbeiterliste an Service für Einspielung und Prüfung Organ.._ (002).csv',

	[string] $FirstNameHeader = 'Name',
	[string] $LastNameHeader = 'Vorname',
	[string] $ManagerHeader = 'manager',
	[string] $UserPrincipalNameHeader = 'upn'
)
function Write-ErrorEventLog ([string] $msg) {
	$WhatIfPreferenceVariable = $WhatIfPreference
	$WhatIfPreference = $false
	$t = $host.ui.RawUI.ForegroundColor
	$host.ui.RawUI.ForegroundColor = "Red"
	Write-Output $msg
	$host.ui.RawUI.ForegroundColor = $t
	$WhatIfPreference = $WhatIfPreferenceVariable
} #function write error 

function Write-InformationEventLog ([string] $msg) {
	$WhatIfPreferenceVariable = $WhatIfPreference
	$WhatIfPreference = $false
	$t = $host.ui.RawUI.ForegroundColor
	$host.ui.RawUI.ForegroundColor = "Yellow"
	Write-Output $msg
	$host.ui.RawUI.ForegroundColor = $t
	$WhatIfPreference = $WhatIfPreferenceVariable
} #function write information


$users = Import-Csv -Path $HRWorksCSV
if ($WhatIfPreference) {Write-InformationEventLog "Following users will be changed:"}
foreach ($user in $users) {
	if ($user.$UserPrincipalNameHeader) {
		$filter = "userprincipalname -eq `"$($user.$UserPrincipalNameHeader)`""
	} else {
		$filter = "displayname -like `"$($user.$FirstNameHeader)*$($user.$LastNameHeader)*`""
	}
	try {
		if ($WhatIfPreference) {
			get-aduser -Filter $filter -Properties displayname |`
			select  displayname,userprincipalname, `
					@{label='manager';expression={(get-aduser -Properties displayname -Filter "displayname -eq `"$($user.$ManagerHeader)`"" -ErrorAction SilentlyContinue).userprincipalname}}
		} else {
			if (get-aduser -Properties displayname -Filter "displayname -eq `"$($user.$ManagerHeader)`"" -ErrorAction SilentlyContinue) {
				get-aduser -Filter $filter -Properties displayname  | Set-ADUser -Manager (get-aduser -Properties displayname -Filter "displayname -eq `"$($user.$ManagerHeader)`"").DistinguishedName
				Write-InformationEventLog "Manager `"$($user.$ManagerHeader)`" has been set for user $($user.$FirstNameHeader) $($user.$LastNameHeader)"
			} else {
				get-aduser -Filter $filter -Properties displayname  | Set-ADUser -Manager $null
				Write-InformationEventLog "Manager has been set to Null for user $($user.$FirstNameHeader) $($user.$LastNameHeader)"
			}
		} 
	} catch {
			Write-ErrorEventLog "Manager has not been found for the user $($user.$FirstNameHeader) $($user.$LastNameHeader)."
	}
}

$domainusers = get-aduser -Filter * -Properties displayname
$domainusers | % {$_.userprincipalname = $_.userprincipalname.tolower()}
$ErrorActionPreference = 'SilentlyContinue'
foreach ($user in $domainusers) {
	if (!$users.$UserPrincipalNameHeader.Contains($user.UserPrincipalName.tolower())) {
		if ($WhatIfPreference) {
			$user | select  displayname,userprincipalname, `
					@{label='manager';expression={""}}
		} else {
			$user | Set-ADUser -Manager $null
			Write-InformationEventLog "Manager has been set to Null for user $($user.UserPrincipalName)"
		}
	}
}
$ErrorActionPreference = 'Continue'