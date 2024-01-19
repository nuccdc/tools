# Path to Sysinternals
$SysinternalsPath = "C:\sysinternals"

Start-Process powershell.exe -ArgumentList "-File .\checklist.ps1 -Script sysinternals"
#this next one just configures sysmon
Start-Process powershell.exe -ArgumentList "-File .\install-sysinternals.ps1"



# Open Sysinternals tools
Start-Process -FilePath "$SysinternalsPath\procmon64_ccdc.exe"
Start-Process -FilePath "$SysinternalsPath\tcpview64_ccdc.exe"
Start-Process -FilePath "$SysinternalsPath\autoruns64_ccdc.exe"
Start-Process -FilePath "$SysinternalsPath\procexp64_ccdc.exe"


# Run the rest
# get info on system
Start-Process powershell.exe -ArgumentList "-File .\information.bat"

# run sfc /scannow
Start-Process powershell.exe -ArgumentList "-File .\sfc.ps1"

# windows defender script
Start-Process powershell.exe -ArgumentList "-File .\sos-windowsdefenderhardening.ps1"

# lots of hardening
#Start-Process powershell.exe -ArgumentList "-File .\first-hour.ps1"

# get and run winpeas
Start-Process powershell.exe -ArgumentList "-File .\invoke-winpeas.ps1"
