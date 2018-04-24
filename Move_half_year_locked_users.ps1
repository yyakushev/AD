$users = get-aduser -filter * -prop LastLogonDate
$HalfYearDay = (Get-Date).AddDays(-180)
$ErrorActionPreference= 'silentlycontinue'
Foreach ($user in $users) {
	if ((($HalfYearDay - $user.LastLogonDate) -gt 0) -and !($user.enabled)){move-adobject $user -targetpath "OU=Users,OU=Archive,Dc=internal,dc=ameria,dc=de"}
}
$ErrorActionPreference= 'continue'

