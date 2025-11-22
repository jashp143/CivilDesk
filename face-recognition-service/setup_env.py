#!/usr/bin/env python3
"""
Setup script to create .env file for face recognition service
"""

import os
from pathlib import Path

def create_env_file():
    """Create .env file with default configuration"""
    env_content = """# Face Recognition Service Configuration
SERVICE_PORT=8000
SERVICE_HOST=0.0.0.0

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USER=postgres
DB_PASSWORD=your_password_here

# Face Recognition Settings
FACE_DETECTION_THRESHOLD=0.65 #0.5
FACE_MATCHING_THRESHOLD=0.6
VIDEO_CAPTURE_DURATION=15
MAX_FACES_PER_FRAME=1    #5

# Live Video Stream Settings (NEW - for real-time detection)
STREAM_CACHE_DURATION=2.0          # Cache duration for face tracking (seconds)
FAST_MODE_DETECTION_SIZE=416 #640       # Detection size in fast mode (smaller = faster)
ENABLE_FACE_TRACKING=True          # Enable temporal face tracking cache

# Storage Paths
EMBEDDINGS_PATH=./data/embeddings.pkl
TEMP_VIDEO_PATH=./data/temp_videos
LOGS_PATH=./logs

# CUDA/GPU Settings
USE_GPU=True
GPU_DEVICE_ID=0
"""
    
    env_path = Path(__file__).parent / '.env'
    
    if env_path.exists():
        print(f'ℹ .env file already exists at {env_path}')
        print('✓ Skipping creation to preserve existing configuration')
        return
    
    with open(env_path, 'w') as f:
        f.write(env_content)
    
    print(f'✓ Created .env file at {env_path}')
    print('\n⚠ Please update the database credentials in .env file')
    print('⚠ Update DB_PASSWORD with your actual PostgreSQL password')

if __name__ == '__main__':
    create_env_file()

