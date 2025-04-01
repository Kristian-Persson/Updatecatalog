# PowerShell script to update the update catalog XML with the latest Chrome version
param (
    [string]$containerName = "updatecatalog",
    [string]$xmlFilePath = "UpdatesCatalog/updatescatalog.xml"
)

# Kontrollera att alla nödvändiga variabler finns
if (-not $env:AZURE_STORAGE_ACCOUNT_NAME -or -not $env:AZURE_CONTAINER_NAME -or -not $env:AZURE_STORAGE_KEY) {
    Write-Host "❌ ERROR: Saknade Azure-credentials! Kontrollera dina GitHub Secrets."
    exit 1
}

# Hämta senaste Chrome-versionen
Write-Host "🔍 Hämtar senaste Chrome-versionen..."
$chromeVersion = (Get-Content "latest_chrome_version.txt").Trim()

if (-not $chromeVersion) {
    Write-Host "❌ ERROR: Ingen Chrome-version hittades i latest_chrome_version.txt"
    exit 1
}

# Generera korrekt nedladdningslänk
$blobFileName = "chrome_update_$chromeVersion.cab"
$downloadUrl = "https://$env:AZURE_STORAGE_ACCOUNT_NAME.blob.core.windows.net/$containerName/$blobFileName"

Write-Host "✅ Genererad URL: $downloadUrl"

# Läs in XML-filen
if (Test-Path $xmlFilePath) {
    [xml]$xml = Get-Content $xmlFilePath
} else {
    Write-Host "❌ ERROR: XML-filen hittades inte på $xmlFilePath"
    exit 1
}

# Hämta den senaste noden från XML
$updates = $xml.UpdateCatalog.Update
$latestUpdate = $updates | Sort-Object -Property Version -Descending | Select-Object -First 1

# Om en tidigare version finns, sätt den som "Expired"
if ($latestUpdate -and $latestUpdate.Version -ne $chromeVersion) {
    Write-Host "⚠️ Tidigare version ($($latestUpdate.Version)) hittad - Markeras som 'Expired'."
    $latestUpdate.Expired = "True"
}

# Skapa en ny update-nod för den nya versionen
$newUpdate = $xml.CreateElement("Update")
$newUpdate.SetAttribute("Version", $chromeVersion)
$newUpdate.SetAttribute("DownloadUrl", $downloadUrl)
$newUpdate.SetAttribute("Expired", "False")

# Lägg till den nya noden i XML-filen
$xml.UpdateCatalog.AppendChild($newUpdate) | Out-Null

# Spara den uppdaterade XML-filen
$xml.Save($xmlFilePath)
Write-Host "✅ XML-filen uppdaterad: $xmlFilePath"

# Kontrollera in i Git och pusha ändringar
Write-Host "🔄 Commitar och pushar XML-uppdateringen till GitHub..."
git add $xmlFilePath
git commit -m "🔄 Uppdaterad Chrome-version $chromeVersion i updatescatalog.xml"
git push

Write-Host "🚀 Klar! XML-filen har uppdaterats och pushats."
