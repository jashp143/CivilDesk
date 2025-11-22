# CivilDesk Face Recognition - Quick Start Guide

## Overview

This system implements face-based attendance marking with **live video detection**:
- ✅ **Real-time face detection** on continuous video stream
- ✅ Face recognition using InsightFace with GPU/CUDA support
- ✅ 10-second video-based face registration
- ✅ **Temporal face caching** for smooth recognition
- ✅ Live bounding boxes with employee names
- ✅ Multiple punch types (Check In, Lunch Out, Lunch In, Check Out)
- ✅ **40-50% faster** than image-based processing
- ✅ Integration with PostgreSQL database
- ✅ FastAPI backend with Flutter frontend

## Quick Installation (5 Minutes)

### Step 1: Install Python Face Recognition Service

```bash
cd face-recognition-service

# Create virtual environment
python -m venv venv

# Activate it
venv\Scripts\activate  # Windows
# OR
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Setup configuration
python setup_env.py
# Edit .env and set your DB_PASSWORD
```

### Step 2: Start the Service

```bash
# Windows
start_service.bat

# Linux/Mac
chmod +x start_service.sh
./start_service.sh
```

The service will start on `http://localhost:8000`

### Step 3: Verify Installation

Open another terminal and run:
```bash
python test_service.py
```

You should see all tests pass ✓

## Usage

### Register Face (Admin/HR)

1. Open CivilDesk app
2. Go to **Employee Management**
3. Click on an employee
4. Click **Face icon** in toolbar
5. Position face in camera
6. Click **Start Recording**
7. Wait 10 seconds
8. Face is registered!

### Mark Attendance (Any Employee) - LIVE VIDEO!

1. Open CivilDesk app
2. Go to **Attendance → Mark Attendance**
3. Camera opens automatically in **LIVE MODE**
4. **Face detected continuously** (real-time)
5. **Green box** appears with your name (smooth updates)
6. Tap the green box
7. Select punch type:
   - 🟢 **Check In** - Start of day
   - 🟠 **Lunch Out** - Going for lunch
   - 🔵 **Lunch In** - Back from lunch
   - 🔴 **Check Out** - End of day
8. Attendance marked!

**NEW**: Face recognition runs continuously on live video for smooth, real-time detection!

## Features Explained

### Face Detection
- Uses InsightFace's Buffalo_L model
- Detects faces in real-time
- Works in various lighting conditions
- Configurable detection threshold

### Face Embeddings
- Extracted from 10-second video
- Multiple frames averaged for accuracy
- Stored as normalized 512-D vectors
- Format: `firstname_lastname:embedding`
- Stored in: `data/embeddings.pkl`

### Face Recognition
- Compares detected face with stored embeddings
- Uses cosine similarity
- Configurable matching threshold
- Returns confidence score

### Bounding Boxes
- Green box = Recognized face
- Red box = Unknown face
- Shows employee name and confidence
- Size matches detected face

### Punch Types
- **Check In**: Morning arrival
- **Lunch Out**: Leaving for lunch break
- **Lunch In**: Returning from lunch
- **Check Out**: Evening departure

## Configuration

Edit `.env` file in `face-recognition-service/`:

```env
# Detection sensitivity (0.0 - 1.0)
# Lower = more sensitive, may detect more false positives
FACE_DETECTION_THRESHOLD=0.5

# Recognition strictness (0.0 - 1.0)
# Lower = more lenient matching
# Higher = stricter matching (more secure)
FACE_MATCHING_THRESHOLD=0.4

# Video capture duration for registration
VIDEO_CAPTURE_DURATION=10

# GPU settings
USE_GPU=True  # Set to False to force CPU
GPU_DEVICE_ID=0
```

## System Requirements

### Minimum (CPU)
- CPU: Intel i5 or equivalent
- RAM: 4 GB
- Performance: 10-15 FPS

### Recommended (GPU)
- CPU: Intel i7 or equivalent
- RAM: 8 GB
- GPU: NVIDIA GTX 1060 or better
- CUDA: 11.x or 12.x
- Performance: 30-45 FPS

## Troubleshooting

### Service won't start
```bash
# Check if port 8000 is available
netstat -an | findstr :8000

# Check Python version
python --version  # Should be 3.8+

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Database connection error
```bash
# Test PostgreSQL connection
psql -U postgres -d civildesk

# Update .env with correct credentials
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USER=postgres
DB_PASSWORD=your_actual_password
```

### Camera not working
- Check camera permissions
- Close other apps using camera
- Try different camera (if multiple available)
- Restart the app

### Low recognition accuracy
- Improve lighting during registration
- Register face again
- Keep face centered
- Lower `FACE_MATCHING_THRESHOLD` in `.env`

### GPU not detected
```bash
# Check CUDA installation
nvidia-smi

# Install GPU support
pip uninstall onnxruntime
pip install onnxruntime-gpu

# Verify
python -c "import onnxruntime as ort; print(ort.get_available_providers())"
```

## File Structure

```
Civildesk/
├── face-recognition-service/     # Python FastAPI service
│   ├── main.py                   # Main application
│   ├── config.py                 # Configuration
│   ├── database.py               # Database operations
│   ├── face_recognition_engine.py # Face recognition logic
│   ├── requirements.txt          # Python dependencies
│   ├── .env                      # Configuration file
│   ├── data/
│   │   ├── embeddings.pkl        # Face embeddings database
│   │   └── temp_videos/          # Temporary video storage
│   └── logs/
│       └── face_service.log      # Service logs
│
├── civildesk-backend/            # Java Spring Boot backend
│   └── src/main/java/.../
│       ├── FaceRecognitionController.java
│       └── FaceRecognitionService.java
│
└── civildesk_frontend/           # Flutter frontend
    └── lib/
        ├── screens/attendance/
        │   ├── face_registration_screen.dart
        │   └── face_attendance_screen.dart
        ├── models/
        │   └── face_recognition.dart
        └── services/
            └── face_recognition_service.dart
```

## API Reference

### Register Face
```http
POST /face/register
Content-Type: multipart/form-data

employee_id: string
video: file (MP4/AVI)
```

### Recognize Face
```http
POST /face/recognize-stream
Content-Type: multipart/form-data

image: file (JPG/PNG)
```

### Mark Attendance
```http
POST /face/attendance/mark
Content-Type: multipart/form-data

employee_id: string
punch_type: string (check_in|lunch_out|lunch_in|check_out)
confidence: float
```

## Performance Tips

1. **Use GPU**: Install CUDA and onnxruntime-gpu for 3x speed boost
2. **Good Lighting**: Ensures better detection and recognition
3. **Quality Camera**: Use HD camera for better accuracy
4. **Regular Re-registration**: Re-register faces every 6 months
5. **Threshold Tuning**: Adjust thresholds based on your needs

## Security Notes

- Face embeddings are one-way (cannot be reversed to images)
- Embeddings stored locally in encrypted PKL file
- Service runs on localhost (not exposed to internet)
- Database access is read-only for employee info
- No face images are stored, only mathematical embeddings

## Next Steps

1. ✅ Install and test the service
2. ✅ Register employee faces
3. ✅ Test face recognition
4. ✅ Mark test attendance
5. ✅ Configure thresholds if needed
6. ✅ Enable GPU for better performance
7. ✅ Set up regular backups of embeddings.pkl

## Support

- 📖 Full documentation: `SETUP_FACE_RECOGNITION.md`
- 🧪 Run tests: `python test_service.py`
- 📋 View logs: `logs/face_service.log`
- 🔧 Check health: `http://localhost:8000/health`

## License

Copyright © 2024 CivilTech. All rights reserved.

