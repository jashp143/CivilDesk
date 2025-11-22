# Face Recognition Attendance System - Workflow

## System Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Frontend                         │
│                    (Employee Interface)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP Requests
                         │
         ┌───────────────┴────────────────┐
         │                                │
         ▼                                ▼
┌─────────────────┐            ┌──────────────────────┐
│  Spring Boot    │            │  FastAPI Service     │
│  Backend        │◄──────────►│  (Face Recognition)  │
│  (Port 8080)    │   Proxies  │  (Port 8000)         │
└────────┬────────┘            └──────────┬───────────┘
         │                                │
         │                                │ Reads
         │ Reads/Writes                   │ Employees
         │ Attendance                     │
         │                                │
         └────────────┬───────────────────┘
                      ▼
              ┌──────────────┐
              │  PostgreSQL  │
              │   Database   │
              └──────────────┘
```

## Face Registration Workflow

```
1. Admin/HR Manager Opens Employee Management
   │
   ├─► Selects Employee
   │
   ├─► Clicks Face Icon
   │
   └─► Face Registration Screen Opens
       │
       ├─► Camera Initializes
       │
       ├─► User Clicks "Start Recording"
       │
       ├─► Records 10-second Video
       │   │
       │   ├─► Frame 1 → Extract Face Embedding
       │   ├─► Frame 2 → Extract Face Embedding
       │   ├─► Frame 3 → Extract Face Embedding
       │   └─► ... (100+ frames)
       │
       ├─► Send Video to FastAPI Service
       │
       └─► FastAPI Service:
           │
           ├─► Fetch Employee Details from Database
           │   └─► Get firstname and lastname
           │
           ├─► Process Video
           │   ├─► Extract faces from frames
           │   ├─► Generate embeddings
           │   └─► Average embeddings
           │
           ├─► Store Embedding
           │   └─► Format: "firstname_lastname": embedding
           │       └─► Save to data/embeddings.pkl
           │
           └─► Return Success
               └─► Display "Face registered successfully!"
```

## Face Recognition Attendance Workflow

```
1. Employee Opens Attendance Module
   │
   ├─► Selects "Face Recognition Attendance"
   │
   └─► Face Attendance Screen Opens
       │
       ├─► Camera Initializes
       │
       ├─► Start Continuous Detection Loop
       │   │
       │   └─► Every 1.5 seconds:
       │       │
       │       ├─► Capture Frame
       │       │
       │       ├─► Send to FastAPI Service
       │       │
       │       └─► FastAPI Service:
       │           │
       │           ├─► Detect Faces in Frame
       │           │   └─► InsightFace Detection
       │           │
       │           ├─► For Each Detected Face:
       │           │   │
       │           │   ├─► Extract Embedding
       │           │   │
       │           │   ├─► Compare with Stored Embeddings
       │           │   │   └─► Calculate Cosine Similarity
       │           │   │
       │           │   ├─► Find Best Match
       │           │   │
       │           │   └─► If similarity > threshold:
       │           │       ├─► recognized = true
       │           │       ├─► employee_id = match.employee_id
       │           │       ├─► first_name = match.first_name
       │           │       └─► last_name = match.last_name
       │           │
       │           └─► Return:
       │               ├─► Bounding Box Coordinates
       │               ├─► Employee Info
       │               └─► Confidence Score
       │
       ├─► Display Results:
       │   │
       │   ├─► Draw Bounding Box
       │   │   ├─► Green if recognized
       │   │   └─► Red if unknown
       │   │
       │   ├─► Show Employee Name
       │   │   └─► Format: "First Last"
       │   │
       │   └─► Show Confidence %
       │
       ├─► User Taps Green Box
       │   │
       │   └─► Show Punch Options:
       │       ├─► 🟢 Check In
       │       ├─► 🟠 Lunch Out
       │       ├─► 🔵 Lunch In
       │       └─► 🔴 Check Out
       │
       ├─► User Selects Punch Type
       │
       └─► Mark Attendance:
           │
           ├─► Send to FastAPI Service:
           │   ├─► employee_id
           │   ├─► punch_type
           │   └─► confidence
           │
           └─► FastAPI Service:
               │
               ├─► Check Database for Today's Record
               │
               ├─► If exists:
               │   └─► Update punch time
               │
               ├─► If not exists:
               │   └─► Create new record
               │
               ├─► Save to Database:
               │   ├─► employee_id
               │   ├─► date = today
               │   ├─► punch_time = now
               │   ├─► recognition_method = "FACE_RECOGNITION"
               │   ├─► confidence = score
               │   └─► status = "PRESENT"
               │
               └─► Return Success
                   └─► Display "Attendance marked!"
