# Face Recognition Service

Face recognition service for CivilDesk attendance management system using InsightFace and OpenCV.

## Features

- Face detection and recognition using InsightFace
- GPU/CUDA support with automatic CPU fallback
- Video-based face registration (10 seconds)
- Real-time face recognition for attendance marking
- Integration with PostgreSQL database
- RESTful API using FastAPI

## Installation

### Prerequisites

- Python 3.8 or higher
- CUDA Toolkit (optional, for GPU support)
- PostgreSQL database

### Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
- Database credentials
- GPU settings
- Service port

4. Run the service:
```bash
python main.py
```

Or use uvicorn:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### Health Check
```
GET /health
```

### Register Face
```
POST /face/register
Form Data:
  - employee_id: string
  - video: file (MP4/AVI)
```

### Detect Faces
```
POST /face/detect
Form Data:
  - image: file (JPG/PNG)
```

### Recognize in Stream
```
POST /face/recognize-stream
Form Data:
  - image: file (JPG/PNG)
```

### Mark Attendance
```
POST /face/attendance/mark
Form Data:
  - employee_id: string
  - punch_type: string (check_in, lunch_out, lunch_in, check_out)
  - confidence: float
```

### Delete Embeddings
```
DELETE /face/embeddings/{employee_id}
```

### List Embeddings
```
GET /face/embeddings/list
```

## GPU Support

The service automatically detects and uses CUDA-enabled GPUs if available. To force CPU usage, set `USE_GPU=False` in `.env`.

### Check GPU Status

```python
import onnxruntime as ort
print(ort.get_available_providers())
```

If `CUDAExecutionProvider` is in the list, GPU will be used.

## Face Registration Process

1. Upload a 10-second video of the employee's face
2. System extracts face embeddings from multiple frames
3. Embeddings are averaged and normalized
4. Stored as `firstname_lastname:embeddings` in PKL file

## Face Recognition Process

1. Capture image from camera/video feed
2. Detect faces using InsightFace
3. Extract embeddings for each detected face
4. Compare with stored embeddings using cosine similarity
5. Return matches with confidence scores
6. Draw bounding boxes with employee names

## Troubleshooting

### CUDA/GPU Issues

If GPU is not being detected:
1. Install CUDA Toolkit from NVIDIA
2. Install `onnxruntime-gpu`: `pip install onnxruntime-gpu`
3. Verify CUDA installation: `nvidia-smi`

### Model Download Issues

InsightFace models are downloaded automatically on first run. If download fails:
1. Check internet connection
2. Manually download models from InsightFace repository
3. Place in `~/.insightface/models/`

### Database Connection Issues

1. Verify PostgreSQL is running
2. Check database credentials in `.env`
3. Ensure database `civildesk` exists
4. Check network connectivity

## Performance

- CPU: ~10-15 FPS for detection and recognition
- GPU (NVIDIA RTX 3060): ~30-45 FPS
- Face registration: ~10 seconds per employee

## License

Copyright © 2024 CivilTech

