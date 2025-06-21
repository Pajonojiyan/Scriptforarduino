# Setze Pfade
$Downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$ZipPath = Join-Path $Downloads "Registry.zip"
$ExtractPath = Join-Path $Downloads "Registry"
$ExeName = "Registry.exe"
$ExeSource = Join-Path $ExtractPath $ExeName
$DocPath = [Environment]::GetFolderPath("MyDocuments")
$ExeTarget = Join-Path $DocPath $ExeName

# Wenn ZIP vorhanden ist, entpacken
if (Test-Path $ZipPath) {
    Write-Host "[+] Registry.zip gefunden."

    try {
        # Entpacken
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        Write-Host "[+] ZIP entpackt nach $ExtractPath"
    } catch {
        Write-Host "[-] Fehler beim Entpacken: $_"
    }

    # .exe verschieben, falls vorhanden
    if (Test-Path $ExeSource) {
        Copy-Item -Path $ExeSource -Destination $ExeTarget -Force
        Write-Host "[+] Registry.exe nach Dokumente kopiert: $ExeTarget"
    } else {
        Write-Host "[-] Registry.exe nicht gefunden in $ExtractPath"
    }

    # ZIP löschen
    try {
        Remove-Item -Path $ZipPath -Force -ErrorAction Stop
        Write-Host "[+] Registry.zip gelöscht."
    } catch {
        Write-Host "[-] Fehler beim Löschen der ZIP: $_"
    }

    # Entpackten Ordner löschen
    try {
        Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        Write-Host "[+] Ordner 'Registry' gelöscht."
    } catch {
        Write-Host "[-] Fehler beim Löschen des Ordners: $_"
    }

} else {
    Write-Host "[-] Registry.zip nicht gefunden im Downloads-Ordner."
}
