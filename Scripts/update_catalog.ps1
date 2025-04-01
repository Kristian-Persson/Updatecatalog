# update_catalog.ps1
# Uppdaterar updatescatalog.xml med den senaste Chrome-versionen

$catalogPath = "UpdatesCatalog/updatescatalog.xml"
$chromeVersionFile = "chrome_update.cab"

# Kontrollera om Chrome-uppdateringsfilen finns
if (!(Test-Path -Path $chromeVersionFile)) {
    Write-Host "❌ ERROR: $chromeVersionFile hittades inte! Avbryter..."
    exit 1
}

# Ladda in den nuvarande XML-filen
if (Test-Path -Path $catalogPath) {
    [xml]$xml = Get-Content -Path $catalogPath
} else {
    Write-Host "⚠️ $catalogPath hittades inte, skapar en ny..."
    $xml = New-Object System.Xml.XmlDocument
    $root = $xml.CreateElement("Catalog")
    $xml.AppendChild($root)
}

# Skapa en ny uppdateringsnod för Chrome
$update = $xml.CreateElement("Update")
$update.SetAttribute("Name", "Google Chrome")
$update.SetAttribute("Version", (Get-Item $chromeVersionFile).LastWriteTime)

# Lägg till uppdateringen i XML
$xml.DocumentElement.AppendChild($update)

# Spara filen
$xml.Save($catalogPath)
Write-Host "✅ updatescatalog.xml har uppdaterats!"

exit 0
