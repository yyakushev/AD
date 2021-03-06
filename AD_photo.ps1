if (-not $(get-module|Select-String activedirectory)) {
    Import-Module activedirectory
}   

function Get-ADPhoto ($user){
    $photo = $(get-aduser $user -Properties thumbnailphoto).thumbnailphoto
    Set-Content d:\temp\usersphoto\$($user).jpeg -Value $photo -Encoding byte
}

#set ad foto
$files=get-childitem C:\Photos *.jpg
foreach ($file in $files) {
$photo = [byte[]](Get-Content $file.fullname -Encoding byte)
Set-ADUser $file.BaseName -Replace @{thumbnailPhoto=$photo} 
}
