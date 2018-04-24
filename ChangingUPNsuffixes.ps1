#####################################
#                                   #
# ITVT internal project             #
#                                   #
# Preparation steps for Office365   #
#                                   #
# Author: Yaroslav Yakushev         #
#                                   #
#####################################

Param(

  [Parameter(Mandatory=$false)]
  [string] $basescope = "OU=ITVT GmbH\, Stuttgart\, Germany,DC=itvt-intern,DC=de",

  [Parameter(Mandatory=$false)]
  [string] $filterPattern = 'SamAccountName -like "*"',

  [Parameter(Mandatory=$True)]
  [bool]   $WhatIfEnabled = $true

)

$logfile = "$((get-location).path)\UPNChangeLog_$((get-date).Ticks).csv"

#get list of users that have email addresses
$users = get-aduser -SearchBase $basescope -filter $filterPattern -prop * #|?{$_.emailaddress -is [string]}

"SamAccountname;emailaddress;OldUserPrincipalName;NewUserPrincipalName;Result;" | out-file $logfile

#set UserPrincipalName the same as emailaddress
foreach ($user in $users) {
    
    if ($user.UserPrincipalName -notlike $user.emailaddress) {
    
        try {
            
            if ($user.emailaddress -is [string]) {
                set-aduser -identity $user.SamAccountName -UserPrincipalName $user.emailaddress -WhatIf:$WhatIfEnabled 
                "$($user.samaccountname);$($user.emailaddress);$($user.UserPrincipalName);$($user.emailaddress);$(if (!($WhatIfEnabled)) {"UserPrincipalName has been set to $($user.emailaddress) for user"}else{"UserPrincipalName will be set to $($user.emailaddress) for user"});" | out-file $logfile -Append
            } else {
                set-aduser -identity $user.SamAccountName -UserPrincipalName "$($user.SamAccountName)@itvt.de" -WhatIf:$WhatIfEnabled 
                "$($user.samaccountname);$($user.emailaddress);$($user.UserPrincipalName);$($user.SamAccountName)@itvt.de;$(if (!($WhatIfEnabled)) {"UserPrincipalName has been set to $($user.SamAccountName)@itvt.de for user"}else{"UserPrincipalName will be set to $($user.SamAccountName)@itvt.de for user"});" | out-file $logfile -Append
            }
        } catch {
            
            write "UserPrincipalName could not be set for user $($user.SamAccountName)"
            
        }
    }
} 



