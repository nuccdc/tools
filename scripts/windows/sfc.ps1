# Run SFC /scannow
Write-Host "Running SFC /scannow..."
Start-Process "sfc" -ArgumentList "/scannow" -Wait
Write-Host "SFC /scannow completed."
