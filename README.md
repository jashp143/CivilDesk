# CivilDesk - Attendance Management System with Face Recognition

A comprehensive attendance management system with advanced face recognition capabilities built using FastAPI, Spring Boot, and Flutter.

## 🌟 Features

### Face Recognition System (Live Video)
- ✅ **Live Video Detection** - Continuous face detection on video stream
- ✅ **Temporal Caching** - Smooth recognition with 2-second cache
- ✅ **Face Registration** - 10-second video-based face registration
- ✅ **High Performance** - 40-50% faster than image-based processing
- ✅ **GPU Support** - CUDA/GPU acceleration with automatic CPU fallback
- ✅ **Real-time Bounding Boxes** - Smooth visual feedback with employee names
- ✅ **Multiple Punch Types** - Check In, Lunch Out, Lunch In, Check Out

### Attendance Management
- ✅ Daily attendance tracking
- ✅ Automatic punch time recording
- ✅ Face recognition confidence logging
- ✅ Real-time attendance overview
- ✅ Historical attendance reports

### Employee Management
- ✅ Complete employee information management
- ✅ Face registration integration
- ✅ Role-based access control
- ✅ Employee search and filtering

### Dashboard & Analytics
- ✅ Admin dashboard with statistics
- ✅ HR manager dashboard
- ✅ Employee self-service dashboard
- ✅ Real-time attendance charts

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter Frontend                      │
│              (Mobile App / Web Application)                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌─────────────┐      ┌──────────────────┐
│   Spring    │      │  Face Recognition│
│   Boot      │◄────►│  Service (FastAPI│
│   Backend   │      │  + InsightFace)  │
└──────┬──────┘      └────────┬─────────┘
       │                      │
       └──────────┬───────────┘
                  ▼
         ┌─────────────────┐
         │   PostgreSQL    │
         │    Database     │
         └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Java 17+
- Flutter 3.0+
- PostgreSQL 12+
- (Optional) NVIDIA GPU with CUDA for better performance

### 1. Clone Repository
```bash
git clone <repository-url>
cd Civildesk
```

### 2. Setup Face Recognition Service
```bash
cd face-recognition-service

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup configuration
python setup_env.py
# Edit .env and set your database credentials

# Start service
python main.py
```

The face recognition service will start on `http://localhost:8000`

### 3. Setup Backend
```bash
cd civildesk-backend/civildesk-backend

# Run with Maven
./mvnw spring-boot:run
```

The backend will start on `http://localhost:8080`

