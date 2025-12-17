# Frontend Configuration Guide

## After Deploying Backend on Personal Server

Once you have deployed your Spring Boot backend on your personal server, you need to update the frontend applications to point to the deployed backend URL.

## Quick Steps

### 1. Update Backend URL in Both Frontend Apps

You need to update the backend URL in **two Flutter applications**:

1. **Admin Frontend**: `civildesk_frontend/lib/core/constants/app_constants.dart`
2. **Employee Frontend**: `civildesk_employee_frontend/lib/core/constants/app_constants.dart`

### 2. Configuration Details

Both files have been updated with a production/development toggle. Here's what you need to change:

#### Find these lines in both files:

```dart
static const String _productionBackendUrl = 'https://your-domain.com'; // TODO: Replace with your actual backend URL
static const bool _isProduction = true; // TODO: Set to false for local development
```

#### Replace with your actual backend URL:

**Option A: If you have a domain name with SSL (HTTPS)**
```dart
static const String _productionBackendUrl = 'https://yourdomain.com';
```

**Option B: If you're using IP address with SSL**
```dart
static const String _productionBackendUrl = 'https://123.456.789.0';
```

**Option C: If you're using HTTP only (not recommended for production)**
```dart
static const String _productionBackendUrl = 'http://your-server-ip:8080';
```

### 3. Important Notes

- **Do NOT include `/api`** in the URL - it's added automatically
- The URL should be the base URL where your backend is accessible
- If you configured Nginx with SSL (as per deployment guide), use `https://your-domain.com`
- If Nginx is configured, the backend is accessible on port 443 (HTTPS) or 80 (HTTP), not 8080

### 4. Face Service URL (Optional)

If you have deployed the face recognition service, update:
```dart
static const String _productionFaceServiceUrl = 'https://your-aws-face-service-url.com';
```

If you haven't deployed it yet, you can leave it as is or set it to an empty string.

### 5. Testing

After updating the URLs:

1. **For Production**: Make sure `_isProduction = true`
2. **For Local Development**: Set `_isProduction = false` to use local URLs

3. Rebuild your Flutter apps:
   ```bash
   # For Admin Frontend
   cd civildesk_frontend
   flutter clean
   flutter pub get
   flutter build apk  # or flutter run
   
   # For Employee Frontend
   cd civildesk_employee_frontend
   flutter clean
   flutter pub get
   flutter build apk  # or flutter run
   ```

### 6. Verify Connection

Test the connection by:
- Opening the app
- Attempting to login
- Checking if API calls are successful

If you see connection errors:
- Verify the backend URL is correct
- Check if the backend is accessible from your device/network
- Ensure CORS is configured on the backend to allow your frontend origin
- Check backend logs: `docker compose logs backend`

## Example Configuration

### If your backend is at `https://api.civildesk.com`:

**civildesk_frontend/lib/core/constants/app_constants.dart:**
```dart
static const String _productionBackendUrl = 'https://api.civildesk.com';
static const bool _isProduction = true;
```

**civildesk_employee_frontend/lib/core/constants/app_constants.dart:**
```dart
static const String _productionBackendUrl = 'https://api.civildesk.com';
static const bool _isProduction = true;
```

### If your backend is at `http://192.168.1.100:8080` (local network):

**civildesk_frontend/lib/core/constants/app_constants.dart:**
```dart
static const String _productionBackendUrl = 'http://192.168.1.100:8080';
static const bool _isProduction = true;
```

**civildesk_employee_frontend/lib/core/constants/app_constants.dart:**
```dart
static const String _productionBackendUrl = 'http://192.168.1.100:8080';
static const bool _isProduction = true;
```

## Backend CORS Configuration

Make sure your backend's `.env` file includes your frontend's origin in CORS settings:

```env
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

Or if testing from mobile apps, you may need to allow all origins temporarily:
```env
CORS_ALLOWED_ORIGINS=*
```

**Note**: Allowing all origins (`*`) is not recommended for production. Use specific origins.

## Troubleshooting

### Connection Timeout
- Check if the backend server is running
- Verify the URL is correct
- Check firewall settings on the server
- Ensure the port is open and accessible

### CORS Errors
- Update `CORS_ALLOWED_ORIGINS` in backend `.env` file
- Restart backend: `docker compose restart backend`

### SSL Certificate Errors
- If using self-signed certificate, you may need to configure Flutter to accept it
- For production, use a valid SSL certificate (Let's Encrypt recommended)

## Files Modified

- ✅ `civildesk_frontend/lib/core/constants/app_constants.dart`
- ✅ `civildesk_employee_frontend/lib/core/constants/app_constants.dart`

Both files now support easy switching between production and development modes.

