#Create e-mail list of users in Crimea location
#need for update address book in M20i

if (-not $(get-module|Select-String activedirectory)) {
    Import-Module activedirectory
} 

$adusers = get-aduser -filter 'l -like "crimea"' -Properties name,mail
$list = $adusers | select @{n='First Name';e = {$_.name}},@{n='E-mail Address';e={$_.mail}} |sort "first name"
$list | Export-Csv c:\temp\address.csv -NoClobber -NoTypeInformation