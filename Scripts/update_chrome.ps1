# Define Variables
$apiUrl = "https://chromiumdash.appspot.com/fetch_releases?platform=Windows&channel=Stable"
$chromeDownloadUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
$msiPath = "$env:TEMP\googlechrome.msi"

Write-Host "🔄 Fetching latest Chrome version from ChromiumDash API..."
try {
    # Fetch latest Chrome version
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{"Cache-Control"="no-cache"}

    # Debugging: Print API Response
    Write-Host "DEBUG: API Raw Response - $($response | ConvertTo-Json -Depth 10)"

    # Extract latest stable version from the first entry
    $latestVersion = $response | Select-Object -First 1 -ExpandProperty version

    if (-not $latestVersion) {
        throw "❌ No stable Windows version found!"
    }

    Write-Host "✅ Latest Chrome version: $latestVersion"
} catch {
    Write-Error "❌ ERROR: Could not retrieve version from Google API!"
    exit 1
}

# Check if Chrome is already installed
$installedVersion = $null
try {
    $installedVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome").DisplayVersion
} catch {
    Write-Host "⚠️ Chrome is not installed."
}

if ($installedVersion -eq $latestVersion) {
    Write-Host "✅ Chrome is already up to date ($latestVersion). No action needed."
    exit 0
}

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

# Compare downloaded MSI version with latest version
if ($msiVersion -ne $latestVersion) {
    Write-Error "❌ ERROR: Downloaded MSI version ($msiVersion) does NOT match latest version ($latestVersion)!"
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
$installedVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome").DisplayVersion
if ($installedVersion -eq $latestVersion) {
    Write-Host "🎉 Chrome updated successfully to version: $installedVersion"
} else {
    Write-Error "❌ ERROR: Chrome update verification failed! Installed version: $installedVersion"
    exit 1
}
