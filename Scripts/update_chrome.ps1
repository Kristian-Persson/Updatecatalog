# update_chrome.ps1
# Uppdaterar Google Chrome, laddar upp till Azure och uppdaterar latest_chrome_version.txt i GitHub

$chromeDownloadURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "chrome_update.msi"
$versionFilePath = "latest_chrome_version.txt"

# 📌 Hämta nuvarande version från latest_chrome_version.txt
if (Test-Path -Path $versionFilePath) {
    $azureVersion = Get-Content $versionFilePath
    Write-Host "🔄 Hämtad version från GitHub: $azureVersion"
} else {
    Write-Host "⚠️ latest_chrome_version.txt hittades inte! Antas vara första gången."
    $azureVersion = "0.0.0.0"
}

Write-Host "☁️ Version på Azure enligt latest_chrome_version.txt: $azureVersion"

# ✅ Hämta senaste Chrome-version från MSI-filens metadata
Write-Host "🔄 Hämtar senaste Chrome-version genom att ladda ner MSI-filen..."
Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

# ✅ Extrahera versionen från MSI-filen
$latestVersion = (Get-Item $localChromePath).VersionInfo.FileVersion
Write-Host "🌍 Senaste Chrome-version: $latestVersion"

# ✅ Jämför versionerna
if ($latestVersion -eq $azureVersion) {
    Write-Host "✅ Chrome är redan uppdaterad på Azure enligt latest_chrome_version.txt. Ingen åtgärd krävs."
    exit 0
}

Write-Host "🚀 Ny version hittad! Skapar CAB-fil..."

# ✅ Skapa en CAB-fil
$newCabName = "chrome_update_$latestVersion.cab"
makecab.exe /D CompressionType=LZX $localChromePath $newCabName

# ✅ Kontrollera att CAB-filen skapades korrekt
if (-Not (Test-Path -Path $newCabName)) {
    Write-Error "❌ ERROR: CAB-filen skapades INTE korrekt!"
    exit 1
}

Write-Host "✅ CAB-fil skapad: $newCabName"

# ✅ Ladda upp till Azure
Write-Host "☁️ Laddar upp filen till Azure Storage..."
az storage blob upload `
  --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
  --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
  --account-key $env:AZURE_STORAGE_KEY `
  --file "$newCabName" `
  --name "$newCabName" `
  --overwrite

Write-Host "✅ Uppladdning slutförd!"

# ✅ Uppdatera latest_chrome_version.txt
Write-Host "📄 Uppdaterar latest_chrome_version.txt..."
$latestVersion | Set-Content $versionFilePath

# ✅ Commit & push till GitHub
Write-Host "🔄 Laddar upp latest_chrome_version.txt till GitHub..."
git add $versionFilePath
git commit -m "🔄 Uppdaterade Chrome-versionen till $latestVersion i latest_chrome_version.txt" || Write-Host "Inga ändringar att committa"
git push

Write-Host "✅ Klart!"
exit 0
