#
#Script send password expiration notification to users.
#Notifications are 
#If expiration date less or equal to 3 days notification copy sends to administrator if pointed.
#
param (
    [parameter(Position=0,Mandatory=$false,ValueFromPipeLine=$false)] [string] $SMTPServer = "",
    [parameter(Position=1,Mandatory=$false,ValueFromPipeLine=$false)] [int]    $NotificationStartDay = 10,
    [parameter(Position=2,Mandatory=$false,ValueFromPipeLine=$false)] [string] $SupportAddress = "",
    [parameter(Position=3,Mandatory=$false,ValueFromPipeLine=$false)] [string] $CopyToAddress,
    [parameter(Position=4,Mandatory=$false,ValueFromPipeLine=$false)] [string] $OU = "",
    [parameter(Position=4,Mandatory=$false,ValueFromPipeLine=$false)] [string[]] $UsersToExclude = "",
    [parameter(Position=5,Mandatory=$false,ValueFromPipeLine=$false)] [string] $URL
)
#
#Examples of use
#  PasswordNotification -SMTPServer "" -NotificationStartDay 10 `
#                       -SupportAddress "" -OU "OU=Batumi,DC=bot,DC=local" `
#                       -URL "" -CopyToAddress ""
#

#Load AD module
if (-not $(get-module|Select-String activedirectory)) {
    Import-Module activedirectory
} 

#Add event source in $EventLog
$Source = 'PasswordNotification'
$EventLog = 'Application'

if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) {
    [System.Diagnostics.EventLog]::CreateEventSource($source, $Eventlog)
}

#Event log functions
function Write-EventInfo([string] $msg)
{                                   
	write-EventLog -LogName $EventLog -Source $Source -EntryType Information -Message $msg -EventId 100
}

function Write-EventError([string] $msg)
{
	write-EventLog -LogName $EventLog -Source $Source -EntryType Error -Message $msg -EventId 500
}

#Send E-mail Function
function send-mail  
{
    param(
     [string]$server      = $(throw "server must be set"),
     [string]$toAddress   = $(throw "toAddress must be set"),
     [string]$CCAddress,
     [string]$toName      = "",
     [string]$fromAddress = $(throw "fromAddress must be set"),
     [string]$fromName    = "",
     [string]$subject     = $(throw "subject must be set"),
     [string[]]$body        = "",
     [string]$replyTo
    )

    # Init Mail address objects
    $emailFrom = New-Object system.net.Mail.MailAddress $fromAddress , $fromName
    $emailTo = New-Object system.net.Mail.MailAddress $toAddress , $toName
    $smtp = new-object Net.Mail.SmtpClient($server)
    $MailMessage = new-object Net.Mail.MailMessage($emailFrom, $emailTo, $subject, $body)
    if ($CCAddress) {
        $emailCC = New-Object system.net.Mail.MailAddress $CCAddress
        $MailMessage.CC.Add($emailCC)
    }
    $MailMessage.IsBodyHtml = $true
    if ($replyToAddress)
        {
        $MailMessage.ReplyTo = $replyTo
        }
    $smtp.Send($MailMessage)
} #Send-mail function

#Get Default Password Age by Domain Password Policy
[int] $PsswrdAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
$Today = [DateTime]::Now

#Get list users who need to be notificated
$users = get-aduser -filter * -SearchBase "$OU" -Properties * 
#|?{$_.DistinguishedName -like "*$OU"}

#Check if Users Password will expire soon and send message
Foreach ($user in $users) {
    if (!($user.PasswordNeverExpires) -and ($user.enabled -eq $true) -and !($user.PasswordExpired) -and !(Compare-Object $user.samaccountname $UsersToExclude -ExcludeDifferent -IncludeEqual)) {
        $PsswrdExpDays = ($user.PasswordLastSet.AddDays($PsswrdAge) - $Today).days
        if (($PsswrdExpDays -le $NotificationStartDay) -and ($PsswrdExpDays -ge 0)){
            try { 
                $subject = "Your password will expire in $PsswrdExpDays days!"
                $toAddress = ($user.ProxyAddresses|?{$_ -clike "SMTP:*"}).Remove(0,5)
                $mssg = "<p>Dear $($user.name)!</p>`
                         <p>Your password will expire in $PsswrdExpDays days.<br>`
                         Please, change it.</p>`
                         <p>---------------------------------------</p>`
                         <p>Количество дней до истечения Вашего пароля: $PsswrdExpDays.<br>`
                         Пожалуйста, смените его в ближайшее время.</p>"   

                switch ($PsswrdExpDays) {
                            30 {$send = $true; $cc=$false}
                            20 {$send = $true; $cc=$false}
			    10 {$send = $true; $cc=$true }
 {($_ -lt 10) -and ($_ -gt 3)} {$send = $true; $cc=$false}
			     3 {$send = $true; $cc=$true }
                    {$_ -lt 3} {$send = $true; $cc=$false}
                       default {$send = $false;$cc=$false}
                } #switch
                if ($send) {
                    send-mail -server $SMTPServer -toAddress $toAddress -CCAddress $($CopyToAddress*$cc) `
                              -fromaddress $SupportAddress -subject $subject -body $mssg
                    Write-EventInfo "Notification to $($user.name) was send"
                } 
            } catch {
                Write-EventError "Notification to $($user.name) wasn't send."
            } #Try catch
        }
    }
}