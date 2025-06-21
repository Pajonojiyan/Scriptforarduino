# Definiere Benutzerpfade
$Downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$Documents = [Environment]::GetFolderPath("MyDocuments")
$ZipPath = Join-Path $Downloads "Registry.zip"
$ExtractPath = Join-Path $Downloads "Registry"
$ExeName = "Registry.exe"
$ExeSourcePath = Join-Path $ExtractPath $ExeName
$ExeTargetPath = Join-Path $Documents $ExeName

# Schritt 1: Prüfe, ob ZIP-Datei existiert
if (Test-Path $ZipPath) {
    Write-Host "[+] ZIP-Datei gefunden: $ZipPath"

    # Schritt 2: Entpacken
    if (-Not (Test-Path $ExtractPath)) {
        New-Item -ItemType Directory -Path $ExtractPath | Out-Null
    }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    Write-Host "[+] ZIP-Datei entpackt nach: $ExtractPath"

    # Schritt 3: Registry.exe finden
    if (Test-Path $ExeSourcePath) {
        Write-Host "[+] Registry.exe gefunden: $ExeSourcePath"

        # Schritt 4: Nach Dokumente kopieren
        Copy-Item -Path $ExeSourcePath -Destination $ExeTargetPath -Force
        Write-Host "[+] Registry.exe wurde nach '$Documents' kopiert."

        # Schritt 5: ZIP-Datei löschen
        Remove-Item -Path $ZipPath -Force
        Write-Host "[+] Registry.zip gelöscht."

        # Schritt 6: Ordner "Registry" löschen
        Remove-Item -Path $ExtractPath -Recurse -Force
        Write-Host "[+] Ordner 'Registry' gelöscht."
    } else {
        Write-Host "[-] Registry.exe nicht im entpackten Ordner gefunden."
    }
} else {
    Write-Host "[-] Registry.zip nicht im Downloads-Ordner gefunden."
}
