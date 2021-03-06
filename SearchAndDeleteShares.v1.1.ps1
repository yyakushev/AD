param ([switch] $help,[string[]]$OrganisationUnit,$ComplistFile,[switch] $delete,[switch] $force)

$OUs = $OUs = Get-ADOrganizationalUnit -filter 'name -like "workst*"'`
    -SearchBase "OU=Ukraine,OU=ameria,DC=internal,DC=ameria,DC=de"`
    -SearchScope OneLevel

function HelpText (){
    $text = "
        This script search all shares in Astelit\computers organisation unit and generate files:
        <region>.txt - list of unaccessible computers
        <region>_shares.txt - list of finded shares
        
        Parameters:
        -OrganisationUnit: OU in AD\computers where are you want to search and delete shares
        -CompListFile: searche shares in list of computers from file
        -delete: searched shares will be deleted with promts
        -force:  delete all shares without promts"
    $text
    exit
}

#Define function that backups files
function BackupFiles ($compFile,$sharesFile)
{
    $ErrorActionPreference = "silentlycontinue"
        get-item $compFile | Move-Item -destination "$(($compFile.split('.'))[0]).old" -force #"$($OU.name).txt"
        get-item $sharesFile | Move-Item -destination "$(($sharesFile.split('.'))[0]).old" -force #"$($OU.name)_shares.txt"
    $ErrorActionPreference = "continue"
} #function BackupFiles
 
function GetComplistFromOU ($Unit)
{
  #Get list of OU's computers 
    $OU = $OUs|?{$_.name -like "$Unit"}
    if (!($OU)) {throw "No such OU: $unit"
    } else {Get-ADComputer -Filter * -SearchBase $OU -SearchScope OneLevel|%{$_.name}}
} #function GetComplistFromOU 

function GetComplistFromFile ($compFile)
{
    if (get-item $compFile) {
        Get-Content $compFile|%{($_.split("`t"))[0]}
    } else {throw "File $compFile don't available"}
} #function GetComplistFromFile

function SearchSharesInCompList ($complist,$compFile,$sharesFile)
{
    $shareslist = @()
    $deleted = $false
    foreach ($comp in $complist) {
  #get list of shares on remote computer
      #get current number of errors in stack
        $errors = $error.count
        $shares = gwmi win32_share -computername $comp 2>&1
        if ($error.count -gt $errors){
            $errors = $error.count
  #Generate list of inaccessible computers       
            ($comp+"`t"+$error[0].Exception.message) >>  $compFile
        } else {
            foreach ($share in $shares) {
                if (($share.type -eq 0) -and ($share.name -ne "print$")) {
  #Delete shares  
                    if ($delete) {
                        if (!($force)) {
                            write-host "Are you sure to delete share $($share.name) on $($comp)? Yes\No\All"
                            $key = $host.ui.readline() 
                            switch ($key) {
                                'y'{": share will be deleted"
                                    $deleted = $true
#                                    $share.delete()
                                    }
                                'n'{": Share $($share.name) on $($comp) wasn't deleted`n"
                                    $deleted = $false
                                    }
                                'a'{write-host -ForegroundColor red ": All shares will be deleted!"
                                    $force = $true
                                    $deleted = $true
#                                    $share.delete()
                                    }
                                default {write-host -ForegroundColor yellow "You don't choose any. Share isn't deleted."}
                            }
                        } else {
#                            $share.delete()
                        }
                    }
  #Generate list of computers whith shares  
                    $shareslist += $share|select name,path,`
                        @{name="computer";expression={$comp}},`
                        @{name="deleted";expression={if ($deleted){"Yes"}else{"No"}}},`
                        description
                    $share|select name,path,`
                        @{name="computer";expression={$comp}},`
                        @{name="deleted";expression={if ($deleted){"Yes"}else{"No"}}},`
                        description >> c:\temp\shares.txt
 
                }
            }
        }
    } #foreach ($comp in $complist)
    $shareslist|ft -auto|Out-file $sharesFile
} #function SearchSharesInCompList

if ($help) {HelpText}
if ($force) {Write-host -ForegroundColor red "All shares will be deleted!"}
if ($OrganisationUnit) {
#    write-host -ForegroundColor yellow "OU"
    foreach ($Unit in $OrganisationUnit) {
        $compslist = GetComplistFromOU $Unit
        BackupFiles "$($Unit).txt" "$($Unit)_shares.txt"
        SearchSharesInCompList $compslist "$($Unit).txt" "$($Unit)_shares.txt"
    } #foreach $unit
} else {
    if (!($ComplistFile)) {
        foreach ($OU in $OUs) {
            $compslist = GetComplistFromOU $OU
            BackupFiles "$($OU.name).txt" "$($OU.name)_shares.txt"
            SearchSharesInCompList $compslist "$($OU.name).txt" "$($OU.name)_shares.txt"
        } #foreach ($OU in $OUs)
    } #if (!($compFile))
} #if ($OrganisationUnit)

if ($ComplistFile) {
#    write-host -ForegroundColor green "Complistfile"
    $compslist = GetComplistFromFile $ComplistFile
    SearchSharesInCompList $compslist $ComplistFile "$($ComplistFile.split('.')[0])_shares.$($ComplistFile.split('.')[1])"
} #if ($compFile)