```

## Data Flow Diagrams

### Face Embedding Storage

```
Employee: John Doe (ID: EMP001)
    │
    ├─► Registration Video (10 seconds)
    │
    ├─► Process Video → Extract 100+ face embeddings
    │
    ├─► Average embeddings → Single 512-D vector
    │
    ├─► Normalize vector → Unit length
    │
    └─► Store in embeddings.pkl:
        {
          "John_Doe": {
            "employee_id": "EMP001",
            "first_name": "John",
            "last_name": "Doe",
            "embedding": [0.123, -0.456, 0.789, ...]  // 512 values
          }
        }
```

### Face Recognition Process

```
Input: Camera Frame (640x480 pixels)
    │
    ├─► Detect Face → Bounding Box (x1, y1, x2, y2)
    │
    ├─► Extract Face Region → Crop image
    │
    ├─► Preprocess → Resize, normalize
    │
    ├─► Neural Network → Generate embedding (512-D)
    │
    ├─► Compare with Database:
    │   │
    │   ├─► For each stored embedding:
    │   │   │
    │   │   ├─► Calculate distance
    │   │   │   └─► ||embedding1 - embedding2||
    │   │   │
    │   │   └─► Find minimum distance
    │   │
    │   └─► If distance < threshold:
    │       ├─► Match found!
    │       └─► Return employee info
    │
    └─► Output:
        ├─► Bounding box coordinates
        ├─► Employee ID
        ├─► First name
        ├─► Last name
        └─► Confidence score
```

## Database Schema

### Employee Table
```sql
CREATE TABLE employee (
  id SERIAL PRIMARY KEY,
  employee_id VARCHAR(50) UNIQUE NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  department VARCHAR(100),
  designation VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  -- ... other fields
);
```

### Attendance Table
```sql
CREATE TABLE attendance (
  id SERIAL PRIMARY KEY,
  employee_id VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  check_in_time TIMESTAMP,
  lunch_out_time TIMESTAMP,
  lunch_in_time TIMESTAMP,
  check_out_time TIMESTAMP,
  recognition_method VARCHAR(50),  -- 'FACE_RECOGNITION'
  face_recognition_confidence DECIMAL(5,4),
  status VARCHAR(20),  -- 'PRESENT', 'ABSENT', etc.
  notes TEXT,
  FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);
```

## File System Storage

```
face-recognition-service/
├── data/
│   ├── embeddings.pkl              ← Face embeddings database
│   │   Format:
│   │   {
│   │     "John_Doe": {
│   │       "employee_id": "EMP001",
│   │       "first_name": "John",
│   │       "last_name": "Doe",
│   │       "embedding": [...]
│   │     },
│   │     "Jane_Smith": { ... },
│   │     ...
│   │   }
│   │
│   └── temp_videos/                ← Temporary video storage
│       ├── EMP001_video.mp4       (deleted after processing)
│       └── EMP002_video.mp4       (deleted after processing)
│
└── logs/
    └── face_service.log            ← Service logs
```

## Network Communication

### Registration Flow
```
Flutter App                Spring Boot             FastAPI
    │                         │                      │
    ├─ POST /api/face/register                      │
    │     (video file)         │                     │
    │  ──────────────────────► │                     │
    │                         │                      │
    │                         ├─ POST /face/register │
    │                         │     (video, emp_id)  │
    │                         │  ───────────────────►│
    │                         │                      │
    │                         │                    ┌─┴─┐
    │                         │                    │ Process:
    │                         │                    │ - Fetch employee
    │                         │                    │ - Extract embeddings
    │                         │                    │ - Store in PKL
    │                         │                    └─┬─┘
    │                         │                      │
    │                         │  ◄─────────────────  │
    │                         │    { success: true } │
    │  ◄────────────────────  │                      │
    │    { success: true }    │                      │
    │                         │                      │
