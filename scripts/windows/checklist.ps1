# Change passwords of users

param(
	[string]$Script
)

# Function for generation of random passwords
function Generate-RandomPassword {
	param (
		[int]$length = 12
	)

	$characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+"
	$password = ""

	1..$length | ForEach-Object {
		$randomIndex = Get-Random -Minimum 0 -Maximum ($characters.Length - 1)
		$password += $characters[$randomIndex]
	}

	return $password
}

# Change passwords for all users
function Local-Passwords {
	$users = Get-LocalUser | %{$_.name }
	$curUser = $env:USERNAME

	foreach ($user in $users) { 
		if ($user -notmatch 'krbtgt' -and $user -ne $curUser) {
			$newPassword = Generate-RandomPassword
			Write-Output $user
			Write-Output $newPassword
			$securePassword = ConvertTo-SecureString -String $newPassword -AsPlainText -Force
			Set-LocalUser -Name $user -Password $securePassword
		}
	}
}

function Domain-Passwords {

	Import-Module ActiveDirectory
	$set = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+"
	$allusers = Get-ADUser -Properties memberof -Filter *
	$non_DA_users = foreach ($user in $allusers) {if ($user.MemberOf -join ';' -notmatch 'Domain Admins' -and $user.Name -notmatch 'krbtgt') {Write-Output $user.SamAccountName}}
	foreach ($user in $non_DA_users) {$password = Generate-RandomPassword; net user $user $password}
}

function Enable-Firewall {
	Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
}

function Download-Sysinternals {

	$url = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
	$outputPath = "C:\SysinternalsSuite.zip"

	Invoke-WebRequest -Uri $url -OutFile $outputPath
	Expand-Archive -Path "C:\SysinternalsSuite.zip" -DestinationPath "C:\sysinternals"
	Get-ChildItem C:\sysinternals\* | Rename-Item -NewName {$_.Name -replace ".exe","_ccdc.exe"}

}

function Defender {

	Set-MpPreference -DisableRealtimeMonitoring $false;
	Get-MpPreference | Select-Object -Property ExclusionExtension | % { if ($_.ExclusionExtension -ne $null) {Remove-MpPreference -ExclusionExtension $_.ExclusionExtension}};
	Get-MpPreference | Select-Object -Property ExclusionPath | % {if ($_.ExclusionPath -ne $null) {Remove-MpPreference -ExclusionPath $_.ExclusionPath}};
	Get-MpPreference | Select-Object -Property ExclusionProcess |
	% {if ($_.ExclusionProcess -ne $null) {Remove-MpPreference -ExclusionProcess $_.ExclusionProcess}}

}

function Ensure-NTP {
	net start w32time
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -name "AnnounceFlags" -Value 5
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer" -Name "Enabled" -Value 1
	Restart-Service w32Time
	w32tm /resync
}

function Open-Ports {
	netstat -anpos tcp
}

if ($Script -match 'lpasswords') {
	Local-Passwords
}
elseif ($Script -match 'dpasswords') {
	Domain-Passwords
}
elseif ($Script -match 'firewall') {
	Enable-Firewall	
}
elseif ($Script -match 'sysinternals') {
	Download-Sysinternals
}
elseif ($Script -match 'defender') {
	Get-MpPreference
	Defender
}
elseif ($Script -match 'ntp') {
	Ensure-NTP
}
elseif ($Script -match 'ports') {
	Open-Ports
}
else {
	Write-Output "Usage .\scripts.ps1 -Script <Command>"
	Write-Output "Commands:"
	Write-Output "lpasswords - Changes passwords for all local users"
	Write-Output "dpasswords - Changes passwords for all domain users"
	Write-Output "firewall - Enables firewall"	
	Write-Output "sysinternals - Downloads sysinternals and changes all the names of the applications"
	Write-Output "defender - This will ensure Windows Defender is enabled with no exclusions"
	Write-Output "ntp - Ensures that NTP is on and synced"
	Write-Output "ports - Prints out the open ports"
}
	





