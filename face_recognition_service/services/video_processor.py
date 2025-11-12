"""
Video Processing Service for face registration
"""
import cv2
import numpy as np
from typing import Dict, List
from services.face_detector import FaceDetector
from services.face_recognizer import FaceRecognizer
from services.embedding_manager import EmbeddingManager


class VideoProcessor:
    """
    Processes video for face registration and embedding extraction
    """
    
    def __init__(self, face_detector: FaceDetector, face_recognizer: FaceRecognizer, 
                 embedding_manager: EmbeddingManager):
        """
        Initialize video processor
        
        Args:
            face_detector: FaceDetector instance
            face_recognizer: FaceRecognizer instance
            embedding_manager: EmbeddingManager instance
        """
        self.face_detector = face_detector
        self.face_recognizer = face_recognizer
        self.embedding_manager = embedding_manager
        self.target_duration = 10  # 10 seconds
        self.fps = 30  # Target FPS for processing
        self.min_faces_required = 5  # Minimum number of face detections required
    
    def process_registration_video(self, video_path: str, employee_id: str) -> Dict:
        """
        Process a 10-second video to extract face embeddings
        
        Args:
            video_path: Path to video file
            employee_id: Employee identifier
            
        Returns:
            Dictionary with success status and results
        """
        try:
            # Open video
            cap = cv2.VideoCapture(video_path)
            
            if not cap.isOpened():
                return {
                    'success': False,
                    'error': 'Could not open video file'
                }
            
            # Get video properties
            fps = cap.get(cv2.CAP_PROP_FPS)
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = total_frames / fps if fps > 0 else 0
            
            # Check video duration
            if duration < self.target_duration * 0.8:  # Allow 20% tolerance
                cap.release()
                return {
                    'success': False,
                    'error': f'Video too short. Required: {self.target_duration}s, Got: {duration:.2f}s'
                }
            
            # Process frames
            embeddings = []
            frame_count = 0
            processed_frames = 0
            face_detections_count = 0
            
            # Calculate frame skip to process at target FPS
            frame_skip = max(1, int(fps / self.fps)) if fps > 0 else 1
            
            print(f"Processing video: {duration:.2f}s, {total_frames} frames, {fps:.2f} FPS")
            
            while cap.isOpened():
                ret, frame = cap.read()
                
                if not ret:
                    break
                
                # Skip frames to process at target FPS
                if frame_count % frame_skip != 0:
                    frame_count += 1
                    continue
                
                # Detect faces in frame
                detections = self.face_detector.detect_faces(frame)
                
                if len(detections) > 0:
                    # Use the first (largest) face detection
                    detection = detections[0]
                    face_detections_count += 1
                    
                    # Extract embedding
                    embedding = None
                    if detection.get('face_object') and hasattr(detection['face_object'], 'embedding'):
                        embedding = detection['face_object'].embedding
                    else:
                        # Extract face region and get embedding
                        face_region = self.face_detector.extract_face_region(frame, detection['bbox'])
                        embedding = self.face_recognizer.extract_embedding(face_region)
                    
                    if embedding is not None:
                        embeddings.append(embedding)
                        processed_frames += 1
                
                frame_count += 1
                
                # Stop if we have enough embeddings
                if len(embeddings) >= 30:  # Collect up to 30 embeddings
                    break
            
            cap.release()
            
            # Validate results
            if face_detections_count < self.min_faces_required:
                return {
                    'success': False,
                    'error': f'Insufficient face detections. Required: {self.min_faces_required}, Got: {face_detections_count}'
                }
            
            if len(embeddings) < self.min_faces_required:
                return {
                    'success': False,
                    'error': f'Insufficient embeddings extracted. Required: {self.min_faces_required}, Got: {len(embeddings)}'
                }
            
            # Store embeddings
            self.embedding_manager.add_embeddings(employee_id, embeddings)
            
            return {
                'success': True,
                'embeddings_count': len(embeddings),
                'face_detections': face_detections_count,
                'processed_frames': processed_frames
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Error processing video: {str(e)}'
            }
    
    def extract_frame_embeddings(self, video_path: str, max_frames: int = 30) -> List[np.ndarray]:
        """
        Extract embeddings from video frames (utility method)
        
        Args:
            video_path: Path to video file
            max_frames: Maximum number of frames to process
            
        Returns:
            List of embeddings
        """
        try:
            cap = cv2.VideoCapture(video_path)
            embeddings = []
            frame_count = 0
            
            while cap.isOpened() and len(embeddings) < max_frames:
                ret, frame = cap.read()
                
                if not ret:
                    break
                
                # Detect and extract embedding
                detections = self.face_detector.detect_faces(frame)
                
                if len(detections) > 0:
                    detection = detections[0]
                    embedding = None
                    
                    if detection.get('face_object') and hasattr(detection['face_object'], 'embedding'):
                        embedding = detection['face_object'].embedding
                    else:
                        face_region = self.face_detector.extract_face_region(frame, detection['bbox'])
                        embedding = self.face_recognizer.extract_embedding(face_region)
                    
                    if embedding is not None:
                        embeddings.append(embedding)
                
                frame_count += 1
            
            cap.release()
            return embeddings
            
        except Exception as e:
            print(f"Error extracting frame embeddings: {e}")
            return []

