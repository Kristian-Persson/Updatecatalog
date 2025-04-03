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

# 🚀 Step 1: Retrieve current version from Azure
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

# 🚀 Step 2: Download the latest Chrome MSI
Write-Host "🔄 Downloading Chrome MSI..."
Invoke-WebRequest -Uri $chromeMsiUrl -OutFile $localChromePath

# 🚀 Step 3: Extract Chrome version from MSI (RESTORED WORKING METHOD)
Write-Host "🔄 Extracting Chrome version from MSI file..."
$msiVersion = (Get-ItemProperty -Path $localChromePath).VersionInfo.FileVersion

if (-not $msiVersion) {
    Write-Error "❌ ERROR: Could not extract version from MSI!"
    exit 1
}

Write-Host "🌍 Latest Chrome version: $msiVersion"

# 🚀 Step 4: Compare versions and decide if update is needed
if ($msiVersion -le $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
}

Write-Host "🚀 New version found! Creating CAB file..."
$cabFileName = "chrome_update_$msiVersion.cab"
$localCabPath = "$PSScriptRoot\$cabFileName"

# 🚀 Step 5: Create CAB file
MakeCab -SourceFile $localChromePath -DestinationFile $localCabPath

# 🚀 Step 6: Verify CAB file exists
if (-not (Test-Path $localCabPath)) {
    Write-Error "❌ ERROR: CAB file was NOT created correctly!"
    exit 1
}

Write-Host "✅ CAB file created: $cabFileName"

# 🚀 Step 7: Upload CAB file to Azure Storage
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
