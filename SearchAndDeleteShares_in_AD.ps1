param ([switch] $help,[string[]]$OrganisationUnit,[switch] $delete,[switch] $force)

$OUs = Get-ADOrganizationalUnit -filter 'name -like "workst*"'`
    -SearchBase "OU=Ukraine,OU=ameria,DC=internal,DC=ameria,DC=de"`
    -SearchScope OneLevel

function HelpText (){
    $text = "
        This script search all shares in Astelit\computers organisation unit and generate files:
        <region>.txt - list of unaccessible computers
        <region>_shares.txt - list of finded shares
        
        Parameters:
        -OrganisationUnit: OU in AD\computers where are you want to search and delete shares
        -delete: searched shares will be deleted with promts
        -force:  delete all shares without promts"
    $text
    exit
}

#Define function that search and delete shares on remote computers
function SearchShares ($OU)
{
    $ErrorActionPreference = "silentlycontinue"
        get-item "$($OU.name).txt" | Move-Item -destination "$($OU.name).old" -force 
        get-item "$($OU.name)_shares.txt" | Move-Item -destination "$($OU.name)_shares.old" -force
    $ErrorActionPreference = "continue"
  #Get list of OU's computers 
    $complist = Get-ADComputer -Filter * -SearchBase $OU -SearchScope OneLevel
  
  #get current number of errors in stack
    $errors = $error.count
    $shareslist = @()
    $deleted = $false
    
    foreach ($comp in $complist) {
  #get list of shares on remote computer
        $shares = gwmi win32_share -computername $comp.name 2>&1
        if ($error.count -gt $errors){
            $errors = $error.count
  #Generate list of inaccessible computers       
            ($comp.name+"`t"+$error[0].Exception.message) >> "$($OU.name).txt"
        } else {
            foreach ($share in $shares) {
                if (($share.type -eq 0) -and ($share.name -ne "print$")) {
  #Delete shares  
                    if ($delete) {
                        if (!($force)) {
                            write-host "Are you sure to delete share $($share.name) on $($comp.name)? Yes\No\All"
                            $key = $host.ui.readline() 
                            switch ($key) {
                                'y'{": share will be deleted"
                                    $deleted = $true
                                    $share.delete()
                                    }
                                'n'{": Share $($share.name) on $($comp.name) wasn't deleted`n"
                                    $deleted = $false
                                    }
                                'a'{write-host -ForegroundColor red ": All shares will be deleted!"
                                    $force = $true
                                    $deleted = $true
                                    $share.delete()
                                    }
                                default {write-host -ForegroundColor yellow "You don't choose any. Share isn't deleted."}
                            }
                        } else {
                            $share.delete()
                        }
                    }
  #Generate list of computers whith shares  
                    $shareslist += $share|select name,path,`
                        @{name="computer";expression={$comp.name}},`
                        @{name="deleted";expression={if ($deleted){"Yes"}else{"No"}}},`
                        description
                }
            }
        }
    }
    $shareslist|ft -auto|Out-file "$($OU.name)_shares.txt"
}

if ($help) {HelpText}
if ($force) {Write-host -ForegroundColor red "All shares will be deleted!"}
if ($OrganisationUnit) {
    foreach ($unit in $OrganisationUnit) {
        $OU = $OUs|?{$_.name -like "$Unit"}
        if ($OU)  {SearchShares $OU} else {Write-host "No such OU: $unit"}
    }
} else {
    foreach ($OU in $OUs) {SearchShares $OU}
}