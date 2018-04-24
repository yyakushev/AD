 $FilterHash = @{}
 $FilterHash.LogName = "Security"
 $FilterHash.ID = "4740"
 $FilterHash.data = "adminyaya" 
Get-WinEvent -MaxEvents 4 -FilterHashtable $FilterHash| %{$_.message}
