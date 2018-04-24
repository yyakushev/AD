# Change Access rule on folders

$path = "users forlder"
$users  = import-csv c:\users.csv
Foreach ($user in $users) {
	$permission = "AMERIA_INTERNAL\abecker","FullControl","None","None","Allow"
	$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permission
	$acl = Get-Acl $path\$($user.login) 
	$acl.SetAccessRule($accessRule)
	$acl | Set-Acl $path\$($user.login) 
}
