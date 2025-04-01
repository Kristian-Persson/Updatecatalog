# update_chrome.ps1
# Uppdaterar Google Chrome om det finns en ny version

$chromeDownloadURL = "https://dl.google.com/update2/installers/ChromeSetup.exe"
$localChromePath = "chrome_update.exe"
$localCabPath = "chrome_update.cab"
$versionFilePath = "latest_chrome_version.txt"

# Hämta nuvarande installerad version av Chrome
$installedVersion = (Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo.FileVersion

# Hämta senaste tillgängliga versionen av Chrome
$latestVersion = Invoke-RestMethod -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions/latest" | Select-Object -ExpandProperty version

Write-Host "Installerad version: $installedVersion"
Write-Host "Senaste version: $latestVersion"

if ($installedVersion -ne $latestVersion) {
    Write-Host "🚀 Ny version hittad! Laddar ner Chrome $latestVersion..."

    # Ladda ner Chrome-installationsfilen
    Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

    # Skapa en CAB-fil från installationsfilen
    makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $localCabPath

    # Byt namn på CAB-filen till rätt format (chrome_update_<version>.cab)
    $newCabName = "chrome_update_$latestVersion.cab"
    Rename-Item -Path $localCabPath -NewName $newCabName

    # Spara den senaste versionen till en fil (används i update_catalog.ps1)
    Set-Content -Path $versionFilePath -Value $latestVersion

    Write-Host "✅ Chrome $latestVersion CAB-fil skapad: $newCabName"
    Write-Host "✅ Sparade senaste versionen i $versionFilePath"
} else {
    Write-Host "✅ Chrome är redan uppdaterad. Ingen åtgärd krävs."
}
