from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
import cv2
import numpy as np
import tempfile
import logging
from pathlib import Path
from typing import Optional
import uvicorn
import io

from config import Config
from face_recognition_engine import FaceRecognitionEngine
from database import Database

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(Config.LOGS_PATH / 'face_service.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Face Recognition Service",
    description="Face recognition service for attendance management using InsightFace",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize face recognition engine
face_engine = None

@app.on_event("startup")
async def startup_event():
    """Initialize face recognition engine on startup"""
    global face_engine
    try:
        logger.info("Initializing face recognition engine...")
        face_engine = FaceRecognitionEngine()
        logger.info("Face recognition engine initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize face recognition engine: {e}")
        raise

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "face-recognition",
        "gpu_enabled": Config.USE_GPU
    }

@app.post("/face/register")
async def register_face(
    employee_id: str = Form(...),
    video: UploadFile = File(...)
):
    """
    Register face from video
    
    Captures 10 seconds of video and extracts face embeddings
    Stores embeddings as firstname_lastname:embeddings
    """
    try:
        # Get employee details from database
        employee = Database.get_employee_by_id(employee_id)
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        first_name = employee['first_name']
        last_name = employee['last_name']
        
        # Save video to temporary file
        temp_video_path = Config.TEMP_VIDEO_PATH / f"{employee_id}_{video.filename}"
        
        with open(temp_video_path, "wb") as buffer:
            content = await video.read()
            buffer.write(content)
        
        # Register face
        success = face_engine.register_face(
            employee_id=employee_id,
            first_name=first_name,
            last_name=last_name,
            video_path=temp_video_path
        )
        
        # Clean up temporary file
        temp_video_path.unlink(missing_ok=True)
        
        if success:
            return {
                "success": True,
                "message": f"Face registered successfully for {first_name} {last_name}",
                "employee_id": employee_id,
                "name": f"{first_name}_{last_name}"
            }
        else:
            raise HTTPException(
                status_code=400,
                detail="Failed to register face. Ensure face is clearly visible in video."
            )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in face registration: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/face/detect")
