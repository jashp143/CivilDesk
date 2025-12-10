#!/bin/bash
# Bash script to sync Google Maps API Key from .env to native configuration files

ENV_FILE=".env"
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"
IOS_APP_DELEGATE="ios/Runner/AppDelegate.swift"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found!"
    echo "Please create a .env file with GOOGLE_MAPS_API_KEY=your_key_here"
    exit 1
fi

# Read API key from .env
API_KEY=$(grep "GOOGLE_MAPS_API_KEY=" "$ENV_FILE" | cut -d '=' -f2)

if [ -z "$API_KEY" ] || [ "$API_KEY" = "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
    echo "Error: GOOGLE_MAPS_API_KEY not set in .env file!"
    exit 1
fi

echo "Found API Key: ${API_KEY:0:20}..."

# Update AndroidManifest.xml
if [ -f "$ANDROID_MANIFEST" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/android:value=\"YOUR_GOOGLE_MAPS_API_KEY_HERE\"/android:value=\"$API_KEY\"/g" "$ANDROID_MANIFEST"
    else
        # Linux
        sed -i "s/android:value=\"YOUR_GOOGLE_MAPS_API_KEY_HERE\"/android:value=\"$API_KEY\"/g" "$ANDROID_MANIFEST"
    fi
    echo "Updated AndroidManifest.xml"
else
    echo "Warning: AndroidManifest.xml not found!"
fi

# Update AppDelegate.swift
if [ -f "$IOS_APP_DELEGATE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/GMSServices.provideAPIKey(\"YOUR_GOOGLE_MAPS_API_KEY_HERE\")/GMSServices.provideAPIKey(\"$API_KEY\")/g" "$IOS_APP_DELEGATE"
    else
        # Linux
        sed -i "s/GMSServices.provideAPIKey(\"YOUR_GOOGLE_MAPS_API_KEY_HERE\")/GMSServices.provideAPIKey(\"$API_KEY\")/g" "$IOS_APP_DELEGATE"
    fi
    echo "Updated AppDelegate.swift"
else
    echo "Warning: AppDelegate.swift not found!"
fi

echo ""
echo "Sync completed successfully!"
echo "Note: You may need to rebuild your app for changes to take effect."

