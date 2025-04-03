# Construct the correct MSI download URL based on API version
$chromeDownloadUrl = "https://dl.google.com/release2/chrome/$latestVersion/googlechromestandaloneenterprise64.msi"
$msiPath = "$env:TEMP\googlechrome.msi"

# Download Chrome MSI
Write-Host "🔄 Downloading Chrome MSI from: $chromeDownloadUrl"
try {
    Invoke-WebRequest -Uri $chromeDownloadUrl -OutFile $msiPath
    Write-Host "✅ Chrome MSI downloaded successfully."
} catch {
    Write-Error "❌ ERROR: Failed to download Chrome MSI!"
    exit 1
}

# Extract MSI version info
Write-Host "🔄 Extracting Chrome version from MSI file..."
try {
    $msiVersion = (Get-Item $msiPath).VersionInfo.FileVersion

    if (-not $msiVersion) {
        Write-Host "⚠️ FileVersion is EMPTY. Trying ProductVersion..."
        $msiVersion = (Get-ItemProperty $msiPath).ProductVersion
    }

    if (-not $msiVersion) {
        Write-Host "⚠️ ProductVersion is also EMPTY. Trying 'Comments' field..."
        $msiVersion = (Get-Item $msiPath).VersionInfo.Comments
    }

    if (-not $msiVersion) {
        throw "❌ ERROR: Could not extract version from MSI!"
    }

    Write-Host "✅ Extracted Chrome MSI version: $msiVersion"
} catch {
    Write-Error $_
    exit 1
}

# Install Chrome MSI
Write-Host "🔄 Installing Chrome MSI..."
try {
    Start-Process "msiexec.exe" -ArgumentList "/i $msiPath /qn /norestart" -Wait -NoNewWindow
    Write-Host "✅ Chrome installed successfully."
} catch {
    Write-Error "❌ ERROR: Failed to install Chrome!"
    exit 1
}

# Verify installation
Write-Host "🎉 Chrome updated successfully to version: $msiVersion"