```

### Attendance Flow
```
Flutter App                FastAPI
    │                         │
    ├─ POST /face/recognize-stream
    │     (image)             │
    │  ──────────────────────►│
    │                         │
    │                       ┌─┴─┐
    │                       │ Process:
    │                       │ - Detect faces
    │                       │ - Extract embeddings
    │                       │ - Match with database
    │                       │ - Return results
    │                       └─┬─┘
    │                         │
    │  ◄────────────────────  │
    │    { faces: [...] }     │
    │                         │
    │  [User taps face]       │
    │                         │
    ├─ POST /face/attendance/mark
    │     (employee_id, type, conf)
    │  ──────────────────────►│
    │                         │
    │                       ┌─┴─┐
    │                       │ Process:
    │                       │ - Validate employee
    │                       │ - Mark attendance in DB
    │                       │ - Return success
    │                       └─┬─┘
    │                         │
    │  ◄────────────────────  │
    │    { success: true }    │
    │                         │
```

## Performance Optimization

### CPU Mode
```
Camera Frame (30 FPS)
    │
    ├─► Capture every 1.5 seconds (to reduce CPU load)
    │
    ├─► Detect faces: ~80-100ms
    │
    ├─► Extract embeddings: ~50-70ms
    │
    ├─► Compare with database: ~10-20ms
    │
    └─► Total: ~140-190ms per frame
        Result: ~5-7 FPS effective processing
```

### GPU Mode
```
Camera Frame (30 FPS)
    │
    ├─► Capture every 1.5 seconds
    │
    ├─► Detect faces: ~15-25ms (GPU accelerated)
    │
    ├─► Extract embeddings: ~10-15ms (GPU accelerated)
    │
    ├─► Compare with database: ~5-10ms
    │
    └─► Total: ~30-50ms per frame
        Result: ~20-30 FPS effective processing
```

## Error Handling

```
Face Registration
    │
    ├─► Error: No face detected
    │   └─► Show: "No face found. Please face the camera."
    │
    ├─► Error: Multiple faces
    │   └─► Show: "Multiple faces detected. Only one person at a time."
    │
    ├─► Error: Video too short
    │   └─► Show: "Recording incomplete. Please try again."
    │
    ├─► Error: Poor quality
    │   └─► Show: "Face not clear. Improve lighting and try again."
    │
    └─► Error: Database connection
        └─► Show: "Connection error. Please try again."

Face Recognition
    │
    ├─► Error: Camera not available
    │   └─► Show: "Camera not accessible. Check permissions."
    │
    ├─► Error: Service unavailable
    │   └─► Show: "Face recognition service not available."
    │
    ├─► Error: No face detected
    │   └─► Show: "Position your face in frame."
    │
    └─► Success: Face recognized
        └─► Show: Green bounding box with name
```

## Security Flow

```
Registration:
    ├─► Video captured → Processed in memory → Deleted
    ├─► Face image → Embedding extracted → Image discarded
    ├─► Embedding stored → Cannot be reversed to image
    └─► One-way transformation: Image → Embedding ✓
                                Embedding → Image ✗

Authentication:
    ├─► JWT token required for API calls
    ├─► Role-based access:
    │   ├─► Registration: Admin, HR Manager
    │   └─► Attendance: All users
    └─► Database: Read-only for face service

Data Storage:
    ├─► Embeddings: Local file system (not cloud)
    ├─► Database: Attendance records only
    └─► Images/Videos: Never stored permanently
```

## Summary

This workflow ensures:
- ✅ Fast and accurate face recognition
- ✅ Secure and private data handling
- ✅ Scalable architecture
- ✅ User-friendly interface
- ✅ Reliable attendance tracking
- ✅ Comprehensive error handling

---

**Last Updated**: November 21, 2025

