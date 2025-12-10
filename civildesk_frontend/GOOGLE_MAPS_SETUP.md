# Google Maps API Key Configuration

This guide explains how to configure the Google Maps API key for the GPS Attendance Map feature.

## Step 1: Get Your Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key
6. (Recommended) Restrict the API key to your app's package name for security

## Step 2: Create .env File

1. In the `civildesk_frontend` directory, create a file named `.env`
2. Add the following content:

```env
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

Replace `your_actual_api_key_here` with your actual Google Maps API key.

## Step 3: Sync API Key to Native Files

The API key needs to be in both the Android and iOS native configuration files. Use the provided script to automatically sync it from `.env`:

### Windows (PowerShell):
```powershell
.\scripts\sync_api_key.ps1
```

### Linux/Mac (Bash):
```bash
chmod +x scripts/sync_api_key.sh
./scripts/sync_api_key.sh
```

This script will:
- Read the API key from `.env`
- Update `android/app/src/main/AndroidManifest.xml`
- Update `ios/Runner/AppDelegate.swift`

## Step 4: Install Dependencies

Make sure you have installed the required packages:

```bash
flutter pub get
```

## Step 5: Rebuild Your App

After setting up the API key, rebuild your app:

```bash
flutter clean
flutter pub get
flutter run
```

## Manual Configuration (Alternative)

If you prefer to set the API key manually:

### Android:
1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the line with `YOUR_GOOGLE_MAPS_API_KEY_HERE`
3. Replace it with your actual API key

### iOS:
1. Open `ios/Runner/AppDelegate.swift`
2. Find the line with `YOUR_GOOGLE_MAPS_API_KEY_HERE`
3. Replace it with your actual API key

## Verification

To verify the API key is configured correctly:

1. Run the app
2. Navigate to **GPS Attendance Map** in the admin panel
3. The map should load without errors
4. You should see markers for attendance punches and site boundaries

## Troubleshooting

### Map shows blank/white screen:
- Check that your API key is correct
- Verify that Maps SDK for Android/iOS is enabled in Google Cloud Console
- Check that the API key restrictions allow your app's package name

### "API key not found" error:
- Make sure `.env` file exists in the `civildesk_frontend` directory
- Verify the key name is exactly `GOOGLE_MAPS_API_KEY`
- Run the sync script again

### Script doesn't work:
- Make sure you're running it from the `civildesk_frontend` directory
- Check that `.env` file exists and contains the API key
- For PowerShell, you may need to set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Security Notes

- **Never commit `.env` file to version control** (it's already in `.gitignore`)
- Restrict your API key in Google Cloud Console to only allow requests from your app
- Use different API keys for development and production if possible
- Regularly rotate your API keys

## Files Modified

- `lib/main.dart` - Loads .env file on app startup
- `lib/core/utils/env_config.dart` - Utility class to access API key
- `android/app/src/main/AndroidManifest.xml` - Android configuration
- `ios/Runner/AppDelegate.swift` - iOS configuration
- `pubspec.yaml` - Added flutter_dotenv package and .env to assets

