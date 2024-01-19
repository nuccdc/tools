# downloads sysinternals, configures sysmon with sysmon-modular
# got from https://raw.githubusercontent.com/socfortress/Wazuh-Rules/main/Windows_Sysmon/sysmon_install.ps1
#$sysinternals_repo = 'download.sysinternals.com'
#$sysinternals_downloadlink = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
$sysinternals_folder = 'C:\sysinternals'
#$sysinternals_zip = 'SysinternalsSuite.zip'
$sysmonconfig_downloadlink = 'https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml'
$sysmonconfig_file = 'sysmonconfig-export.xml'



$OutPath = $env:TMP
Invoke-WebRequest -Uri $sysmonconfig_downloadlink -OutFile $OutPath\$sysmonconfig_file
Invoke-Command {reg.exe ADD HKCU\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f}
Invoke-Command {reg.exe ADD HKU\.DEFAULT\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f}
Start-Process -FilePath $sysinternals_folder\Sysmon64_ccdc.exe -Argumentlist @("-i", "$OutPath\$sysmonconfig_file")





#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#if (Test-Path -Path $sysinternals_folder) {
    write-host ('Sysinternals folder already exists')
#} else {
#  $OutPath = $env:TMP
#  $output = $sysinternals_zip
##  New-Item -Path "C:\Program Files" -Name "sysinternals" -ItemType "directory"
 # $X = 0
 # do {
 #   Write-Output "Waiting for network"
 #   Start-Sleep -s 5
 #   $X += 1
 # } until(($connectreult = Test-NetConnection $sysinternals_repo -Port 443 | ? { $_.TcpTestSucceeded }) -or $X -eq 3)

 # if ($connectreult.TcpTestSucceeded -eq $true){
  #   Try
  #   {
  #   write-host ('Downloading and copying Sysinternals Tools to C:\Program Files\sysinternals...')
  #   Invoke-WebRequest -Uri $sysinternals_downloadlink -OutFile $OutPath\$output
  #   Expand-Archive -path $OutPath\$output -destinationpath $sysinternals_folder
  #   Start-Sleep -s 10
  #   $OutPath = $env:TMP
  #   Invoke-WebRequest -Uri $sysmonconfig_downloadlink -OutFile $OutPath\$sysmonconfig_file
  #   $serviceName = 'Sysmon64'
  #   If (Get-Service $serviceName -ErrorAction SilentlyContinue) {
  #   write-host ('Sysmon Is Already Installed')
  #   } else {
  #   Invoke-Command {reg.exe ADD HKCU\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f}
  #   Invoke-Command {reg.exe ADD HKU\.DEFAULT\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f}
  #   Start-Process -FilePath $sysinternals_folder\Sysmon64_ccdc.exe -Argumentlist @("-i", "$OutPath\$sysmonconfig_file")
  #   }
  #   }
  #   Catch
  #   {
  #       $ErrorMessage = $_.Exception.Message
  #       $FailedItem = $_.Exception.ItemName
  #       Write-Error -Message "$ErrorMessage $FailedItem"
  #       exit 1
  #   }
  #   Finally
  #   {
  #       Remove-Item -Path $OutPath\$output
  #   }

  # } else {
  #     Write-Output "Unable to connect to Sysinternals Repo"
  # }
#}

