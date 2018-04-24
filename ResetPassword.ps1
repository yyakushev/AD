Set-ADAccountPassword -Identity bob -Reset 
Set-ADAccountPassword -Identity ivoronova -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "!q2w3e4r5t6y" -Force)