async def detect_faces(
    image: UploadFile = File(...)
):
    """
    Detect and recognize faces in an image
    
    Returns bounding boxes and employee information for recognized faces
    """
    try:
        # Read image
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image file")
        
        # Recognize faces
        faces = face_engine.recognize_face(img)
        
        return {
            "success": True,
            "faces": faces,
            "count": len(faces)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in face detection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/face/recognize-stream")
async def recognize_stream(
    image: UploadFile = File(...),
    fast_mode: bool = True
):
    """
    Recognize faces in real-time video stream (optimized for live detection)
    
    This endpoint is optimized for continuous video processing:
    - Uses fast_mode by default for real-time performance
    - Caches recent detections for temporal consistency
    - Returns all detected faces (recognized and unknown)
    
    Args:
        image: Video frame as image file
        fast_mode: Enable optimizations for real-time processing (default: True)
    """
    try:
        # Read image
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image file")
        
        # Recognize faces with fast_mode enabled for live video
        faces = face_engine.recognize_face(img, fast_mode=fast_mode)
        
        # Enhanced terminal logging
        print("\n" + "="*80)
        logger.info(f"🔍 FACE DETECTION: {len(faces)} face(s) detected in frame")
        print("="*80)
        
        # Format response for real-time display
        result_faces = []
        recognized_names = []  # Track names for logging
        
        for idx, face in enumerate(faces, 1):
            face_data = {
                'bbox': face['bbox'],
                'confidence': face['confidence'],
                'recognized': face['recognized'],
                'match_confidence': face['match_confidence']
            }
            
            # Add employee info if recognized
            if face['recognized']:
                face_data.update({
                    'employee_id': face['employee_id'],
                    'first_name': face['first_name'],
                    'last_name': face['last_name'],
                    'name': f"{face['first_name']}_{face['last_name']}",
                    'display_name': f"{face['first_name']} {face['last_name']}"
                })
                recognized_names.append(f"{face['first_name']}_{face['last_name']}")
                
                # Enhanced logging for recognized face
                print(f"\n✅ FACE #{idx} RECOGNIZED:")
                print(f"   👤 Name: {face['first_name']}_{face['last_name']}")
                print(f"   🆔 Employee ID: {face['employee_id']}")
                print(f"   📊 Match Confidence: {face['match_confidence']*100:.1f}%")
                print(f"   📍 BBox: ({face['bbox']['x1']}, {face['bbox']['y1']}) → ({face['bbox']['x2']}, {face['bbox']['y2']})")
                
                logger.info(f"✅ Face #{idx}: {face['first_name']}_{face['last_name']} (ID: {face['employee_id']}, Confidence: {face['match_confidence']*100:.1f}%)")
            else:
                print(f"\n⚠️  FACE #{idx} UNKNOWN:")
                print(f"   🔴 Not recognized in database")
                print(f"   📊 Detection Confidence: {face['confidence']:.2f}")
                print(f"   📍 BBox: ({face['bbox']['x1']}, {face['bbox']['y1']}) → ({face['bbox']['x2']}, {face['bbox']['y2']})")
                
                logger.info(f"⚠️  Face #{idx}: Unknown (Detection confidence: {face['confidence']:.2f})")
            
            result_faces.append(face_data)
        
        # Summary logging
        if recognized_names:
            print(f"\n📹 SUMMARY: {len(recognized_names)} face(s) recognized - {', '.join(recognized_names)}")
            logger.info(f"📹 Frame processed: {len(recognized_names)} face(s) recognized - {', '.join(recognized_names)}")
        elif len(faces) > 0:
            print(f"\n📹 SUMMARY: {len(faces)} face(s) detected but none recognized")
            logger.info(f"📹 Frame processed: {len(faces)} face(s) detected but none recognized")
        
        print("="*80 + "\n")
        
        return {
            "success": True,
            "faces": result_faces,
            "frame_processed": True
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in face recognition stream: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/face/attendance/mark")
async def mark_attendance(
    employee_id: str = Form(...),
    punch_type: str = Form(...),  # check_in, lunch_out, lunch_in, check_out
    confidence: float = Form(...)
):
    """
    Mark attendance for an employee
    
    punch_type: check_in, lunch_out, lunch_in, check_out
    """
    try:
        # Validate punch type
        valid_punch_types = ['check_in', 'lunch_out', 'lunch_in', 'check_out']
        if punch_type not in valid_punch_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid punch type. Must be one of: {', '.join(valid_punch_types)}"
            )
        
        # Get employee details
        employee = Database.get_employee_by_id(employee_id)
        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")
        
        # Mark attendance
        attendance_id = Database.mark_attendance(employee_id, punch_type, confidence)
        
        # Enhanced terminal logging for attendance marking
        print("\n" + "🎯"*40)
        print(f"✅ ATTENDANCE MARKED SUCCESSFULLY!")
        print(f"   👤 Name: {employee['first_name']}_{employee['last_name']}")
        print(f"   🆔 Employee ID: {employee_id}")
        print(f"   ⏰ Punch Type: {punch_type.upper().replace('_', ' ')}")
        print(f"   📊 Confidence: {confidence*100:.1f}%")
        print(f"   🔖 Attendance ID: {attendance_id}")
        print("🎯"*40 + "\n")
        
        logger.info(f"✅ ATTENDANCE MARKED: {employee['first_name']}_{employee['last_name']} (ID: {employee_id}) - {punch_type.upper()} - Confidence: {confidence*100:.1f}%")
        
        return {
            "success": True,
            "message": f"Attendance marked successfully for {employee['first_name']} {employee['last_name']}",
            "employee_id": employee_id,
            "punch_type": punch_type,
            "attendance_id": attendance_id
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking attendance: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/face/embeddings/{employee_id}")
async def delete_embeddings(employee_id: str):
    """
    Delete face embeddings for an employee
    """
    try:
        success = face_engine.delete_embeddings(employee_id)
        
        if success:
            return {
                "success": True,
                "message": f"Embeddings deleted for employee {employee_id}"
            }
        else:
            return {
                "success": False,
                "message": f"No embeddings found for employee {employee_id}"
            }
    
    except Exception as e:
        logger.error(f"Error deleting embeddings: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/face/embeddings/list")
async def list_embeddings():
    """
    List all registered face embeddings
    """
    try:
        embeddings_list = []
        for key, data in face_engine.embeddings_db.items():
            embeddings_list.append({
                'name': key,
                'employee_id': data['employee_id'],
                'first_name': data['first_name'],
                'last_name': data['last_name']
            })
        
        return {
            "success": True,
            "count": len(embeddings_list),
            "embeddings": embeddings_list
        }
    
    except Exception as e:
        logger.error(f"Error listing embeddings: {e}")
        raise HTTPException(status_code=500, detail=str(e))

def draw_face_boxes(image: np.ndarray, faces: list) -> np.ndarray:
    """
    Draw bounding boxes and names on the image
    
    Args:
        image: Original image
        faces: List of detected faces with recognition results
        
    Returns:
        Annotated image with bounding boxes and names
    """
    annotated_img = image.copy()
    
    for face in faces:
        bbox = face['bbox']
        recognized = face['recognized']
        
        # Get coordinates
        x1, y1 = bbox['x1'], bbox['y1']
        x2, y2 = bbox['x2'], bbox['y2']
        
        # Choose color based on recognition status
        if recognized:
            color = (0, 255, 0)  # Green for recognized
            name = f"{face['first_name']}_{face['last_name']}"
            confidence = face['match_confidence']
        else:
            color = (0, 0, 255)  # Red for unknown
            name = "Unknown"
            confidence = face['confidence']
        
        # Draw bounding box
        cv2.rectangle(annotated_img, (x1, y1), (x2, y2), color, 2)
        
        # Prepare text
        if recognized:
            text = f"{name} ({confidence*100:.1f}%)"
        else:
            text = f"{name}"
        
        # Calculate text size and position
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.6
        thickness = 2
        
        (text_width, text_height), baseline = cv2.getTextSize(text, font, font_scale, thickness)
        
        # Draw text background
        text_x = x1
        text_y = y1 - 10
        
        # Ensure text is within image bounds
        if text_y - text_height - 5 < 0:
            text_y = y2 + text_height + 10
        
        # Draw filled rectangle for text background
        cv2.rectangle(
            annotated_img,
            (text_x, text_y - text_height - 5),
            (text_x + text_width + 5, text_y + 5),
            color,
            -1  # Filled rectangle
        )
        
        # Draw text
        cv2.putText(
            annotated_img,
            text,
            (text_x + 2, text_y),
            font,
            font_scale,
            (255, 255, 255),  # White text
            thickness,
            cv2.LINE_AA
        )
    
    return annotated_img

@app.post("/face/recognize-annotated")
async def recognize_annotated(
    image: UploadFile = File(...),
    fast_mode: bool = True
):
    """
    Recognize faces and return annotated image with bounding boxes and names
    
    This endpoint processes the image, detects faces, recognizes them,
    and returns an image with bounding boxes and names drawn on it.
    
    Args:
        image: Image file
        fast_mode: Enable optimizations for real-time processing (default: True)
        
    Returns:
        Annotated image (JPEG) with bounding boxes and names
    """
    try:
        # Read image
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image file")
        
        # Recognize faces
        faces = face_engine.recognize_face(img, fast_mode=fast_mode)
        
        print("\n" + "🖼️ "*30)
        logger.info(f"🖼️  ANNOTATING IMAGE: {len(faces)} face(s) detected")
        
        # Draw bounding boxes and names
        annotated_img = draw_face_boxes(img, faces)
        
        # Log recognized faces with details
        recognized_names = []
        for face in faces:
            if face['recognized']:
                name = f"{face['first_name']}_{face['last_name']}"
                recognized_names.append(name)
                print(f"   ✅ Drawing bbox for: {name} (ID: {face['employee_id']})")
        
        if recognized_names:
            print(f"🖼️  Total recognized: {len(recognized_names)} - {', '.join(recognized_names)}")
            logger.info(f"🖼️  Annotated image: {len(recognized_names)} face(s) recognized - {', '.join(recognized_names)}")
        elif len(faces) > 0:
            print(f"🖼️  Total detected: {len(faces)} (none recognized)")
            logger.info(f"🖼️  Annotated image: {len(faces)} face(s) detected but none recognized")
        
        print("🖼️ "*30 + "\n")
        
        # Encode image to JPEG
        _, buffer = cv2.imencode('.jpg', annotated_img, [cv2.IMWRITE_JPEG_QUALITY, 90])
        
        # Convert to bytes
        img_bytes = io.BytesIO(buffer.tobytes())
        
        # Return as image
        return StreamingResponse(img_bytes, media_type="image/jpeg")
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in face recognition with annotation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=Config.SERVICE_HOST,
        port=Config.SERVICE_PORT,
        reload=True
    )

