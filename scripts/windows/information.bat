@echo off

call :sub >output.txt
exit /b

:sub
:: Listing basic inventory
echo Hostname:
hostname
echo:
echo Ipconfig:
ipconfig /all
echo:
echo Operating System:
systeminfo | findstr OS

:: Checking for listening ports
echo:
echo Listening Ports:
netstat -ano | findstr LIST | findstr /V ::1 | findstr /V 127.0.0.1

:: Listing users and groups
echo:
echo Users:
net user
echo:
echo Groups:
net localgroup
echo:
echo Administrators Users:
net localgroup "Administrators"
echo:
echo Remote Desktop Users:
net localgroup "Remote Desktop Users"
echo:
echo Remote Management Users:
net localgroup "Remote Management Users"

:: Looking for network shares
echo:
echo Network Shares:
net share

:: Exporting list of scheduled tasks
echo: 
echo Scheduled Tasks:
powershell -Command "get-scheduledtask | export-clixml 'tasks.xml'"

:: Check startup programs
echo:
echo Startup Programs (all users):
dir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

:: Check for stuff running on boot
echo:
echo Boot Execution:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "BootExecute"
reg query "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components" /v "StubPath"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components" /v "StubPath"

:: Check for startup services (include wow6432node?)
echo:
echo Startup Services:
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices"

:: Printing run keys
echo:
echo Run Keys:
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"

:: Check password filters
echo:
echo Password Filters:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "Notification Packages"
:: Check authentication packages
echo: 
echo Authentication Packages:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "Authentication Packages"
:: Check Security Support Providers
echo:
echo Security Packages:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "Security Packages" 
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\OSConfig" /v "Security Packages"

:: Network Provider
echo:
echo Network Providers:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order" /v "ProviderOrder"

:: you can load dlls into firewall
echo: 
echo netsh DLLs:
reg query "HKLM\SOFTWARE\Microsoft\NetSh"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\NetSh"

:: Check custom DLLs
echo:
echo AppInit_DLLs:
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs
reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs

:: AppCert DLLs (doesn't exist natively)
echo:
echo AppCertDLLs:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\" /v AppCertDLLs

:: Check for Custom DLLs in Winlogon
echo:
echo Winlogon DLLs:
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Notify
reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell
reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit
reg query "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Notify

:: Check for unsigned files (run this in the same directory as sigcheck!)
:: Might want to comment out to make script faster
echo:
echo Unsigned Files:
sigcheck64 -u -e c:\windows\system32
