# update_chrome.ps1
# Uppdaterar Google Chrome om det finns en nyare version och laddar upp den till Azure

$chromeDownloadURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "chrome_update.msi"
$localCabPath = "chrome_update.cab"
$xmlFilePath = "UpdatesCatalog/updatescatalog.xml"

# ✅ Hämta nuvarande version från updatescatalog.xml i GitHub
Write-Host "🔄 Hämtar nuvarande version från updatescatalog.xml..."
if (Test-Path -Path $xmlFilePath) {
    [xml]$xmlContent = Get-Content $xmlFilePath
    $azureVersion = $xmlContent.Updates.Update.Version
} else {
    Write-Host "⚠️ updatescatalog.xml hittades inte! Antas vara första gången."
    $azureVersion = "0.0.0.0"
}

Write-Host "☁️ Version på Azure: $azureVersion"

# ✅ Hämta senaste Chrome-version från Google
Write-Host "🔄 Hämtar senaste Chrome-version från Google..."
$latestVersion = (Invoke-WebRequest -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions/latest" | ConvertFrom-Json).version

if (-not $latestVersion) {
    Write-Error "❌ ERROR: Kunde inte hämta senaste Chrome-versionen!"
    exit 1
}

Write-Host "🌍 Senaste Chrome-version: $latestVersion"

# ✅ Jämför versionerna
if ($latestVersion -eq $azureVersion) {
    Write-Host "✅ Chrome är redan uppdaterad på Azure. Ingen åtgärd krävs."
    exit 0
}

Write-Host "🚀 Ny version hittad! Laddar ner Chrome $latestVersion..."

# ✅ Ladda ner Chrome MSI-filen
Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

# ✅ Kontrollera att nedladdningen lyckades
if (-Not (Test-Path -Path $localChromePath)) {
    Write-Error "❌ ERROR: Chrome MSI-filen kunde inte laddas ner!"
    exit 1
}

# ✅ Skapa en CAB-fil från installationsfilen
makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $localCabPath

# ✅ Döp om CAB-filen till chrome_update_<version>.cab
$newCabName = "chrome_update_$latestVersion.cab"
Rename-Item -Path $localCabPath -NewName $newCabName

# ✅ Kontrollera att CAB-filen skapades
if (-Not (Test-Path -Path $newCabName)) {
    Write-Error "❌ ERROR: CAB-filen skapades INTE korrekt!"
    exit 1
}

Write-Host "✅ Chrome $latestVersion CAB-fil skapad: $newCabName"
Write-Host "☁️ Laddar upp CAB-filen till Azure..."

# ✅ Kontrollera att Azure credentials finns
$missingSecrets = @()
if (-not $env:AZURE_STORAGE_ACCOUNT_NAME) { $missingSecrets += "AZURE_STORAGE_ACCOUNT_NAME" }
if (-not $env:AZURE_STORAGE_CONTAINER_NAME) { $missingSecrets += "AZURE_STORAGE_CONTAINER_NAME" }
if (-not $env:AZURE_STORAGE_KEY) { $missingSecrets += "AZURE_STORAGE_KEY" }

if ($missingSecrets.Count -gt 0) {
    Write-Error "❌ ERROR: Saknade Azure-credentials! Följande secrets saknas: $($missingSecrets -join ', ')"
    exit 1
}

# ✅ Ladda upp CAB-filen till Azure
az storage blob upload `
  --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
  --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
  --account-key $env:AZURE_STORAGE_KEY `
  --file "$newCabName" `
  --name "$newCabName" `
  --overwrite

Write-Host "✅ Uppladdning slutförd!"

# ✅ Uppdatera latest_chrome_version.txt
Set-Content -Path "latest_chrome_version.txt" -Value $latestVersion
Write-Host "✅ Sparade senaste versionen i latest_chrome_version.txt"

exit 0
