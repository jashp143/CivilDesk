import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    # Service Configuration
    SERVICE_PORT = int(os.getenv("SERVICE_PORT", "8000"))
    SERVICE_HOST = os.getenv("SERVICE_HOST", "0.0.0.0")
    
    # Database Configuration
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = int(os.getenv("DB_PORT", "5432"))
    DB_NAME = os.getenv("DB_NAME", "civildesk")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    
    # Face Recognition Settings
    FACE_DETECTION_THRESHOLD = float(os.getenv("FACE_DETECTION_THRESHOLD", "0.65")) #0.5
    FACE_MATCHING_THRESHOLD = float(os.getenv("FACE_MATCHING_THRESHOLD", "0.6"))  # Increased to 0.6 for better matching
    VIDEO_CAPTURE_DURATION = int(os.getenv("VIDEO_CAPTURE_DURATION", "15")) #10
    MAX_FACES_PER_FRAME = int(os.getenv("MAX_FACES_PER_FRAME", "1")) #5
    MIN_FACE_SAMPLES = int(os.getenv("MIN_FACE_SAMPLES", "10"))  # 5Minimum face samples required for registration
    
    # Live Video Stream Settings
    STREAM_CACHE_DURATION = float(os.getenv("STREAM_CACHE_DURATION", "2.0"))  # seconds
    FAST_MODE_DETECTION_SIZE = int(os.getenv("FAST_MODE_DETECTION_SIZE", "416")) #640
    ENABLE_FACE_TRACKING = os.getenv("ENABLE_FACE_TRACKING", "True").lower() == "true"
    
    # Storage Paths
    BASE_DIR = Path(__file__).resolve().parent
    DATA_DIR = BASE_DIR / "data"
    EMBEDDINGS_PATH = Path(os.getenv("EMBEDDINGS_PATH", str(DATA_DIR / "embeddings.pkl")))
    TEMP_VIDEO_PATH = Path(os.getenv("TEMP_VIDEO_PATH", str(DATA_DIR / "temp_videos")))
    LOGS_PATH = Path(os.getenv("LOGS_PATH", str(BASE_DIR / "logs")))
    
    # CUDA/GPU Settings
    USE_GPU = os.getenv("USE_GPU", "True").lower() == "true"
    GPU_DEVICE_ID = int(os.getenv("GPU_DEVICE_ID", "0"))
    
    # Redis Configuration (Phase 4 Optimization - Enhanced Caching)
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")
    REDIS_DB = int(os.getenv("REDIS_DB", "0"))
    REDIS_ENABLED = os.getenv("REDIS_ENABLED", "True").lower() == "true"
    
    # Database connection string
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    
    @classmethod
    def create_directories(cls):
        """Create necessary directories if they don't exist"""
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)
        cls.TEMP_VIDEO_PATH.mkdir(parents=True, exist_ok=True)
        cls.LOGS_PATH.mkdir(parents=True, exist_ok=True)

# Create directories on import
Config.create_directories()

