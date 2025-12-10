# PowerShell script to sync Google Maps API Key from .env to native configuration files

$envFile = ".\.env"
$androidManifest = ".\android\app\src\main\AndroidManifest.xml"
$iosAppDelegate = ".\ios\Runner\AppDelegate.swift"

# Check if .env file exists
if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with GOOGLE_MAPS_API_KEY=your_key_here" -ForegroundColor Yellow
    exit 1
}

# Read API key from .env
$apiKey = ""
Get-Content $envFile | ForEach-Object {
    if ($_ -match "GOOGLE_MAPS_API_KEY=(.+)") {
        $apiKey = $matches[1]
    }
}

if ([string]::IsNullOrEmpty($apiKey) -or $apiKey -eq "YOUR_GOOGLE_MAPS_API_KEY_HERE") {
    Write-Host "Error: GOOGLE_MAPS_API_KEY not set in .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "Found API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..." -ForegroundColor Green

# Update AndroidManifest.xml
if (Test-Path $androidManifest) {
    $content = Get-Content $androidManifest -Raw
    $content = $content -replace 'android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"', "android:value=`"$apiKey`""
    Set-Content $androidManifest -Value $content -NoNewline
    Write-Host "Updated AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "Warning: AndroidManifest.xml not found!" -ForegroundColor Yellow
}

# Update AppDelegate.swift
if (Test-Path $iosAppDelegate) {
    $content = Get-Content $iosAppDelegate -Raw
    $content = $content -replace 'GMSServices.provideAPIKey\("YOUR_GOOGLE_MAPS_API_KEY_HERE"\)', "GMSServices.provideAPIKey(`"$apiKey`")"
    Set-Content $iosAppDelegate -Value $content -NoNewline
    Write-Host "Updated AppDelegate.swift" -ForegroundColor Green
} else {
    Write-Host "Warning: AppDelegate.swift not found!" -ForegroundColor Yellow
}

Write-Host "`nSync completed successfully!" -ForegroundColor Green
Write-Host "Note: You may need to rebuild your app for changes to take effect." -ForegroundColor Yellow

