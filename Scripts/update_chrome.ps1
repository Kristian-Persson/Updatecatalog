# Define the Enterprise MSI download URL
$msiUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$msiPath = "$env:TEMP\googlechrome.msi"

Write-Host "🔄 Downloading Chrome Enterprise MSI from: $msiUrl"
try {
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath
    Write-Host "✅ Chrome Enterprise MSI downloaded successfully."
} catch {
    Write-Error "❌ ERROR: Failed to download Chrome Enterprise MSI!"
    exit 1
}
$msiPath = "$env:TEMP\googlechrome.msi"
$msi = Get-Item $msiPath

Write-Host "🔍 Debug: Full MSI Metadata"
$msi | Format-List *  # Show all available metadata

Write-Host "🔍 Debug: File Version Info"
$msi.VersionInfo | Format-List *

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

# Define CAB file path with extracted version
$cabPath = "$env:TEMP\chrome_$msiVersion.cab"
Write-Host "🔄 Naming CAB file as: $cabPath"

# Simulating CAB file creation (Replace this with actual CAB creation process)
Write-Host "🔄 Creating CAB file..."
try {
    New-Item -ItemType File -Path $cabPath -Force | Out-Null
    Write-Host "✅ CAB file created successfully: $cabPath"
} catch {
    Write-Error "❌ ERROR: Failed to create CAB file!"
    exit 1
}

# Define XML file path
$xmlPath = "$env:TEMP\update_catalog.xml"

# Update XML file with new version
Write-Host "🔄 Updating XML file with new version..."
try {
    if (Test-Path $xmlPath) {
        [xml]$xml = Get-Content $xmlPath
        $xml.Update.Version = $msiVersion
        $xml.Save($xmlPath)
        Write-Host "✅ XML file updated successfully."
    } else {
        Write-Host "⚠️ XML file not found. Creating a new one..."
        $xmlContent = @"
<Update>
    <Version>$msiVersion</Version>
</Update>
"@
        $xmlContent | Out-File $xmlPath
        Write-Host "✅ New XML file created successfully."
    }
} catch {
    Write-Error "❌ ERROR: Failed to update XML file!"
    exit 1
}

Write-Host "🎉 Process completed successfully!"
exit 0
