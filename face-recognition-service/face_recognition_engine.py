import cv2
import numpy as np
import pickle
import logging
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import insightface
from insightface.app import FaceAnalysis
from config import Config

# Phase 2 Optimization: FAISS for fast face matching
try:
    import faiss
    FAISS_AVAILABLE = True
except ImportError:
    FAISS_AVAILABLE = False
    logging.warning("FAISS not available. Using linear search for face matching.")

# Phase 4 Optimization: Redis caching
try:
    import redis
    import json
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    logging.warning("Redis not available. Using in-memory cache only.")

logger = logging.getLogger(__name__)

class FaceRecognitionEngine:
    """Face recognition engine using InsightFace with FAISS optimization"""
    
    def __init__(self):
        self.app = None
        self.embeddings_db = {}
        self.detection_threshold = Config.FACE_DETECTION_THRESHOLD
        self.matching_threshold = Config.FACE_MATCHING_THRESHOLD
        self.face_cache = {}  # Cache for recent face detections
        self.cache_duration = Config.STREAM_CACHE_DURATION
        self.ctx_id = -1  # Device ID for model
        
        # FAISS index for fast similarity search
        self.faiss_index = None
        self.index_to_key = {}  # Map FAISS index to embeddings_db key
        
        # Phase 4 Optimization: Redis client for distributed caching
        self.redis_client = None
        if REDIS_AVAILABLE and Config.REDIS_ENABLED:
            try:
                self.redis_client = redis.Redis(
                    host=Config.REDIS_HOST,
                    port=Config.REDIS_PORT,
                    password=Config.REDIS_PASSWORD if Config.REDIS_PASSWORD else None,
                    db=Config.REDIS_DB,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5,
                )
                # Test connection
                self.redis_client.ping()
                logger.info("Redis connection established for face recognition service")
            except Exception as e:
                logger.warning(f"Redis not available: {e}. Using in-memory cache only.")
                self.redis_client = None
        
        self._initialize_model()
        self._load_embeddings()
    
    def _initialize_model(self):
        """Initialize InsightFace model with GPU/CPU support"""
        try:
            # Determine device
            self.ctx_id = -1  # CPU
            if Config.USE_GPU:
                try:
                    import onnxruntime as ort
                    providers = ort.get_available_providers()
                    if 'CUDAExecutionProvider' in providers:
                        self.ctx_id = Config.GPU_DEVICE_ID
                        logger.info(f"Using GPU (device {self.ctx_id}) for face recognition")
                    else:
                        logger.warning("CUDA not available, falling back to CPU")
                except Exception as e:
                    logger.warning(f"Error checking CUDA: {e}, falling back to CPU")
            else:
                logger.info("Using CPU for face recognition")
            
            # Initialize FaceAnalysis
            self.app = FaceAnalysis(
            
                providers=['CUDAExecutionProvider', 'CPUExecutionProvider'] if self.ctx_id >= 0 else ['CPUExecutionProvider']
            )
            #name='buffalo_l',
            # Set detection size based on config (smaller for faster processing)
            det_size = (Config.FAST_MODE_DETECTION_SIZE, Config.FAST_MODE_DETECTION_SIZE)
            self.app.prepare(ctx_id=self.ctx_id, det_size=det_size)
            
            logger.info(f"Face recognition model initialized successfully (detection size: {det_size})")
            
        except Exception as e:
            logger.error(f"Error initializing face recognition model: {e}")
            raise
    
    def _load_embeddings(self):
        """Load face embeddings from pickle file"""
        try:
            if Config.EMBEDDINGS_PATH.exists():
                with open(Config.EMBEDDINGS_PATH, 'rb') as f:
                    self.embeddings_db = pickle.load(f)
                
                # CRITICAL: Ensure all stored embeddings are normalized
                logger.info(f"Loaded {len(self.embeddings_db)} face embeddings from database")
                for key, data in self.embeddings_db.items():
                    embedding = data['embedding']
                    norm = np.linalg.norm(embedding)
                    logger.info(f"   {key}: embedding norm = {norm:.4f}")
                    if norm > 1.01 or norm < 0.99:  # Not normalized (should be ~1.0)
                        logger.warning(f"   [WARN] {key} embedding not normalized! Normalizing now...")
                        data['embedding'] = embedding / norm
                
                logger.info("All embeddings verified and normalized")
                
                # Build FAISS index for fast matching
                self._build_faiss_index()
            else:
                self.embeddings_db = {}
                logger.info("No existing embeddings database found, starting fresh")
        except Exception as e:
            logger.error(f"Error loading embeddings: {e}")
            self.embeddings_db = {}
    
    def _build_faiss_index(self):
        """Build FAISS index for fast similarity search - Phase 2 Optimization"""
        if not FAISS_AVAILABLE:
            logger.warning("FAISS not available, skipping index build")
            return
        
        if not self.embeddings_db:
            logger.info("No embeddings to index")
            self.faiss_index = None
            self.index_to_key = {}
            return
        
        try:
            # Get embedding dimension from first embedding
            first_key = next(iter(self.embeddings_db))
            dimension = len(self.embeddings_db[first_key]['embedding'])
            
            # Create FAISS index for Inner Product (cosine similarity with normalized vectors)
            self.faiss_index = faiss.IndexFlatIP(dimension)
            
            # Prepare embeddings array
            embeddings = []
            self.index_to_key = {}
            
            for idx, (key, data) in enumerate(self.embeddings_db.items()):
                embedding = np.array(data['embedding'], dtype=np.float32)
                # Normalize for cosine similarity
                embedding = embedding / np.linalg.norm(embedding)
                embeddings.append(embedding)
                self.index_to_key[idx] = key
            
            # Convert to numpy array and add to index
            embeddings_array = np.array(embeddings).astype('float32')
            self.faiss_index.add(embeddings_array)
            
            logger.info(f"FAISS index built successfully with {len(embeddings)} embeddings (dimension: {dimension})")
            
        except Exception as e:
            logger.error(f"Error building FAISS index: {e}")
            self.faiss_index = None
            self.index_to_key = {}
    
    def _save_embeddings(self):
        """Save face embeddings to pickle file"""
        try:
            with open(Config.EMBEDDINGS_PATH, 'wb') as f:
                pickle.dump(self.embeddings_db, f)
            logger.info(f"Saved {len(self.embeddings_db)} face embeddings to database")
        except Exception as e:
            logger.error(f"Error saving embeddings: {e}")
            raise
    
    def detect_faces(self, image: np.ndarray, fast_mode: bool = False) -> List[Dict]:
        """
        Detect faces in an image (optimized for video streams)
        
        Args:
            image: BGR image from OpenCV
            fast_mode: If True, use faster but slightly less accurate detection
            
        Returns:
            List of detected faces with bounding boxes and embeddings
        """
        try:
            # Convert BGR to RGB
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Detect faces (detection size is set during initialization)
            faces = self.app.get(rgb_image)
            
            results = []
            for face in faces[:Config.MAX_FACES_PER_FRAME]:
                bbox = face.bbox.astype(int)
                results.append({
                    'bbox': {
                        'x1': int(bbox[0]),
                        'y1': int(bbox[1]),
                        'x2': int(bbox[2]),
                        'y2': int(bbox[3])
                    },
                    'confidence': float(face.det_score),
                    'embedding': face.embedding,
                    'landmarks': face.kps.tolist() if hasattr(face, 'kps') else None
                })
            
            return results
        except Exception as e:
            logger.error(f"Error detecting faces: {e}")
            return []
    
    def extract_embeddings_from_video(
        self, 
        video_path: Path, 
        duration: int = 10
    ) -> Optional[np.ndarray]:
        """
        Extract face embeddings from video
        
        Args:
            video_path: Path to video file
            duration: Duration in seconds to capture
            
        Returns:
            Average embedding vector or None if no face detected
        """
        try:
            cap = cv2.VideoCapture(str(video_path))
            fps = cap.get(cv2.CAP_PROP_FPS)
            
            # If FPS is very low or invalid, use default
            if fps < 1 or fps > 120:
                fps = 30  # Default to 30 FPS
                logger.warning(f"Invalid FPS detected, using default: {fps}")
            
            total_frames = int(fps * duration)
            
            embeddings = []
            frame_count = 0
            processed_count = 0
            
            logger.info(f"Processing video: {fps} FPS, {total_frames} total frames")
            
            while frame_count < total_frames:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # Process every 3rd frame (was 5th) - more samples
                if frame_count % 3 == 0:
                    faces = self.detect_faces(frame)
                    processed_count += 1
                    
                    # Take the first face if multiple detected
                    if faces and len(faces) > 0:
                        embeddings.append(faces[0]['embedding'])
                        if len(embeddings) % 5 == 0:  # Log progress
                            logger.info(f"Collected {len(embeddings)} face samples so far...")
                
                frame_count += 1
            
            cap.release()
            
            logger.info(f"Processed {processed_count} frames, collected {len(embeddings)} face samples")
            
            # Require at least 5 good samples (was 10) - more lenient
            if len(embeddings) < 5:
                logger.warning(f"Not enough face samples: {len(embeddings)}. Need at least 5 samples. "
                             f"Make sure face is clearly visible throughout the video.")
                return None
            
            # If we have less than 10 samples, log a warning but continue
            if len(embeddings) < 10:
                logger.warning(f"Low number of face samples: {len(embeddings)}. "
                             f"For best results, ensure face is clearly visible and well-lit.")
            
            # Average all embeddings
            avg_embedding = np.mean(embeddings, axis=0)
            # Normalize
            avg_embedding = avg_embedding / np.linalg.norm(avg_embedding)
            
            logger.info(f"Successfully extracted and averaged {len(embeddings)} embeddings from video")
            return avg_embedding
            
        except Exception as e:
            logger.error(f"Error extracting embeddings from video: {e}")
            return None
    
    def register_face(self, employee_id: str, first_name: str, last_name: str, 
                     video_path: Path) -> bool:
        """
        Register a face from video
        
        Args:
            employee_id: Employee ID
            first_name: First name
            last_name: Last name
            video_path: Path to video file
            
        Returns:
            True if registration successful
        """
        try:
            embedding = self.extract_embeddings_from_video(
                video_path, 
                Config.VIDEO_CAPTURE_DURATION
            )
            
            if embedding is None:
                return False
            
            # Store with format: firstname_lastname
            key = f"{first_name}_{last_name}"
            self.embeddings_db[key] = {
                'employee_id': employee_id,
                'embedding': embedding,
                'first_name': first_name,
                'last_name': last_name
            }
            
            self._save_embeddings()
            
            # Rebuild FAISS index with new embedding (Phase 2 Optimization)
            self._build_faiss_index()
            
            logger.info(f"Registered face for {key} (ID: {employee_id})")
            return True
            
        except Exception as e:
            logger.error(f"Error registering face: {e}")
            return False
    

    def recognize_face(self, image: np.ndarray, fast_mode: bool = True) -> List[Dict]:
        """
        Recognize faces in an image by matching against all stored embeddings
        Uses FAISS for O(log n) search when available (Phase 2 Optimization)
        
        Args:
            image: BGR image from OpenCV
            fast_mode: Use optimizations for real-time video processing
            
        Returns:
            List of recognized faces with employee info
        """
        try:
            # Detect faces in the image
            detected_faces = self.detect_faces(image, fast_mode=fast_mode)
            
            logger.info(f"Detected {len(detected_faces)} face(s) in image")
            logger.info(f"Stored embeddings: {len(self.embeddings_db)}")
            logger.info(f"Matching threshold: {self.matching_threshold}")
            
            results = []
            
            # Use FAISS for fast matching if available and index is built
            use_faiss = FAISS_AVAILABLE and self.faiss_index is not None and self.faiss_index.ntotal > 0
            if use_faiss:
                logger.info("Using FAISS for fast face matching")
            
            # Process each detected face
            for face_idx, face in enumerate(detected_faces, 1):
                detected_embedding = face['embedding']
                bbox = face['bbox']
                
                # Normalize the detected embedding
                embedding_norm = np.linalg.norm(detected_embedding)
                if embedding_norm > 0:
                    normalized_embedding = detected_embedding / embedding_norm
                else:
                    normalized_embedding = detected_embedding
                
                logger.info(f"\nProcessing Face #{face_idx}:")
                logger.info(f"  Embedding norm: {np.linalg.norm(normalized_embedding):.4f}")
                
                best_match = None
                best_similarity = 0.0
                best_match_key = None
                
                if use_faiss:
                    # FAISS-based fast search (O(log n))
                    query = np.array([normalized_embedding], dtype=np.float32)
                    similarities, indices = self.faiss_index.search(query, 1)
                    
                    best_similarity = float(similarities[0][0])
                    best_idx = int(indices[0][0])
                    
                    if best_idx >= 0 and best_idx in self.index_to_key:
                        best_match_key = self.index_to_key[best_idx]
                        best_match = self.embeddings_db.get(best_match_key)
                        logger.info(f"  FAISS match: {best_match_key}, similarity = {best_similarity:.4f}")
                else:
                    # Linear search fallback (O(n))
                    for key, data in self.embeddings_db.items():
                        stored_embedding = data['embedding']
                        
                        # Ensure stored embedding is normalized
                        stored_norm = np.linalg.norm(stored_embedding)
                        if stored_norm > 0:
                            stored_embedding = stored_embedding / stored_norm
                        
                        # Calculate COSINE SIMILARITY (dot product of normalized vectors)
                        similarity = float(np.dot(normalized_embedding, stored_embedding))
                        similarity = max(0.0, min(1.0, similarity))
                        
                        logger.info(f"  {key}: similarity = {similarity:.4f}")
                        
                        if similarity > best_similarity:
                            best_similarity = similarity
                            best_match = data
                            best_match_key = key
                
                # Check if best match is ABOVE threshold
                recognized = False
                employee_id = None
                first_name = None
                last_name = None
                match_confidence = 0.0
                
                if best_match and best_similarity >= self.matching_threshold:
                    recognized = True
                    employee_id = best_match['employee_id']
                    first_name = best_match['first_name']
                    last_name = best_match['last_name']
                    match_confidence = float(best_similarity)
                    
                    logger.info(f"✅ RECOGNIZED: {first_name}_{last_name} (Similarity: {best_similarity:.4f}, Confidence: {match_confidence*100:.1f}%)")
                else:
                    if best_match:
                        logger.warning(f"❌ NOT RECOGNIZED: Best match '{best_match_key}' has similarity {best_similarity:.4f} < threshold {self.matching_threshold}")
                    else:
                        logger.warning(f"❌ NOT RECOGNIZED: No embeddings in database")
                
                # Append result
                results.append({
                    'bbox': bbox,
                    'confidence': face['confidence'],
                    'recognized': recognized,
                    'employee_id': employee_id,
                    'first_name': first_name,
                    'last_name': last_name,
                    'match_confidence': match_confidence
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Error recognizing faces: {e}")
            return []
    

    def _calculate_similarity(self, embedding1: np.ndarray, embedding2: np.ndarray) -> float:
        """Calculate cosine similarity between two normalized embeddings"""
        # Normalize embeddings
        emb1_norm = embedding1 / np.linalg.norm(embedding1)
        emb2_norm = embedding2 / np.linalg.norm(embedding2)
        
        # Calculate cosine similarity
        similarity = float(np.dot(emb1_norm, emb2_norm))
        
        # Ensure similarity is between 0 and 1
        return max(0.0, min(1.0, similarity))

    
    def _calculate_distance(self, embedding1: np.ndarray, embedding2: np.ndarray) -> float:
        """Calculate Euclidean distance between two embeddings"""
        return float(np.linalg.norm(embedding1 - embedding2))
    
    def _cleanup_cache(self):
        """Remove old entries from face cache"""
        try:
            current_time = cv2.getTickCount()
            keys_to_remove = []
            
            for key, entry in self.face_cache.items():
                age = (current_time - entry['timestamp']) / cv2.getTickFrequency()
                if age > self.cache_duration * 2:  # Remove entries older than 2x cache duration
                    keys_to_remove.append(key)
            
            for key in keys_to_remove:
                del self.face_cache[key]
                
        except Exception as e:
            logger.error(f"Error cleaning cache: {e}")
    
    def get_employee_cached(self, employee_id: str):
        """
        Get employee with Redis caching (Phase 4 Optimization)
        
        Args:
            employee_id: Employee ID to lookup
            
        Returns:
            Employee data or None
        """
        if not self.redis_client:
            # Fallback to direct database lookup
            from database import Database
            return Database.get_employee_by_id(employee_id)
        
        cache_key = f"employee:{employee_id}"
        
        try:
            # Try to get from cache
            cached = self.redis_client.get(cache_key)
            if cached:
                import json
                return json.loads(cached)
            
            # Cache miss - get from database
            from database import Database
            employee = Database.get_employee_by_id(employee_id)
            
            if employee:
                # Cache for 5 minutes
                import json
                self.redis_client.setex(
                    cache_key,
                    300,  # 5 minutes TTL
                    json.dumps(employee, default=str)
                )
            
            return employee
        except Exception as e:
            logger.warning(f"Redis cache error for employee {employee_id}: {e}")
            # Fallback to direct database lookup
            from database import Database
            return Database.get_employee_by_id(employee_id)
    
    def invalidate_employee_cache(self, employee_id: str):
        """
        Invalidate employee cache when employee data changes
        
        Args:
            employee_id: Employee ID to invalidate
        """
        if self.redis_client:
            try:
                cache_key = f"employee:{employee_id}"
                self.redis_client.delete(cache_key)
            except Exception as e:
                logger.warning(f"Error invalidating cache for {employee_id}: {e}")
    
    def delete_embeddings(self, employee_id: str) -> bool:
        """
        Delete face embeddings for an employee
        
        Args:
            employee_id: Employee ID
            
        Returns:
            True if deleted successfully
        """
        try:
            # Find and remove embeddings with this employee_id
            keys_to_delete = []
            for key, data in self.embeddings_db.items():
                if data['employee_id'] == employee_id:
                    keys_to_delete.append(key)
            
            for key in keys_to_delete:
                del self.embeddings_db[key]
            
            if keys_to_delete:
                self._save_embeddings()
                
                # Rebuild FAISS index after deletion (Phase 2 Optimization)
                self._build_faiss_index()
                
                logger.info(f"Deleted {len(keys_to_delete)} embeddings for employee {employee_id}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error deleting embeddings: {e}")
            return False

