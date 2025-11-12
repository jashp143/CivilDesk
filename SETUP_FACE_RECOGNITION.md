# Face Recognition Setup Guide

This guide will help you set up the face recognition system for the Civildesk attendance marking application.

## Prerequisites

- Python 3.8 or higher
- Java 17 or higher (for Spring Boot)
- Flutter SDK
- PostgreSQL database
- Camera access on your device

## Setup Steps

### 1. Python Flask Service Setup

1. Navigate to the `face_recognition_service` directory:
```bash
cd face_recognition_service
```

2. Create a virtual environment:
```bash
python -m venv venv
```

3. Activate the virtual environment:
- Windows: `venv\Scripts\activate`
- Linux/Mac: `source venv/bin/activate`

4. Install dependencies:
```bash
pip install -r requirements.txt
```

5. The InsightFace models will be automatically downloaded on first run. Alternatively, you can download them manually:
- RetinaFace model for face detection
- ArcFace model for face recognition

6. Start the Flask service:
```bash
python app.py
```

The service will run on `http://localhost:8000`

### 2. Spring Boot Backend Setup

1. Ensure PostgreSQL is running and the database is created.

2. The backend will automatically create the `attendance` table on startup.

3. Update `application.properties` or `.env` file with face recognition service URL:
```properties
face.recognition.service.url=http://localhost:8000
```

4. Start the Spring Boot application:
```bash
cd civildesk-backend/civildesk-backend
./mvnw spring-boot:run
```

### 3. Flutter Frontend Setup

1. Navigate to the Flutter project:
```bash
cd civildesk_frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update `lib/core/constants/app_constants.dart` if needed to point to your backend and face recognition service URLs.

4. Run the Flutter app:
```bash
flutter run
```

## Usage

### Registering a Face

1. Navigate to the employee management screen (Admin/HR Manager only).
2. Select an employee.
3. Click "Register Face" button.
4. The app will open the camera.
5. Click "Start Recording" and record a 10-second video of the employee's face.
6. The video will be processed and face embeddings will be stored.

### Marking Attendance

1. Navigate to the attendance marking screen.
2. The camera will automatically start detecting faces.
3. When a recognized face appears (green bounding box), tap on it to mark attendance.
4. Unknown faces will show a red bounding box.

## API Endpoints

### Face Recognition Service (Flask - Port 8000)

- `GET /health` - Health check
- `POST /face/register` - Register face from video
  - Form data: `video` (file), `employee_id` (string)
- `POST /face/detect` - Detect and recognize faces in image
  - Form data: `image` (file)
- `GET /face/embeddings/list` - List all registered employees
- `DELETE /face/embeddings/<employee_id>` - Delete employee embeddings

### Spring Boot Backend (Port 8080)

- `POST /api/face/register` - Register face (requires authentication)
- `POST /api/face/detect` - Detect faces (requires authentication)
- `GET /api/face/health` - Check face recognition service health
- `POST /api/attendance/mark` - Mark attendance with face recognition
- `POST /api/attendance/checkout` - Check out
- `GET /api/attendance/today/{employeeId}` - Get today's attendance
- `GET /api/attendance/employee/{employeeId}` - Get attendance history

## Troubleshooting

### Face Recognition Service Not Starting

- Check if port 8000 is available
- Ensure all Python dependencies are installed
- Check if InsightFace models are downloaded

### Face Not Detected

- Ensure good lighting conditions
- Face should be clearly visible and centered
- Check camera permissions

### Face Not Recognized

- Ensure face is registered first
- Check if embeddings.pickle file exists and has data
- Verify employee_id matches

### Spring Boot Cannot Connect to Flask Service

- Verify Flask service is running on port 8000
- Check `face.recognition.service.url` in application.properties
- Check firewall settings

## File Structure

```
face_recognition_service/
├── app.py                    # Flask application
├── requirements.txt          # Python dependencies
├── embeddings.pickle        # Stored face embeddings (auto-generated)
├── uploads/                  # Temporary upload directory
└── services/
    ├── face_detector.py     # Face detection service
    ├── face_recognizer.py  # Face recognition service
    ├── embedding_manager.py # Embedding storage manager
    └── video_processor.py   # Video processing service
```

## Configuration

### Face Recognition Threshold

Default threshold is 0.6 (60% similarity). You can adjust this in:
- `face_recognition_service/services/face_recognizer.py` - `threshold` parameter

### Video Duration

Default video duration for registration is 10 seconds. You can adjust this in:
- `face_recognition_service/services/video_processor.py` - `target_duration` parameter

## Security Notes

- Face recognition service should be run on a secure network
- Consider adding authentication to Flask endpoints
- Store embeddings.pickle file securely
- Implement rate limiting for production use

