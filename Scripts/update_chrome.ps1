# Variables
$chromeUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$downloadPath = "$env:GITHUB_WORKSPACE\chrome.msi"
$cabFilePath = "$env:GITHUB_WORKSPACE\chrome_update.cab"
$xmlFilePath = "$env:GITHUB_WORKSPACE\Updates\updatescatalog.xml"

# Download the latest Google Chrome MSI
Write-Host "Downloading latest Google Chrome MSI..."
Invoke-WebRequest -Uri $chromeUrl -OutFile $downloadPath

# Create a .CAB file from the MSI
Write-Host "Creating .CAB file..."
makecab /D CompressionType=LZX /D CompressionMemory=21 /D CabinetName1=chrome_update.cab $downloadPath $cabFilePath

# Upload to Azure Blob Storage
Write-Host "Uploading to Azure..."
az storage blob upload --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
  --container-name $env:AZURE_CONTAINER_NAME `
  --file $cabFilePath `
  --name "chrome_update.cab" `
  --account-key $env:AZURE_STORAGE_KEY

# Update updatescatalog.xml
Write-Host "Updating updatescatalog.xml..."
[xml]$xml = Get-Content $xmlFilePath
$updateNode = $xml.CreateElement("Update")
$updateNode.SetAttribute("Name", "Google Chrome")
$updateNode.SetAttribute("Version", (Get-Date -Format "yyyy.MM.dd"))
$updateNode.SetAttribute("DownloadURL", "https://$env:AZURE_STORAGE_ACCOUNT_NAME.blob.core.windows.net/$env:AZURE_CONTAINER_NAME/chrome_update.cab")
$xml.DocumentElement.AppendChild($updateNode) | Out-Null
$xml.Save($xmlFilePath)

Write-Host "Updates catalog XML updated!"

# Commit & Push updatescatalog.xml to GitHub
Write-Host "Committing and pushing updatescatalog.xml to GitHub..."
git config --global user.name "GitHub Actions Bot"
git config --global user.email "github-actions@github.com"
git add $xmlFilePath
git commit -m "Updated Chrome version $(Get-Date -Format 'yyyy.MM.dd') in updatescatalog.xml"
git push
