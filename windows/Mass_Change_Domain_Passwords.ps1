Import-Module ActiveDirectory
$set = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
$allusers = Get-ADUser -Properties memberof -Filter *
$non_DA_users = foreach ($user in $allusers) {if ($user.MemberOf -join ';' -notmatch 'Domain Admins' -and $user.name -notmatch 'krbtgt') {Write-Output $user.name}}
foreach ($user in $non_DA_users) {$password="";for ($i=1; $i -le 64; $i++){$password += $set | Get-Random};net user $user $password}
