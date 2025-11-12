"""
Face Detection Service using InsightFace
"""
import cv2
import numpy as np
from insightface.app import FaceAnalysis


class FaceDetector:
    """
    Face detection class using InsightFace RetinaFace model
    """
    
    def __init__(self, model_path='models/retinaface_r50_v1.onnx'):
        """
        Initialize face detector with InsightFace RetinaFace model
        
        Args:
            model_path: Path to the RetinaFace ONNX model
        """
        self.model_path = model_path
        self.detector = None
        self._initialize_detector()
    
    def _initialize_detector(self):
        """Initialize the InsightFace face detector (optimized for speed)"""
        try:
            # Try GPU first, fallback to CPU
            providers = []
            try:
                # Try CUDA if available
                import onnxruntime
                available_providers = onnxruntime.get_available_providers()
                if 'CUDAExecutionProvider' in available_providers:
                    providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
                    print("CUDA available - using GPU acceleration")
                else:
                    providers = ['CPUExecutionProvider']
                    print("CUDA not available - using CPU")
            except:
                providers = ['CPUExecutionProvider']
            
            # Initialize InsightFace app for face detection
            # Use smaller det_size for faster processing (320x320 instead of 640x640)
            self.detector = FaceAnalysis(providers=providers)
            self.detector.prepare(ctx_id=0, det_size=(320, 320))
            print("Face detector initialized successfully with optimized settings")
        except Exception as e:
            print(f"Error initializing face detector: {e}")
            # Fallback to OpenCV Haar Cascade if InsightFace fails
            self.detector = cv2.CascadeClassifier(
                cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            )
            print("Using OpenCV Haar Cascade as fallback")
    
    def detect_faces(self, image):
        """
        Detect faces in an image
        
        Args:
            image: numpy array image (BGR format)
            
        Returns:
            List of face detections with bounding boxes and landmarks
        """
        try:
            if isinstance(self.detector, FaceAnalysis):
                # InsightFace detection
                faces = self.detector.get(image)
                detections = []
                
                for face in faces:
                    bbox = face.bbox.astype(int)
                    detections.append({
                        'bbox': {
                            'x1': int(bbox[0]),
                            'y1': int(bbox[1]),
                            'x2': int(bbox[2]),
                            'y2': int(bbox[3])
                        },
                        'confidence': float(face.det_score),
                        'landmarks': face.landmark_2d_106.tolist() if hasattr(face, 'landmark_2d_106') else None,
                        'face_object': face  # Keep face object for embedding extraction
                    })
                
                return detections
            else:
                # OpenCV Haar Cascade fallback
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
                faces = self.detector.detectMultiScale(
                    gray,
                    scaleFactor=1.1,
                    minNeighbors=5,
                    minSize=(30, 30)
                )
                
                detections = []
                for (x, y, w, h) in faces:
                    detections.append({
                        'bbox': {
                            'x1': int(x),
                            'y1': int(y),
                            'x2': int(x + w),
                            'y2': int(y + h)
                        },
                        'confidence': 1.0,
                        'landmarks': None,
                        'face_object': None
                    })
                
                return detections
                
        except Exception as e:
            print(f"Error detecting faces: {e}")
            return []
    
    def extract_face_region(self, image, bbox):
        """
        Extract face region from image based on bounding box
        
        Args:
            image: numpy array image
            bbox: Dictionary with x1, y1, x2, y2 coordinates
            
        Returns:
            Cropped face image
        """
        x1 = max(0, bbox['x1'])
        y1 = max(0, bbox['y1'])
        x2 = min(image.shape[1], bbox['x2'])
        y2 = min(image.shape[0], bbox['y2'])
        
        face_region = image[y1:y2, x1:x2]
        return face_region

