Start-Process notepad
Start-Sleep -Seconds 1
Get-Process notepad | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process notepad
Start-Sleep -Seconds 1
$wshell = New-Object -ComObject wscript.shell
$wshell.AppActivate("Unbenannt - Editor")
Start-Sleep -Milliseconds 500
$wshell.SendKeys("Hallo Welt")
