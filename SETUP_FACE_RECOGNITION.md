# Face Recognition Setup Guide

This guide will help you set up the face recognition system for CivilDesk attendance management.

## Architecture

The system consists of three components:
1. **Python FastAPI Service** - Face recognition backend using InsightFace
2. **Java Spring Boot Backend** - Main application backend
3. **Flutter Frontend** - Mobile/web application

## Prerequisites

### System Requirements
- Python 3.8 or higher
- PostgreSQL 12 or higher
- Java 17 or higher
- Flutter 3.0 or higher
- (Optional) NVIDIA GPU with CUDA for better performance

### Python Dependencies
- InsightFace
- OpenCV
- FastAPI
- ONNX Runtime (with GPU support if available)

## Installation Steps

### 1. Setup Python Face Recognition Service

#### Navigate to service directory
```bash
cd face-recognition-service
```

#### Create virtual environment
```bash
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate
```

#### Install dependencies
```bash
# Install CPU version (works on all systems)
pip install -r requirements.txt

# For GPU support (NVIDIA GPUs only)
pip uninstall onnxruntime
pip install onnxruntime-gpu==1.16.3
```

#### Configure environment
```bash
# Create .env file
python setup_env.py

# Edit .env file and update:
# - DB_PASSWORD with your PostgreSQL password
# - DB_HOST, DB_PORT, DB_NAME if different
# - USE_GPU=True if you have CUDA-enabled GPU
```

#### Test the service
```bash
# Start the service
python main.py

# In another terminal, run tests
python test_service.py
```

### 2. Verify Database Connection

The face recognition service needs access to your PostgreSQL database.

```sql
-- Connect to PostgreSQL
psql -U postgres

-- Verify civildesk database exists
\l

-- If not, create it
CREATE DATABASE civildesk;

-- Connect to database
\c civildesk

-- Verify employee table exists
\dt
```

### 3. Configure Java Backend

The Java backend is already configured to communicate with the face recognition service.

Verify in `application.properties`:
```properties
face.recognition.service.url=http://localhost:8000
```

### 4. Configure Flutter Frontend

The Flutter frontend is already configured to use the face recognition service.

Verify in `lib/core/constants/app_constants.dart`:
```dart
static String get faceServiceUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';  // Android emulator
  } else if (Platform.isIOS) {
    return 'http://localhost:8000';  // iOS simulator
  } else {
    return 'http://localhost:8000';  // Desktop
  }
}
```

**For physical devices:** Update with your computer's IP address:
```dart
return 'http://192.168.1.100:8000';  // Replace with your IP
```

## Running the System

### Start all services in order:

#### 1. Start PostgreSQL
```bash
# On Windows
# PostgreSQL should be running as a service

# On Linux/Mac
sudo systemctl start postgresql
```

#### 2. Start Face Recognition Service
```bash
cd face-recognition-service
venv\Scripts\activate  # or source venv/bin/activate
python main.py
```

The service will start on `http://localhost:8000`

#### 3. Start Java Backend
```bash
cd civildesk-backend/civildesk-backend
./mvnw spring-boot:run
```

The backend will start on `http://localhost:8080`

#### 4. Start Flutter Frontend
```bash
cd civildesk_frontend
flutter run
```

## Usage

### Face Registration (Employee Management)

1. Login as Admin or HR Manager
2. Navigate to Employee Management
3. Select an employee
4. Click the "Face" icon in the toolbar
5. The camera will open
6. Click "Start Recording"
7. Keep your face in frame for 10 seconds
8. The system will process and register your face

### Face Recognition Attendance

1. Login as any user
2. Navigate to Attendance → Mark Attendance
3. The camera will open automatically
4. Position your face in front of the camera
5. When recognized, a green bounding box appears with your name
6. Tap on the green box
7. Select punch type (Check In, Lunch Out, Lunch In, Check Out)
8. Attendance will be marked

## GPU Support

### Check GPU Availability

```python
import onnxruntime as ort
print(ort.get_available_providers())
```

If `CUDAExecutionProvider` is listed, GPU will be used automatically.

