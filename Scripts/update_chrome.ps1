# update_chrome.ps1
# Uppdaterar Google Chrome om det finns en ny version

$chromeDownloadURL = "https://dl.google.com/update2/installers/ChromeSetup.exe"
$localChromePath = "chrome_update.exe"
$localCabPath = "chrome_update.cab"
$versionFilePath = "latest_chrome_version.txt"
$xmlFilePath = "UpdatesCatalog/updatescatalog.xml"
$githubRawURL = "https://raw.githubusercontent.com/YOUR_GITHUB_USER/YOUR_REPO/main/$xmlFilePath"

# 🛠 Funktion för att hämta version från XML-filen på GitHub
function Get-ChromeVersionFromXML {
    param ($xmlUrl)
    
    try {
        Write-Host "🔄 Hämtar nuvarande version från XML-filen i GitHub..."
        $xmlContent = [xml](Invoke-WebRequest -Uri $xmlUrl -UseBasicParsing).Content
        $chromeVersion = $xmlContent.catalog.package | Where-Object { $_.name -match "chrome_update_" } | Select-Object -ExpandProperty version

        if ($chromeVersion) {
            return $chromeVersion
        } else {
            Write-Host "⚠️ Ingen Chrome-version hittades i XML-filen."
            return "0.0.0.0"
        }
    } catch {
        Write-Host "⚠️ Kunde inte hämta XML-filen från GitHub. Antar att det är första gången."
        return "0.0.0.0"
    }
}

# 🛠 Hämta nuvarande version från XML-filen (GitHub)
$githubVersion = Get-ChromeVersionFromXML -xmlUrl $githubRawURL

# 🔍 Hämta senaste Chrome-version från Google
Write-Host "🔄 Hämtar senaste Chrome-version från Google..."
$chromeData = Invoke-RestMethod -Uri "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json" -UseBasicParsing
$latestVersion = $chromeData.channels.Stable.version

Write-Host "🌍 Senaste Chrome-version: $latestVersion"
Write-Host "📄 Version i XML-filen (GitHub): $githubVersion"

# 🔄 Jämför versionerna
if ($latestVersion -ne $githubVersion) {
    Write-Host "🚀 Ny version hittad! Laddar ner Chrome $latestVersion..."

    # 🛠 Ladda ner Chrome-installationsfilen
    Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

    # ✅ Kontrollera att filen laddades ner korrekt
    if (-Not (Test-Path -Path $localChromePath)) {
        Write-Error "❌ ERROR: Chrome installationsfilen laddades INTE ner korrekt!"
        exit 1
    }

    # 🛠 Skapa en CAB-fil från installationsfilen
    Write-Host "📦 Skapar CAB-fil..."
    makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $localCabPath

    # ✅ Kontrollera att CAB-filen skapades
    if (-Not (Test-Path -Path $localCabPath)) {
        Write-Error "❌ ERROR: CAB-filen skapades INTE korrekt!"
        exit 1
    }

    # 🛠 Byt namn på CAB-filen till rätt format
    $newCabName = "chrome_update_$latestVersion.cab"
    Rename-Item -Path $localCabPath -NewName $newCabName

    # 🛠 Spara den senaste versionen i en fil
    Set-Content -Path $versionFilePath -Value $latestVersion

    Write-Host "✅ Chrome $latestVersion CAB-fil skapad: $newCabName"
    Write-Host "✅ Sparade senaste versionen i $versionFilePath"
} else {
    Write-Host "✅ Chrome i GitHub är redan den senaste versionen. Ingen uppdatering krävs."
}
