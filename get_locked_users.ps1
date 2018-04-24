$users = get-aduser -filter * -prop LastLogonDate
$ErrorActionPreference= 'silentlycontinue'

$UsersToDisable = @()
Foreach ($user in $users) {
	if (!($user.enabled)){
		$UsersToDisable += $user
	}
}
#Lock users in Lync
$UsersToDisable | %{get-csuser $_.name| Disable-CsUser}

$ErrorActionPreference= 'continue'

