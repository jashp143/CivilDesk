# Face Recognition Service

A Flask-based face recognition service using InsightFace and OpenCV for attendance marking.

## Features

- Face detection using InsightFace RetinaFace model
- Face embedding extraction and storage
- Face recognition and matching
- 10-second video processing for face registration
- Real-time face detection with bounding boxes

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Download InsightFace models:
The service will automatically download required models on first run. Alternatively, you can download them manually:
- RetinaFace model for face detection
- ArcFace model for face recognition

## Usage

1. Start the Flask service:
```bash
python app.py
```

The service will run on `http://localhost:8000`

## API Endpoints

### Health Check
- `GET /health` - Check service health

### Face Registration
- `POST /face/register` - Register a face from 10-second video
  - Form data:
    - `video`: Video file (MP4, AVI, etc.)
    - `employee_id`: Employee identifier string

### Face Detection
- `POST /face/detect` - Detect and recognize faces in an image
  - Form data:
    - `image`: Image file (JPG, PNG, etc.)
  - Returns: List of detected faces with bounding boxes and recognition results

### Embeddings Management
- `GET /face/embeddings/list` - List all registered employee IDs
- `DELETE /face/embeddings/<employee_id>` - Delete embeddings for an employee

## File Structure

```
face_recognition_service/
├── app.py                 # Flask application
├── requirements.txt       # Python dependencies
├── embeddings.pickle      # Stored face embeddings (auto-generated)
├── uploads/               # Temporary upload directory
└── services/
    ├── __init__.py
    ├── face_detector.py   # Face detection service
    ├── face_recognizer.py # Face recognition service
    ├── embedding_manager.py # Embedding storage manager
    └── video_processor.py # Video processing service
```

## Configuration

- Face recognition threshold: 0.6 (configurable in `FaceRecognizer`)
- Video duration: 10 seconds
- Minimum face detections: 5 frames
- Target FPS for processing: 30

