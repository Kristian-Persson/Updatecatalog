# update_chrome.ps1
# Script to download the latest Chrome MSI, extract version, create a CAB file, and upload to Azure Storage.

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

# 🚀 Step 3: Extract Chrome version from MSI
Write-Host "🔄 Extracting Chrome version from MSI file..."

# 🛠 Try multiple ways to extract version
$msiVersion = $null

# Method 1: Use Get-ItemProperty
$msiItem = Get-Item -Path $localChromePath
$msiInfo = $msiItem.VersionInfo

if ($msiInfo.FileVersion) {
    $msiVersion = $msiInfo.FileVersion
    Write-Host "✅ Extracted FileVersion: $msiVersion"
} elseif ($msiInfo.ProductVersion) {
    $msiVersion = $msiInfo.ProductVersion
    Write-Host "✅ Extracted ProductVersion: $msiVersion"
} else {
    Write-Host "⚠️ FileVersion & ProductVersion are empty. Trying 'Comments' field..."
}

# Method 2: Extract from Comments metadata using Shell.Application
if (-not $msiVersion) {
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Get-Item $localChromePath).DirectoryName)
        $file = $folder.ParseName((Get-Item $localChromePath).Name)
        
        for ($i = 0; $i -lt 300; $i++) {
            $property = $folder.GetDetailsOf($file, $i)
            if ($property -match "(\d+\.\d+\.\d+\.\d+)") {
                $msiVersion = $matches[1]
                Write-Host "✅ Extracted version from Comments field: $msiVersion"
                break
            }
        }
    } catch {
        Write-Host "⚠️ Failed to extract version from Comments field."
    }
}

# Final check
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
Write-Host "🔄 Creating CAB file..."
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
