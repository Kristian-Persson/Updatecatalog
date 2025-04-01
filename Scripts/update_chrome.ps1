# update_chrome.ps1
# Uppdaterar Google Chrome om det finns en ny version

$chromeDownloadURL = "https://dl.google.com/update2/installers/ChromeSetup.exe"
$localChromePath = "chrome_update.exe"
$localCabPath = "chrome_update.cab"
$versionFilePath = "latest_chrome_version.txt"
$azureVersionFileURL = "https://updatecatalog.blob.core.windows.net/updatecatalog/latest_chrome_version.txt"

# Hämta nuvarande version som finns på Azure
Write-Host "🔄 Hämtar nuvarande version från Azure..."
try {
    $azureVersion = Invoke-WebRequest -Uri $azureVersionFileURL -UseBasicParsing | Select-Object -ExpandProperty Content
} catch {
    Write-Host "⚠️ Kunde inte hämta nuvarande version från Azure. Antas vara första gången."
    $azureVersion = "0.0.0.0"
}

# Hämta senaste Chrome-version från Google
Write-Host "🔄 Hämtar senaste Chrome-version från Google..."
$chromeVersions = Invoke-RestMethod -Uri "https://omahaproxy.appspot.com/all.json" -UseBasicParsing
$latestVersion = ($chromeVersions | Where-Object { $_.os -eq "win64" -and $_.channel -eq "stable" }).version

Write-Host "🌍 Senaste Chrome-version: $latestVersion"
Write-Host "☁️ Version på Azure: $azureVersion"

if ($latestVersion -ne $azureVersion) {
    Write-Host "🚀 Ny version hittad! Laddar ner Chrome $latestVersion..."

    # Ladda ner Chrome-installationsfilen
    Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

    # Skapa en CAB-fil från installationsfilen
    makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $localCabPath

    # Byt namn på CAB-filen till rätt format
    $newCabName = "chrome_update_$latestVersion.cab"
    Rename-Item -Path $localCabPath -NewName $newCabName

    # Spara den senaste versionen till en fil (används i update_catalog.ps1)
    Set-Content -Path $versionFilePath -Value $latestVersion

    Write-Host "✅ Chrome $latestVersion CAB-fil skapad: $newCabName"
    Write-Host "✅ Sparade senaste versionen i $versionFilePath"
} else {
    Write-Host "✅ Chrome på Azure är redan den senaste versionen. Ingen uppdatering krävs."
}
