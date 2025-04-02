# update_chrome.ps1
# Updates Google Chrome if a new version is available and uploads it to Azure.

# 📌 Configuration
$chromeDownloadURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$localChromePath = "chrome_update.msi"
$latestVersionFile = "latest_chrome_version.txt"

# 🔄 Step 1: Retrieve version from GitHub (.txt file)
Write-Host "🔄 Retrieving version from GitHub..."
if (Test-Path -Path $latestVersionFile) {
    $githubVersion = Get-Content $latestVersionFile
    Write-Host "✅ Retrieved version from GitHub: $githubVersion"
} else {
    Write-Host "⚠️ No version file found! Assuming first-time setup."
    $githubVersion = "0.0.0.0"
}

# 🔄 Step 2: Check if a CAB file exists in Azure
Write-Host "🔄 Checking for existing CAB file on Azure..."
$azureVersion = "0.0.0.0"

$azureBlobList = az storage blob list `
    --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
    --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
    --account-key $env:AZURE_STORAGE_KEY `
    --query "[].name" -o tsv 2>$null

foreach ($blob in $azureBlobList) {
    if ($blob -match "chrome_update_(\d+\.\d+\.\d+\.\d+)\.cab") {
        $azureVersion = $matches[1]
        Write-Host "✅ Found version on Azure: $azureVersion"
        break
    }
}

if ($azureVersion -eq "0.0.0.0") {
    Write-Host "⚠️ No CAB file found on Azure. Assuming first-time upload."
}

Write-Host "☁️ Version on Azure: $azureVersion"

# 🔄 Step 3: Download the latest Chrome MSI
Write-Host "🔄 Downloading Chrome MSI..."
Invoke-WebRequest -Uri $chromeDownloadURL -OutFile $localChromePath

# 🔍 Step 4: Extract Chrome version from MSI
Write-Host "🔄 Extracting Chrome version from MSI..."
$msiVersion = (Get-WmiObject Win32_Product | Where-Object { $_.Name -like "Google Chrome*" }).Version

if (-not $msiVersion) {
    Write-Error "❌ ERROR: Could not extract version from MSI!"
    exit 1
}

Write-Host "🌍 Latest Chrome version: $msiVersion"

# ✅ Step 5: Compare versions (only update if newer)
if ($msiVersion -le $githubVersion -and $msiVersion -le $azureVersion) {
    Write-Host "✅ Chrome is already updated on Azure. No action needed."
    exit 0
} else {
    Write-Host "🚀 New version detected! Updating..."
}

# 🗜 Step 6: Create CAB file
$cabFileName = "chrome_update_$msiVersion.cab"
Write-Host "🔄 Creating CAB file: $cabFileName..."
makecab.exe /D CompressionType=LZX /D CompressionMemory=21 /D Cabinet=ON /D MaxDiskSize=0 /D ReservePerCabinetSize=8 /D ReservePerFolderSize=8 /D ReservePerDataBlockSize=8 $localChromePath $cabFileName

# ✅ Verify CAB file
if (-Not (Test-Path -Path $cabFileName)) {
    Write-Error "❌ ERROR: CAB file creation failed!"
    exit 1
}

Write-Host "✅ CAB file created successfully: $cabFileName"

# 💾 Step 7: Save latest version to file
Write-Host "💾 Saving latest version to $latestVersionFile..."
$msiVersion | Out-File -Encoding utf8 $latestVersionFile

# ☁️ Step 8: Upload CAB file to Azure
Write-Host "☁️ Uploading $cabFileName to Azure Storage..."
az storage blob upload `
    --container-name $env:AZURE_STORAGE_CONTAINER_NAME `
    --account-name $env:AZURE_STORAGE_ACCOUNT_NAME `
    --account-key $env:AZURE_STORAGE_KEY `
    --file $cabFileName `
    --name $cabFileName `
    --overwrite

Write-Host "✅ CAB file uploaded successfully."

# 🔄 Step 9: Commit latest version file to GitHub
Write-Host "🔄 Committing latest version file to GitHub..."
git add $latestVersionFile
git commit -m "🔄 Auto-update: Chrome $msiVersion"
git push

Write-Host "🎉 Chrome update process completed successfully!"
