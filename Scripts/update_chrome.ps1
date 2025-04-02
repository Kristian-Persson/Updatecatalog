# update_chrome.ps1
# Updates Google Chrome if a new version is available and uploads it to Azure.

# 📌 Configuration
$chromeDownloadURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "chrome_update.msi"
$latestVersionFile = "latest_chrome_version.txt"
$azureBlobName = "chrome_update.cab"

# 🔄 Retrieve version from GitHub
Write-Host "🔄 Retrieving version from GitHub..."
if (Test-Path -Path $latestVersionFile) {
    $githubVersion = Get-Content $latestVersionFile
    Write-Host "✅ Retrieved version from GitHub: $githubVersion"
} else {
    Write-Host "⚠️ GitHub version file not found. Assuming first-time setup."
    $githubVersion = "0.0.0.0"
}

# 🔄 Retrieve version from Azure
Write-Host "🔄 Retrieving version from Azure..."
$azureVersion = az storage blob show `
    --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
    --name $azureBlobName `
    --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
    --account-key $env:AZURE_STORAGE_KEY `
    --query properties.metadata.version -o tsv 2>$null

if (-not $azureVersion) {
    Write-Host "⚠️ Could not retrieve version from Azure. Assuming first-time upload."
    $azureVersion = "0.0.0.0"
}

Write-Host "☁️ Version on Azure: $azureVersion"

# 🔄 Retrieve the latest Chrome version
Write-Host "🔄 Checking the latest available Chrome version..."
$latestVersion = (Invoke-WebRequest -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions/latest" -UseBasicParsing | ConvertFrom-Json).version

if (-not $latestVersion) {
    Write-Error "❌ ERROR: Could not fetch latest Chrome version!"
    exit 1
}

Write-Host "🌍 Latest Chrome version: $latestVersion"

# ✅ Compare versions
if ($latestVersion -eq $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
} else {
    Write-Host "🚀 New version detected! Downloading and packaging Chrome..."
}

# ⬇️ Download Chrome MSI
Write-Host "🔄 Downloading Chrome $latestVersion..."
Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

# 🗜 Create CAB file
$cabFileName = "chrome_update_$latestVersion.cab"
Write-Host "🔄 Creating CAB file: $cabFileName..."
makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $cabFileName

# ✅ Verify CAB file
if (-Not (Test-Path -Path $cabFileName)) {
    Write-Error "❌ ERROR: CAB file creation failed!"
    exit 1
}

Write-Host "✅ CAB file created successfully: $cabFileName"

# 📂 Save latest version to file
Write-Host "💾 Saving latest version to $latestVersionFile..."
$latestVersion | Out-File -Encoding utf8 $latestVersionFile

# ☁️ Upload CAB file to Azure
Write-Host "☁️ Uploading $cabFileName to Azure Storage..."
az storage blob upload `
    --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
    --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
    --account-key $env:AZURE_STORAGE_KEY `
    --file $cabFileName `
    --name $cabFileName `
    --overwrite

Write-Host "✅ CAB file uploaded successfully."

# ✅ Update GitHub version file
Write-Host "🔄 Committing latest version file to GitHub..."
git add $latestVersionFile
git commit -m "🔄 Auto-update: Chrome $latestVersion"
git push

Write-Host "🎉 Chrome update process completed successfully!"
