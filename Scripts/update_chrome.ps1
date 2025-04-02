# update_chrome.ps1
# Script to download the latest Chrome MSI, create a CAB file, and upload to Azure Storage.

param (
    [string]$AzureStorageAccount = $env:AZURE_STORAGE_ACCOUNT_NAME,
    [string]$AzureContainer = $env:AZURE_STORAGE_CONTAINER_NAME,
    [string]$AzureStorageKey = $env:AZURE_STORAGE_KEY
)

# 🚀 Variables
$chromeMsiUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "$PSScriptRoot\chrome_installer.msi"
$latestVersionFile = "$PSScriptRoot\latest_chrome_version.txt"

# 🚀 Step 1: Retrieve current version from GitHub
Write-Host "🔄 Retrieving version from GitHub..."
if (Test-Path $latestVersionFile) {
    $currentVersion = Get-Content $latestVersionFile
    Write-Host "✅ Retrieved version from GitHub: $currentVersion"
} else {
    Write-Host "⚠️ No version file found. Assuming first-time setup."
    $currentVersion = "0.0.0.0"
}

# 🚀 Step 2: Retrieve current version from Azure
Write-Host "🔄 Retrieving version from Azure..."
$blobList = az storage blob list `
    --container-name $AzureContainer `
    --account-name $AzureStorageAccount `
    --account-key $AzureStorageKey `
    --output json | ConvertFrom-Json

$existingCab = $blobList | Where-Object { $_.name -match "chrome_update_(\d+\.\d+\.\d+\.\d+)\.cab" }
if ($existingCab) {
    $azureVersion = [regex]::Match($existingCab.name, "chrome_update_(\d+\.\d+\.\d+\.\d+).cab").Groups[1].Value
    Write-Host "✅ Version found on Azure: $azureVersion"
} else {
    Write-Host "⚠️ Could not retrieve version from Azure. Assuming first-time upload."
    $azureVersion = "0.0.0.0"
}

# 🚀 Step 3: Download the latest Chrome MSI
Write-Host "🔄 Downloading Chrome..."
Invoke-WebRequest -Uri $chromeMsiUrl -OutFile $localChromePath

# 🚀 Step 4: Extract Chrome version from MSI (FAST METHOD)
Write-Host "🔄 Extracting Chrome version from MSI file..."
$msiVersion = (Get-ItemProperty -Path $localChromePath).VersionInfo.FileVersion

if (-not $msiVersion) {
    Write-Error "❌ ERROR: Could not extract version from MSI!"
    exit 1
}

Write-Host "🌍 Latest Chrome version: $msiVersion"

# 🚀 Step 5: Compare versions and decide if update is needed
if ($msiVersion -le $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
}

Write-Host "🚀 New version found! Creating CAB file..."
$cabFileName = "chrome_update_$msiVersion.cab"
$localCabPath = "$PSScriptRoot\$cabFileName"

# 🚀 Step 6: Create CAB file
MakeCab -SourceFile $localChromePath -DestinationFile $localCabPath

# 🚀 Step 7: Verify CAB file exists
if (-not (Test-Path $localCabPath)) {
    Write-Error "❌ ERROR: CAB file was NOT created correctly!"
    exit 1
}

Write-Host "✅ CAB file created: $cabFileName"

# 🚀 Step 8: Upload CAB file to Azure Storage
Write-Host "☁️ Uploading CAB file to Azure..."
az storage blob upload `
    --container-name $AzureContainer `
    --account-name $AzureStorageAccount `
    --account-key $AzureStorageKey `
    --file $localCabPath `
    --name $cabFileName `
    --overwrite

Write-Host "✅ CAB file uploaded successfully."

# 🚀 Step 9: Update version file
Write-Host "📂 Updating version file in GitHub..."
$msiVersion | Out-File -FilePath $latestVersionFile -Encoding utf8

Write-Host "✅ Version file updated."

exit 0
