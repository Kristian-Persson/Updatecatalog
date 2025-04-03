# update_chrome.ps1
# Script to download the latest Chrome MSI, fetch version from Google API, create CAB, and upload to Azure Storage.

param (
    [string]$AzureStorageAccount = $env:AZURE_STORAGE_ACCOUNT_NAME,
    [string]$AzureContainer = $env:AZURE_STORAGE_CONTAINER_NAME,
    [string]$AzureStorageKey = $env:AZURE_STORAGE_KEY
)

# 🚀 Variables
$chromeMsiUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "$PSScriptRoot\chrome_installer.msi"

# 🚀 Step 1: Retrieve latest version from Google API
Write-Host "🔄 Fetching latest Chrome version from Google API..."
try {
    $apiUrl = "https://versionhistory.googleapis.com/v1/chrome/platforms/win/channels/stable/versions/latest"
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get
    $latestVersion = $response.version
    Write-Host "🌍 Latest Chrome version from API: $latestVersion"
} catch {
    Write-Error "❌ ERROR: Could not retrieve version from Google API!"
    exit 1
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
    Write-Host "⚠️ No existing version found on Azure. Assuming first-time upload."
    $azureVersion = "0.0.0.0"
}

# 🚀 Step 3: Compare versions and decide if update is needed
if ($latestVersion -le $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
}

Write-Host "🚀 New version found! Downloading and creating CAB file..."

# 🚀 Step 4: Download the latest Chrome MSI
Write-Host "🔄 Downloading Chrome MSI..."
Invoke-WebRequest -Uri $chromeMsiUrl -OutFile $localChromePath

# 🚀 Step 5: Verify MSI download
if (-not (Test-Path $localChromePath)) {
    Write-Error "❌ ERROR: Chrome MSI download failed!"
    exit 1
}

# 🚀 Step 6: Create CAB file
$cabFileName = "chrome_update_$latestVersion.cab"
$localCabPath = "$PSScriptRoot\$cabFileName"

Write-Host "🔄 Creating CAB file..."
MakeCab -SourceFile $localChromePath -DestinationFile $localCabPath

# 🚀 Step 7: Verify CAB file creation
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

exit 0
