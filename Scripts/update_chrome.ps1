# update_chrome.ps1
# Updates Chrome, uploads to Azure, and updates latest_chrome_version.txt in GitHub

$chromeDownloadURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "chrome_update.msi"
$versionFilePath = "latest_chrome_version.txt"

# 📌 Get current version from latest_chrome_version.txt
if (Test-Path -Path $versionFilePath) {
    $azureVersion = Get-Content $versionFilePath
    Write-Host "🔄 Retrieved version from GitHub: $azureVersion"
} else {
    Write-Host "⚠️ latest_chrome_version.txt not found! Assuming first run."
    $azureVersion = "0.0.0.0"
}

Write-Host "☁️ Version on Azure: $azureVersion"

# ✅ Download the latest Chrome MSI
Write-Host "🔄 Downloading latest Chrome MSI..."
Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

# ✅ Extract version from MSI file
$latestVersion = (Get-Item $localChromePath).VersionInfo.FileVersion
Write-Host "🌍 Latest Chrome version: $latestVersion"

# ✅ Compare versions
if ($latestVersion -eq $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
}

Write-Host "🚀 New version found! Creating CAB file..."

# ✅ Create a CAB file
$newCabName = "chrome_update_$latestVersion.cab"
makecab.exe /D CompressionType=LZX $localChromePath $newCabName

# ✅ Verify that the CAB file was created
if (-Not (Test-Path -Path $newCabName)) {
    Write-Error "❌ ERROR: CAB file was NOT created correctly!"
    exit 1
}

Write-Host "✅ CAB file created: $newCabName"

# ✅ Upload to Azure
Write-Host "☁️ Uploading file to Azure Storage..."
az storage blob upload `
  --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
  --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
  --account-key $env:AZURE_STORAGE_KEY `
  --file "$newCabName" `
  --name "$newCabName" `  # ✅ Corrected name
  --overwrite

Write-Host "✅ Upload completed!"

# ✅ Verify the upload
Write-Host "🔍 Verifying the uploaded file..."
az storage blob show `
  --container-name "$env:AZURE_STORAGE_CONTAINER_NAME" `
  --name "$newCabName" `  # ✅ Checking the correct file
  --account-name "$env:AZURE_STORAGE_ACCOUNT_NAME" `
  --account-key "$env:AZURE_STORAGE_KEY"

# ✅ Update latest_chrome_version.txt
Write-Host "📄 Updating latest_chrome_version.txt..."
$latestVersion | Set-Content $versionFilePath

# ✅ Commit & push to GitHub
Write-Host "🔄 Pushing latest_chrome_version.txt to GitHub..."
git add $versionFilePath
git commit -m "🔄 Updated Chrome version to $latestVersion in latest_chrome_version.txt" || Write-Host "No changes to commit"
git push

Write-Host "✅ Done!"
exit 0
