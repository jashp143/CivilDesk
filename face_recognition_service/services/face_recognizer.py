"""
Face Recognition Service using InsightFace
"""
import cv2
import numpy as np
from insightface.app import FaceAnalysis
from services.face_detector import FaceDetector
from services.embedding_manager import EmbeddingManager


class FaceRecognizer:
    """
    Face recognition class for matching detected faces with stored embeddings
    """
    
    def __init__(self, threshold=0.6):
        """
        Initialize face recognizer
        
        Args:
            threshold: Similarity threshold for face matching (0.0 to 1.0)
        """
        self.threshold = threshold
        self.face_detector = FaceDetector()
        self.embedding_manager = EmbeddingManager()
        
        # Initialize InsightFace for embedding extraction (optimized)
        try:
            # Try GPU first, fallback to CPU
            providers = []
            try:
                import onnxruntime
                available_providers = onnxruntime.get_available_providers()
                if 'CUDAExecutionProvider' in available_providers:
                    providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
                    print("Face recognizer: CUDA available - using GPU acceleration")
                else:
                    providers = ['CPUExecutionProvider']
                    print("Face recognizer: CUDA not available - using CPU")
            except:
                providers = ['CPUExecutionProvider']
            
            # Use smaller det_size for faster processing
            self.face_analysis = FaceAnalysis(providers=providers)
            self.face_analysis.prepare(ctx_id=0, det_size=(320, 320))
            print("Face recognizer initialized successfully with optimized settings")
        except Exception as e:
            print(f"Error initializing face recognizer: {e}")
            self.face_analysis = None
    
    def extract_embedding(self, image, face_detection=None):
        """
        Extract face embedding from an image
        
        Args:
            image: numpy array image (BGR format)
            face_detection: Optional face detection object from detector
            
        Returns:
            numpy array of face embedding (512-dimensional vector)
        """
        try:
            if self.face_analysis is None:
                return None
            
            if face_detection and hasattr(face_detection, 'embedding'):
                # Use embedding from detection if available
                return face_detection.embedding
            
            # Extract embedding using InsightFace
            faces = self.face_analysis.get(image)
            if len(faces) > 0:
                return faces[0].embedding
            else:
                return None
                
        except Exception as e:
            print(f"Error extracting embedding: {e}")
            return None
    
    def calculate_similarity(self, embedding1, embedding2):
        """
        Calculate cosine similarity between two embeddings
        
        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector
            
        Returns:
            Similarity score (0.0 to 1.0)
        """
        try:
            # Normalize embeddings
            emb1_norm = embedding1 / np.linalg.norm(embedding1)
            emb2_norm = embedding2 / np.linalg.norm(embedding2)
            
            # Calculate cosine similarity
            similarity = np.dot(emb1_norm, emb2_norm)
            
            # Ensure similarity is between 0 and 1
            similarity = max(0.0, min(1.0, similarity))
            
            return float(similarity)
        except Exception as e:
            print(f"Error calculating similarity: {e}")
            return 0.0
    
    def recognize_face(self, embedding):
        """
        Recognize a face by matching embedding with stored embeddings
        
        Args:
            embedding: Face embedding vector
            
        Returns:
            Dictionary with employee_id and confidence, or None if no match
        """
        if embedding is None:
            return None
        
        try:
            stored_embeddings = self.embedding_manager.load_embeddings()
            
            if not stored_embeddings:
                return None
            
            best_match = None
            best_similarity = 0.0
            
            # Compare with all stored embeddings
            for employee_id, employee_embeddings in stored_embeddings.items():
                for stored_embedding in employee_embeddings:
                    similarity = self.calculate_similarity(embedding, stored_embedding)
                    
                    if similarity > best_similarity:
                        best_similarity = similarity
                        best_match = {
                            'employee_id': employee_id,
                            'confidence': similarity
                        }
            
            # Return match if above threshold
            if best_match and best_match['confidence'] >= self.threshold:
                return best_match
            else:
                return None
                
        except Exception as e:
            print(f"Error recognizing face: {e}")
            return None
    
    def detect_and_recognize(self, image_path):
        """
        Detect faces in an image and recognize them (optimized for speed)
        
        Args:
            image_path: Path to image file
            
        Returns:
            List of detected faces with recognition results
        """
        try:
            # Read image
            image = cv2.imread(image_path)
            if image is None:
                return []
            
            # Resize image for faster processing (max 800px width/height)
            height, width = image.shape[:2]
            max_dimension = 800
            if width > max_dimension or height > max_dimension:
                scale = max_dimension / max(width, height)
                new_width = int(width * scale)
                new_height = int(height * scale)
                image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_LINEAR)
                print(f"Resized image from {width}x{height} to {new_width}x{new_height} for faster processing")
            
            # Use face_analysis directly for detection (faster, gets embedding in one pass)
            if self.face_analysis is None:
                # Fallback to face_detector
                detections = self.face_detector.detect_faces(image)
                results = []
                for detection in detections:
                    bbox = detection['bbox']
                    face_region = self.face_detector.extract_face_region(image, bbox)
                    embedding = self.extract_embedding(face_region)
                    recognition = self.recognize_face(embedding) if embedding is not None else None
                    
                    result = {
                        'bbox': bbox,
                        'confidence': detection['confidence'],
                        'recognized': recognition is not None,
                    }
                    if recognition:
                        result['employee_id'] = recognition['employee_id']
                        result['match_confidence'] = recognition['confidence']
                    else:
                        result['employee_id'] = None
                        result['match_confidence'] = 0.0
                    results.append(result)
                return results
            
            # Fast path: Use face_analysis.get() which does detection + embedding in one call
            faces = self.face_analysis.get(image)
            
            if not faces:
                return []
            
            # Load embeddings once (not per face)
            stored_embeddings = self.embedding_manager.load_embeddings()
            
            results = []
            for face in faces:
                bbox = face.bbox.astype(int)
                bbox_dict = {
                    'x1': int(bbox[0]),
                    'y1': int(bbox[1]),
                    'x2': int(bbox[2]),
                    'y2': int(bbox[3])
                }
                
                # Use embedding directly from face object (already computed)
                embedding = face.embedding if hasattr(face, 'embedding') else None
                
                # Recognize face (optimized - embeddings already loaded)
                recognition = None
                if embedding is not None and stored_embeddings:
                    best_match = None
                    best_similarity = 0.0
                    
                    # Compare with all stored embeddings
                    for employee_id, employee_embeddings in stored_embeddings.items():
                        for stored_embedding in employee_embeddings:
                            similarity = self.calculate_similarity(embedding, stored_embedding)
                            if similarity > best_similarity:
                                best_similarity = similarity
                                best_match = {
                                    'employee_id': employee_id,
                                    'confidence': similarity
                                }
                    
                    # Return match if above threshold
                    if best_match and best_match['confidence'] >= self.threshold:
                        recognition = best_match
                
                result = {
                    'bbox': bbox_dict,
                    'confidence': float(face.det_score),
                    'recognized': recognition is not None,
                }
                
                if recognition:
                    result['employee_id'] = recognition['employee_id']
                    result['match_confidence'] = recognition['confidence']
                else:
                    result['employee_id'] = None
                    result['match_confidence'] = 0.0
                
                results.append(result)
            
            return results
            
        except Exception as e:
            print(f"Error in detect_and_recognize: {e}")
            import traceback
            traceback.print_exc()
            return []

