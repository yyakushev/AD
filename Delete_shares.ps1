
param ($OrganisationUnit,[switch] $delete)

#get list of OUs domain computers
$OUs = Get-ADOrganizationalUnit -filter *  `
    -SearchBase "OU=Computers,OU=ASTELIT,DC=astelit,DC=ukr"`
    -SearchScope OneLevel

$OU = $OUs|?{$_.name -like " *$OrganisationUnit*"}
 
$complist = Get-ADComputer -Filter * -SearchBase $OU -SearchScope OneLevel                                                       

$errors = $error.count

Foreach ($comp in $complist) {
#get list of shares on remote computer
    $shares = gwmi win32_share -computername $comp.name
    if ($error.count -gt $errors){
       $errors = $error.count
#Generate list of inaccessible computers       
       $comp.name >> "$($OU.name).txt"
    } else {
        foreach ($share in $shares) {
            if ($share.type -eq 0) {
#Generate list of computers where shares will be deleted 
                $share|select name,path,description,@{name="computer";expression={$comp.name}}|`
                    ft -HideTableHeaders >> "$($OU.name)_deleted.txt"
#Uncomment next string to delete shares
#                $share.delete()
            }
        }
    }  
}