### 4. Setup Frontend
```bash
cd civildesk_frontend

# Get dependencies
flutter pub get

# Run app
flutter run
```

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get started in 5 minutes
- **[Setup Guide](SETUP_FACE_RECOGNITION.md)** - Detailed installation and configuration
- **[API Documentation](#api-endpoints)** - Complete API reference

## 🎯 Usage

### For Administrators

#### Register Employee Face
1. Navigate to **Employee Management**
2. Select an employee
3. Click **Face icon** in toolbar
4. Follow on-screen instructions
5. Record 10-second video
6. Face is registered!

#### View Attendance
1. Navigate to **Attendance → Daily Overview**
2. View all employee attendance for today
3. Filter by status, department, etc.

### For Employees

#### Mark Attendance with Face
1. Navigate to **Attendance → Mark Attendance**
2. Camera opens automatically
3. Position face in frame
4. When recognized, tap green box
5. Select punch type:
   - 🟢 **Check In** - Morning arrival
   - 🟠 **Lunch Out** - Going for lunch
   - 🔵 **Lunch In** - Back from lunch
   - 🔴 **Check Out** - End of day
6. Attendance marked!

## 🔧 Configuration

### Face Recognition Settings

Edit `face-recognition-service/.env`:

```env
# Detection sensitivity (0.0 - 1.0)
FACE_DETECTION_THRESHOLD=0.5

# Recognition strictness (0.0 - 1.0)
FACE_MATCHING_THRESHOLD=0.4

# Video duration for registration (seconds)
VIDEO_CAPTURE_DURATION=10

# GPU settings
USE_GPU=True
GPU_DEVICE_ID=0
```

### Backend Configuration

Edit `civildesk-backend/src/main/resources/application.properties`:

```properties
# Face service URL
face.recognition.service.url=http://localhost:8000

# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/civildesk
spring.datasource.username=postgres
spring.datasource.password=your_password
```

### Frontend Configuration

Edit `civildesk_frontend/lib/core/constants/app_constants.dart`:

```dart
// For physical devices, update with your computer's IP
static const String baseUrl = 'http://192.168.1.100:8080/api';
static const String faceServiceUrl = 'http://192.168.1.100:8000';
```

## 🎨 Screenshots

### Face Registration
![Face Registration](docs/images/face-registration.png)

### Face Recognition Attendance
![Face Attendance](docs/images/face-attendance.png)

### Employee Management
![Employee Management](docs/images/employee-management.png)

## 📊 Performance (Live Video Mode)

### CPU Mode
- Face Detection: 14-25 FPS (was 10-15)
- Processing Time: 40-70ms per frame (was 80-120ms)
- Cache Hit Rate: 60-80%
- **~45% faster** than image-based

### GPU Mode (NVIDIA RTX 3060)
- Face Detection: 40-60 FPS (was 25-35)
- Processing Time: 15-25ms per frame (was 25-40ms)
- Cache Hit Rate: 60-80%
- **~40% faster** than image-based

**NEW**: Temporal caching reduces computation by 60-80% for recognized faces!

## 🔐 Security

- **Face Embeddings**: One-way mathematical representation (cannot be reversed)
- **Local Storage**: Embeddings stored locally, not in cloud
- **Database Security**: Encrypted connections, parameterized queries
- **API Security**: JWT authentication, role-based access control
- **No Image Storage**: Only embeddings stored, never face images

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop
- ✅ Web Browser

## 🛠️ Technology Stack

### Backend
- **FastAPI** - Modern Python web framework
- **InsightFace** - State-of-the-art face recognition
- **OpenCV** - Computer vision library
- **ONNX Runtime** - High-performance inference
- **Spring Boot** - Java application framework
- **PostgreSQL** - Relational database

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Provider** - State management
- **Camera** - Camera access
- **Dio** - HTTP client

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 📄 License

Copyright © 2024 CivilTech. All rights reserved.

## 🐛 Troubleshooting

### Service won't start
```bash
# Check dependencies
pip list | grep insightface

# Check port availability
netstat -an | findstr :8000

# View logs
tail -f face-recognition-service/logs/face_service.log
```

### Low recognition accuracy
1. Improve lighting during registration
2. Register face again with better quality
3. Adjust `FACE_MATCHING_THRESHOLD` in .env
4. Ensure face is centered and clear

### GPU not detected
```bash
# Check CUDA installation
nvidia-smi

# Check ONNX Runtime providers
python -c "import onnxruntime; print(onnxruntime.get_available_providers())"

# Install GPU support
pip install onnxruntime-gpu
```

## 📞 Support

For issues, questions, or feature requests:
1. Check documentation: [SETUP_FACE_RECOGNITION.md](SETUP_FACE_RECOGNITION.md)
2. Run tests: `python face-recognition-service/test_service.py`
3. View logs: `face-recognition-service/logs/face_service.log`
4. Open an issue on GitHub

## 🎓 Credits

- **InsightFace** - Face recognition models
- **OpenCV** - Computer vision
- **FastAPI** - Web framework
- **Flutter** - UI framework

## 📈 Roadmap

- [ ] Multi-face recognition in single frame
- [ ] Liveness detection (anti-spoofing)
- [ ] Face mask detection
- [ ] Attendance analytics dashboard
- [ ] Mobile app notifications
- [ ] Biometric alternatives (fingerprint)
- [ ] Cloud deployment support
- [ ] Docker containerization

## 🌐 API Endpoints

### Face Recognition Service (Port 8000)

#### Health Check
```http
GET /health
```

#### Register Face
```http
POST /face/register
Content-Type: multipart/form-data

Parameters:
  - employee_id: string
  - video: file (MP4/AVI)

Response:
{
  "success": true,
  "message": "Face registered successfully",
  "employee_id": "EMP001",
  "name": "John_Doe"
}
```

#### Recognize Face (Stream)
```http
POST /face/recognize-stream
Content-Type: multipart/form-data

Parameters:
  - image: file (JPG/PNG)

Response:
{
  "success": true,
  "faces": [
    {
      "bbox": {"x1": 100, "y1": 120, "x2": 250, "y2": 300},
      "employee_id": "EMP001",
      "name": "John_Doe",
      "display_name": "John Doe",
      "confidence": 0.95
    }
  ]
}
```

#### Mark Attendance
```http
POST /face/attendance/mark
Content-Type: multipart/form-data

Parameters:
  - employee_id: string
  - punch_type: string (check_in|lunch_out|lunch_in|check_out)
  - confidence: float

Response:
{
  "success": true,
  "message": "Attendance marked successfully",
  "employee_id": "EMP001",
  "punch_type": "check_in",
  "attendance_id": 123
}
```

#### Delete Embeddings
```http
DELETE /face/embeddings/{employee_id}

Response:
{
  "success": true,
  "message": "Embeddings deleted for employee EMP001"
}
```

#### List Embeddings
```http
GET /face/embeddings/list

Response:
{
  "success": true,
  "count": 10,
  "embeddings": [
    {
      "name": "John_Doe",
      "employee_id": "EMP001",
      "first_name": "John",
      "last_name": "Doe"
    }
  ]
}
```

### Spring Boot Backend (Port 8080)

All endpoints are proxied through the main backend with JWT authentication.

#### Register Face
```http
POST /api/face/register
Authorization: Bearer <token>
Content-Type: multipart/form-data

Parameters:
  - employee_id: string
  - video: file
```

#### Detect Faces
```http
POST /api/face/detect
Authorization: Bearer <token>
Content-Type: multipart/form-data

Parameters:
  - image: file
```

#### Health Check
```http
GET /api/face/health
Authorization: Bearer <token>
```

---

**Built with ❤️ by CivilTech**

