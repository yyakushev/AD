Start-Process -FilePath C:\windows\system32\manage-bde.exe -ArgumentList '-protectors -adbackup c: -ID {2AB9A7A7-C065-45DD-B7D7-EBF3488BA564}' -RedirectStandardOutput  C:\temp\bitlocker.log -NoNewWindow
Invoke-Expression -Command 'manage-bde.exe -protectors -adbackup c: -ID `{2AB9A7A7-C065-45DD-B7D7-EBF3488BA564`}'
