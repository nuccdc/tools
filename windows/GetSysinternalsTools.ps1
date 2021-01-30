$uri = "live.sysinternals.com"
$tools = @("procexp64.exe", "Autoruns64.exe", "Tcpview.exe", "sigcheck64.exe", "Procmon64.exe", "Sysmon64.exe")
$dirname = "sysinternals"

mkdir $dirname

foreach($tool in $tools) {
    Invoke-WebRequest -uri "$uri/$tool" -OutFile "$dirname\$tool"
}
