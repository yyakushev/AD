param (
    [string] $DaysUnavailable = "90",
    [string] $path = "oldclients.csv"
)
$lastLogonDate = (get-date).adddays(-$DaysUnavailable)
try {

    $oldclients = Get-ADComputer -Filter * -Properties * |  ? {($_.OperatingSystem -notlike "*server*")-and($_.OperatingSystem -like "Windows*")} | ? LastLogonDate -lt $lastLogonDate
    $oldclients | select name, OperatingSystem, lastlogondate, DistinguishedName | Export-Csv -Delimiter ";" -Path $path -Encoding UTF8

} catch {"something went wrong"}