### Enable GPU Support

1. Install CUDA Toolkit from NVIDIA
2. Install cuDNN
3. Install onnxruntime-gpu:
```bash
pip uninstall onnxruntime
pip install onnxruntime-gpu
```

4. Set in `.env`:
```
USE_GPU=True
GPU_DEVICE_ID=0
```

## Performance

### CPU Performance
- Detection: 10-15 FPS
- Recognition: 8-12 FPS
- Registration: 10 seconds

### GPU Performance (RTX 3060)
- Detection: 30-45 FPS
- Recognition: 25-35 FPS
- Registration: 10 seconds

## Troubleshooting

### Service won't start

**Error:** `ModuleNotFoundError: No module named 'insightface'`
- Solution: Activate virtual environment and run `pip install -r requirements.txt`

**Error:** `Connection to database failed`
- Solution: Verify PostgreSQL is running and credentials in `.env` are correct

### Face detection not working

**Issue:** No faces detected
- Ensure good lighting
- Face should be clearly visible
- Try adjusting `FACE_DETECTION_THRESHOLD` in `.env` (lower = more sensitive)

### Face recognition low accuracy

**Issue:** Faces not recognized or low confidence
- Register face again with better lighting
- Ensure face is centered during registration
- Adjust `FACE_MATCHING_THRESHOLD` in `.env` (higher = more strict)

### GPU not being used

**Issue:** Service running on CPU despite GPU available
- Install CUDA Toolkit
- Install onnxruntime-gpu
- Set `USE_GPU=True` in `.env`
- Restart the service

### Camera not working in Flutter

**Android:** Add permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS:** Add to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access required for face recognition</string>
```

### Cannot connect from mobile device

**Issue:** Connection refused or timeout
- Use computer's IP address instead of localhost
- Ensure firewall allows connections on ports 8000 and 8080
- Both devices should be on the same network

## API Endpoints

### Face Recognition Service (Port 8000)

- `GET /health` - Health check
- `POST /face/register` - Register face from video
- `POST /face/detect` - Detect faces in image
- `POST /face/recognize-stream` - Recognize faces (real-time)
- `POST /face/attendance/mark` - Mark attendance
- `DELETE /face/embeddings/{employee_id}` - Delete face data
- `GET /face/embeddings/list` - List registered faces

### Java Backend (Port 8080)

- `POST /api/face/register` - Proxy to face service
- `POST /api/face/detect` - Proxy to face service
- `GET /api/face/health` - Check face service health

## File Structure

```
face-recognition-service/
├── main.py                      # FastAPI application
├── config.py                    # Configuration
├── database.py                  # Database operations
├── face_recognition_engine.py   # Face recognition logic
├── requirements.txt             # Python dependencies
├── setup_env.py                 # Environment setup script
├── test_service.py             # Test script
├── .env                        # Configuration (create this)
├── data/
│   ├── embeddings.pkl          # Stored face embeddings
│   └── temp_videos/            # Temporary video storage
└── logs/
    └── face_service.log        # Service logs
```

## Security Considerations

1. **Face Data Storage**: Face embeddings are stored locally in PKL file
2. **Database Access**: Service needs read access to employee table
3. **API Access**: No authentication on face service (runs locally)
4. **Data Privacy**: Face embeddings cannot be reverse-engineered to images

## Maintenance

### Backup Face Embeddings

```bash
cp data/embeddings.pkl data/embeddings_backup_$(date +%Y%m%d).pkl
```

### Clear All Face Data

```bash
# Stop the service first
rm data/embeddings.pkl
# Restart the service
```

### View Logs

```bash
tail -f logs/face_service.log
```

### Update Models

InsightFace models are downloaded automatically on first run to:
- Windows: `C:\Users\<username>\.insightface\models\`
- Linux/Mac: `~/.insightface/models/`

To update models, delete the folder and restart the service.

## Support

For issues or questions:
1. Check logs: `logs/face_service.log`
2. Run test script: `python test_service.py`
3. Verify all services are running
4. Check network connectivity

## License

Copyright © 2024 CivilTech. All rights reserved.

