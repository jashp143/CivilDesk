#!/usr/bin/env python3
"""
Test script for face recognition service
"""

import requests
import cv2
import numpy as np
import tempfile
from pathlib import Path

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"✓ Health check: {response.json()}")
        return True
    except Exception as e:
        print(f"✗ Health check failed: {e}")
        return False

def test_face_detection():
    """Test face detection with a sample image"""
    print("\nTesting face detection...")
    try:
        # Create a dummy image
        img = np.zeros((480, 640, 3), dtype=np.uint8)
        
        # Save to temporary file
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            cv2.imwrite(tmp.name, img)
            tmp_path = tmp.name
        
        # Send request
        with open(tmp_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(f"{BASE_URL}/face/detect", files=files)
        
        # Clean up
        Path(tmp_path).unlink()
        
        print(f"✓ Face detection response: {response.json()}")
        return True
    except Exception as e:
        print(f"✗ Face detection failed: {e}")
        return False

def test_embeddings_list():
    """Test listing embeddings"""
    print("\nTesting embeddings list...")
    try:
        response = requests.get(f"{BASE_URL}/face/embeddings/list")
        data = response.json()
        print(f"✓ Embeddings count: {data.get('count', 0)}")
        if data.get('embeddings'):
            print(f"  Registered employees:")
            for emb in data['embeddings'][:5]:  # Show first 5
                print(f"    - {emb['name']} (ID: {emb['employee_id']})")
        return True
    except Exception as e:
        print(f"✗ Embeddings list failed: {e}")
        return False

def test_gpu_status():
    """Test GPU availability"""
    print("\nTesting GPU status...")
    try:
        import onnxruntime as ort
        providers = ort.get_available_providers()
        print(f"  Available providers: {providers}")
        
        if 'CUDAExecutionProvider' in providers:
            print("✓ GPU (CUDA) is available")
        else:
            print("✓ Using CPU (CUDA not available)")
        
        return True
    except Exception as e:
        print(f"✗ GPU status check failed: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Face Recognition Service Test Suite")
    print("=" * 60)
    
    tests = [
        ("Health Check", test_health),
        ("GPU Status", test_gpu_status),
        ("Face Detection", test_face_detection),
        ("Embeddings List", test_embeddings_list),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, result))
        except Exception as e:
            print(f"✗ {name} raised exception: {e}")
            results.append((name, False))
    
    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    
    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status:10} {name}")
    
    total = len(results)
    passed = sum(1 for _, result in results if result)
    print(f"\nTotal: {passed}/{total} tests passed")

if __name__ == '__main__':
    main()

