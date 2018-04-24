$path = 'C:\DfsRoots\Daten\Vertrauliche Daten\Alice Becker'
$ADUser = 'AMERIA_INTERNAL\abecker'

$permission = $ADUser,"FullControl","None","None","Allow"
$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permission

ls -Path $path | ?{$_.mode -like "d----" } | ls -recurse |%{
	$acl = get-acl $_.fullname
	$acl.AddAccessRule($accessRule)
	$acl | set-acl $_.fullname
}
